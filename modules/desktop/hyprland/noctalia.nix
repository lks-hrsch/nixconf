{ inputs, config, ... }:
let
  inherit (config.repo.constants) location;
in
{
  flake.modules.homeManager.desktop-hyprland-noctalia =
    {
      lib,
      pkgs,
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

      # Stable symlink so noctalia's wallpaper path survives rebuilds.
      # toString config.stylix.image gives a /nix/store/<hash>-... path that
      # changes on every rebuild; noctalia persists paths as runtime state
      # (wallpaper.last), so after a rebuild those persisted paths go stale.
      # A fixed symlink in the home dir breaks that cycle.
      home.file.".local/share/wallpaper/current.png".source = config.stylix.image;

      # Configure Noctalia Shell v5
      programs.noctalia = {
        enable = true;
        package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

        # Stylix-driven palette (Catppuccin Mocha OLED base16 scheme from
        # modules/home-manager/stylix.nix), selected via theme.source = "custom".
        # Accents echo the cherry-blossom wallpaper (blossom / sky / train);
        # structural roles follow https://nix-community.github.io/stylix/styling.html
        # (base02/03 = selection/unfocused-border ramp, base08 = error).
        customPalettes.stylix = {
          dark = {
            mPrimary = colors.base0F; # flamingo — cherry-blossom accent (soft pastel by design)
            mOnPrimary = colors.base00;
            mSecondary = colors.base07; # lavender — dusk sky; styleguide "light bg" slot, used as accent here
            mOnSecondary = colors.base00;
            mTertiary = colors.base0D; # blue — the train
            mOnTertiary = colors.base00;
            mError = colors.base08; # red
            mOnError = colors.base00;
            mSurface = colors.base00; # OLED black
            mOnSurface = colors.base05; # text
            mSurfaceVariant = colors.base00;
            mOnSurfaceVariant = colors.base05;
            mOutline = colors.base03; # surface1 — unfocused borders per styleguide
            mShadow = colors.base00;
            mHover = colors.base02; # surface0 — one ramp step above mSurfaceVariant so hover is visible
            mOnHover = colors.base05;
          };
          # Noctalia requires both dark and light sections to accept a custom palette.
          # This is a dark-only theme so light mirrors dark; light mode is never active.
          light = {
            mPrimary = colors.base0F;
            mOnPrimary = colors.base00;
            mSecondary = colors.base07;
            mOnSecondary = colors.base00;
            mTertiary = colors.base0D;
            mOnTertiary = colors.base00;
            mError = colors.base08;
            mOnError = colors.base00;
            mSurface = colors.base00;
            mOnSurface = colors.base05;
            mSurfaceVariant = colors.base00;
            mOnSurfaceVariant = colors.base05;
            mOutline = colors.base03;
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
              session_placement = "floating";
              session_position = "center";
              shadow = false;
              transparency_mode = "glass";
              wallpaper_placement = "floating";
              wallpaper_position = "center";
            };

            screen_corners.enabled = true;

            shadow.alpha = 0.0;
          };

          # ── Wallpaper ────────────────────────────────────────────────────────

          wallpaper =
            let
              stablePath = "${config.home.homeDirectory}/.local/share/wallpaper/current.png";
            in
            {
              enabled = true;
              directory = "${config.home.homeDirectory}/.local/share/wallpaper";
              # Stable path via home.file symlink above — survives rebuilds even
              # when noctalia persists wallpaper.last with the old path.
              default.path = stablePath;
              monitors = {
                ${primary}.path = stablePath;
              }
              // lib.optionalAttrs (secondary != null) {
                ${secondary}.path = stablePath;
              };
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

          # ── Weather ──────────────────────────────────────────────────────────
          # enabled defaults to true in v5 (config_types.h:902); set explicitly
          # since v5 is alpha and example.toml wrongly documents it as false.
          # Coordinates come from [location] above. unit: "imperial" = °F; any
          # other value = °C (struct default "metric"), so omit for Celsius.
          weather = {
            enabled = true;
            refresh_minutes = 30;
            effects = true; # animated rain/snow overlays in the weather panel
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
            capsule_border = "primary";
            capsule_fill = "surface";
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
              "ram"
              "temp"
              "gpu"
              "gpu-vram"
              "gpu-temperature"
              "network_rx"
              "network_tx"
              "tray"
              "caffeine"
              "date"
              "clock"
            ];

            monitor = {
              # Primary monitor — full bar from the main widget lists
              ${primary} = {
                enabled = true;
              };
            }
            // lib.optionalAttrs (secondary != null) {
              # Secondary (portrait) monitor — workspaces, plus weather/privacy
              # ported from a live GUI edit (2026-08-16)
              ${secondary} = {
                enabled = true;
                start = [ "weather" ];
                center = [ "workspaces" ];
                end = [ "privacy" ];
              };
            };
          };

          # ── Per-widget settings ──────────────────────────────────────────────

          # v5 renamed sysmon presentation keys: display="text" -> visualization="none",
          # show_label=false -> show_value=true. GPU (uppercase, no type=) was a stale
          # duplicate of gpu below and resolved to an invalid widget type - dropped.
          widget = {
            "control-center".glyph = "snowflake";
            CPU = {
              show_value = true;
              type = "sysmon";
              visualization = "none";
            };
            gpu = {
              show_value = true;
              stat = "gpu_usage";
              type = "sysmon";
              visualization = "none";
            };
            "gpu-temperature" = {
              glyph = "cpu-temperature";
              show_value = true;
              stat = "gpu_temp";
              type = "sysmon";
              visualization = "none";
            };
            "gpu-vram" = {
              show_value = true;
              stat = "gpu_vram";
              type = "sysmon";
              visualization = "none";
            };
            network_rx.visualization = "none";
            network_tx.visualization = "none";
            ram = {
              show_value = true;
              visualization = "none";
            };
            temp = {
              show_value = true;
              visualization = "none";
            };
            # max_length ported from a live GUI edit (2026-08-16)
            weather.max_length = 320;
            workspaces = {
              label_source = "name";
              max_label_chars = 3;
              style = "minimal";
            };
          };

          # ── Desktop widgets (disabled) ───────────────────────────────────────

          desktop_widgets.enabled = false;

          # ── Lockscreen widgets ───────────────────────────────────────────────

          lockscreen_widgets = {
            enabled = true;
            schema_version = 2;
            widget_order = [
              "lockscreen-login-box@${primary}"
            ]
            ++ lib.optionals (secondary != null) [ "lockscreen-login-box@${secondary}" ]
            ++ [
              "lockscreen-widget-0000000000000001"
              "lockscreen-widget-0000000000000002"
              "lockscreen-widget-0000000000000003"
            ];

            grid = {
              cell_size = 16;
              major_interval = 4;
              visible = true;
            };

            widget = {
              # Login boxes — positions are monitor-geometry-specific
              "lockscreen-login-box@${primary}" = {
                box_height = 0.0;
                box_width = 0.0;
                cx = 1280.0;
                cy = 1317.0;
                output = primary;
                rotation = 0.0;
                type = "login_box";
              };
            }
            // lib.optionalAttrs (secondary != null) {
              "lockscreen-login-box@${secondary}" = {
                box_height = 0.0;
                box_width = 0.0;
                cx = 540.0;
                cy = 1797.0;
                output = secondary;
                rotation = 0.0;
                type = "login_box";
              };
            }
            // {
              "lockscreen-widget-0000000000000001" = {
                box_height = 176.0;
                box_width = 512.0;
                cx = 1280.0;
                cy = 1168.0;
                output = primary;
                rotation = 0.0;
                type = "media_player";
                settings = {
                  hide_when_no_media = true;
                  layout = "horizontal";
                };
              };
              "lockscreen-widget-0000000000000002" = {
                box_height = 176.0;
                box_width = 512.0;
                cx = 1840.0;
                cy = 256.0;
                output = primary;
                rotation = 0.0;
                type = "weather";
              };
              "lockscreen-widget-0000000000000003" = {
                box_height = 176.0;
                box_width = 512.0;
                cx = 1296.0;
                cy = 256.0;
                output = primary;
                rotation = 0.0;
                type = "clock";
                settings.clock_style = "digital";
              };
            };
          };

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
