_: {
  flake.modules.homeManager.codex =
    # https://mynixos.com/home-manager/options/programs.codex
    # https://github.com/openai/codex-plugin-cc
    { pkgs, config, ... }:
    {
      programs.codex = {
        enable = true;
        enableMcpIntegration = true;
        package = pkgs.unstable.codex;

        # Codex persists directory-trust into ~/.codex/config.toml, but Nix makes
        # that file a read-only store symlink so the runtime write fails
        # (config/batchWrite … code -32603). Declare trust here instead — Codex
        # reads it and never needs to write. Exact-path match only (no wildcard),
        # so list every directory you launch `codex` in.
        settings.projects = {
          "/etc/nixos".trust_level = "trusted";
          "${config.home.homeDirectory}/repos.nosync".trust_level = "trusted";
        };
      };
    };
}
