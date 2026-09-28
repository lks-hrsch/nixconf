_: {
  # `tool.packages` from every module importing overlays/uv-module.nix concatenates (also set in
  # modules/home-manager/claude-code/claude-code.nix, currently `graphifyy`), so the final install
  # set is the union across every module the `base` aggregator imports. Imported here directly
  # instead of relying on claude-code.nix's import: this module must keep working standalone.
  flake.modules.homeManager.uv = _: {
    imports = [ ../../overlays/uv-module.nix ];

    # Hugging Face Hub CLI — installs the `hf` command (`hf auth login`, `hf download`, ...).
    # https://huggingface.co/docs/huggingface_hub/guides/cli
    programs.uv = {
      enable = true;
      tool = {
        packages = [
          "huggingface_hub"
          "kaggle"
        ];
        prune = true;
      };
    };
  };
}
