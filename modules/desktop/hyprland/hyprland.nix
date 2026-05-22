{ inputs, ... }:
{
  flake.modules.homeManager.desktop-hyprland-hyprland =
    { pkgs, ... }:
    let
      # Switch to workspace N on DP-3, or L<N> on DP-2, depending on focused monitor
      hypr-ws-switch = pkgs.writeShellScript "hypr-ws-switch" ''
        ws=$1
        mon=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
        if [ "$mon" = "DP-3" ]; then
          hyprctl dispatch workspace "$ws"
        else
          hyprctl dispatch workspace "name:L$ws"
        fi
      '';
      hypr-ws-move = pkgs.writeShellScript "hypr-ws-move" ''
        ws=$1
        mon=$(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[] | select(.focused) | .name')
        if [ "$mon" = "DP-3" ]; then
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
            "DP-3,highrr,auto,1,vrr,2"
            "DP-2,highres,auto-left,1,transform,1,vrr,2"
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

          # define workspaces — 1–9 on DP-3, L1–L9 (IDs 11–19) on DP-2
          workspace = [
            # main (center) monitor
            "1, monitor:DP-3, default:true"
            "2, monitor:DP-3"
            "3, monitor:DP-3"
            "4, monitor:DP-3"
            "5, monitor:DP-3"
            "6, monitor:DP-3"
            "7, monitor:DP-3"
            "8, monitor:DP-3"
            "9, monitor:DP-3"
            # left monitor
            "name:L1, monitor:DP-2, default:true"
            "name:L2, monitor:DP-2"
            "name:L3, monitor:DP-2"
            "name:L4, monitor:DP-2"
            "name:L5, monitor:DP-2"
            "name:L6, monitor:DP-2"
            "name:L7, monitor:DP-2"
            "name:L8, monitor:DP-2"
            "name:L9, monitor:DP-2"
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
            # CTRL+1-9 → workspace N on focused monitor (DP-3: 1-9, DP-2: L1-L9)
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
