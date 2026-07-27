_: {
  # The `overlays/uv-module.nix` import that declares the `tool.*` options lives in
  # modules/home-manager/claude-code/claude-code.nix, which also sets `enable`/`prune` and its own
  # `tool.packages` (currently `graphifyy`). Repeating identical `enable`/`prune` values here is
  # harmless — the module system merges them — but `tool.packages` from both files concatenates,
  # so the final install set is the union across every module the `base` aggregator imports.
  flake.modules.homeManager.uv = _: {
    # Hugging Face Hub CLI — installs the `hf` command (`hf auth login`, `hf download`, ...).
    # https://huggingface.co/docs/huggingface_hub/guides/cli
    programs.uv = {
      enable = true;
      tool = {
        packages = [ "huggingface_hub" ];
        prune = true;
      };
    };
  };
}
