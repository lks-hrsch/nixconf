_: {
  flake.modules.homeManager.opencode =
    {
      pkgs,
      config,
      ...
    }:
    let
      secretPath = name: config.sops.secrets."opencode/provider/${name}".path;

      superpowers = pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "3dcbd5c4b48e02263fbf4a3c01e3fe4f81d584d9"; # v6.2.0
        hash = "sha256-F5LEk0yNWbMpan1vZSFZM76XSpsFGvA7h8q6Idrvenk=";
      };
      ponytail = pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        rev = "16f29800fd2681bdf24f3eb4ccffe38be3baec6b"; # v4.8.4 + 53
        hash = "sha256-Y7d4s7uqjH6IbEXhqAiQ+yaxr6iiGcv2X64LuMtG1T8=";
      };
      caveman = pkgs.fetchFromGitHub {
        owner = "JuliusBrussee";
        repo = "caveman";
        rev = "fcf7663366c217dc8f334a11028de52ed950ceab"; # v1.10.0
        hash = "sha256-3lPEPb+hzomLLz4xfU7wQS++10gXP0UbXHXq/yluAGM=";
      };
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
        package = pkgs.unstable.opencode;
        settings = {
          "skills"."paths" = [ "${caveman}/skills" ];
          "plugin" = [
            # Retained existing version-pinned OpenCode npm plugins.
            "opencode-with-claude@1.6.14"
            "@tarquinen/opencode-dcp@3.1.14"
            # New native integrations are store-backed and installer-free.
            "${superpowers}/.opencode/plugins/superpowers.js"
            "${ponytail}/.opencode/plugins/ponytail.mjs"
            # The source-tree entry uses Caveman's built-in helper fallback.
            "${caveman}/src/plugins/opencode/plugin.js"
          ];
          "model" = "github-copilot/gpt-5.6-terra";
          "small_model" = "github-copilot/gpt-5.6-luna";
          "lsp" = {
            "pyrefly" = {
              "command" = [
                "pyrefly"
                "lsp"
              ];
              "extensions" = [
                ".py"
                ".pyi"
              ];
            };
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
