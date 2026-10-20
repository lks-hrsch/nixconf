_: {
  # Self-hosted GitHub Actions runners for Xcode/tvOS builds. One runner per
  # repo (a runner registers to exactly one repo), all as `_github-runner`.
  #
  # Hand-rolled instead of nix-darwin's services.github-runners: that module
  # asserts nix.enable, which base.nix turns off for Determinate Nix.
  #
  # Workflows expect /Applications/Xcode-27.1.app. Xcode comes from the App
  # Store (masApps in modules/darwin/homebrew.nix); the homebrew step runs
  # before postActivation, which renames it and finishes setup.
  # shortcut: App Store only serves the latest Xcode, and onActivation.upgrade
  # updates it in place; pin via a .xip install if the workflow needs exact 27.1.
  configurations.darwin."lkshrsch-mb-pro-m1".module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      xcodeVersion = "27.1";
      xcode = "/Applications/Xcode-${xcodeVersion}.app";
      user = "_github-runner";
      root = "/var/lib/github-runners";
      labels = "self-hosted,macOS,ARM64,xcode-${xcodeVersion},tvos,ios";

      # name -> repo URL. Each gets state in ${root}/<name> and a sops token
      # at github-runner/<name>.
      runners = {
        ci-streamyfin = "https://github.com/lks-hrsch/streamyfin";
        ci-ldr-connect = "https://github.com/lks-hrsch/ldr-connect";
      };

      tokenFile = name: config.sops.secrets."github-runner/${name}".path;
      forRunners = f: lib.mapAttrs' f runners;
    in
    {
      users.users.${user} = {
        uid = 533;
        gid = 533;
        home = root;
        createHome = false;
        shell = "/bin/bash";
        description = "GitHub Runner service user";
      };
      users.groups.${user} = {
        gid = 533;
        description = "GitHub Runner service user group";
      };
      users.knownUsers = [ user ];
      users.knownGroups = [ user ];

      # Registration tokens expire after 1h but are only needed for the first
      # registration; credentials then live in ${root}/<name>/.runner.
      # To re-register: new token in sops, delete .runner, rebuild.
      sops.secrets = forRunners (
        name: _:
        lib.nameValuePair "github-runner/${name}" {
          sopsFile = ../../secrets/secrets-lkshrsch-mb-pro-m1.yaml;
          key = "github-runner/${name}";
          owner = user;
          mode = "0400";
        }
      );

      launchd.daemons = forRunners (
        name: url:
        let
          stateDir = "${root}/${name}";
          workDir = "${root}/_work/${name}";
        in
        lib.nameValuePair "github-runner-${name}" {
          environment = {
            HOME = stateDir;
            RUNNER_ROOT = stateDir;
          };
          # xcodebuild/xcrun live in /usr/bin; nix from the Determinate profile.
          path = with pkgs; [
            bash
            coreutils
            git
            gnutar
            gzip
            "/nix/var/nix/profiles/default/bin"
            "/usr/bin"
            "/bin"
            "/usr/sbin"
            "/sbin"
          ];
          # Same flow as the nix-darwin module: register once, then listen.
          # A missing token (sops not ready at boot) exits; KeepAlive retries.
          script = ''
            set -euo pipefail
            find ${workDir} -mindepth 1 -delete
            if [ ! -f "$RUNNER_ROOT/.runner" ]; then
              token=$(<"${tokenFile name}")
              case "$token" in
                ghp_* | github_pat_*) auth=--pat ;;
                *) auth=--token ;;
              esac
              ${pkgs.github-runner}/bin/config.sh --unattended --disableupdate \
                --url ${lib.escapeShellArg url} \
                --name ${name} \
                --work ${workDir} \
                --labels ${labels} \
                "$auth" "$token"
            fi
            exec ${pkgs.github-runner}/bin/Runner.Listener run --startuptype service
          '';
          serviceConfig = {
            UserName = user;
            GroupName = user;
            KeepAlive = true;
            RunAtLoad = true;
            ThrottleInterval = 30;
            ProcessType = "Interactive";
            WorkingDirectory = stateDir;
            WatchPaths = [ (tokenFile name) ];
            StandardOutPath = "/var/log/github-runners/${name}.log";
            StandardErrorPath = "/var/log/github-runners/${name}.err.log";
          };
        }
      );

      # Dirs must exist, owned by the runner, before launchd starts it.
      system.activationScripts.launchd.text =
        let
          dirs = lib.concatStringsSep " " (
            [
              root
              "${root}/_work"
              "/var/log/github-runners"
            ]
            ++ lib.concatMap (name: [
              "${root}/${name}"
              "${root}/_work/${name}"
            ]) (lib.attrNames runners)
          );
        in
        lib.mkBefore ''
          mkdir -p ${dirs}
          chmod 0750 ${dirs}
          chown ${user}:${user} ${dirs}
        '';

      # Runs as root. Every step is guarded: a failing command here aborts
      # the rest of activation (home-manager, sops).
      system.activationScripts.postActivation.text = ''
        echo "configuring Xcode ${xcodeVersion}..." >&2
        if [ ! -e ${xcode} ] && [ -d /Applications/Xcode.app ]; then
          v=$(/usr/bin/defaults read /Applications/Xcode.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || true)
          if [ "$v" = "${xcodeVersion}" ]; then
            mv /Applications/Xcode.app ${xcode}
          else
            echo "warning: /Applications/Xcode.app is '$v', not ${xcodeVersion}; not renaming" >&2
          fi
        fi
        if [ -d ${xcode} ]; then
          if [ "$(/usr/bin/xcode-select -p)" != "${xcode}/Contents/Developer" ]; then
            /usr/bin/xcode-select -s ${xcode} || echo "warning: xcode-select failed" >&2
          fi
          /usr/bin/xcodebuild -checkFirstLaunchStatus >/dev/null 2>&1 \
            || /usr/bin/xcodebuild -runFirstLaunch \
            || echo "warning: xcodebuild -runFirstLaunch failed" >&2
          # Multi-GB downloads, first activation only.
          for p in tvOS iOS; do
            if ! /usr/bin/xcrun simctl runtime list 2>/dev/null | grep -q "$p"; then
              /usr/bin/xcodebuild -downloadPlatform "$p" || echo "warning: $p platform download failed" >&2
            fi
          done
        else
          echo "warning: ${xcode} missing; install Xcode ${xcodeVersion} to /Applications" >&2
        fi
      '';
    };
}
