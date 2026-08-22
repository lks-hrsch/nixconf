_: {
  flake.modules.homeManager.stylix =
    {
      pkgs,
      config,
      ...
    }:
    let
      #################################################################################
      # Catppuccin Mocha Palette (Full) with Base16 Mapping Override
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
        base = "#1e1e2e"; # Mocha base — unused (base00 overridden to pure black for OLED)
        mantle = "#181825"; # one step below base — also unused in the mapping
        crust = "#11111b"; # deepest Mocha shade — used as base01 (alternate background)

      };
      # Base16 mapping (standard Catppuccin Mocha, OLED dark-end override).
      # Comments give the Stylix UI role first (drives GTK/Qt/Firefox/VS Code/
      # terminal across all targets) then the base16 syntax role.
      # https://nix-community.github.io/stylix/styling.html
      # https://github.com/catppuccin/base16/blob/main/base16/mocha.yaml
      # OLED override: base00 is pure black; base01 lifted to crust (#11111b)
      # so alternate backgrounds/panels stay visible against it.
      base16 = {
        base00 = "#000000"; # default background (OLED pure black, overrides Mocha base)
        base01 = catppuccinMocha.crust; # alternate background — status bars, panels, cards
        base02 = catppuccinMocha.surface0; # selection background
        base03 = catppuccinMocha.surface1; # unfocused/low-urgency borders; comments, invisibles
        base04 = catppuccinMocha.surface2; # alternate text (status bars); dark foreground
        base05 = catppuccinMocha.text; # default text / foreground
        base06 = catppuccinMocha.rosewater; # light foreground (rarely used)
        base07 = catppuccinMocha.lavender; # light background (rarely used)
        base08 = catppuccinMocha.red; # error / urgent; variables, diff deleted
        base09 = catppuccinMocha.peach; # urgent-alt; integers, constants
        base0A = catppuccinMocha.yellow; # warning; classes, search background
        base0B = catppuccinMocha.green; # accent/icon palette; strings, diff added
        base0C = catppuccinMocha.teal; # accent/icon palette; support, regex, escapes
        base0D = catppuccinMocha.blue; # focus/selection accent; functions, headings
        base0E = catppuccinMocha.mauve; # accent/icon palette; keywords, selectors
        base0F = catppuccinMocha.flamingo; # accent/icon palette; deprecated, embedded tags
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
        # Path is relative to modules/home-manager/ -> up to root, then into wallpaper/
        image = ../../wallpaper/anime-girl-cherry-blossom-train-looking-away-4k-oc.png;
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
          name = "macOS";
          package = pkgs.apple-cursor;
          size = 22;
        };

        targets = {
          firefox = {
            profileNames = [ config.home.username ];
          };
          vscode = {
            profileNames = [
              "default"
              config.home.username
            ];
          };
          gnome.enable = pkgs.stdenv.isLinux; # Only enable GNOME theming on Linux
          # Noctalia v5 owns wallpapers; stylix's hyprland target would
          # otherwise force-enable the redundant hyprpaper service, which
          # crashes on monitor disconnect/DPMS events.
          hyprland.hyprpaper.enable = false;
        };
      };
    };
}
