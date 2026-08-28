_:
{
  flake.modules.homeManager.desktop-hyprland-hyprland =
    {
      pkgs,
      lib,
      osConfig,
      ...
    }:
    let
      inherit (osConfig.desktop.monitors) primary secondary;
      inherit (lib.generators) mkLuaInline;

      # Command shorthands (were hyprlang $variables)
      terminal = "uwsm app -- ghostty";
      fileManager = "uwsm app -- nautilus";
      ipc = "noctalia msg";
      mod = "SUPER";

      # Lua bind helpers — each renders as hl.bind(keys, <lua>, opts?)
      bind = keys: lua: { _args = [ keys (mkLuaInline lua) ]; };
      bind' = keys: lua: opts: { _args = [ keys (mkLuaInline lua) opts ]; };
      exec = keys: cmd: bind keys ''hl.dsp.exec_cmd("${cmd}")'';
    in
    {

      # install extra packages
      home.packages = [
        pkgs.hyprpicker
        pkgs.wl-clipboard
        pkgs.grimblast
      ];

      wayland.windowManager.hyprland = {
        enable = true; # enable Hyprland
        systemd.enable = false;
        # set the flake package
        package = null; # use the NixOS package
        portalPackage = null; # use the NixOS package
        # Generate ~/.config/hypr/hyprland.lua — hyprlang is deprecated since
        # Hyprland 0.55. Each settings.<name> attr renders as hl.<name>(...);
        # list values render one call per element (and lists merge across
        # modules, e.g. noctalia.nix contributes `on` and `layer_rule`).
        configType = "lua";
        settings = {
          # Lua locals (rendered first): switch/move to workspace N on the
          # primary monitor, or L<N> on the secondary
          ws_switch._var = mkLuaInline ''
            function(n)
              local mon = hl.get_active_monitor()
              local ws = (mon and mon.name == "${primary}") and n or ("name:L" .. n)
              hl.dispatch(hl.dsp.focus({ workspace = ws }))
            end'';
          ws_move._var = mkLuaInline ''
            function(n)
              local mon = hl.get_active_monitor()
              local ws = (mon and mon.name == "${primary}") and n or ("name:L" .. n)
              hl.dispatch(hl.dsp.window.move({ workspace = ws, follow = true }))
            end'';

          # hl.config — plain config tables (stylix merges its colors here too)
          config = {
            input = {
              kb_layout = "gb";
              kb_options = "grp:alt_shift_toggle";

              accel_profile = "flat";

              touchpad = {
                natural_scroll = true;
                scroll_factor = 0.8;
                tap_to_click = false;
                clickfinger_behavior = true;
              };
            };

            cursor = {
              no_hardware_cursors = true;
            };

            general = {
              gaps_in = 2;
              gaps_out = {
                top = 2;
                right = 4;
                bottom = 4;
                left = 4;
              };
            };

            decoration = {
              rounding = 10;

              blur = {
                enabled = true;
              };
            };

            dwindle = {
              preserve_split = true; # you probably want this
            };
          };

          monitor = [
            {
              output = primary;
              mode = "highrr";
              position = "auto";
              scale = 1;
              vrr = 2;
            }
          ]
          ++ lib.optionals (secondary != null) [
            {
              output = secondary;
              mode = "highres";
              position = "auto-left";
              scale = 1;
              transform = 1;
              vrr = 2;
            }
          ]
          ++ [
            # Catch-all so any output not named above (e.g. a USB-C monitor)
            # still comes up instead of staying disabled.
            {
              output = "";
              mode = "preferred";
              position = "auto";
              scale = 1;
            }
          ];

          window_rule = [
            # Prevents focus on empty XWayland windows
            {
              match = {
                class = "^$";
                title = "^$";
                xwayland = true;
                float = true;
                fullscreen = false;
                pin = false;
              };
              no_focus = true;
            }
            # You'll probably like this.
            {
              match.class = ".*";
              suppress_event = "maximize";
            }
          ];

          gesture = [
            {
              fingers = 3;
              direction = "horizontal";
              action = "workspace";
            }
            {
              fingers = 4;
              direction = "horizontal";
              action = "workspace";
            }
            {
              fingers = 5;
              direction = "horizontal";
              action = "workspace";
            }
          ];

          # define workspaces — 1–9 on primary, L1–L9 on secondary (if present)
          workspace_rule =
            builtins.genList (i: {
              workspace = toString (i + 1);
              monitor = primary;
              default = i == 0;
            }) 9
            ++ lib.optionals (secondary != null) (
              builtins.genList (i: {
                workspace = "name:L${toString (i + 1)}";
                monitor = secondary;
                default = i == 0;
              }) 9
            );

          # autostart (was exec-once) — list form so noctalia.nix's hook
          # merges as its own hl.on call
          on = [
            {
              _args = [
                "hyprland.start"
                (mkLuaInline ''
                  function()
                    hl.exec_cmd("uwsm app -- ibus start --type wayland")
                    hl.exec_cmd("uwsm app -- 1password --silent")
                    hl.exec_cmd("uwsm app -- librepods --hide")
                  end'')
              ];
            }
          ];

          bind = [
            (exec "${mod} + T" terminal)
            (exec "${mod} + E" fileManager)
            (exec "${mod} + F" "uwsm app -- firefox")
            (exec "${mod} + SPACE" "${ipc} panel-toggle launcher")
            (exec "${mod} + S" "${ipc} panel-toggle control-center")
            (exec "${mod} + comma" "${ipc} settings-toggle")

            (bind "${mod} + Q" "hl.dsp.window.close()")
            (exec "${mod} + CTRL + Q" "${ipc} session lock")
            (bind "${mod} + CTRL + F" ''hl.dsp.window.fullscreen({ action = "toggle" })'')
            (bind "${mod} + SHIFT + F" ''hl.dsp.window.float({ action = "toggle" })'')
            (bind "${mod} + P" ''hl.dsp.window.pseudo({ action = "toggle" })'') # dwindle
            (bind "${mod} + J" ''hl.dsp.layout("togglesplit")'') # dwindle

            # clipboard history (via Noctalia panel)
            (exec "${mod} + ALT + C" "${ipc} panel-toggle clipboard")

            # grimblast
            (exec "${mod} + SHIFT + 3" "grimblast --notify copysave active")
            (exec "${mod} + SHIFT + 4" "grimblast --notify copysave area")
            (exec "${mod} + SHIFT + 5" "grimblast --notify copysave output")

            # workspaces
            (bind "CTRL + left" ''hl.dsp.focus({ workspace = "m-1" })'')
            (bind "CTRL + right" ''hl.dsp.focus({ workspace = "m+1" })'')

            # mouse binds (were bindm — drag/resize dispatchers imply mouse)
            (bind "${mod} + mouse:272" "hl.dsp.window.drag()")
            (bind "${mod} + mouse:273" "hl.dsp.window.resize()")

            # media keys — repeating for volume/brightness (was bindel),
            # locked so they also work on the lock screen
            (bind' "XF86AudioRaiseVolume" ''hl.dsp.exec_cmd("${ipc} volume-up")'' {
              repeating = true;
              locked = true;
            })
            (bind' "XF86AudioLowerVolume" ''hl.dsp.exec_cmd("${ipc} volume-down")'' {
              repeating = true;
              locked = true;
            })
            (bind' "XF86MonBrightnessUp" ''hl.dsp.exec_cmd("${ipc} brightness-up")'' {
              repeating = true;
              locked = true;
            })
            (bind' "XF86MonBrightnessDown" ''hl.dsp.exec_cmd("${ipc} brightness-down")'' {
              repeating = true;
              locked = true;
            })
            (bind' "XF86AudioMute" ''hl.dsp.exec_cmd("${ipc} volume-mute")'' { locked = true; })
          ]
          ++ (
            # CTRL+1-9 → workspace N on focused monitor (primary: 1-9, secondary: L1-L9)
            # CTRL+SHIFT+1-9 → move window to workspace N on focused monitor
            builtins.concatLists (
              builtins.genList (
                i:
                let
                  ws = toString (i + 1);
                in
                [
                  (bind "CTRL + code:1${toString i}" "function() ws_switch(${ws}) end")
                  (bind "CTRL + SHIFT + code:1${toString i}" "function() ws_move(${ws}) end")
                ]
              ) 9
            )
          );
        };
      };
    };
}
