_: {
  flake.modules.homeManager.opencode =
    { pkgs, config, ... }:
    let
      # Paths to decrypted secret files. sops-nix creates these at activation
      # time in $XDG_RUNTIME_DIR/secrets/... (mode 0400, owner-only).
      # Only the PATH is interpolated into the Nix store — never the value.
      secretPath = name: config.sops.secrets."opencode/provider/${name}".path;
    in
    {
      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        package = pkgs.unstable.opencode;
        settings = {
          "plugin" = [
            "opencode-with-claude"
            "opencode-dcp"
          ];
          "provider" = {
            "anthropic" = {
              "options" = {
                # {file:...} is resolved by opencode at runtime, not by Nix at
                # eval time. The decrypted file must exist when opencode starts.
                "baseURL" = "{file:${secretPath "anthropic/base-url"}}";
                "apiKey" = "{file:${secretPath "anthropic/api-key"}}";
              };
            };
            "develappers" = {
              "npm" = "@ai-sdk/openai-compatible";
              "name" = "develappers - vllm (local)";
              "options" = {
                "baseURL" = "{file:${secretPath "develappers/base-url"}}";
                "apiKey" = "{file:${secretPath "develappers/api-key"}}";
              };
              "models" = {
                "qwen3-coder-next:latest" = {
                  "name" = "qwen3-coder-next:latest";
                  "limit" = {
                    "context" = 128000;
                    "output" = 8192;
                  };
                };
              };
            };
          };
        };
      };
    };
}
