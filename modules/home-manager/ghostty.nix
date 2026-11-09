_: {
  flake.modules.homeManager.ghostty =
    { pkgs, lib, ... }:
    let
      inherit (pkgs.stdenv) isDarwin;
      # Ghostty stays a dumb terminal: every window lands in tmux session "main".
      tmuxLauncher = pkgs.writeShellScript "ghostty-tmux" ''
        tmux=${pkgs.tmux}/bin/tmux
        # VS Code "open native console" starts Ghostty in a folder: give it a window there
        if [ "$PWD" != "$HOME" ] && "$tmux" has-session -t main 2>/dev/null; then
          "$tmux" new-window -t main: -c "$PWD"
        fi
        # fall back to a shell when tmux fails (bad config, protocol mismatch after an upgrade)
        "$tmux" new-session -A -s main -c "$PWD" || exec ${pkgs.zsh}/bin/zsh -l
      '';
      mod = if isDarwin then "super" else "ctrl";
      fontKeys = [
        "${mod}++=increase_font_size:1"
        "${mod}+-=decrease_font_size:1"
        "${mod}+0=reset_font_size"
      ];
    in
    {
      programs.ghostty = {
        enable = true;
        enableZshIntegration = true;
        enableBashIntegration = true;
        clearDefaultKeybinds = true;
        settings = {
          command = "${tmuxLauncher}";
          # closing a window only detaches tmux
          confirm-close-surface = false;
          # otherwise every window opened after a VS Code one inherits its folder
          window-inherit-working-directory = false;
          keybind =
            fontKeys
            ++ (
              if isDarwin then
                [
                  "super+c=copy_to_clipboard:mixed"
                  "super+v=paste_from_clipboard"
                  "super+n=new_window"
                  "super+w=close_surface"
                  "super+shift+w=close_window"
                  "super+q=quit"
                  "super+ctrl+f=toggle_fullscreen"
                  "super+shift+,=reload_config"
                  "super+,=open_config:os_open"
                ]
              else
                [
                  "ctrl+shift+c=copy_to_clipboard:mixed"
                  "ctrl+shift+v=paste_from_clipboard"
                  "ctrl+shift+n=new_window"
                  "ctrl+shift+w=close_window"
                  "ctrl+shift+q=quit"
                  "f11=toggle_fullscreen"
                  "ctrl+shift+,=reload_config"
                ]
            );
        }
        // lib.optionalAttrs isDarwin {
          # tmux restores state, not Ghostty
          window-save-state = "never";
          # left only: right Option keeps typing @ [ ] { } | on a German layout
          macos-option-as-alt = "left";
        };
        package = if isDarwin then pkgs.unstable.ghostty-bin else pkgs.unstable.ghostty;
      };
    };
}
