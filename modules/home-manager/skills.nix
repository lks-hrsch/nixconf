# https://www.skills.sh/
_: {
  flake.modules.homeManager.skills =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      cfg = config.programs.skills;

      mkSkillPath =
        skill:
        let
          fetched = pkgs.fetchFromGitHub {
            inherit (skill.src)
              owner
              repo
              rev
              hash
              ;
          };
        in
        if skill.subdir == "." then fetched else "${fetched}/${skill.subdir}";

      mkHomeFiles =
        baseDir:
        lib.mapAttrs' (
          name: skill:
          lib.nameValuePair "${baseDir}/${name}" {
            source = mkSkillPath skill;
          }
        ) cfg.skills;
    in
    {
      options.programs.skills = {
        enable = lib.mkEnableOption "Declarative agent skills shared across claude-code and opencode";

        skills = lib.mkOption {
          default = { };
          description = ''
            Attrset of agent skills, each materialised as a symlink at
            ~/.claude/skills/<name> and ~/.config/opencode/skills/<name>.

            To add a skill:
              1. nix run nixpkgs#nix-prefetch-github -- <owner> <repo>
              2. Add an entry here with the returned rev + hash.
              3. Rebuild.
          '';
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                src = lib.mkOption {
                  description = "GitHub source pin.";
                  type = lib.types.submodule {
                    options = {
                      owner = lib.mkOption { type = lib.types.str; };
                      repo = lib.mkOption { type = lib.types.str; };
                      rev = lib.mkOption { type = lib.types.str; };
                      hash = lib.mkOption {
                        type = lib.types.str;
                        description = "SRI hash from nix-prefetch-github (sha256-...=).";
                      };
                    };
                  };
                };
                subdir = lib.mkOption {
                  type = lib.types.str;
                  default = ".";
                  description = "Subdirectory within the repo containing SKILL.md. Omit if SKILL.md is at the root.";
                };
                description = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                };
              };
            }
          );
        };
      };

      config = lib.mkMerge [
        {
          programs.skills = {
            enable = lib.mkDefault true;
            skills.obsidian = {
              # https://github.com/bitbonsai/mcpvault — companion skill to the
              # @bitbonsai/mcpvault MCP server declared in mcp.nix
              src = {
                owner = "bitbonsai";
                repo = "mcpvault";
                rev = "dec984fee1f5daeac5d6a23ae1d9a62d6318fcb1";
                hash = "sha256-Hd3ml5FmD9/EvhcWfX3AgF1vJQmBQRhRbIb+rW56N8A=";
              };
              subdir = "skills/obsidian";
              description = "Obsidian vault skill (companion to @bitbonsai/mcpvault MCP server)";
            };
            skills.context7-mcp = {
              # https://github.com/upstash/context7 — companion skill to the
              # context7 MCP server declared in mcp.nix
              src = {
                owner = "upstash";
                repo = "context7";
                rev = "7cacc9460a77efe61273433e56298d03694d7ba7";
                hash = "sha256-wWD8V3sxy6WGvWKdLxA1ranwFPvRpRRCrPWKJ3IDEuw=";
              };
              subdir = "skills/context7-mcp";
              description = "Context7 MCP skill for up-to-date library documentation";
            };
          };
        }
        (lib.mkIf cfg.enable {
          home.file = (mkHomeFiles ".claude/skills") // (mkHomeFiles ".config/opencode/skills");
        })
      ];
    };
}
