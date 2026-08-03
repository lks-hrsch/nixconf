_: {
  flake.modules.homeManager.claude-code =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      statusline = {
        text = builtins.readFile ./statusline-command.sh;
        executable = true;
      };
      # anthropics/claude-plugins-official — pinned to latest main as of 2026-07-24
      official = pkgs.fetchFromGitHub {
        owner = "anthropics";
        repo = "claude-plugins-official";
        rev = "b4810bd800e10c8595d79835e61e5945c1cd81ba";
        hash = "sha256-t5fhBhsOiIEkK7kvTqnsbGj06YpSOJho4JykkXGIIxY=";
      };
      superpowers = pkgs.fetchFromGitHub {
        owner = "obra";
        repo = "superpowers";
        rev = "3dcbd5c4b48e02263fbf4a3c01e3fe4f81d584d9"; # v6.2.0
        hash = "sha256-F5LEk0yNWbMpan1vZSFZM76XSpsFGvA7h8q6Idrvenk=";
      };
      claude-mem = pkgs.fetchFromGitHub {
        owner = "thedotmack";
        repo = "claude-mem";
        rev = "21434061901629e2b78d75328f39536a8a3caec8"; # v13.12.4
        hash = "sha256-4Q95emcF4fUFc7eMwU18v44Uoz/ZAenCcXbwZC8z0kM=";
      };
      # openai/codex-plugin-cc — "codex" plugin in the "openai-codex" marketplace
      codex-plugin-cc = pkgs.fetchFromGitHub {
        owner = "openai";
        repo = "codex-plugin-cc";
        rev = "db52e28f4d9ded852ab3942cea316258ae4ef346"; # v1.0.6
        hash = "sha256-S/R4kHTcIHBcG0TRX063C7ILXZZm0oMqunchPGg6ToU=";
      };
      # DietrichGebert/ponytail — repo root is both the marketplace and the plugin
      ponytail = pkgs.fetchFromGitHub {
        owner = "DietrichGebert";
        repo = "ponytail";
        rev = "16f29800fd2681bdf24f3eb4ccffe38be3baec6b"; # main as of 2026-07-15 (v4.8.4 + 53)
        hash = "sha256-Y7d4s7uqjH6IbEXhqAiQ+yaxr6iiGcv2X64LuMtG1T8=";
      };
      # JuliusBrussee/caveman — repo root is both the marketplace and the plugin
      caveman = pkgs.fetchFromGitHub {
        owner = "JuliusBrussee";
        repo = "caveman";
        rev = "0d95a81d35a9f2d123a5e9430d1cfc43d55f1bb0"; # v1.9.1
        hash = "sha256-VqRHx3/4SSCnEh3cUJ/he5saIfwNhS0hOzoH/wwtU2o=";
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
        # for the security-guidance and claude-security plugin hooks
        (unstable.python3.withPackages (ps: [ ps.claude-agent-sdk ]))
      ];

      # graphify skill CLI — https://github.com/Graphify-Labs/graphify
      # (PyPI package is `graphifyy`; installed command is `graphify`)
      programs.uv.tool.packages = [ "graphifyy" ];

      programs.claude-code = {
        enable = true;
        enableMcpIntegration = true;
        package = pkgs.unstable.claude-code;
        marketplaces = {
          superpowers = superpowers;
          claude-mem = claude-mem;
          openai-codex = codex-plugin-cc;
          ponytail = ponytail;
          caveman = caveman;
        };
        plugins = [
          "${official}/plugins/code-review"
          "${official}/plugins/code-simplifier"
          "${official}/plugins/claude-md-management"
          "${official}/plugins/claude-security"
          "${official}/plugins/security-guidance"
          "${official}/plugins/pyright-lsp"
          "${official}/plugins/rust-analyzer-lsp"
          "${official}/plugins/swift-lsp"
          "${official}/plugins/typescript-lsp"
          # superpowers is an external plugin referenced by the official marketplace
          superpowers
          # claude-mem
          "${claude-mem}/plugin"
          # openai codex plugin — /codex:* review & delegate commands
          "${codex-plugin-cc}/plugins/codex"
          # ponytail — lazy-senior-dev ruleset; /ponytail{,-review,-audit,-debt,-gain,-help}
          ponytail
          # caveman — ultra-compressed prose mode; /caveman, active by default
          caveman
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
              # web
              "WebFetch(domain:github.com)"
              "WebFetch(domain:raw.githubusercontent.com)"
              "WebFetch(domain:nix.dev)"
              "WebFetch(domain:mynixos.com)"
              "WebFetch(domain:wiki.nixos.org)"
              # mcp
              "mcp__plugin_claude-code-home-manager_context7__resolve-library-id"
              "mcp__plugin_claude-code-home-manager_context7__query-docs"
              "mcp__plugin_claude-code-home-manager_nixos__nix"
              "mcp__plugin_claude-code-home-manager_nixos__nix_versions"
              "mcp__plugin_claude-code-home-manager_grep-app__searchGitHub"
              "mcp__plugin_claude-code-home-manager_obsidian__read_note"
              "mcp__plugin_claude-code-home-manager_obsidian__read_multiple_notes"
              "mcp__plugin_claude-code-home-manager_obsidian__search_notes"
              "mcp__plugin_claude-code-home-manager_obsidian__list_directory"
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
          claude-work = "CLAUDE_CONFIG_DIR=\"$HOME/.claude-work\" claude";
          claude-collana-private = "DISABLE_INTERLEAVED_THINKING=1 CLAUDE_CODE_EFFORT_LEVEL=unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 ANTHROPIC_BASE_URL=\"$(cat ${secretPath "collana/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "collana/auth-token"})\" ANTHROPIC_MODEL=coding ANTHROPIC_CUSTOM_MODEL_OPTION=general ANTHROPIC_DEFAULT_HAIKU_MODEL=coding ANTHROPIC_DEFAULT_SONNET_MODEL=coding ANTHROPIC_DEFAULT_OPUS_MODEL=general CLAUDE_MEM_MODEL=general claude --model coding";
          claude-collana = "CLAUDE_CONFIG_DIR=\"$HOME/.claude-work\" DISABLE_INTERLEAVED_THINKING=1 CLAUDE_CODE_EFFORT_LEVEL=unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 ANTHROPIC_BASE_URL=\"$(cat ${secretPath "collana/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "collana/auth-token"})\" ANTHROPIC_MODEL=coding ANTHROPIC_CUSTOM_MODEL_OPTION=general ANTHROPIC_DEFAULT_HAIKU_MODEL=coding ANTHROPIC_DEFAULT_SONNET_MODEL=coding ANTHROPIC_DEFAULT_OPUS_MODEL=general CLAUDE_MEM_MODEL=general claude --model coding";
          claude-develappers = "CLAUDE_CONFIG_DIR=\"$HOME/.claude-work\" DISABLE_INTERLEAVED_THINKING=1 CLAUDE_CODE_EFFORT_LEVEL=unset CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 ANTHROPIC_BASE_URL=\"$(cat ${secretPath "develappers/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "develappers/auth-token"})\" ANTHROPIC_MODEL=develappers-coding ANTHROPIC_CUSTOM_MODEL_OPTION=gemma-4-fast ANTHROPIC_DEFAULT_HAIKU_MODEL=gemma-4-fast ANTHROPIC_DEFAULT_SONNET_MODEL=develappers-coding ANTHROPIC_DEFAULT_OPUS_MODEL=develappers-coding CLAUDE_MEM_MODEL=develappers-coding claude --model develappers-coding";
        };

      # claude-mem settings — declarative replacement for auto-generated
      # ~/.claude-mem/settings.json.  Tier models use real model names so the
      # worker never sends "general" to the API (gateway/collana aliases set
      # CLAUDE_MEM_MODEL=general at runtime; that alias is resolved by LiteLLM).
      home.file = {
        ".claude/statusline-command.sh" = statusline;

        # ~/.claude-work is the CLAUDE_CONFIG_DIR used by the claude-work /
        # claude-collana / claude-develappers aliases above — mirror the base setup
        # so those sessions get the same settings, statusline and skills.
        ".claude-work/statusline-command.sh" = statusline;
        ".claude-work/settings.json".source =
          config.home.file."${config.programs.claude-code.configDir}/settings.json".source;
      }
      // lib.mapAttrs' (
        name: src:
        lib.nameValuePair ".claude-work/skills/${name}" {
          source = src;
          recursive = true;
        }
      ) config.programs.claude-code.skills;
    };
}
