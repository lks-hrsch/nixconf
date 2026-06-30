# Declarative agent skills shared across claude-code and opencode.
#
# Each skill pins a GitHub source; the fetched store path is handed to the native
# home-manager options programs.{claude-code,opencode}.skills, which symlink it
# into ~/.claude/skills/<name> and $XDG_CONFIG_HOME/opencode/skills/<name>.
#
# To add a skill:
#   1. nix run nixpkgs#nix-prefetch-github -- <owner> <repo>
#   2. Add an entry below with the returned rev + hash and the subdir holding SKILL.md.
#   3. Rebuild.
_: {
  flake.modules.homeManager.skills =
    {
      lib,
      pkgs,
      ...
    }:
    let
      # name -> GitHub source pin + subdir containing SKILL.md
      skills = {
        obsidian = {
          # companion skill to the @bitbonsai/mcpvault MCP server (mcp.nix)
          owner = "bitbonsai";
          repo = "mcpvault";
          rev = "ed18307c205c4c8bedc242601304fc4c50f63918";
          hash = "sha256-3jAb7lWZAK0eEfL4nfYeP+KMnmS3dCfn/JKU0hJ8bf8=";
          subdir = "skills/obsidian";
        };
        context7-mcp = {
          # companion skill to the context7 MCP server (mcp.nix)
          owner = "upstash";
          repo = "context7";
          rev = "b1fb8b523263143db858d09698f9c67e3be79e33";
          hash = "sha256-7bqUsYnpceA9GG/t/p24Y8c47YPHwYiYlJQ2Xqs/FzQ=";
          subdir = "skills/context7-mcp";
        };
        find-skills = {
          owner = "vercel-labs";
          repo = "skills";
          rev = "2adcfe5a4cce0ce5f4d5547a997b2a161ec5d127";
          hash = "sha256-176EeM1VhNSBH1cYUUy3oLST21PbV0v+tCNglfM9+6Y=";
          subdir = "skills/find-skills";
        };
        grill-me = {
          owner = "mattpocock";
          repo = "skills";
          rev = "801dca688564c529fa84f247f64472520d9ebe28";
          hash = "sha256-nIA5wobtzjSoOe6ZgRiiUoLxkISEG9/Omk2OXg13twI=";
          subdir = "skills/productivity/grill-me";
        };
        grill-with-docs = {
          owner = "mattpocock";
          repo = "skills";
          rev = "801dca688564c529fa84f247f64472520d9ebe28";
          hash = "sha256-nIA5wobtzjSoOe6ZgRiiUoLxkISEG9/Omk2OXg13twI=";
          subdir = "skills/engineering/grill-with-docs";
        };
        tdd = {
          owner = "mattpocock";
          repo = "skills";
          rev = "801dca688564c529fa84f247f64472520d9ebe28";
          hash = "sha256-nIA5wobtzjSoOe6ZgRiiUoLxkISEG9/Omk2OXg13twI=";
          subdir = "skills/engineering/tdd";
        };
        improve-codebase-architecture = {
          owner = "mattpocock";
          repo = "skills";
          rev = "801dca688564c529fa84f247f64472520d9ebe28";
          hash = "sha256-nIA5wobtzjSoOe6ZgRiiUoLxkISEG9/Omk2OXg13twI=";
          subdir = "skills/engineering/improve-codebase-architecture";
        };
      };

      # name -> store path of the skill's directory (containing SKILL.md). Identical
      # pins share one fetchFromGitHub derivation, so a repo is fetched only once.
      skillPaths = lib.mapAttrs (
        _: s: "${pkgs.fetchFromGitHub { inherit (s) owner repo rev hash; }}/${s.subdir}"
      ) skills;
    in
    {
      programs.claude-code.skills = skillPaths;
      programs.opencode.skills = skillPaths;
    };
}
