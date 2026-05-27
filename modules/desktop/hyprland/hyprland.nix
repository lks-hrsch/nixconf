{ inputs, ... }:
{
  flake.modules.homeManager.desktop-hyprland-hyprland =
    { pkgs, osConfig, ... }:
    let
      inherit (osConfig.desktop.monitors) primary secondary;

      # Switch to workspace N on primary monitor, or L<N> on secondary
      hypr-ws-switch = pkgs.writeShellScript "hypr-ws-switch" ''
        ws=$1
        mon=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
        if [ "$mon" = "${primary}" ]; then
          hyprctl dispatch workspace "$ws"
        else
          hyprctl dispatch workspace "name:L$ws"
        fi
      '';
      hypr-ws-move = pkgs.writeShellScript "hypr-ws-move" ''
        ws=$1
        mon=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
        if [ "$mon" = "${primary}" ]; then
          hyprctl dispatch movetoworkspace "$ws"
        else
          hyprctl dispatch movetoworkspace "name:L$ws"
        fi
      '';
    in
    {

      # install extra packages
      home.packages = [
        pkgs.hyprpicker
        pkgs.wl-clipboard
        inputs.hyprland-contrib.packages.${pkgs.stdenv.hostPlatform.system}.grimblast
      ];

      wayland.windowManager.hyprland = {
        enable = true; # enable Hyprland
        systemd.enable = false;
        # set the flake package
        package = null; # use the NixOS package
        portalPackage = null; # use the NixOS package
        settings = {
          "$terminal" = "uwsm app -- ghostty";
          "$fileManager" = "uwsm app -- nautilus";
          "$ipc" = "noctalia-shell ipc call";
          "$mod" = "SUPER";

          exec-once = [
            "uwsm app -- ibus start --type wayland"
            "uwsm app -- 1password --silent"
            "uwsm app -- librepods --hide"
          ];

          monitor = [
            "${primary},highrr,auto,1,vrr,2"
            "${secondary},highres,auto-left,1,transform,1,vrr,2"
          ];

          windowrule = [
            "no_focus on, match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false" # Prevents focus on empty XWayland windows
            "suppress_event maximize, match:class .*" # You'll probably like this.
          ];

          input = {
            kb_layout = "gb";
            kb_options = "grp:alt_shift_toggle";

            accel_profile = "flat";

            touchpad = {
              natural_scroll = true;
              scroll_factor = 0.8;
              tap-to-click = false;
              clickfinger_behavior = true;
            };
          };

          device = {
            name = "apple-inc.-magic-trackpad";
          };

          gesture = [
            "3, horizontal, workspace"
            "4, horizontal, workspace"
            "5, horizontal, workspace"
          ];

          cursor = {
            no_hardware_cursors = true;
          };

          general = {
            gaps_in = 2;
            gaps_out = "2, 4, 4, 4";
          };

          decoration = {
            rounding = 10;

            blur = {
              enabled = true;
            };
          };

          dwindle = {
            preserve_split = "yes"; # you probably want this
          };

          # define workspaces — 1–9 on primary, L1–L9 (IDs 11–19) on secondary
          workspace = [
            # main (center) monitor
            "1, monitor:${primary}, default:true"
            "2, monitor:${primary}"
            "3, monitor:${primary}"
            "4, monitor:${primary}"
            "5, monitor:${primary}"
            "6, monitor:${primary}"
            "7, monitor:${primary}"
            "8, monitor:${primary}"
            "9, monitor:${primary}"
            # left monitor
            "name:L1, monitor:${secondary}, default:true"
            "name:L2, monitor:${secondary}"
            "name:L3, monitor:${secondary}"
            "name:L4, monitor:${secondary}"
            "name:L5, monitor:${secondary}"
            "name:L6, monitor:${secondary}"
            "name:L7, monitor:${secondary}"
            "name:L8, monitor:${secondary}"
            "name:L9, monitor:${secondary}"
          ];

          bind = [
            "$mod, T, exec, $terminal"
            "$mod, E, exec, $fileManager"
            "$mod, F, exec, uwsm app -- firefox"
            "$mod, SPACE, exec, $ipc launcher toggle"
            "$mod, S, exec, $ipc controlCenter toggle"
            "$mod, comma, exec, $ipc settings toggle"

            "$mod, Q, killactive"
            "$mod CTRL, Q, exec, $ipc lockScreen lock"
            "$mod CTRL, F, fullscreen,"
            "$mod SHIFT, F, togglefloating,"
            "$mod, P, pseudo," # dwindle
            "$mod, J, layoutmsg, togglesplit," # dwindle

            # clipboard history (via Noctalia launcher)
            "$mod ALT, C, exec, $ipc launcher clipboard"

            # grimblast
            "$mod SHIFT, 3, exec, grimblast --notify copysave active"
            "$mod SHIFT, 4, exec, grimblast --notify copysave area"
            "$mod SHIFT, 5, exec, grimblast --notify copysave output"

            # workspaces
            "CTRL, left, workspace, m-1"
            "CTRL, right, workspace, m+1"
          ]
          ++ (
            # CTRL+1-9 → workspace N on focused monitor (primary: 1-9, secondary: L1-L9)
            # CTRL+SHIFT+1-9 → move window to workspace N on focused monitor
            builtins.concatLists (
              builtins.genList (
                i:
                let
                  ws = i + 1;
                in
                [
                  "CTRL, code:1${toString i}, exec, ${hypr-ws-switch} ${toString ws}"
                  "CTRL SHIFT, code:1${toString i}, exec, ${hypr-ws-move} ${toString ws}"
                ]
              ) 9
            )
          );

          bindm = [
            "$mod, mouse:272, movewindow"
            "$mod, mouse:273, resizewindow"
          ];

          # Media keys (continuous for volume/brightness)
          bindel = [
            ", XF86AudioRaiseVolume, exec, $ipc volume increase"
            ", XF86AudioLowerVolume, exec, $ipc volume decrease"
            ", XF86MonBrightnessUp, exec, $ipc brightness increase"
            ", XF86MonBrightnessDown, exec, $ipc brightness decrease"
          ];

          # Media keys (one-shot for mute)
          bindl = [
            ", XF86AudioMute, exec, $ipc volume muteOutput"
          ];
        };
      };
    };
}
