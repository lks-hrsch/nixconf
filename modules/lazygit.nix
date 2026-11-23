_: {
  flake =
    let
      lazygitHomeManager =
        { config, ... }:
        {
          programs.lazygit = {
            enable = true;
            settings = {
              gui.nerdFontsVersion = "3";
              os.editPreset = "nvim-remote";
              git.overrideGpg = true;
            };
          };

          # prefix g: popup, so tmux pane navigation never sees lazygit's keys. Absolute path: Ghostty-launched tmux lacks the HM PATH.
          programs.tmux.extraConfig = ''
            bind g display-popup -E -d "#{pane_current_path}" -w 90% -h 90% "${config.home.profileDirectory}/bin/lazygit"
          '';
        };

      lazygitNixvim = {
        programs.nixvim = {
          plugins.lazygit.enable = true;
          keymaps = [
            {
              mode = "n";
              key = "<leader>gg";
              action = "<cmd>LazyGit<cr>";
              options.desc = "LazyGit";
            }
            {
              mode = "n";
              key = "<leader>gf";
              action = "<cmd>LazyGitCurrentFile<cr>";
              options.desc = "LazyGit: current file's repo";
            }
            {
              mode = "n";
              key = "<leader>gl";
              action = "<cmd>LazyGitFilter<cr>";
              options.desc = "LazyGit: commit log";
            }
          ];
          extraConfigLua = ''
            -- float: let Ctrl-h/j/k/l reach lazygit (vim-tmux-navigator maps them in terminal mode), and
            -- land on the tab that nvim-remote opened or jumped to (lazygit.nvim re-focuses the pre-float window on exit)
            local group = vim.api.nvim_create_augroup("lazygit_fixups", { clear = true })
            local float_tab, entered
            vim.api.nvim_create_autocmd("FileType", { group = group, pattern = "lazygit", callback = function(a)
              float_tab, entered = vim.api.nvim_get_current_tabpage(), nil
              for _, k in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
                vim.keymap.set("t", k, k, { buffer = a.buf })
              end
            end })
            vim.api.nvim_create_autocmd("TabEnter", { group = group, callback = function()
              local t = vim.api.nvim_get_current_tabpage()
              if vim.g.lazygit_opened == 1 then entered = t ~= float_tab and t or nil end
            end })
            vim.g.lazygit_on_exit_callback = function()
              if entered and vim.api.nvim_tabpage_is_valid(entered) then vim.api.nvim_set_current_tabpage(entered) end
              entered = nil
            end
          '';
        };
      };
    in
    {
      modules = {
        homeManager.lazygit = lazygitHomeManager;
        nixos.lazygit = lazygitNixvim;
        darwin.lazygit = lazygitNixvim;
      };
    };
}
