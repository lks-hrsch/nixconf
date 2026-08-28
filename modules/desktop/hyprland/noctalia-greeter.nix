{ config, inputs, ... }:
let
  inherit (config.flake.users.owner) username;
in
{
  flake.modules.nixos.desktop-hyprland-noctalia-greeter =
    {
      config,
      pkgs,
      ...
    }:
    let
      hm = config.home-manager.users.${username};
      colors = hm.lib.stylix.colors.withHashtag;
    in
    {

      # noctalia-greeter's NixOS module lives only in nixpkgs-unstable (26.11) —
      # 26.05 has neither the module nor the package. Drop this import and the
      # pkgs.unstable pin below once the system nixpkgs reaches 26.11.
      imports = [
        "${inputs.nixpkgs-unstable}/nixos/modules/services/display-managers/noctalia-greeter.nix"
      ];

      services.greetd.enable = true;

      services.displayManager.noctalia-greeter = {
        enable = true;
        package = pkgs.unstable.noctalia-greeter;
        cursorTheme = {
          inherit (hm.stylix.cursor) name package;
        };
        settings = {
          session.default = "Hyprland (uwsm-managed)"; # label from hyprland-uwsm.desktop
          user.default = username;
          output.name = config.desktop.monitors.primary;
          cursor.size = hm.stylix.cursor.size;
          keyboard = {
            layout = "gb"; # matches modules/desktop/hyprland/hyprland.nix kb_layout
            options = "grp:alt_shift_toggle";
          };
          appearance = {
            scheme = "Synced";
            theme_mode = "dark";
            font_family = hm.stylix.fonts.sansSerif.name;
            wallpaper = {
              path = toString hm.stylix.image;
              fill_mode = "crop";
            };
            # Same stylix base16 roles as modules/desktop/hyprland/noctalia.nix
            # customPalettes.stylix — keep both in sync if the mapping changes.
            palette = {
              primary = colors.base0F;
              on_primary = colors.base00;
              secondary = colors.base07;
              on_secondary = colors.base00;
              tertiary = colors.base0D;
              on_tertiary = colors.base00;
              error = colors.base08;
              on_error = colors.base00;
              surface = colors.base00;
              on_surface = colors.base05;
              surface_variant = colors.base00;
              on_surface_variant = colors.base05;
              outline = colors.base03;
              shadow = colors.base00;
              hover = colors.base02;
              on_hover = colors.base05;
            };
          };
        };
      };

      # The greeter runs as `greeter`, not ${username} — stylix only installs
      # fonts into the user profile, so the greeter needs its own copy.
      fonts.packages = [ hm.stylix.fonts.sansSerif.package ];
    };
}
