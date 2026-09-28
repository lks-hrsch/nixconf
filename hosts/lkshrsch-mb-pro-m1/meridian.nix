{ inputs, ... }:
{
  # Meridian: exposes this user's Claude Max subscription as a local
  # Anthropic-/OpenAI-compatible API on 0.0.0.0:3456 (LAN).
  #
  # MERIDIAN_API_KEY is REQUIRED for LAN exposure — without it anyone on the
  # network can burn the subscription. launchd services can't read the login
  # Keychain, so auth uses a long-lived `claude setup-token` OAuth token
  # instead of `claude login`. Both secrets come from sops at runtime and
  # never enter the Nix store or plist.
  configurations.darwin."lkshrsch-mb-pro-m1".module =
    { config, pkgs, ... }:
    let
      # From meridian's flake; fall back to .default if the attr is renamed.
      meridianBase =
        inputs.meridian.packages.${pkgs.stdenv.hostPlatform.system}.meridian
          or inputs.meridian.packages.${pkgs.stdenv.hostPlatform.system}.default;
      meridian = meridianBase.override { claude-code = pkgs.unstable.claude-code; };

      keyPath = config.sops.secrets."meridian/api-key".path;
      tokenPath = config.sops.secrets."meridian/oauth-token".path;

      start = pkgs.writeShellScript "meridian-start" ''
        export MERIDIAN_API_KEY="$(cat "${keyPath}")"
        export CLAUDE_CODE_OAUTH_TOKEN="$(cat "${tokenPath}")"
        # Isolated config dir with no .credentials.json — the SDK must not
        # fall back to on-disk creds and mask token failures (meridian#446).
        export CLAUDE_CONFIG_DIR="/Users/lkshrsch/.config/meridian/sdk-config"
        mkdir -p "$CLAUDE_CONFIG_DIR"
        exec ${meridian}/bin/meridian
      '';
    in
    {
      sops.secrets."meridian/api-key" = {
        sopsFile = ../../secrets/secrets.yaml;
        key = "meridian/api-key";
        owner = "lkshrsch";
        mode = "0400";
      };

      # claude setup-token; rotates annually — update sops and rebuild.
      sops.secrets."meridian/oauth-token" = {
        sopsFile = ../../secrets/secrets.yaml;
        key = "meridian/oauth-token";
        owner = "lkshrsch";
        mode = "0400";
      };

      # Same firewall gotcha as llama-cpp.nix. The listening binary is node,
      # extracted from the wrapper since meridian doesn't expose its nodejs.
      system.activationScripts.postActivation.text = ''
        sfw=/usr/libexec/ApplicationFirewall/socketfilterfw
        node=$(grep -o '/nix/store/[^" ]*/bin/node' "${meridian}/bin/meridian" | head -1)
        if [ -n "$node" ]; then
          "$sfw" --add "$node" >/dev/null
          "$sfw" --unblockapp "$node" >/dev/null
        fi
      '';

      # Daemon, not agent: nix-darwin loads agents as root into the system
      # domain anyway; a UserName daemon runs there as lkshrsch and starts
      # at boot without a login (headless clamshell server).
      launchd.daemons.meridian = {
        serviceConfig = {
          ProgramArguments = [ "${start}" ];
          UserName = "lkshrsch";
          GroupName = "staff";
          EnvironmentVariables = {
            MERIDIAN_HOST = "0.0.0.0";
            MERIDIAN_PORT = "3456";
          };
          KeepAlive = true;
          RunAtLoad = true;
          StandardOutPath = "/Users/lkshrsch/Library/Logs/meridian.log";
          StandardErrorPath = "/Users/lkshrsch/Library/Logs/meridian.err.log";
        };
      };
    };
}
