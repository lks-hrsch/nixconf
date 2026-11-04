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
        rev = "4ae2317ddb22b046e26455e4f9c9b3aaaf62212d";
        hash = "sha256-3vhd77xfZjKUYJsIwPFevIZPUAzUgZXr0RYj5NQrBwk=";
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
          rev = "a138857cc23f0abaf214b72b15d974e61598369b"; # ctx7@0.9.0
          hash = "sha256-TLRU0Tqe3Rnwp9T2fTvKbSk/nnBvy+vk5311lhOS76o=";
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
          rev = "1c68c8af745fd4e88c67aac2f34947c8bea6ce49";
          hash = "sha256-WvNylKxZwqRVmwXUI1WTYryJHLDkzb7RLOVn+8qsYLI=";
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

      # graphify ships one SKILL.md per agent (skill.md, skill-opencode.md) plus per-agent references/,
      # so postFetch reshapes the repo into the layout `graphify install --platform <agent>` writes
      # (minus its .graphify_version stamp). Bump the version with its hash: it also pins the CLI below.
      graphifyVersion = "0.9.102";
      graphify = pkgs.fetchFromGitHub {
        name = "graphify-skills-${graphifyVersion}";
        owner = "Graphify-Labs";
        repo = "graphify";
        rev = "v${graphifyVersion}";
        hash = "sha256-qI4NDTtrBQyGhWjdrCqaqkI40u7pFkDLLcv7nCFSUN0=";
        postFetch = ''
          tmp=$(mktemp -d)
          for agent in claude opencode; do
            mkdir $tmp/$agent
            mv $out/graphify/skills/$agent/references $tmp/$agent/references
          done
          mv $out/graphify/skill.md $tmp/claude/SKILL.md
          mv $out/graphify/skill-opencode.md $tmp/opencode/SKILL.md
          rm -rf $out
          mv $tmp $out
        '';
      };
    in
    {
      programs = {
        claude-code.skills = skillPaths // {
          graphify = "${graphify}/claude";
        };
        opencode.skills = skillPaths // {
          graphify = "${graphify}/opencode";
        };
        # graphify CLI the skill drives: PyPI package `graphifyy`, command `graphify`.
        # programs.uv.tool comes from overlays/uv-module.nix, imported by claude-code.nix.
        uv.tool.packages = [ "graphifyy==${graphifyVersion}" ];
      };
    };
}
