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
            "@tarquinen/opencode-dcp@latest"
            "superpowers@git+https://github.com/obra/superpowers.git" # https://github.com/obra/superpowers/blob/main/docs/README.opencode.md
            # "oh-my-openagent" # https://github.com/code-yeongyu/oh-my-openagent/blob/3f30dac3f14b25911f8ed1a3c199410f8125d1b2/docs/guide/installation.md
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
            "vllm-develappers" = {
              "npm" = "@ai-sdk/openai-compatible";
              "name" = "develappers - vllm (local)";
              "options" = {
                "baseURL" = "{file:${secretPath "develappers/base-url"}}";
                "apiKey" = "{file:${secretPath "develappers/api-key"}}";
              };
              "models" = {
                "develappers-coding" = {
                  "name" = "develappers-coding";
                  "limit" = {
                    "context" = 256000;
                    "output" = 16384;
                  };
                };
              };
            };
            "vllm-develappers-proxy" = {
              "npm" = "@ai-sdk/openai-compatible";
              "name" = "develappers - vllm (proxy)";
              "options" = {
                "baseURL" = "{file:${secretPath "develappers-proxy/base-url"}}";
                "apiKey" = "{file:${secretPath "develappers-proxy/api-key"}}";
              };
              "models" = {
                "develappers-coding" = {
                  "name" = "develappers-coding";
                  "limit" = {
                    "context" = 256000;
                    "output" = 16384;
                  };
                };
              };
            };
            "vllm-workstation-nixos" = {
              "npm" = "@ai-sdk/openai-compatible";
              "name" = "lkshrsch - vllm (workstation-nixos)";
              "options" = {
                "baseURL" = "{file:${secretPath "workstation-nixos/base-url"}}";
                "apiKey" = "{file:${secretPath "workstation-nixos/api-key"}}";
              };
              "models" = {
                "google/gemma-4-E2B-it" = {
                  "name" = "google/gemma-4-E2B-it";
                  "limit" = {
                    "context" = 128000;
                    "output" = 16384;
                  };
                };
                "google/gemma-4-E4B-it" = {
                  "name" = "google/gemma-4-E4B-it";
                  "limit" = {
                    "context" = 128000;
                    "output" = 16384;
                  };
                };
                "RedHatAI/gemma-4-26B-A4B-it-NVFP4" = {
                  "name" = "RedHatAI/gemma-4-26B-A4B-it-NVFP4";
                  "limit" = {
                    "context" = 65536;
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
