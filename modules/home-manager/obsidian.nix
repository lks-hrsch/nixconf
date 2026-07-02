{ config, ... }:
let
  inherit (config.repo.constants) obsidianBasePath;
in
{
  flake.modules.homeManager.obsidian =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    with config.lib.stylix.colors.withHashtag;
    let
      # Vault dirs below ${obsidianBasePath}; each gets the same nix-managed
      # style layer. The mcpvault MCP server (mcp.nix) only uses "private".
      vaultNames = [
        "private"
        "work-develappers"
      ];

      # Community plugins are deliberately NOT managed here: nix-managed
      # plugin files would be /nix/store symlinks that cannot be synced to
      # non-nix devices (iPhone). Plugins are installed/updated via the app
      # UI and sync as real files through syncthing. Nix only owns the
      # style layer (CSS snippet + appearance).
      vaultSettings = {
        # appearance.json becomes nix-managed as soon as cssSnippets is set
        # (the module materializes it for either). These values are a
        # snapshot of the previously mutable .obsidian/appearance.json;
        # enabledCssSnippets is injected by the module. Appearance changes
        # in the app UI no longer persist — edit them here instead.
        appearance = {
          accentColor = "#e8989a";
          baseFontSize = 18;
        };

        cssSnippets = [
          {
            name = "obsidian-stylix-css";
            text = ''
              :root .theme-dark {
                  --background-primary:         ${base00};
                  --background-primary-alt:     ${base01};
                  --background-secondary:       ${base01};
                  --background-secondary-alt:   ${base02};

                  --text-normal:                ${base05}; /*Text body of note*/
                  --text-muted:                 ${base05}; /*Text darker for sidebar, toggles, inactive, tags, etc*/
                  --text-accent:                ${base0D}; /*Links*/
                  --text-accent-hover:          ${base0B}; /*Links hover*/

              }
            '';
          }
        ];
      };
    in
    {
      programs.obsidian = {
        enable = true;
        package = pkgs.unstable.obsidian; # track unstable for the latest app

        # Official Obsidian CLI (`cli: true` in obsidian.json).
        cli.enable = true;

        # Vault attr name = target path relative to $HOME.
        vaults = lib.genAttrs (map (v: "${obsidianBasePath}/${v}") vaultNames) (_: {
          settings = vaultSettings;
        });
      };

      # Syncthing ignores for the vault folder (~/${obsidianBasePath}, see
      # secrets/syncthing-settings.nix). Takes over the previously manual
      # .stignore (**.nosync / **.DS_Store) and adds:
      #  - **.Trash: local macOS trash, never sync
      #  - appearance.json + snippets per vault: nix-managed /nix/store
      #    symlinks whose targets differ per machine and change on every
      #    rebuild; each nix host renders its own copy from this module.
      # .stignore itself never syncs — mirror lines manually on other devices
      # if they should also skip these paths.
      home.file."${obsidianBasePath}/.stignore".text = ''
        **.nosync
        **.DS_Store
        **.Trash
        **.trash
      ''
      + lib.concatMapStrings (v: ''
        /${v}/.obsidian/appearance.json
        /${v}/.obsidian/snippets
      '') vaultNames;
    };
}
