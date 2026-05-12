_: {
  flake.modules.homeManager.opencode =
    { pkgs, config, ... }:
    let
      secretPath = name: config.sops.secrets."opencode/provider/${name}".path;

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
            "vllm-develappers" = makeVllmProvider "develappers - vllm (local)" "develappers" {
              "develappers-coding" = makeModel "develappers-coding" 256000 16384;
            };
            "vllm-develappers-proxy" = makeVllmProvider "develappers - vllm (proxy)" "develappers-proxy" {
              "develappers-coding" = makeModel "develappers-coding" 256000 16384;
            };
            "vllm-workstation-nixos" = makeVllmProvider "lkshrsch - vllm (workstation-nixos)" "workstation-nixos" {
              "google/gemma-4-E2B-it" = makeModel "google/gemma-4-E2B-it" 128000 16384;
              "google/gemma-4-E4B-it" = makeModel "google/gemma-4-E4B-it" 128000 16384;
              "RedHatAI/gemma-4-26B-A4B-it-NVFP4" = makeModel "RedHatAI/gemma-4-26B-A4B-it-NVFP4" 65536 8192;
            };
          };
        };
      };
    };
}
