_: {
  # Self-hosted GitHub Actions runners for Xcode/tvOS builds. One runner per
  # repo (a runner registers to exactly one repo), each with its own macOS
  # user: separate keychains (concurrent fastlane setup_ci jobs would clobber
  # a shared keychain search list) and no access to the other's credentials.
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
      root = "/var/lib/github-runners";
      logRoot = "/var/log/github-runners";
      labels = "self-hosted,macOS,ARM64,xcode-${xcodeVersion},tvos,ios";

      # name -> repo URL and uid (also the gid). Each runner gets user and
      # group `_github-runner-<name>`, home/state ${root}/<name>, and a sops token at
      # github-runner/<name>.
      runners = {
        ci-streamyfin = {
          url = "https://github.com/lks-hrsch/streamyfin";
          uid = 534;
        };
        ci-ldr-connect = {
          url = "https://github.com/lks-hrsch/ldr-connect";
          uid = 535;
        };
      };

      userOf = name: "_github-runner-${name}";
      tokenFile = name: config.sops.secrets."github-runner/${name}".path;
      forRunners = f: lib.mapAttrs' f runners;
    in
    {
      users.users = forRunners (
        name: r:
        lib.nameValuePair (userOf name) {
          inherit (r) uid;
          gid = r.uid;
          # Must match the service's HOME: macOS keeps the keychain search
          # list under the recorded home, not $HOME.
          home = "${root}/${name}";
          createHome = false;
          shell = "/bin/bash";
          description = "GitHub Runner ${name}";
        }
      );
      users.groups = forRunners (
        name: r:
        lib.nameValuePair (userOf name) {
          gid = r.uid;
          description = "GitHub Runner ${name}";
        }
      );
      # _github-runner was the old shared user; listed but undefined, so
      # nix-darwin deletes its record (dscl -delete, home left alone).
      users.knownUsers = [ "_github-runner" ] ++ map userOf (lib.attrNames runners);
      users.knownGroups = [ "_github-runner" ] ++ map userOf (lib.attrNames runners);

      # Registration tokens expire after 1h but are only needed for the first
      # registration; credentials then live in ${root}/<name>/.runner.
      # To re-register: new token in sops, delete .runner, rebuild.
      sops.secrets = forRunners (
        name: _:
        lib.nameValuePair "github-runner/${name}" {
          sopsFile = ../../secrets/secrets-lkshrsch-mb-pro-m1.yaml;
          key = "github-runner/${name}";
          owner = userOf name;
          mode = "0400";
        }
      );

      launchd.daemons = forRunners (
        name: r:
        let
          stateDir = "${root}/${name}";
          workDir = "${root}/_work/${name}";
          # Env lives in the script: sudo resets the daemon's environment.
          # Same flow as the nix-darwin module: register once, then listen.
          # A missing token (sops not ready at boot) exits; KeepAlive retries.
          runner = pkgs.writeShellScript "github-runner-${name}" ''
            set -euo pipefail
            # xcodebuild/xcrun live in /usr/bin; nix from the Determinate profile.
            export PATH=${
              lib.makeBinPath (
                with pkgs;
                [
                  bash
                  coreutils
                  git
                  gnutar
                  gzip
                ]
              )
            }:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin
            export HOME=${stateDir} RUNNER_ROOT=${stateDir}
            cd ${stateDir}
            find ${workDir} -mindepth 1 -delete
            if [ ! -f "$RUNNER_ROOT/.runner" ]; then
              token=$(<"${tokenFile name}")
              case "$token" in
                ghp_* | github_pat_*) auth=--pat ;;
                *) auth=--token ;;
              esac
              ${pkgs.github-runner}/bin/config.sh --unattended --disableupdate \
                --url ${lib.escapeShellArg r.url} \
                --name ${name} \
                --work ${workDir} \
                --labels ${labels} \
                "$auth" "$token"
            fi
            exec ${pkgs.github-runner}/bin/Runner.Listener run --startuptype service
          '';
        in
        lib.nameValuePair "github-runner-${name}" {
          # codesign can't use a keychain's private key from the system launchd
          # domain (managername "System"), even unlocked with a partition list;
          # it works in the user's own domain (tested: "Background", SIGN OK).
          # So the daemon runs as root only to enter that domain via `asuser`
          # (exec, so launchd still tracks the runner), then drops to the user.
          command = "/bin/launchctl asuser ${toString r.uid} /usr/bin/sudo -u ${userOf name} -H ${runner}";
          serviceConfig = {
            # Own security (audit) session, as in the passing test, not root's.
            SessionCreate = true;
            KeepAlive = true;
            RunAtLoad = true;
            ThrottleInterval = 30;
            ProcessType = "Interactive";
            WatchPaths = [ (tokenFile name) ];
            StandardOutPath = "${logRoot}/${name}/stdout.log";
            StandardErrorPath = "${logRoot}/${name}/stderr.log";
          };
        }
      );

      # Dirs must exist, owned by their runner, before launchd starts it.
      # chown -R only when ownership is off (migration from _github-runner);
      # DerivedData under the home makes a blanket chown -R slow.
      system.activationScripts.launchd.text = lib.mkBefore (
        ''
          mkdir -p ${root} ${root}/_work ${logRoot}
          chown root:wheel ${root} ${root}/_work ${logRoot}
          chmod 0755 ${root} ${root}/_work ${logRoot}
        ''
        + lib.concatMapStrings (
          name:
          let
            u = userOf name;
            dirs = lib.concatMapStringsSep " " (d: "${d}/${name}") [
              root
              "${root}/_work"
              logRoot
            ];
          in
          ''
            mkdir -p ${dirs} ${root}/${name}/Library/Preferences ${root}/${name}/Library/Keychains
            for d in ${dirs}; do
              [ "$(/usr/bin/stat -f %Su "$d")" = ${u} ] || chown -R ${u}:${u} "$d"
            done
            chown ${u}:${u} ${root}/${name}/Library ${root}/${name}/Library/Preferences ${root}/${name}/Library/Keychains
            chmod 0700 ${dirs}
          ''
        ) (lib.attrNames runners)
      );

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
