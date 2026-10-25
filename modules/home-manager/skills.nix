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
      # mattpocock/skills is pinned once; every mattpocock skill below points into a different
      # subdir of the same rev.
      mattpocockSkills = {
        owner = "mattpocock";
        repo = "skills";
        rev = "5beb35b040e3de97e54fa9e386d7e42d15c295c2";
        hash = "sha256-2FKfe3/Fwc4MmwBLa+d/oQW4/gtYIssdWapy2MPd39I=";
      };

      # name -> GitHub source pin + subdir containing SKILL.md
      skills = {
        code-review = mattpocockSkills // {
          subdir = "skills/engineering/code-review";
        };
        context7-mcp = {
          # companion skill to the context7 MCP server (mcp.nix)
          owner = "upstash";
          repo = "context7";
          rev = "58194009e925230037dbf92dcbd65c8a6f68803c"; # ctx7@0.8.2
          hash = "sha256-OPvv8IRNP7pjftNhoQ4M7HDr7qn3GryB5pfW8DeLZls=";
          subdir = "skills/context7-mcp";
        };
        grill-me = mattpocockSkills // {
          subdir = "skills/productivity/grill-me";
        };
        grill-with-docs = mattpocockSkills // {
          subdir = "skills/engineering/grill-with-docs";
        };
        grilling = mattpocockSkills // {
          subdir = "skills/productivity/grilling";
        };
        handoff = mattpocockSkills // {
          subdir = "skills/productivity/handoff";
        };
        improve-codebase-architecture = mattpocockSkills // {
          subdir = "skills/engineering/improve-codebase-architecture";
        };
        obsidian = {
          # companion skill to the @bitbonsai/mcpvault MCP server (mcp.nix)
          owner = "bitbonsai";
          repo = "mcpvault";
          rev = "c5abeda9bed11864079f70ae7f33d134e294aad2";
          hash = "sha256-K7MCnTBOtNYzJT1zz4v3H9y+N2lE1+S2xi8BNUXDEl0=";
          subdir = "skills/obsidian";
        };
        pr = mattpocockSkills // {
          subdir = "skills/engineering/pr";
        };
        research = mattpocockSkills // {
          subdir = "skills/engineering/research";
        };
        tdd = mattpocockSkills // {
          subdir = "skills/engineering/tdd";
        };
        writing-for-agents = mattpocockSkills // {
          subdir = "skills/productivity/writing-for-agents";
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
