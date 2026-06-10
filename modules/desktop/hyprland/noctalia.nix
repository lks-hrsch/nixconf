{ inputs, config, ... }:
let
  inherit (config.repo.constants) location;
in
{
  flake.modules.homeManager.desktop-hyprland-noctalia =
    {
      lib,
      osConfig,
      config,
      ...
    }:
    let
      inherit (osConfig.desktop.monitors) primary secondary;
      colors = config.lib.stylix.colors.withHashtag;
    in
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      # Configure Noctalia Shell v5
      programs.noctalia = {
        enable = true;

        # Stylix-driven palette (Catppuccin Mocha OLED base16 scheme from
        # modules/home-manager/stylix.nix), selected via theme.source = "custom".
        customPalettes.stylix = {
          dark = {
            mPrimary = colors.base0E; # mauve
            mOnPrimary = colors.base00;
            mSecondary = colors.base0D; # blue
            mOnSecondary = colors.base00;
            mTertiary = colors.base0C; # teal
            mOnTertiary = colors.base00;
            mError = colors.base08; # red
            mOnError = colors.base00;
            mSurface = colors.base00; # OLED black
            mOnSurface = colors.base05; # text
            mSurfaceVariant = colors.base02; # surface0 — capsule fill contrast
            mOnSurfaceVariant = colors.base05;
            mOutline = colors.base03; # surface1
            mShadow = colors.base00;
            mHover = colors.base02;
            mOnHover = colors.base05;
          };
        };

        settings = {
          # ── Shell ────────────────────────────────────────────────────────────

          shell = {
            avatar_path = "${config.home.homeDirectory}/.face";
            clipboard_enabled = true;
            corner_radius_scale = 0.75;
            polkit_agent = true;
            settings_show_advanced = true;

            animation.enabled = false;

            panel = {
              shadow = false;
              transparency_mode = "glass";
            };

            screen_corners.enabled = true;

            shadow.alpha = 0.0;
          };

          # ── Wallpaper ────────────────────────────────────────────────────────

          wallpaper = {
            enabled = true;
            directory = toString ../../../wallpaper;
          };

          # ── Theme ────────────────────────────────────────────────────────────

          theme = {
            mode = "dark";
            source = "custom";
            custom_palette = "stylix";

            templates = {
              enable_builtin_templates = false;
              enable_community_templates = false;
            };
          };

          # ── Night Light ──────────────────────────────────────────────────────

          nightlight.enabled = true;

          # ── Location ─────────────────────────────────────────────────────────

          location = {
            auto_locate = false;
            address = location;
          };

          # ── Idle ─────────────────────────────────────────────────────────────

          idle.behavior = {
            lock = {
              timeout = 600;
              command = "noctalia:session lock";
              enabled = true;
            };
            "screen-off" = {
              timeout = 1800;
              command = "noctalia:dpms-off";
              resume_command = "noctalia:dpms-on";
              enabled = true;
            };
          };

          # ── Notifications ────────────────────────────────────────────────────

          notification.background_opacity = 0.75;

          # ── System Monitor ───────────────────────────────────────────────────

          system.monitor = {
            enabled = true;
            cpu_poll_seconds = 5;
            gpu_poll_seconds = 5;
            memory_poll_seconds = 5;
            network_poll_seconds = 5;
          };

          # ── Control Center shortcuts ─────────────────────────────────────────

          control_center.shortcuts = [
            { type = "nightlight"; }
            { type = "bluetooth"; }
            { type = "wifi"; }
          ];

          # ── Bar ──────────────────────────────────────────────────────────────

          bar.main = {
            position = "top";
            background_opacity = 0.0;
            capsule = true;
            capsule_padding = 14.0;
            thickness = 24;
            radius = 32;
            padding = 8;
            margin_edge = 2;
            margin_ends = 0;
            shadow = false;

            start = [
              "control-center"
              "workspaces"
            ];
            center = [ "active_window" ];
            end = [
              "CPU"
              "temp"
              "ram"
              "gpu"
              "gpu-temperature"
              "network_rx"
              "network_tx"
              "tray"
              "caffeine"
              "weather"
              "date"
              "clock"
            ];

            monitor = {
              # Secondary (portrait) monitor — workspaces only
              ${secondary} = {
                enabled = true;
                start = [ ];
                center = [ "workspaces" ];
                end = [ ];
              };
              # Primary monitor — full bar from the main widget lists
              ${primary} = {
                enabled = true;
              };
            };
          };

          # ── Per-widget settings ──────────────────────────────────────────────

          widget = {
            CPU = {
              display = "text";
              type = "sysmon";
            };
            "control-center".glyph = "snowflake";
            gpu = {
              display = "text";
              stat = "gpu_usage";
              type = "sysmon";
            };
            "gpu-temperature" = {
              display = "text";
              stat = "gpu_temp";
              type = "sysmon";
            };
            network_rx.display = "text";
            network_tx.display = "text";
            ram.display = "text";
            temp.display = "text";
            workspaces = {
              display = "name";
              minimal = true;
            };
          };

          # ── Desktop widgets (disabled) ───────────────────────────────────────

          desktop_widgets.enabled = false;

          # ── Lockscreen widgets (disabled) ───────────────────────────────────────────────

          lockscreen_widgets.enabled = false;

          # ── Dock (disabled) ──────────────────────────────────────────────────

          dock.enabled = false;
        };
      };

      # Noctalia additions to Hyprland (lua config — see hyprland.nix)
      wayland.windowManager.hyprland.settings = {
        # Auto-start Noctalia via UWSM (keeps it in the compositor's app scope)
        on = [
          {
            _args = [
              "hyprland.start"
              (lib.generators.mkLuaInline ''
                function()
                  hl.exec_cmd("uwsm app -- noctalia")
                end'')
            ];
          }
        ];
        # Blur rule — v5 layer namespaces per official docs:
        # https://docs.noctalia.dev/v5/compositor-settings/hyprland/
        # ignore_alpha below the docs' 0.5: glass-mode panels render their
        # background at 0.55 alpha, leaving blur marginal at the 0.5 cutoff.
        layer_rule = [
          {
            name = "noctalia";
            match.namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$";
            blur = true;
            blur_popups = true;
            ignore_alpha = 0.2;
          }
        ];
        # The settings panel is an xdg window (not a layer surface) with an
        # opaque Surface background — force opacity so compositor blur applies
        window_rule = [
          {
            name = "noctalia-settings";
            match.class = "^dev\\.noctalia\\.Noctalia\\.Settings$";
            opacity = "0.9";
          }
        ];
      };
    };
}
