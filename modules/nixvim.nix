_: {
  flake =
    let
      commonNixvimConfig =
        { pkgs, ... }:
        {
          programs.nixvim = {
            enable = true;
            nixpkgs.useGlobalPackages = true;
            extraPackages = [ pkgs.unstable.yaml-language-server ];
            viAlias = true;
            vimAlias = true;

            dependencies = {
              # claude comes from home-manager on clients; servers must not get a second copy
              claude-code.enable = false;
              # telescope find_files / live_grep
              fd.enable = true;
              ripgrep.enable = true;
            };

            globals.mapleader = " ";
            opts.clipboard = "unnamedplus";

            # Over SSH (servers, or a client reached by ssh) copy via OSC 52 through tmux to Ghostty.
            # Paste returns nvim's own last copy: an OSC 52 paste query hangs behind tmux.
            extraConfigLua = ''
              if vim.env.SSH_CONNECTION then
                local osc52 = require("vim.ui.clipboard.osc52")
                local last = { {}, "v" }
                local function copy(reg)
                  local send = osc52.copy(reg)
                  return function(lines, regtype)
                    last = { lines, regtype }
                    send(lines)
                  end
                end
                local function paste()
                  return last
                end
                vim.g.clipboard = {
                  name = "osc52-copy-only",
                  copy = { ["+"] = copy("+"), ["*"] = copy("*") },
                  paste = { ["+"] = paste, ["*"] = paste },
                }
              end
            '';

            keymaps = [
              {
                mode = "n";
                key = "<leader>ab";
                action = "<cmd>ClaudeCodeAdd %<cr>";
                options.desc = "Claude: add buffer";
              }
              {
                mode = "v";
                key = "<leader>as";
                action = "<cmd>ClaudeCodeSend<cr>";
                options.desc = "Claude: send selection";
              }
              {
                mode = "n";
                key = "<leader>aa";
                action = "<cmd>ClaudeCodeDiffAccept<cr>";
                options.desc = "Claude: accept diff";
              }
              {
                mode = "n";
                key = "<leader>ad";
                action = "<cmd>ClaudeCodeDiffDeny<cr>";
                options.desc = "Claude: deny diff";
              }
            ];

            colorschemes = {
              catppuccin = {
                enable = true;
                settings.flavour = "mocha";
              };
            };

            plugins = {
              lualine.enable = true;
              nvim-tree.enable = true;
              web-devicons.enable = true;
              blink-cmp.enable = true;
              tmux-navigator.enable = true;

              # Claude runs in a tmux pane (`claude --ide`), the plugin only serves the IDE websocket.
              claudecode = {
                enable = true;
                settings.terminal.provider = "none";
              };

              telescope = {
                enable = true;
                extensions.fzf-native.enable = true;
                settings = {
                  pickers.find_files.find_command = [
                    "fd"
                    "--type"
                    "f"
                    "--hidden"
                    "--exclude"
                    ".git"
                  ];
                  # <C-a> sends the selected file(s) to Claude as @-mentions
                  defaults.mappings =
                    let
                      sendToClaude.__raw = ''
                        function(prompt_bufnr)
                          local state = require("telescope.actions.state")
                          local entries = state.get_current_picker(prompt_bufnr):get_multi_selection()
                          if #entries == 0 then
                            entries = { state.get_selected_entry() }
                          end
                          require("telescope.actions").close(prompt_bufnr)
                          for _, e in ipairs(entries) do
                            local path = e.path or e.filename
                            if path then
                              local ok, err = require("claudecode").send_at_mention(vim.fn.fnamemodify(path, ":p"))
                              if not ok then
                                vim.notify("Claude: " .. tostring(err), vim.log.levels.WARN)
                              end
                            end
                          end
                        end
                      '';
                    in
                    {
                      i."<C-a>" = sendToClaude;
                      n."<C-a>" = sendToClaude;
                    };
                };
                keymaps = {
                  "<leader>ff" = {
                    action = "find_files";
                    options.desc = "Find files";
                  };
                  "<leader>fg" = {
                    action = "live_grep";
                    options.desc = "Live grep";
                  };
                  "<leader>fb" = {
                    action = "buffers";
                    options.desc = "Buffers";
                  };
                  "<leader>fr" = {
                    action = "oldfiles";
                    options.desc = "Recent files";
                  };
                  "<leader>fh" = {
                    action = "help_tags";
                    options.desc = "Help tags";
                  };
                  "<leader>fd" = {
                    action = "diagnostics";
                    options.desc = "Diagnostics";
                  };
                };
              };

              lsp = {
                enable = true;
                servers = {
                  ruff = {
                    enable = true;
                  };
                  yamlls = {
                    enable = true;
                  };
                };
              };
            };
          };
        };
    in
    {
      modules.nixos.nixvim = commonNixvimConfig;
      modules.darwin.nixvim = commonNixvimConfig;
    };
}
