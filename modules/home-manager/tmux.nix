_: {
  # Clients: Ghostty starts this tmux; Ctrl+h/j/k/l pass through to nvim and claude (vim-tmux-navigator).
  flake.modules.homeManager.tmux =
    { config, ... }:
    {
      programs.tmux = {
        enable = true;
        terminal = "tmux-256color";
        escapeTime = 10;
        historyLimit = 50000;
        mouse = true;
        focusEvents = true;
        clock24 = true;
        # default socket dir /run/user/$UID is only exported to shells, not to a Ghostty-launched tmux
        secureSocket = false;
        extraConfig = ''
          set -as terminal-features ",xterm-ghostty:RGB:extkeys:usstyle:hyperlinks:clipboard"
          set -as terminal-features ",xterm*:extkeys"
          set -s extended-keys on
          set -g allow-passthrough on
          set -g set-clipboard on
          bind C-l send-keys C-l

          # leading ' *': ps can print the state blank, which the upstream '^[^TXZ ]+' rejects
          is_vim="ps -o state= -o comm= -t '#{pane_tty}' | grep -iqE '^ *[^TXZ ]* +(\\S+\\/)?g?\\.?(view|l?n?vim?x?|fzf|claude)(diff)?(-wrapped)?$'"
          bind-key -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
          bind-key -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
          bind-key -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
          bind-key -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"

          # A (AI): not a default binding; C is the default customize-mode
          bind A split-window -h -c "#{pane_current_path}" "${config.home.profileDirectory}/bin/claude --ide"
        '';
      };
    };
}
