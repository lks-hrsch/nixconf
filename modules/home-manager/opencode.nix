_: {
  flake.modules.homeManager.opencode =
    {
      pkgs,
      config,
      ...
    }:
    let
      secretPath = name: config.sops.secrets."opencode/provider/${name}".path;

      inherit (import ../../overlays/claude-plugin-sources.nix pkgs) superpowers ponytail caveman;

      makeModel = name: context: output: {
        "name" = name;
        "limit" = {
          "context" = context;
          "output" = output;
        };
      };

      makeVllmProvider = label: secretPrefix: models: {
        "npm" = "@ai-sdk/openai-compatible";
        "name" = label;
        "options" = {
          "baseURL" = "{file:${secretPath "${secretPrefix}/base-url"}}";
          "apiKey" = "{file:${secretPath "${secretPrefix}/api-key"}}";
        };
        "models" = models;
      };
    in
    {
      programs.opencode = {
        enable = true;
        enableMcpIntegration = true;
        # shortcut: bun 1.4.4 made node_modules libc-dependent and nixpkgs' hash is stale, drop once NixOS/nixpkgs#582675 reaches nixpkgs-unstable.
        package = pkgs.unstable.opencode.overrideAttrs (old: {
          node_modules = old.node_modules.overrideAttrs {
            outputHash =
              if pkgs.stdenv.hostPlatform.isDarwin then
                "sha256-dIveiaiPFGSItwLyeMuPDxTE9gpvvnlTCB/+nG24qCc="
              else
                "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA=";
          };
        });
        settings = {
          "skills"."paths" = [ "${caveman}/skills" ];
          "plugin" = [
            # Retained existing version-pinned OpenCode npm plugins.
            "opencode-with-claude@1.11.2"
            "@tarquinen/opencode-dcp@3.2.0"
            # New native integrations are store-backed and installer-free.
            "${superpowers}/.opencode/plugins/superpowers.js"
            "${ponytail}/.opencode/plugins/ponytail.mjs"
            # The source-tree entry uses Caveman's built-in helper fallback.
            "${caveman}/src/plugins/opencode/plugin.js"
          ];
          "model" = "github-copilot/gpt-5.6-terra";
          "small_model" = "github-copilot/gpt-5.6-luna";
          "lsp" = {
            "ruff" = {
              "command" = [
                "ruff"
                "server"
              ];
              "extensions" = [
                ".py"
                ".pyi"
              ];
            };
          };
          "provider" = {
            "anthropic" = {
              "options" = {
                # {file:...} is resolved by opencode at runtime, not by Nix at
                # eval time. The decrypted file must exist when opencode starts.
                "baseURL" = "{file:${secretPath "anthropic/base-url"}}";
                "apiKey" = "{file:${secretPath "anthropic/api-key"}}";
              };
            };
            "collana" = makeVllmProvider "collana" "collana" {
              "coding" = makeModel "coding" 128000 16384;
              "general" = makeModel "general" 128000 16384;
            };
            "develappers" = makeVllmProvider "develappers - vllm (local)" "develappers" {
              "develappers-coding" = makeModel "develappers-coding" 256000 16384;
              "gemma-4-fast" = makeModel "gemma-4-fast" 256000 16384;
            };
            "vllm-workstation-nixos" =
              makeVllmProvider "lkshrsch - vllm (workstation-nixos)" "workstation-nixos"
                {
                  "google/gemma-4-E2B-it" = makeModel "google/gemma-4-E2B-it" 128000 16384;
                  "google/gemma-4-E4B-it" = makeModel "google/gemma-4-E4B-it" 128000 16384;
                  "RedHatAI/gemma-4-26B-A4B-it-NVFP4" = makeModel "RedHatAI/gemma-4-26B-A4B-it-NVFP4" 65536 8192;
                };
          };
        };
      };
    };
}
