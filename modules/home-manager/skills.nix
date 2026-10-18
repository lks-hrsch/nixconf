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
      # mattpocock/skills is pinned once; grill-me/grill-with-docs/tdd/improve-codebase-architecture
      # below all point into different subdirs of the same rev.
      mattpocockSkills = {
        owner = "mattpocock";
        repo = "skills";
        rev = "24fe0ef7737efae15c87225755e9f6f5965e4888";
        hash = "sha256-/mAmj7QFdyOWhLmy3Rt2/Hfsh5qwirTRax7hmQffFdo=";
      };

      # name -> GitHub source pin + subdir containing SKILL.md
      skills = {
        obsidian = {
          # companion skill to the @bitbonsai/mcpvault MCP server (mcp.nix)
          owner = "bitbonsai";
          repo = "mcpvault";
          rev = "c5abeda9bed11864079f70ae7f33d134e294aad2";
          hash = "sha256-K7MCnTBOtNYzJT1zz4v3H9y+N2lE1+S2xi8BNUXDEl0=";
          subdir = "skills/obsidian";
        };
        context7-mcp = {
          # companion skill to the context7 MCP server (mcp.nix)
          owner = "upstash";
          repo = "context7";
          rev = "e0041949fdb3b49b304d98715dde35be51b7c3d1"; # ctx7@0.8.0
          hash = "sha256-oIqqAtRGs77g1Q+Thz1/r+qGMr+xn+7O65ESqXByWh0=";
          subdir = "skills/context7-mcp";
        };
        grill-me = mattpocockSkills // {
          subdir = "skills/productivity/grill-me";
        };
        grill-with-docs = mattpocockSkills // {
          subdir = "skills/engineering/grill-with-docs";
        };
        tdd = mattpocockSkills // {
          subdir = "skills/engineering/tdd";
        };
        improve-codebase-architecture = mattpocockSkills // {
          subdir = "skills/engineering/improve-codebase-architecture";
        };
      };

      # name -> store path of the skill's directory (containing SKILL.md). Identical
      # pins share one fetchFromGitHub derivation, so a repo is fetched only once.
      skillPaths = lib.mapAttrs (
        _: s:
        "${
          pkgs.fetchFromGitHub {
            inherit (s)
              owner
              repo
              rev
              hash
              ;
          }
        }/${s.subdir}"
      ) skills;
    in
    {
      programs.claude-code.skills = skillPaths;
      programs.opencode.skills = skillPaths;
    };
}
