# lazygit via home-manager and nixvim: research

Researched 2026-11-23. Research only: nothing was added to the flake, nothing was deployed. Everything is from primary sources (upstream source and docs at the exact version nixpkgs ships, the locked flake inputs, the repo's own files) or from local experiments marked **observed**. Anything else is marked **unverified**.

Source shorthand. Store paths are the locked inputs; realised paths can be garbage collected (one vanished mid-session), so every one has an upstream URL equivalent. Re-realise with e.g. `nix build --no-link .#darwinConfigurations.MacBook-000553.pkgs.lazygit.src`.

| Short | Meaning |
| --- | --- |
| `lazygit:<path>` | lazygit v0.66.3 (nixpkgs 26.05 `pkgs.lazygit`, `lazygit.src.rev = refs/tags/v0.66.3`). `https://github.com/jesseduffield/lazygit/blob/v0.66.3/<path>`, store `/nix/store/gkqgl1x6mfn8rrqf087166vqvznby6ps-source/<path>` |
| `lazygit.nvim:<path>` | kdheepak/lazygit.nvim rev `a04ad0dbc725134edbee3a5eea29290976695357` (nixpkgs `vimPlugins.lazygit-nvim` 0-unstable-2025-12-19). `https://github.com/kdheepak/lazygit.nvim/blob/a04ad0dbc725134edbee3a5eea29290976695357/<path>`, store `/nix/store/k56in5f8p9c3w7jzr0vh0yld2qdblhw5-source/<path>` |
| `navigator:<path>` | christoomey/vim-tmux-navigator rev `e41c431a0c7b7388ae7ba341f01a0d217eb3a432` (nixpkgs 1.0-unstable-2026-01-25). `https://github.com/christoomey/vim-tmux-navigator/blob/e41c431a0c7b7388ae7ba341f01a0d217eb3a432/<path>`, store `/nix/store/pi6csscyqhk1nvwixcbsaviqp1hwx5fb-source/<path>` |
| `snacks:<path>` | folke/snacks.nvim rev `ad9ede6a9cddf16cedbd31b8932d6dcdee9b716e` (nixpkgs 2.31.0-unstable-2026-03-21). `https://github.com/folke/snacks.nvim/blob/ad9ede6a9cddf16cedbd31b8932d6dcdee9b716e/<path>`, store `/nix/store/gxccb1fr188yjl73ygnr0df35l7lvn53-source/<path>` |
| `nixvim:<path>` | locked nixvim input (`nixos-26.05`), store `/nix/store/7krr2j4jw1bidplsbqzn20a54w9wa1yx-source/<path>` |
| `hm:<path>` | locked home-manager input, store `/nix/store/mq6k123g378wgwcz88s7zdmbwf69cxdy-source/<path>` |
| `stylix:<path>` | locked stylix input, store `/nix/store/lihqr1g32l6cgfigx3ggvfna1j5m10hn-source/<path>` |
| `nixpkgs:<path>` | locked nixpkgs input (26.05), store `/nix/store/7sa2x9c9566lfxkaxs36n3z4yayl5cy4-source/<path>` |
| `repo:<path>` | files in this repo at the working tree of 2026-11-23 |

Versions in play (all via the flake): lazygit 0.66.3, neovim-unwrapped 0.12.4 (the nixvim default package; `pkgs.unstable` has 0.12.6), git 2.54.0 (`pkgs.git`), nvim terminal job API `jobstart(..., { term = true })` as used by lazygit.nvim (`lazygit.nvim:lua/lazygit.lua:65`).

Provenance of **observed** results. Headless nvim 0.12.4 (`--headless --listen`, driven with `nvim --server ... --remote-send/--remote-expr`), the real lazygit 0.66.3 binary, lazygit.nvim at the rev above, scratch git repos under the Claude scratchpad. No UI was attached, so rendering is not tested, but the behaviours below are event-order and key-routing logic, which is the same with or without a UI. `$TMUX` was set to a fake socket where noted so vim-tmux-navigator registers its terminal-mode mappings; no tmux server was involved.

## Summary of answers

1. **`os.editPreset: "nvim-remote"`** (Q1). Inside nvim (`$NVIM` set) lazygit does not suspend; for `e` it runs `nvim --server "$NVIM" --remote-send "q"` (quits lazygit through the float's terminal), then `nvim --server "$NVIM" --remote-tab <file>`, plus `--remote-send ":<line>"` when jumping to a line. Outside nvim (`$NVIM` unset) it falls back to a plain suspended `nvim -- <file>`. No `nvr` is needed (`--server/--remote-*` are nvim's own client flags). lazygit.nvim's `use_neovim_remote` is a different feature (git commit editor via `nvr`) and is inert without `nvr` on PATH. **Gotcha, observed:** with lazygit.nvim the float closes and the file opens, but in a new tab that the plugin's exit handler immediately leaves (it re-focuses the pre-float window), so the user stays on the old tab. A short `lazygit_on_exit_callback` that re-enters the tab opened while the float was up fixes it (section 1; a naive `tablast` variant is wrong).
2. **Key collisions** (Q2). Defaults: `<ctrl+j>`/`<ctrl+k>` move a commit down/up (Commits panel, alternates `<alt+down>`/`<alt+up>`), `<ctrl+l>` opens log options (Commits panel). `<ctrl+h>` is unbound. Standalone in a tmux pane: tmux's `is_vim` regex does not match `lazygit`, so tmux swallows all four keys as pane navigation (`prefix C-l` still forwards C-l, `repo:modules/home-manager/tmux.nix:23`). Inside the nvim float: vim-tmux-navigator registers **terminal-mode** `tnoremap` for all four keys whenever `$TMUX` is set, exempting only `ft=fzf`, so they never reach lazygit (**observed**: `<C-l>` did not open the log menu). A buffer-local pass-through for `ft=lazygit` fixes it (**observed**).
3. **Signing** (Q3). With `commit.gpgsign=true` and `git.overrideGpg: false` (default) lazygit commits, amends and rewords HEAD through a suspended subprocess and refuses (error "Feature not available for users using GPG") every operation that goes through `BeginInteractiveRebaseForCommit[Range]`: reword of non-HEAD commits (also from the message panel's "open in editor"), author reset or change and co-author on non-HEAD commits, discard-file-changes-from-commit, custom-patch operations, and edit-stop on merge commits. `git.overrideGpg: true` streams git without a terminal handover instead, which suits 1Password `op-ssh-sign` (its prompt is a GUI dialog, not a TTY prompt), and unlocks those operations. Not tested against 1Password.
4. **git-crypt** (Q4). This repo's `diff=git-crypt` textconv makes lazygit's diff panel show decrypted plaintext of `secrets/**` (**observed** via the same `git diff` flags lazygit uses). Line staging in such files breaks (upstream issue 4196); whole-file staging uses the clean filter and works.
5. **Stylix** (Q5). Target writes only `programs.lazygit.settings.gui.theme.*` (9 keys, hex colours from the repo's base16 scheme), auto-enabled. Sibling `gui.*` keys merge; the same theme key set by hand **concatenates lists** (not an override) and a scalar clash errors. Use `lib.mkForce` per key.
6. **Darwin config path** (Q6). HM writes `~/.config/lazygit/config.yml` here because `xdg.enable` evaluates true on the three hosts checked (both Macs and the workstation), and lazygit reads `$XDG_CONFIG_HOME/lazygit` (`/Users/lkshrsch/.config`, exported by `hm-session-vars.sh`). Without that variable lazygit would use `~/Library/Application Support/lazygit`, exactly where HM would write with `xdg.enable = false`: the two always agree. `config_file_path` in lazygit.nvim is not needed (**observed** `lazygit -cd` both ways).
7. **lazygit.nvim** (Q7). Commands: `LazyGit`, `LazyGitCurrentFile`, `LazyGitFilter`, `LazyGitFilterCurrentFile`, `LazyGitConfig`, `LazyGitLog`. plenary.nvim is optional (all uses are `pcall(require, ...)`), and is probably on the runtimepath here anyway through telescope's lua dependencies (inferred).
8. **Alternative** (Q8). snacks.nvim's lazygit already defaults to `nvim-remote`, ends on the opened file's tab (**observed**), but nixvim's snacks module does not pull in lazygit, and it rewrites `LG_CONFIG_FILE` and a cache theme file. Not a better fit unless other snacks modules are wanted.

## 1. `editPreset: nvim-remote`, neovim-remote, and the float

**Documented behaviour.**
- `lazygit:docs/Config.md:958-967`: `os.editPreset` picks a built-in editor preset; supported presets include `nvim` and `nvim-remote`; "`nvim-remote` is an experimental preset for when you have invoked lazygit from within a neovim process, allowing lazygit to open the file from within the parent process rather than spawning a new one."
- `lazygit:docs/Config.md:980`: `editInTerminal` "should really be named `suspend`"; it decides whether lazygit suspends before calling the editor.
- Design intent, from the PR that introduced the current behaviour (jesseduffield/lazygit#3508 "Improve `nvim-remote` mode", merged 2024-05-19, `https://github.com/jesseduffield/lazygit/pull/3508`): if not inside a neovim session, "treat as a normal nvim invocation and suspend lazygit"; if inside one: "Do not try to suspend lazygit. Send `q` keystroke to neovim session to quit lazygit. Send filename/line/etc. to neovim session."

**Exact commands** (`lazygit:pkg/config/editor_presets.go:57-86`, POSIX-shell variant at lines 68-70; fish at 60-62 and nushell at 64-66 are selected by `$SHELL`/`$FISH_VERSION`/`$NU_VERSION`, lines 59 and 63):

| Action | Template (POSIX) |
| --- | --- |
| edit (`e` in the Files panel) | `[ -z "$NVIM" ] && (nvim -- {{filename}}) \|\| (nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote-tab {{filename}})` |
| edit at line (`e` from a diff or staging view) | `[ -z "$NVIM" ] && (nvim +{{line}} -- {{filename}}) \|\| (nvim --server "$NVIM" --remote-send "q" && nvim --server "$NVIM" --remote-tab {{filename}} && nvim --server "$NVIM" --remote-send ":{{line}}<CR>")` |
| open dir | same shape with `{{dir}}` |
| edit and wait (patch editing) | `nvim +{{line}} {{filename}}`, i.e. no remote variant: "No remote-wait support yet. See https://github.com/neovim/neovim/pull/17856" (line 79-80) |
| `suspend` | `func() bool { _, ok := os.LookupEnv("NVIM"); return !ok }` (lines 82-85): suspend only when `$NVIM` is unset |

- `$NVIM` is set by nvim for every `:terminal` and `jobstart()` child: "`$NVIM` is set to `v:servername` by `terminal` and `jobstart()`" (`https://github.com/neovim/neovim/blob/v0.12.4/runtime/doc/vvars.txt#L597-L600`). lazygit.nvim starts lazygit with `jobstart(command, { term = true, ... })` (`lazygit.nvim:lua/lazygit.lua:65`), so it is set in the float.
- Fallback when `$NVIM` is unset (standalone lazygit in a tmux pane): the first branch, `nvim -- <file>`, run with a suspended UI (`files_helper.go` `callEditor`: `suspend` true goes through `RunSubprocessAndRefresh`, false through a plain `Run()`, `lazygit:pkg/gui/controllers/helpers/files_helper.go:71-79`). `nvim` resolves to the nixvim wrapper (`viAlias`/`vimAlias`, `repo:modules/nixvim.nix:11-12`). One shell quirk: the `A && B || C` shape runs the remote branch if `nvim -- file` exits non-zero (for example `:cq`), where it then fails because `$NVIM` is empty.
- `os.editInTerminal` is a `*bool` (`lazygit:pkg/config/user_config.go:713`); when set it overrides the preset's dynamic `suspend` (`editor_presets.go:193-197`). Leave it unset with `nvim-remote`.
- Without a preset, lazygit guesses from `core.editor`, `$GIT_EDITOR`, `$VISUAL`, `$EDITOR` (`lazygit:pkg/commands/git_commands/file.go:80-101`) and falls back to the `vim` preset (`editor_presets.go:177`). The repo sets none of those (grepped `repo:modules` and `repo:hosts` for `EDITOR`, `VISUAL`, `core.editor`: no hits), so without `nvim-remote` an `e` inside the float opens a **nested** `vim` (the nixvim alias) in the lazygit terminal.
- `confirmOnQuit` defaults to `false` (`lazygit:docs/Config.md:609-610`). If it is turned on, the `q` that nvim-remote sends only raises the confirm popup and the edit appears stuck.

**Does it close the lazygit.nvim float? Yes, as a side effect of `q`.**
- The `q` keystroke goes through nvim into the float's terminal job, where `q` is lazygit's quit key (`lazygit:docs/Config.md:689`, `quit: [q, <ctrl+c>]`; quit action at `lazygit:pkg/gui/controllers/quit_actions.go:12-33`). lazygit exits 0.
- lazygit.nvim's `on_exit` (`lazygit.nvim:lua/lazygit.lua:18-44`) returns early on a non-zero exit (line 19), otherwise closes the float window, deletes the buffer, and calls `vim.api.nvim_set_current_win(prev_win)` (line 32).
- lazygit itself does not process that `q` until the edit handler returns, because `callEditor` runs the shell command synchronously (`files_helper.go:71-79`). So the order is fixed: `remote-tab` creates and enters the new tab, **then** lazygit quits, **then** `on_exit` calls `nvim_set_current_win(prev_win)`.

**Observed consequence (the gotcha).** Real lazygit 0.66.3, lazygit.nvim `a04ad0d`, nvim 0.12.4, `os.editPreset: nvim-remote`, modified `edited.txt` selected in the Files panel, `e` pressed inside the float:

| Setup | Result after `e` |
| --- | --- |
| lazygit.nvim as shipped | float closed, lazygit exited; `tabpagenr()=1 of 2`, current buffer `a.txt`; `edited.txt` sits in tab 2 and is not shown |
| lazygit.nvim plus the `TabEnter` callback below | `tabpagenr()=2 of 2`, current buffer `edited.txt`, normal mode |
| `Snacks.lazygit()` (default config, section 8) | `tabpagenr()=2 of 2`, current buffer `edited.txt` |

```lua
local float_tab, entered
vim.api.nvim_create_autocmd("FileType", { pattern = "lazygit", callback = function()
  float_tab, entered = vim.api.nvim_get_current_tabpage(), nil
end })
-- remember the tab nvim-remote opened or jumped to while lazygit was running
vim.api.nvim_create_autocmd("TabEnter", { callback = function()
  local t = vim.api.nvim_get_current_tabpage()
  if vim.g.lazygit_opened == 1 and t ~= float_tab then entered = t end
end })
vim.g.lazygit_on_exit_callback = function()
  if entered and vim.api.nvim_tabpage_is_valid(entered) then vim.api.nvim_set_current_tabpage(entered) end
  entered = nil
end
```

`lazygit_on_exit_callback` is documented in `lazygit.nvim:README.md:96` and called at `lazygit.lua:41-43`, after the window switch; `vim.g.lazygit_opened` is 1 while the float is open (`lazygit.lua:50`, reset to 0 at line 25).

**Observed**, three tabs (`a.txt`, `b.txt`, `c.txt`), float opened from tab 1, real lazygit with the HM-generated config of the Recommendations:

| Case | `tablast` variant (count tabs, jump to last) | `TabEnter` variant above |
| --- | --- | --- |
| `e` on `edited.txt`, not open anywhere | WRONG: ended on tab 4 (`c.txt`); `--remote-tab` inserted the new tab at position 2 | tab 2 of 4, `edited.txt` |
| `e` on `edited.txt`, already open in tab 3 | WRONG: stayed on tab 1 (tab count unchanged, `drop` jumped to tab 3 and the exit handler jumped back) | tab 3 of 3, `edited.txt` |
| plain `q`, float opened from tab 2 of 3 | stays on tab 2 | stays on tab 2 |

Do not use the tab-count version; the `TabEnter` version handles all three. A Ctrl-l key pass-through (section 2) was also re-checked together with the `TabEnter` snippet (log menu opened).

Known open upstream issues touching this path, not reproduced: jesseduffield/lazygit#5121 (`e` from the staging panel with nvim-remote reported not to jump to the line, v0.56.0), #4859 (reword-in-editor leaves the Commits panel looking stuck in a rebase, with lazygit.nvim and `nvim-remote`), kdheepak/lazygit.nvim#166 (a manual `--server` setup leaves lazygit in normal mode on a second edit).

**Is neovim-remote (`nvr`) needed? No.**
- The preset uses nvim's built-in remote client flags (`--server`, `--remote-send`, `--remote-tab`); the 0.12.4 binary ran all three in the observed tests. `nvr` is the separate Python tool `mhinz/neovim-remote`.
- lazygit.nvim's `use_neovim_remote` (`lazygit.nvim:plugin/lazygit.vim:18-20`: `executable('nvr') ? 1 : 0`) only matters for `git commit` editor flows: `ftplugin/gitcommit.vim:1-7` re-opens lazygit when a `gitcommit` buffer unloads, and only `if g:lazygit_opened && g:lazygit_use_neovim_remote && executable("nvr")`. The README (`lazygit.nvim:README.md:131-163`) shows exporting `GIT_EDITOR`/`EDITOR` with `nvr -cc split --remote-wait ...` so the commit message opens in the parent nvim. With no `nvr` installed, the whole feature is off whatever the setting says, and nixvim's own option text says the same (`nixvim:plugins/by-name/lazygit/default.nix:46-48`).
- Impact here: `c` (lazygit's own commit panel) never calls an editor. `C` (commit via git's editor lookup; none of `core.editor`, `GIT_EDITOR`, `VISUAL`, `EDITOR` is set here, so git falls back to its built-in `vi`, which is the nixvim alias only if `repo:modules/nixvim.nix:11` `viAlias` comes first on PATH, inferred) opens a nested editor inside the float. That is usable; only install `nvr` and set `GIT_EDITOR` if the nested editor bothers you. Not needed for the recommendation.

## 2. Key collisions: lazygit vs vim-tmux-navigator

**lazygit 0.66.3 defaults involving Ctrl-h/j/k/l** (`lazygit:docs/Config.md:831-832, 844` and `lazygit:docs/keybindings/Keybindings_en.md:101-102, 109`; searched every `<ctrl+h|j|k|l>` in both files):

| Key | Where | Action | Alternate default |
| --- | --- | --- | --- |
| `<ctrl+j>` | Commits panel | Move commit down one | `<alt+down>` |
| `<ctrl+k>` | Commits panel | Move commit up one | `<alt+up>` |
| `<ctrl+l>` | Commits panel | View log options | none |
| `<ctrl+h>` | nowhere | unbound | n/a |

Everything else uses plain keys (`j`/`k` lists, `h`/`l` panel switching, `<ctrl+u>`/`<ctrl+d>` scroll). Rebinding syntax is a string or list under `keybinding.commits.*` (`Config.md:831-832` shows lists).

**Standalone lazygit in a tmux pane.**
- `repo:modules/home-manager/tmux.nix:28-32`: all four keys are root-table bindings that `send-keys` to the pane only when `$is_vim` matches, else `select-pane`. `is_vim` greps `ps -o state= -o comm= -t '#{pane_tty}'` against `^ *[^TXZ ]* +(\S+\/)?g?\.?(view|l?n?vim?x?|fzf|claude)(diff)?(-wrapped)?$`.
- **Observed** with that exact regex on sample `ps` lines: `lazygit`, `/nix/store/.../bin/lazygit`, `zsh`, `git`, `lg` do not match; `nvim` and `.nvim-wrapped` do. So in a pane running lazygit, tmux eats Ctrl-h/j/k/l for pane navigation and lazygit never sees them: move-commit via Ctrl-j/k and log options via Ctrl-l are unreachable by keyboard there. `<alt+down>`/`<alt+up>` still work in principle (Ghostty has `macos-option-as-alt = "left"`, `repo:modules/home-manager/ghostty.nix:67`; delivery through tmux is **unverified**). `<prefix> C-l` is the repo's own escape hatch that forwards C-l to the pane (`repo:modules/home-manager/tmux.nix:23`, `bind C-l send-keys C-l`).

**lazygit inside the nvim float (lazygit.nvim).**
- Here tmux sees `nvim` on the pane tty (`is_vim` matches) and forwards the key to nvim, where vim-tmux-navigator takes over. `navigator:plugin/tmux_navigator.vim:17-31`: normal-mode maps always, and when `$TMUX` is set also **terminal-mode** maps:
  `tnoremap <expr> <silent> <C-j> IsFZF() ? "\<C-j>" : "\<C-w>:\<C-U> TmuxNavigateDown\<cr>"` (and `-h/-k/-l`). `IsFZF()` is `&ft == 'fzf'` only (lines 25-27). These are global mappings, and lazygit.nvim sets the float's filetype to `lazygit` (`lazygit.nvim:lua/lazygit/window.lua:56`), so nothing exempts it.
- **Observed** (`$TMUX` faked, plugin at the rev above, `maparg` and a real lazygit): terminal-mode `<C-j>` maps to `IsFZF() ? "\<NL>" : "\<C-W>:\<C-U> TmuxNavigateDown\<CR>"`; without `$TMUX` there is no terminal-mode map. With the repo's setup, pressing `<C-l>` in the Commits panel inside the float did **not** open "Commit Log Options". With this buffer-local pass-through it did:

```lua
vim.api.nvim_create_autocmd("FileType", { pattern = "lazygit", callback = function(a)
  for _, k in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
    vim.keymap.set("t", k, k, { buffer = a.buf })
  end
end })
```

  Cost: Ctrl-h/j/k/l no longer navigate away from the float (you leave it with lazygit's `q`, which is what you want).
- Alternative that fixes both contexts at once and needs no nvim code: rebind the three lazygit keys to something neither tmux nor nvim claims, for example `keybinding.commits.moveDownCommit = [ "<alt+down>" ]`, `moveUpCommit = [ "<alt+up>" ]`, `openLogMenu = "<alt+l>"` (`<alt+l>` is unbound by default: the only Alt bindings in the defaults are `<alt+shift+c>` (`Config.md:776`), the `<alt+down|up>` pair (`831-832`) and the Mac text-editing words in comments (`719-728`)). Syntax: `lazygit:docs/keybindings/Custom_Keybindings.md:1-52` allows `<alt+down>` and `<alt-down>` interchangeably (`+` or `-`, long or short modifier names, `alt+` or `a+`), and lists `<alt+down>`-style keys as needing the newer keyboard protocol. **Observed** with the exact YAML that home-manager would generate (including the Stylix theme; see the Recommendations): lazygit started with no config error, `<M-l>` in the Commits panel inside the nvim float opened "Commit Log Options", and `<M-Down>` and `<M-Up>` moved commits (history rewritten in a scratch repo, signing disabled there). That covers the nvim terminal half. The Ghostty and tmux half is still **unverified** (the repo already carries the settings that upstream recommends for it, `set -s extended-keys on` and `terminal-features ...:extkeys`, `repo:modules/home-manager/tmux.nix:17-19`, matching `Custom_Keybindings.md:88-97`).

## 3. Commit signing (SSH via 1Password `op-ssh-sign`)

**Repo setup.** `repo:modules/home-manager/git.nix:32-43`: `gpg.format = "ssh"`, `gpg.ssh.program` = `/Applications/1Password.app/Contents/MacOS/op-ssh-sign` on Darwin (`lib.getExe' pkgs.unstable._1password-gui "op-ssh-sign"` on Linux), `commit.gpgsign = true`. Observed in the live config: `git config commit.gpgsign` is `true`.

**What lazygit does.**
- `lazygit:pkg/commands/git_commands/config.go:41-54`: `NeedsGpgSubprocess` is true when `commit.gpgSign` (or `tag.gpgSign`) is true, unless `git.overrideGpg` is true. `lazygit:docs/Config.md:521-522`: `overrideGpg: false` is "If true, do not spawn a separate process when using GPG".
- Commit (`working_tree_helper.go:184`), amend (`amend_helper.go:23`), reword of the HEAD commit (`local_commits_controller.go:910`) and tag creation (`tags_helper.go:49`) all go through `GpgHelper.withGpgHandling` (`lazygit:pkg/gui/controllers/helpers/gpg_helper.go:53-80`). When a subprocess is needed it calls `RunSubprocess(cmdObj)`: lazygit hands the terminal to `git commit`, then refreshes. With `promptToReturnFromSubprocess` (default `true`, `Config.md:679-681`, "display a confirmation when subprocess terminates") you press Enter to return. Upstream describes the effect: "committing drops to the subprocess terminal ... ('Press enter to return to lazygit')" (jesseduffield/lazygit#6094). Without the subprocess (`overrideGpg: true`) the command is streamed with a waiting status and no TTY (`gpg_helper.go:78-97`, `runAndStream`).
- With the subprocess flag on, these are **refused** with "Feature not available for users using GPG. If you are using a passphrase agent (e.g. gpg-agent) so that you don't have to type your passphrase when signing, you can enable this feature by adding git: overrideGpg: true" (`lazygit:pkg/i18n/english.go:1728`): `BeginInteractiveRebaseForCommit` and `...ForCommitRange` (`lazygit:pkg/commands/git_commands/rebase.go:405-453`, check at 409 and 433), whose callers are: reword of a non-HEAD commit (`rebase.go:37-44`, `local_commits_controller.go:853`) and the message panel's switch to the editor (`local_commits_controller.go:884`), author reset, change and co-author through `GenericAmend` (`rebase.go:89-95`), discard-file-changes-from-commit (`rebase.go:520-521`), and the custom-patch operations (`patch.go:242`; callers at `patch.go:181, 210, 316, 370, 413`). Other history-editing actions are not gated by this check: squash, fixup, drop, move and edit go through `InteractiveRebase` (`rebase.go:143`), and amend-to (`A` on an older commit) through `AmendTo` (`rebase.go:299-315`); whether they cope with a signer that needs a terminal in the default mode was not tested.
- Maintainers confirm the intended fix: "`git.overrideGpg` ... if your signing uses some sort of password agent so that no password needs to be typed" (jesseduffield/lazygit#3758, stefanhaller).

**What `overrideGpg: true` changes.** It disables the subprocess handover and lifts the refusals above. It also changes how commit output is shown (jesseduffield/lazygit#4745, open: commits no longer take over the full screen, so pre-commit/commit-msg hook output is only in lazygit's own log panel; this repo has no commit hooks). Caveat (jesseduffield/lazygit#6094, open): the streamed path has no pty or credential detection, so a signer that asks for a PIN or touch **on the terminal** (the reporter uses a FIDO2 key) fails outright with "Git command failed".

**op-ssh-sign fit.** 1Password's docs say that on `git commit` "You'll be prompted to authorize your SSH key the same way you unlock the 1Password app" (Touch ID or Windows Hello), with `[gpg "ssh"] program = /Applications/1Password.app/Contents/MacOS/op-ssh-sign` (`https://www.1password.dev/ssh/git-commit-signing/`, fetched 2026-11-23, redirected from `developer.1password.com`). That prompt is a GUI dialog, so `overrideGpg: true` is the better fit: no TTY is needed. Upstream issues found by searching `op-ssh-sign` and `1password` in the lazygit tracker: none about 1Password itself (#6094 and #4668 are about FIDO2 and pinentry). The 1Password page lists no GUI-client or TTY limitation and does not say whether the app must stay unlocked during signing.

## 4. git-crypt

- Repo: `secrets/**`, `hosts/**/stacks/**` and `hosts/**/vpn.nix` carry `filter=git-crypt diff=git-crypt` (`repo:.gitattributes`); this clone has `filter.git-crypt.required=true` and `diff.git-crypt.textconv=git-crypt diff` configured and is unlocked. `git-crypt` is in HM `home.packages` (`repo:modules/home-manager/git.nix:11`).
- No upstream lazygit issue mentions git-crypt (searched the tracker for `git-crypt`: no results).
- **Diffs show plaintext, observed.** lazygit builds file diffs with `git diff --no-ext-diff ...` and never passes `--no-textconv` (`lazygit:pkg/commands/git_commands/working_tree.go:396-412`, `git_command_builder.go:166-176`; grepped the package: no `textconv` outside tests). `--no-ext-diff` does not disable textconv. On this clone, `git diff --no-ext-diff --color=never -- secrets/stacks-mars-deimos.yaml` printed a 22-line textual diff, and the same with `--no-textconv` printed a 3-line "Binary files differ" stanza (line counts only; no content was printed). So lazygit's main panel will render decrypted secrets for any modified `secrets/**` or stack file. The diff command is created with `.DontLog()` (`working_tree.go:412`), so it does not appear in the command log. Anything on screen (screen sharing) shows the plaintext. Whether a terminal scrollback or tmux history keeps a copy was not checked (lazygit is a full-screen UI, so probably not).
- **Line and hunk staging breaks**: lazygit builds patches from the displayed diff, and textconv output does not apply (jesseduffield/lazygit#4196, open, "Can't stage lines when using custom textconv diff driver", suggests `--no-textconv`). Stage whole files with Space: that goes through `git add`, so the clean filter encrypts.
- Because `filter.git-crypt.required=true`, any lazygit action that runs the filter needs `git-crypt` on `PATH`. HM puts it on the user PATH; the nvim float inherits the shell PATH, so this holds there too.
- Which git runs: nixvim prepends `git-2.54.0` and `lazygit-0.66.3` to nvim's PATH (observed via `programs.nixvim.extraPackages` with the plugin enabled), while this Mac's interactive shell finds Homebrew's `git` 2.56.1 first (`which -a git`). So the same repo is driven by two different git versions depending on whether lazygit starts from the float or a pane. Harmless here, worth knowing when comparing behaviour.

## 5. Stylix lazygit target

`stylix:modules/lazygit/hm.nix:1-22` (whole file): a plain `mkTarget` with no `autoEnable` override, so it follows `stylix.autoEnable` (true, `repo:modules/home-manager/stylix.nix:95`). It sets exactly `programs.lazygit.settings.gui.theme` with the repo's base16 colours (hex):

| Key | Value (this repo's scheme) |
| --- | --- |
| `activeBorderColor` | `[ "#89b4fa" "bold" ]` (base0D) |
| `inactiveBorderColor` | `[ "#45475a" ]` (base03) |
| `searchingActiveBorderColor` | `[ "#585b70" "bold" ]` (base04) |
| `optionsTextColor` | `[ "#f5e0dc" ]` (base06) |
| `selectedLineBgColor` | `[ "#45475a" ]` (base03) |
| `cherryPickedCommitBgColor` | `[ "#313244" ]` (base02) |
| `cherryPickedCommitFgColor` | `[ "#45475a" ]` (base03) |
| `unstagedChangesColor` | `[ "#f38ba8" ]` (base08) |
| `defaultFgColor` | `[ "#cdd6f4" ]` (base05) |

**Observed** by evaluating the real Darwin host with `programs.lazygit.enable = true` added through `extendModules` (nothing built): `stylix.targets.lazygit.enable = true` and `programs.lazygit.settings` equals exactly the table above; the file is `/Users/lkshrsch/.config/lazygit/config.yml`. It sets no `nerdFontsVersion`, `showIcons`, fonts, or anything outside `gui.theme`.

**Conflict rules.** `programs.lazygit.settings` has type `(pkgs.formats.yaml {}).type` (`hm:modules/programs/lazygit.nix:31-32`), which is `attrsOf` for sets, `listOf` for lists (`nixpkgs:lib/types.nix:1488-1507`). **Observed** with `lib.evalModules` and that type:
- Sibling keys merge: user `gui.nerdFontsVersion = "3"` next to stylix's `gui.theme.*` is fine.
- Same key, list values: **concatenated**, not overridden. Stylix `[ "#89b4fa" "bold" ]` plus user `[ "green" ]` evaluates to `[ "green" "#89b4fa" "bold" ]` (and lazygit would read several colours). Use `lib.mkForce [ "green" ]` to replace it (**observed** result `[ "green" ]`).
- Same key, scalar values: evaluation error (conflicting definitions).
- To opt out entirely: `stylix.targets.lazygit.enable = false`.

## 6. Darwin config location and lazygit.nvim

- HM: `hm:modules/programs/lazygit.nix:14-18` picks `Library/Application Support` when `isDarwin && !config.xdg.enable`, else `config.xdg.configHome`; the file is `${configDir}/lazygit/config.yml`, only written when `settings != {}` (lines 78-81).
- lazygit: `lazygit:pkg/config/app_config.go:796-812` (`findConfigFile`): `$CONFIG_DIR` if set, else searches XDG for `jesseduffield/lazygit/config.yml` then `lazygit/config.yml`, default `xdg.ConfigHome/lazygit`. It uses `github.com/adrg/xdg` (line 15), whose macOS default config home is `~/Library/Application Support`. `lazygit:docs/Config.md:3-17` lists the macOS default and `export XDG_CONFIG_HOME="$HOME/.config"` as the way to move it.
- This repo: `xdg.enable` evaluates `true` for `MacBook-000553`, `lkshrsch-mb-pro-m1` and the workstation (`nix eval ...config.home-manager.users.lkshrsch.xdg.enable`); I did not find where it is set (no `xdg.enable` in `repo:modules` or `repo:hosts`; see "Could not confirm"). `/etc/profiles/per-user/lkshrsch/etc/profile.d/hm-session-vars.sh:15` exports `XDG_CONFIG_HOME="/Users/lkshrsch/.config"` and `~/.zshenv` sources it, so even a plain `zsh -c` has it.
- **Observed**: `lazygit -cd` prints `/Users/lkshrsch/.config/lazygit` with that variable and `/Users/lkshrsch/Library/Application Support/lazygit` with it unset. Neither directory exists yet. A scratch `XDG_CONFIG_HOME` with `lazygit/config.yml` containing `os.editPreset: nvim-remote` was honoured by the real binary (the nvim-remote flow in section 1 ran from it).
- So HM's target and lazygit's lookup agree on every combination: (`xdg.enable` true, variable exported) here; (`xdg.enable` false, variable unset, `Library/Application Support`) in the other. They would disagree only if `XDG_CONFIG_HOME` were exported while `xdg.enable` is false, which cannot happen via HM.
- **lazygit.nvim `config_file_path` is not needed.** By default (`use_custom_config_file_path = 0`) the plugin runs plain `lazygit` with no `-ucf` (`lazygit.nvim:lua/lazygit.lua:162-174`) and the float inherits nvim's environment, so lazygit resolves the same file as standalone. `use_custom_config_file_path`/`config_file_path` exist to pass `-ucf` (lines 123-130, 167-174) and also drive `:LazyGitConfig`, which finds the file via `lazygit -cd` plus `/config.yml` (line 71-74). That command will open the HM-managed symlink into `/nix/store`, which is read-only (inferred from `home.file` semantics; not tested).
- Shell wrapper: `programs.lazygit.shellWrapperName` defaults to `lg` (`hm:modules/programs/lazygit.nix:65-72`); the zsh integration appends a function to `programs.zsh.initContent` (line 125) that exports `LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir` (line 85-89; `home.preferXdgDirectories` is `false` here, so not an XDG path), runs `command lazygit "$@"`, then `cd`s if the file exists. HM `programs.lazygit.package` evaluates to the same store path (`/nix/store/j2j18bzbd15hhqgncq4j5cl144a1fv0b-lazygit-0.66.3`) as nixvim's dependency package, so enabling both installs one copy.

## 7. lazygit.nvim: commands, options, dependencies

- Commands (`lazygit.nvim:plugin/lazygit.vim:45-55`): `LazyGit` (runs `lazygit` in nvim's cwd; with `-p <path>` only when called with a path argument), `LazyGitLog` (`lazygit log`), `LazyGitCurrentFile` (git root of the current file, or cwd for terminal buffers), `LazyGitFilter` (`lazygit -f <path>`), `LazyGitFilterCurrentFile`, `LazyGitConfig`. A Telescope extension (`lua/telescope/_extensions/lazygit.lua`) lists visited repos.
- nixvim: `plugins.lazygit` is a `mkVimPlugin` with `globalPrefix = "lazygit_"` (`nixvim:plugins/by-name/lazygit/default.nix:9-13`), so options live under `plugins.lazygit.settings.*` and become `vim.g.lazygit_*`. Options: `floating_window_winblend`, `floating_window_scaling_factor`, `floating_window_border_chars`, `floating_window_use_plenary`, `use_neovim_remote`, `use_custom_config_file_path`, `config_file_path` (lines 22-62). Unlisted globals such as `lazygit_on_exit_callback` can still be set under `settings` (freeform) or `globals`.
- Dependencies (`default.nix:17-20`): `dependencies = [ "git" "lazygit" ]`. `enableDependencies` sets `dependencies.<name>.enable = mkDefault true` (`nixvim:lib/plugins/utils.nix:133-146`) and `modules/dependencies.nix:117-119` puts the enabled packages in `extraPackages` (prefixed to nvim's PATH). **Observed** with `programs.nixvim.plugins.lazygit.enable = true` added by `extendModules`: `extraPackages` gains `git-2.54.0` and `lazygit-0.66.3` and `dependencies.lazygit.package` is `/nix/store/j2j18bzbd15hhqgncq4j5cl144a1fv0b-lazygit-0.66.3`. Closure cost of lazygit alone: about 24 MiB (`nix path-info -Sh --store https://cache.nixos.org`).
- plenary.nvim: not a hard dependency. `lazygit.nvim:lua/lazygit/window.lua:12` and `lua/lazygit/utils.lua:29` use `pcall(require, 'plenary...')` and fall back; `floating_window_use_plenary` defaults to 0. nixpkgs gives the plugin no `dependencies` (`vimPlugins.lazygit-nvim.dependencies = []`, observed). plenary is nevertheless present on this config's runtimepath because `plugins.telescope` is enabled and `vimPlugins.telescope-nvim.propagatedBuildInputs` includes `luajit2.1-plenary.nvim-scm-1` (observed; whether it ends up in the final wrapper's rtp was not inspected). When present, `get_root` uses `plenary.job` instead of `git rev-parse` through `system()`.
- Behaviour notes from the source: `project_root_dir()` temporarily sets `vim.o.shell = 'bash'` (`utils.lua:50-86`), so `bash` must be on PATH; the float is a scratch buffer with `filetype=lazygit` (`window.lua:46-56`) and `LazyGit` re-enters terminal mode with `startinsert` (`lazygit.lua:68`); on a clean exit the buffer is deleted and `:checktime` runs (`lazygit.lua:18-26`), which reloads files changed by lazygit.

## 8. Alternative: snacks.nvim lazygit (short)

`snacks:lua/snacks/lazygit.lua`: `Snacks.lazygit()` opens lazygit in a snacks terminal float and, with `configure = true`, defaults `config.os.editPreset = "nvim-remote"` and `gui.nerdFontsVersion = "3"` (lines 29-42), generates a theme from the current colourscheme into `stdpath("cache")/lazygit-theme.yml` (lines 43-57, 119-185), and sets `vim.env.LG_CONFIG_FILE` to your default `config.yml` plus that theme file (lines 77-103). Also `Snacks.lazygit.log()` and `log_file()` (lines 211-226). nixvim has `plugins.snacks` (`nixvim:plugins/by-name/snacks/default.nix`, no lazygit option and no `dependencies`, so lazygit would have to come from HM or `extraPackages`).

Verdict: not a better fit here. It ended on the edited file's tab without any workaround (observed), but it brings a large plugin for one feature, silently merges a second config and a theme over the Stylix one (confusing next to `programs.lazygit.settings`), writes into `~/.cache/nvim` (my test run created `lazygit-theme.yml` there; I deleted it), exports `LG_CONFIG_FILE` into nvim's environment for every later child, and does not pull lazygit in. It would not avoid the Ctrl-h/j/k/l interception (that is a global `tnoremap` in vim-tmux-navigator; not re-tested with snacks' own terminal keys). Pick it only if other snacks modules are wanted.

## Recommendations

Layout (dendritic, one feature per file): `modules/home-manager/lazygit.nix` for the HM part (add `lazygit` to the `imports` list in `modules/home-manager/base.nix`, as `repo:.claude/rules/modules.md` requires), and the nixvim part in a client-only module so servers (mercury, mars/*, which share `commonNixvimConfig` in `repo:modules/nixvim.nix` and have no home-manager) do not get `lazygit` and `git` on nvim's PATH (about 24 MiB each) or a `:LazyGit` they cannot configure. If one shared place is preferred, adding `plugins.lazygit.enable = true` to `commonNixvimConfig` also works; the cost is that closure on every server. Attach the client variant to `flake.modules.darwin.base` imports and the NixOS client role (`flake.modules.nixos.desktop` in `repo:modules/desktop/base.nix`); which NixOS client hosts import which role was not traced.

home-manager:

```nix
programs.lazygit = {
  enable = true;
  settings = {
    gui.nerdFontsVersion = "3";                  # stylix font is JetBrainsMono Nerd Font Mono
    os.editPreset = "nvim-remote";               # do not set os.editInTerminal; the preset decides
    git.overrideGpg = true;                      # 1Password op-ssh-sign needs no TTY; unlocks rebase-based actions
    # optional: keys that neither tmux nor vim-tmux-navigator claims (Alt delivery unverified)
    keybinding.commits = {
      moveDownCommit = [ "<alt+down>" ];
      moveUpCommit = [ "<alt+up>" ];
      openLogMenu = "<alt+l>";
    };
  };
  # shellWrapperName stays "lg"; zsh integration is on by default
};
```

Leave `stylix.targets.lazygit` alone (auto-enabled, no clash with the keys above). If a `gui.theme.*` key is ever set by hand, wrap it in `lib.mkForce`.

nixvim (client-only module, system level like the rest of `modules/nixvim.nix`):

```nix
programs.nixvim = {
  plugins.lazygit.enable = true;                 # also puts git and lazygit on nvim's PATH
  keymaps = [
    { mode = "n"; key = "<leader>gg"; action = "<cmd>LazyGit<cr>"; options.desc = "LazyGit"; }
    { mode = "n"; key = "<leader>gf"; action = "<cmd>LazyGitCurrentFile<cr>"; options.desc = "LazyGit: current file's repo"; }
    { mode = "n"; key = "<leader>gl"; action = "<cmd>LazyGitFilter<cr>"; options.desc = "LazyGit: commit log"; }
  ];                                             # <leader>g* is free in repo:modules/nixvim.nix (only a*, f* are used)
  # Do not set config_file_path / use_custom_config_file_path, and do not install nvr.
  extraConfigLua = ''
    -- float: let Ctrl-h/j/k/l reach lazygit (vim-tmux-navigator maps them in terminal mode), and
    -- land on the tab that nvim-remote opened or jumped to (lazygit.nvim re-focuses the pre-float window on exit)
    local float_tab, entered
    vim.api.nvim_create_autocmd("FileType", { pattern = "lazygit", callback = function(a)
      float_tab, entered = vim.api.nvim_get_current_tabpage(), nil
      for _, k in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
        vim.keymap.set("t", k, k, { buffer = a.buf })
      end
    end })
    vim.api.nvim_create_autocmd("TabEnter", { callback = function()
      local t = vim.api.nvim_get_current_tabpage()
      if vim.g.lazygit_opened == 1 and t ~= float_tab then entered = t end
    end })
    vim.g.lazygit_on_exit_callback = function()
      if entered and vim.api.nvim_tabpage_is_valid(entered) then vim.api.nvim_set_current_tabpage(entered) end
      entered = nil
    end
  '';
};
```

Notes: if the Alt rebinding is used, the Ctrl pass-through only matters for anyone who keeps the Ctrl defaults; keep it anyway, it is harmless. Do not combine with `snacks.lazygit`. **Evaluated** with `extendModules` on `MacBook-000553` (nothing built): the three keymaps are added next to the existing 10 with no key clash, `extraConfigLua` from a second definition is concatenated with the existing OSC 52 block (both present), and `extraPackages` gains `git-2.54.0` and `lazygit-0.66.3`. The home-manager block was evaluated through the same route; its generated YAML is reproduced below.

Generated `config.yml` for the home-manager block (the Stylix theme merges in unchanged; `<alt+down>` loads, **observed**):

```yaml
git:
  overrideGpg: true
gui:
  nerdFontsVersion: '3'
  theme: { activeBorderColor: ['#89b4fa', bold], ... }   # 9 Stylix keys, section 5
keybinding:
  commits:
    moveDownCommit: [<alt+down>]
    moveUpCommit: [<alt+up>]
    openLogMenu: <alt+l>
os:
  editPreset: nvim-remote
```

After a switch (hand-over, never run from here): `lazygit -cd` should print `/Users/lkshrsch/.config/lazygit`, then `lg` in a tmux pane for the standalone case and `<leader>gg` in nvim for the float.

## Could not confirm

- **Real-UI behaviour.** All nvim-remote, key-routing and tab results are from headless nvim with the real lazygit binary and a fake `$TMUX`. The logic is event order, so a UI should match, but it was not run in Ghostty with tmux and the real nixvim wrapper. The recommended Lua was run (headless) from a plain init file, not through nixvim's generated `init.lua`.
- **Alt keys through Ghostty and tmux.** `<alt+down>`, `<alt+up>`, `<alt+l>` were verified only as keys sent into the nvim terminal. Whether they survive Ghostty (`macos-option-as-alt = "left"` only covers the left Option key) and tmux (`extended-keys on`) to a standalone lazygit pane was not tested.
- **1Password with `overrideGpg: true`.** No signed commit was made (it would raise an authorization prompt). Unknown: how many prompts a multi-commit rebase raises, behaviour when 1Password is locked (lazygit shows a waiting status; whether git or op-ssh-sign times out was not checked), and whether squash, fixup, drop and move cope with a terminal-needing signer in the default mode.
- **Background fetches vs the 1Password agent.** `git.autoFetch` is `true` with `refresher.fetchInterval: 60` and `fetchAll: true` (`lazygit:docs/Config.md:472, 602, 492`). For SSH remotes (the repo forces `core.sshCommand` through the agent for GitHub, `repo:modules/home-manager/git.nix:28`) this may raise periodic agent approval prompts depending on the 1Password SSH approval setting. Not observed; no setting recommended for it.
- **Where `xdg.enable = true` comes from.** It evaluates true for all three HM hosts, but there is no `xdg.enable` in `repo:modules` or `repo:hosts` and none in the HM or stylix module sources I grepped. The Darwin result depends on it only through the agreement argument in section 6, which holds either way.
- **Linux clients.** Only the workstation was evaluated for `xdg.enable` (true); the ThinkPad was not. The nvim-remote and tmux findings are platform-independent code, but nothing was run on Linux. Which NixOS hosts import the `desktop` role was not traced.
- **plenary in the final wrapper rtp** (only inferred from telescope's propagated lua inputs) and **`:LazyGitConfig` opening a read-only store file** (inferred from `home.file`).
- **Upstream issue states** (#5121, #4859, #4745, #6094, #4196, lazygit.nvim#166) were read on 2026-11-23 and are open at that time except as noted; none were reproduced here.
