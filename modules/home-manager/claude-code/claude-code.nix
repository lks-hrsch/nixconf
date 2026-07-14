_: {
  flake.modules.homeManager.claude-code =
    { pkgs, config, ... }:
    let
      # anthropics/claude-plugins-official — rev is the current ~/.claude .gcs-sha
      official = pkgs.fetchFromGitHub {
        owner = "anthropics";
        repo = "claude-plugins-official";
        rev = "cd3ca5bd4a4b62bf006b59b68848b59e95f95439";
        hash = "sha256-goJj0/7DtdVp/iwcmD1Bj4jZsQLdc7GLTYk4bhqgoN8=";
      };
      superpowers = pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "896224c4b1879920ab573417e68fd51d2ccc9072"; # v6.0.3
        hash = "sha256-+lT2a/qq0SF4k0PgnEDKiuidVlZX2p0vEso4d/5T1os=";
      };
      claude-mem = pkgs.fetchFromGitHub {
        owner = "thedotmack";
        repo = "claude-mem";
        rev = "f5633c1f84181673896c038cbe285131c6d669a3"; # v13.11.0
        hash = "sha256-CWvBXPHU195o9B0KBEWuMbefc5YUPFZtu0nMbxGq1p8=";
      };
    in
    {
      imports = [ ../../../overlays/uv-module.nix ];

      # Decrypted at HM activation; read at runtime by the `claude-collana` /
      # `claude-develappers` aliases (below) so no value enters the Nix store.
      sops.secrets = {
        "claude-code/provider/collana/base-url" = { };
        "claude-code/provider/collana/auth-token" = { };
        "claude-code/provider/develappers/base-url" = { };
        "claude-code/provider/develappers/auth-token" = { };
      };

      # dependencies
      home.packages = with pkgs; [
        nodejs_24
        bun
      ];

      # graphify skill CLI — https://github.com/Graphify-Labs/graphify
      # (PyPI package is `graphifyy`; installed command is `graphify`)
      programs.uv = {
        enable = true;
        tool = {
          packages = [ "graphifyy" ];
          prune = true;
        };
      };

      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        package = pkgs.unstable.claude-code;
        marketplaces = {
          superpowers = superpowers;
          claude-mem = claude-mem;
        };
        plugins = [
          "${official}/plugins/code-review"
          "${official}/plugins/code-simplifier"
          "${official}/plugins/claude-md-management"
          "${official}/plugins/pyright-lsp"
          "${official}/plugins/rust-analyzer-lsp"
          "${official}/plugins/swift-lsp"
          "${official}/plugins/typescript-lsp"
          # superpowers is an external plugin referenced by the official marketplace
          superpowers
          # claude-mem
          "${claude-mem}/plugin"
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
              "mcp__plugin_claude-code-home-manager_grep-app__searchGitHub"
              "mcp__plugin_claude-code-home-manager_nixos__nix"
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
          feedbackSurveyRate = 0;
          tui = "fullscreen";
        };
      };

      # TODO: Wait for Litellm Issue #23841 and PR #23844, #28595 merge (input_text block translation fix) — see https://github.com/BerriAI/litellm/issues/23841
      programs.zsh.shellAliases =
        let
          secretPath = name: config.sops.secrets."claude-code/provider/${name}".path;
        in
        {
          claude-develappers = "ANTHROPIC_BASE_URL=\"$(cat ${secretPath "develappers/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "develappers/auth-token"})\" ANTHROPIC_MODEL=develappers-coding ANTHROPIC_CUSTOM_MODEL_OPTION=gemma-4-fast ANTHROPIC_DEFAULT_HAIKU_MODEL=develappers-coding ANTHROPIC_DEFAULT_SONNET_MODEL=gemma-4-fast ANTHROPIC_DEFAULT_OPUS_MODEL=develappers-coding claude";
          claude-collana = "ANTHROPIC_BASE_URL=\"$(cat ${secretPath "collana/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "collana/auth-token"})\" ANTHROPIC_MODEL=general ANTHROPIC_CUSTOM_MODEL_OPTION=coding ANTHROPIC_DEFAULT_HAIKU_MODEL=coding ANTHROPIC_DEFAULT_SONNET_MODEL=coding ANTHROPIC_DEFAULT_OPUS_MODEL=general claude";
        };

      home.file.".claude/statusline-command.sh" = {
        text = builtins.readFile ./statusline-command.sh;
        executable = true;
      };
    };
}
