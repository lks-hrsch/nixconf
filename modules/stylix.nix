{ ... }:
{
  flake.homeManagerModules.stylix =
    {
      pkgs,
      config,
      ...
    }:
    let
      #################################################################################
      # Catppuccin Mocha Palette (Full) with Base16 Mapping Override and change to OLED
      #################################################################################
      # Define each color using its common name, then build a Base16 mapping.
      # https://catppuccin.com/palette/
      # https://github.com/catppuccin/infinity/issues/3#issuecomment-1581791124

      catppuccinMocha = {
        # Full Palette Definitions
        rosewater = "#f5e0dc"; # Soft pastel rose
        flamingo = "#f2cdcd"; # Muted pink
        pink = "#f5c2e7"; # Gentle pink hue
        mauve = "#cba6f7"; # Warm mauve/purple
        red = "#f38ba8"; # Bold red for emphasis
        maroon = "#eba0ac"; # Soft maroon accent
        peach = "#fab387"; # Vibrant peach
        yellow = "#f9e2af"; # Soft, warm yellow
        green = "#a6e3a1"; # Calming green
        teal = "#94e2d5"; # Light teal
        sky = "#89dceb"; # Soothing sky blues
        sapphire = "#74c7ec"; # Cool sapphire blue
        blue = "#89b4fa"; # Vivid blue tone
        lavender = "#b4befe"; # Delicate lavender for highlights
        text = "#cdd6f4"; # Primary text color
        subtext1 = "#bac2de"; # Slightly muted secondary text
        subtext0 = "#a6adc8"; # More subdued tertiary text
        overlay2 = "#9399b2"; # Low contrast overlay for inactive elements
        overlay1 = "#7f849c"; # Darker overlay for subtle UI details
        overlay0 = "#6c7086"; # Dark overlay used for hints
        surface2 = "#585b70"; # Darker background for panels
        surface1 = "#45475a"; # Medium surface background
        surface0 = "#313244"; # Lighter surface background
        base = "#040404"; # "#1e1e2e"; # Original base (kept for reference)
        mantle = "#080808"; # "#181825"; # Slightly lighter than base (e.g. for status bars)
        crust = "#000000"; # "#11111b"; # Deepest shade (used as base00 below)

      };
      # Base16 Mapping: Building the mapping by referencing the named colors.
      # https://github.com/catppuccin/base16/blob/main/base16/mocha.yaml
      # Note: Here we want base00 to use "crust".
      base16 = {
        base00 = catppuccinMocha.crust; # Default Background
        base01 = catppuccinMocha.mantle; # Lighter Background
        base02 = catppuccinMocha.surface0; # Selection Background
        base03 = catppuccinMocha.surface1; # Comments/invisibles
        base04 = catppuccinMocha.surface2; # Dark Foreground
        base05 = catppuccinMocha.text; # Default Foreground
        base06 = catppuccinMocha.rosewater; # Light Foreground
        base07 = catppuccinMocha.lavender; # Light Background
        base08 = catppuccinMocha.red; # Variables/XML tags/diff deleted
        base09 = catppuccinMocha.peach; # Integers/XML attributes
        base0A = catppuccinMocha.yellow; # Classes/markup bold/search background
        base0B = catppuccinMocha.green; # Strings/markup code
        base0C = catppuccinMocha.teal; # Support/regex/quotes
        base0D = catppuccinMocha.blue; # Functions/headings
        base0E = catppuccinMocha.mauve; # Keywords/selectors/markup italic
        base0F = catppuccinMocha.flamingo; # Deprecated/embedded language tags
      };
    in
    {
      home.packages = with pkgs; [
        # It is sometimes useful to fine-tune packages, for example, by applying
        # overrides. You can do that directly here, just don't forget the
        # parentheses. Maybe you want to install Nerd Fonts with a limited number of
        # fonts?
        font-awesome
        nerd-fonts.jetbrains-mono
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji

        # Icon packages
        adwaita-icon-theme
      ];

      stylix = {
        enable = true;
        autoEnable = true;
        # Path is relative to modules/homeManager/features -> up to /etc/nixos, then into wallpaper/
        image = ../../../wallpaper/anime-girl-cherry-blossom-train-looking-away-4k-oc.png;
        polarity = "dark";

        base16Scheme = base16;

        # https://fonts.google.com/?query=Notos
        fonts = {
          monospace = {
            package = pkgs.nerd-fonts.jetbrains-mono;
            name = "JetBrainsMono Nerd Font Mono";
          };
          sansSerif = {
            package = pkgs.noto-fonts;
            name = "Noto Sans";
          };
          serif = config.stylix.fonts.sansSerif; # Use same as sansSerif
          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };
        };

        cursor = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 22;
        };

        targets = {
          mako = {
            enable = false; # lkshrsch profile: The option definition `services.mako.extraConfig' in `/nix/store/hfig46d452pr4i0g5ks17571z38cs1il-source/modules/mako/hm.nix' no longer has any effect; please remove it. Use services.mako.settings instead.
          };
          firefox = {
            profileNames = [ "lkshrsch" ];
          };
          vscode = {
            profileNames = [
              "default"
              "lkshrsch"
            ];
          };
          waybar = {
            addCss = false;
          };
          gnome.enable = pkgs.stdenv.isLinux; # Only enable GNOME theming on Linux
        };
      };
    };
}
