_: {
  flake.modules.homeManager.claude-code =
    { pkgs, config, ... }:
    {
      programs.claude-code = {
        enable = true;
        # enableMcpIntegration = true; # TODO - currently not in home manager 25.11 check it later
        mcpServers = config.programs.mcp.servers;
        package = pkgs.unstable.claude-code;
        settings = {
          model = "opusplan";
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
          enabledPlugins = {
            "rust-analyzer-lsp@claude-plugins-official" = true;
            "typescript-lsp@claude-plugins-official" = true;
            "superpowers@claude-plugins-official" = true;
            "code-review@claude-plugins-official" = true;
            "claude-md-management@claude-plugins-official" = true;
            "pyright-lsp@claude-plugins-official" = true;
          };
          promptSuggestionEnabled = false;
          autoMemoryEnabled = true;
          autoDreamEnabled = true;
          remoteControlAtStartup = false;
        };
      };

      home.file.".claude/statusline-command.sh" = {
        text = builtins.readFile ./statusline-command.sh;
        executable = true;
      };
    };
}
