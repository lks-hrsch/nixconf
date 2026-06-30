_: {
  flake.modules.homeManager.claude-code =
    { pkgs, ... }:
    {
      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        package = pkgs.unstable.claude-code;
        # Plugins loaded directly via --plugin-dir from pinned sources (no marketplace
        # registration). Bump a rev+hash like the skills pins in skills.nix to update.
        plugins =
          let
            # anthropics/claude-plugins-official — rev is the current ~/.claude .gcs-sha
            official = pkgs.fetchFromGitHub {
              owner = "anthropics";
              repo = "claude-plugins-official";
              rev = "3d5017bc1d40ef08c5733243516afeb993a6f5e5";
              hash = "sha256-fhE6Zm83EUbdLBjY4VSCtoHyLVJ+Aexz7DN7n0Y0FLA=";
            };
          in
          [
            "${official}/plugins/code-review"
            "${official}/plugins/claude-md-management"
            "${official}/plugins/pyright-lsp"
            "${official}/plugins/rust-analyzer-lsp"
            "${official}/plugins/typescript-lsp"
            # superpowers is an external plugin referenced by the official marketplace
            (pkgs.fetchFromGitHub {
              owner = "obra";
              repo = "superpowers";
              rev = "6fd4507659784c351abbd2bc264c7162cfd386dc"; # v5.1.0
              hash = "sha256-P/FD8HTQO+QzvMe3A/B2v2vjs8T6ZmIYH3MPp79dSzo=";
            })
          ];
        settings = {
          skillListingBudgetFraction = 0.05;
          model = "opusplan";
          effortLevel = "xhigh";
          cleanupPeriodDays = 30;
          permissions = {
            allow = [
              # file metadata (no content)
              "Bash(ls:*)"
              "Bash(find:*)"
              "Bash(stat:*)"
              "Bash(file:*)"
              "Bash(wc:*)"
              "Bash(du:*)"
              "Bash(df:*)"
              # navigation / output
              "Bash(pwd)"
              "Bash(which:*)"
              "Bash(basename:*)"
              "Bash(dirname:*)"
              "Bash(date:*)"
              "Bash(echo:*)"
              "Bash(printf:*)"
              "Bash(env:*)"
              # text transforms (stdin/pipeline, not file reading)
              "Bash(sort:*)"
              "Bash(uniq:*)"
              "Bash(cut:*)"
              "Bash(tr:*)"
              # system info
              "Bash(ps:*)"
              "Bash(uname:*)"
              # git read-only (structure/history, no file content)
              "Bash(git log:*)"
              "Bash(git status:*)"
              "Bash(git branch:*)"
              "Bash(git remote:*)"
              "Bash(git ls-files:*)"
              "Bash(git stash list:*)"
              "Bash(git rev-parse:*)"
              # nix read-only
              "Bash(nix flake show:*)"
              "Bash(nix path-info:*)"
              "Bash(nix eval:*)"
              # web
              "WebFetch(domain:github.com)"
              "WebFetch(domain:raw.githubusercontent.com)"
              "WebFetch(domain:mynixos.com)"
              "WebFetch(domain:nix.dev)"
              "WebFetch(domain:wiki.nixos.org)"
              # mcp
              "mcp__context7__resolve-library-id"
              "mcp__context7__query-docs"
              "mcp__nixos__nix"
              "mcp__nixos__nix_versions"
              "mcp__obsidian__read_note"
              "mcp__obsidian__read_multiple_notes"
              "mcp__obsidian__search_notes"
              "mcp__obsidian__list_directory"
            ];
            defaultMode = "default";
          };
          statusLine = {
            type = "command";
            command = "bash ~/.claude/statusline-command.sh";
          };
          promptSuggestionEnabled = false;
          autoMemoryEnabled = true;
          autoDreamEnabled = true;
          remoteControlAtStartup = false;
        };
      };

      # TODO: Wait for Litellm Issue #23841 and PR #23844, #28595 merge (input_text block translation fix) — see https://github.com/BerriAI/litellm/issues/23841
      programs.zsh.shellAliases = {
        claude-office = "ANTHROPIC_BASE_URL=https://llm.develappers-intranet.de:11434 ANTHROPIC_MODEL=develappers-coding ANTHROPIC_CUSTOM_MODEL_OPTION=gemma-4-fast ANTHROPIC_DEFAULT_HAIKU_MODEL=develappers-coding ANTHROPIC_DEFAULT_SONNET_MODEL=gemma-4-fast ANTHROPIC_DEFAULT_OPUS_MODEL=develappers-coding claude";
      };

      home.file.".claude/statusline-command.sh" = {
        text = builtins.readFile ./statusline-command.sh;
        executable = true;
      };
    };
}
