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
        rev = "6f7f7831a625f040a8e06a0e7954826b87ce775a";
        hash = "sha256-kM/OK6+kbTHzlN5d6wjL9hM80lolcSCoO8A1oRvEJEU=";
      };

      mattpocock =
        category: names:
        lib.genAttrs names (name: mattpocockSkills // { subdir = "skills/${category}/${name}"; });

      # name -> GitHub source pin + subdir containing SKILL.md
      skills =
        # Left out, superpowers owns these phases: diagnosing-bugs, implement, implement-spec, tdd,
        # to-spec, to-tickets.
        mattpocock "engineering" [
          "ask-matt"
          "code-review"
          "codebase-design"
          "domain-modeling"
          "grill-with-docs"
          "improve-codebase-architecture"
          "pr"
          "prototype"
          "research"
          "retro"
          "setup-matt-pocock-skills"
          "triage"
          "wayfinder"
          "wizard"
        ]
        // mattpocock "productivity" [
          "grill-me"
          "grilling"
          "handoff"
          "teach"
          "to-questionnaire"
          "wait-what"
          "writing-for-agents"
        ]
        // {
          # companion skills to the MCP servers in mcp.nix
          context7-mcp = {
            owner = "upstash";
            repo = "context7";
            rev = "2c1e8641a99d344a2a016e9aaf4c5c1f4c5c6744"; # ctx7@0.13.0
            hash = "sha256-JSlo9oqnbvG6lQUREY5PjuVYoDCB4cetld7llZ48m3c=";
            subdir = "skills/context7-mcp";
          };
          obsidian = {
            owner = "bitbonsai";
            repo = "mcpvault";
            rev = "5d4e68550e9fe27fc24b9e16d96b8ff5b39355d7"; # v0.18.4
            hash = "sha256-T+HlU151bA5Gf48v08qq6xsXJoSececlGPkywO/FluA=";
            subdir = "skills/obsidian";
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
      graphifyVersion = "0.9.120";
      graphify = pkgs.fetchFromGitHub {
        name = "graphify-skills-${graphifyVersion}";
        owner = "Graphify-Labs";
        repo = "graphify";
        rev = "v${graphifyVersion}";
        hash = "sha256-BYbDcEQGZGAlhaGnOZWwdGhu6GY8wo7cYzO+SVy5lHE=";
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
          reflect = ./reflect;
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
