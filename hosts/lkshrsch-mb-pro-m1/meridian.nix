{ inputs, ... }:
{
  # Meridian: re-exposes this user's Claude Max subscription as a local
  # Anthropic-/OpenAI-compatible HTTP API, LAN-accessible on 0.0.0.0:3456.
  #
  # MERIDIAN_API_KEY is REQUIRED for LAN exposure — without it anyone on the
  # network can burn the subscription. The key is sourced from sops at
  # runtime (wrapper script reads the decrypted file) so it never enters the
  # Nix store or the launchd plist.
  #
  # Authentication reference: x-api-key header or "Authorization: Bearer <key>".
  # Routes /  and /health remain open; all others (including /v1/*) require
  # the key.
  #
  # Credentials: launchd LaunchAgents cannot read the macOS login Keychain
  # where `claude login` stores its OAuth token. The fix is a long-lived
  # headless token from `claude setup-token` (1-year, subscription-tied,
  # Pro/Max/Team/Enterprise), stored in sops and injected at runtime as
  # CLAUDE_CODE_OAUTH_TOKEN. Meridian passes this through to the Agent SDK.
  #
  # CLAUDE_CONFIG_DIR is pinned to an isolated directory with no
  # .credentials.json so the SDK can't fall back to on-disk creds and mask
  # token failures (meridian#446). The dir is created by the wrapper script
  # before exec so it exists the first time.
  configurations.darwin."lkshrsch-mb-pro-m1".module =
    { config, pkgs, ... }:
    let
      # Meridian package from its own flake; aarch64-darwin is in its
      # nix-systems/default set. Prefer the named attr; fall back to
      # .default if the attr name ever changes upstream.
      meridian =
        inputs.meridian.packages.${pkgs.stdenv.hostPlatform.system}.meridian
          or inputs.meridian.packages.${pkgs.stdenv.hostPlatform.system}.default;

      # Paths where sops-nix decrypts the secrets at system activation.
      keyPath = config.sops.secrets."meridian/api-key".path;
      tokenPath = config.sops.secrets."meridian/oauth-token".path;

      # Wrapper: reads both secrets at runtime, exports them, pins an
      # isolated config dir, then exec's meridian. Secrets never enter the
      # Nix store or the launchd plist.
      start = pkgs.writeShellScript "meridian-start" ''
        export MERIDIAN_API_KEY="$(cat "${keyPath}")"
        export CLAUDE_CODE_OAUTH_TOKEN="$(cat "${tokenPath}")"
        # Isolated config dir — no .credentials.json — prevents SDK from
        # silently falling back to on-disk creds (meridian#446).
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

      # Long-lived subscription OAuth token (claude setup-token).
      # Rotates annually; store the new token in sops and rebuild.
      sops.secrets."meridian/oauth-token" = {
        sopsFile = ../../secrets/secrets.yaml;
        key = "meridian/oauth-token";
        owner = "lkshrsch";
        mode = "0400";
      };

      launchd.agents.meridian = {
        serviceConfig = {
          ProgramArguments = [ "${start}" ];
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
