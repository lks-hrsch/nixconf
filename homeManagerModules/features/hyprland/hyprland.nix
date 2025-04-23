{ inputs, pkgs, ... }: {

  # install extra packages
  home.packages = with pkgs; [
    hyprpicker
    hyprsunset
    # hyprsysteminfo
  ];

  wayland.windowManager.hyprland = {
    enable = true; # enable Hyprland
    systemd.enable = true;
    # set the flake package
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;

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
        "suppressevent maximize, class:.*" # You'll probably like this.
      ];

      input = {
        kb_layout = "gb";
        kb_options = "grp:alt_shift_toggle";

        follow_mouse = 1;

        sensitivity = 0; # -1.0 to 1.0, 0 means no modification.
        force_no_accel = 1;
      };

      cursor = {
        no_hardware_cursors = true;
      };

      general = {
        gaps_in = 5;
        gaps_out = 5;
        border_size = 2;
        # col.active_border = "rgba(ffffffcc)";  # White color for active border
        # col.inactive_border = "rgba(000000cc)";  # Black color for inactive border

        layout = "dwindle";
      };

      decoration = {
        rounding = 10;

        blur = {
          enabled = true;
          size = 3;
        };

        shadow = {
          enabled = true;
        };
      };

      dwindle = {
        pseudotile = "yes"; # master switch for pseudotiling. Enabling is bound to mainMod + P in the keybinds section below
        preserve_split = "yes"; # you probably want this
      };

      bind =
        [
          "$mod, T, exec, $terminal"
          "$mod, E, exec, $fileManager"
          "$mod, F, exec, uwsm app -- firefox"
          "$mod, SPACE, exec, $menu -show drun"
          "$mod, Q, killactive"
          # "$mod SHIFT, Q, exit"
          "$mod CTRL, Q, exec, uwsm app -- hyprlock"
          "$mod SHIFT, F, togglefloating,"
          "$mod, P, pseudo," # dwindle
          "$mod, J, togglesplit," # dwindle
        ]
        ++ (
          # workspaces
          # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
          builtins.concatLists (builtins.genList
            (i:
              let ws = i + 1;
              in [
                "$mod, code:1${toString i}, workspace, ${toString ws}"
                "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
              ]
            )
            9)
        );

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
