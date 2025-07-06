{ inputs, pkgs, ... }:
{

  # install extra packages
  home.packages = [
    pkgs.hyprpicker
    pkgs.hyprsunset
    pkgs.wl-clipboard
    # hyprsysteminfo
    inputs.hyprland-contrib.packages.${pkgs.system}.grimblast
  ];

  wayland.windowManager.hyprland = {
    enable = true; # enable Hyprland
    systemd.enable = false;
    # set the flake package
    package = null; # use the NixOS package
    portalPackage = null; # use the NixOS package
    plugins = with inputs.hyprland-plugins.packages.${pkgs.system}; [
      hyprexpo
    ];

    settings = {
      "$terminal" = "uwsm app -- alacritty";
      "$fileManager" = "uwsm app -- nautilus";
      "$menu" = "uwsm app -- rofi";
      "$mod" = "SUPER";

      exec-once = [
        "uswm app -- hyprpolkitagent"
        "uwsm app -- hyprpaper"
        "uwsm app -- hyprsunset"
        "uwsm app -- dunst"
        "uwsm app -- 1password --silent"
        "uwsm app -- fcitx5 -d --replace"
        "uwsm app -- fcitx5-remote -r"
      ];

      monitor = [
        "DP-3,highrr,auto,1,vrr,1"
        "DP-2,highrr,auto-left,1,transform,1,vrr,1"
      ];

      windowrule = [
        "pseudo, class:fcitx, title:fcitx"
        "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0" # Prevents focus on empty XWayland windows
        "suppressevent maximize, class:.*" # You'll probably like this.
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

      gestures = {
        workspace_swipe = true;
        workspace_swipe_min_fingers = true;
      };

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
        pseudotile = "yes"; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = "yes"; # you probably want this
      };

      # define workspaces
      workspace = [
        "1, monitor:DP-3, default:true"
        "2, monitor:DP-3"
        "3, monitor:DP-3"
        "4, monitor:DP-3"
        "5, monitor:DP-3"
        "6, monitor:DP-3"
        "7, monitor:DP-2, default:true"
        "8, monitor:DP-2"
        "9, monitor:DP-2"
      ];

      bind =
        [
          "$mod, T, exec, $terminal"
          "$mod, E, exec, $fileManager"
          "$mod, F, exec, uwsm app -- firefox"
          "$mod, SPACE, exec, $menu -show drun"
          "$mod, Q, killactive"
          "$mod CTRL, Q, exec, uwsm app -- hyprlock"
          "$mod CTRL, F, fullscreen,"
          "$mod SHIFT, F, togglefloating,"
          "$mod, P, pseudo," # dwindle
          "$mod, J, togglesplit," # dwindle

          # cliphist
          "$mod ALT, C, exec, cliphist list | $menu -dmenu | cliphist decode | wl-copy"

          # hyprexpo
          # "$mod, grave, hyprexpo:expo, toggle"
          ", F3, hyprexpo:expo, toggle"
          "CTRL, up, hyprexpo:expo, toggle"

          # grimblast
          "$mod SHIFT, 3, exec, grimblast --notify copysave active"
          "$mod SHIFT, 4, exec, grimblast --notify copysave area"
          "$mod SHIFT, 5, exec, grimblast --notify copysave output"

          # workspaces
          "CTRL, left, workspace, m-1"
          "CTRL, right, workspace, m+1"
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (
            builtins.genList (
              i:
              let
                ws = i + 1;
              in
              [
                "CTRL, code:1${toString i}, workspace, ${toString ws}"
                "CTRL SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            ) 9
          )
        );

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      plugin = {
        hyprexpo = {
          columns = 3;
          gap_size = 5;
          workspace_method = "center current";
        };
      };
    };
  };
}
