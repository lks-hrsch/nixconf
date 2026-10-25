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
      # anthropics/claude-plugins-official — pinned to latest main as of 2026-10-25
      official = pkgs.fetchFromGitHub {
        owner = "anthropics";
        repo = "claude-plugins-official";
        rev = "58267944f92187b7d6a1c822165c96c81c864806";
        hash = "sha256-f6wBcSVGNvY+lqFbs0cczTRfRjYZrqWb0hslE7IX2p8=";
      };
      inherit (import ../../../overlays/claude-plugin-sources.nix pkgs) superpowers ponytail caveman;

      claude-mem = pkgs.fetchFromGitHub {
        owner = "thedotmack";
        repo = "claude-mem";
        rev = "1ce03615ca3df37683baf22b5ac0a7b12d3e9866"; # v15.2.0
        hash = "sha256-K7kN0sulwKKDEZwhOZjNbb50fbCxtsTGkUyzRn7qnGA=";
      };
    in
    {
      imports = [ ../../../overlays/uv-module.nix ];

      # Decrypted at activation, read at runtime by the aliases below — keeps secrets out of the Nix store.
      sops.secrets = {
        "claude-code/provider/collana/base-url" = { };
        "claude-code/provider/collana/auth-token" = { };
        "claude-code/provider/develappers/base-url" = { };
        "claude-code/provider/develappers/auth-token" = { };
        "claude-mem/env" = { };
      };

      home = {
        # jq-patched, not home.file-owned: claude-mem writes other keys back at runtime (cloud-sync, mode-creator, telegram).
        activation.claudeMemGatewaySettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          settings="$HOME/.claude-mem/settings.json"
          if [ -f "$settings" ]; then
            run ${lib.getExe pkgs.jq} \
              '.CLAUDE_MEM_PROVIDER = "claude" | .CLAUDE_MEM_CLAUDE_AUTH_METHOD = "gateway" | .CLAUDE_MEM_MODEL = "coding"' \
              "$settings" > "$settings.tmp" && run mv "$settings.tmp" "$settings"
          fi
        '';

        packages = with pkgs; [
          nodejs_24
          bun
          # for the security-guidance and claude-security plugin hooks
          (unstable.python3.withPackages (ps: [ ps.claude-agent-sdk ]))
        ];

        # CLAUDE_MEM_MODEL=general is set by the gateway aliases and resolved via LiteLLM at runtime.
        file = {
          ".claude/statusline-command.sh" = statusline;

          # claude-mem gateway credentials, symlinked out of the Nix store
          ".claude-mem/.env".source =
            config.lib.file.mkOutOfStoreSymlink
              config.sops.secrets."claude-mem/env".path;

          # ~/.claude-work: CLAUDE_CONFIG_DIR for claude-work/-collana/-develappers — mirrors the
          # base setup so those sessions get the same settings, statusline and skills.
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

      programs = {
        # graphify skill CLI: PyPI package `graphifyy`, command `graphify`
        uv.tool.packages = [ "graphifyy" ];

        claude-code = {
          enable = true;
          enableMcpIntegration = true;
          package = pkgs.unstable.claude-code;
          marketplaces = {
            inherit superpowers;
            inherit claude-mem;
            inherit ponytail;
            inherit caveman;
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
            # ponytail — lazy-senior-dev ruleset; /ponytail{,-review,-audit,-debt,-gain,-help}
            ponytail
            # caveman — ultra-compressed prose mode; /caveman, active by default
            caveman
          ];
          settings = {
            outputStyle = "Concise";
            skillListingBudgetFraction = 0.05;
            model = "opusplan";
            # Top-level effortLevel only applies to legacy/custom models (gateway aliases);
            effortLevel = "xhigh";
            modelSettings = {
              "claude-opus-5-5".effortLevel = "high";
              "claude-sonnet-5-5".effortLevel = "high";
            };
            spinnerTipsEnabled = false;
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
                "Bash(cut:*)"
                "Bash(tr:*)"
                # system info
                "Bash(ps:*)"
                "Bash(uname:*)"
                # git read-only (structure/history, no file content)
                "Bash(git log:*)"
                "Bash(git status:*)"
                "Bash(git branch)"
                "Bash(git branch -a)"
                "Bash(git branch --list *)"
                "Bash(git remote -v)"
                "Bash(git remote get-url *)"
                "Bash(git diff *)"
                "Bash(git show *)"
                "Bash(git blame *)"
                "Bash(git ls-files:*)"
                "Bash(git stash list:*)"
                "Bash(git rev-parse:*)"
                # nix read-only
                "Bash(nix flake show:*)"
                "Bash(nix path-info:*)"
                "Bash(nix eval *)"
                "Bash(nix flake check *)"
                "Bash(nix flake metadata *)"
                "Bash(nix search *)"
                "Bash(nix log *)"
                # search / json
                "Bash(rg *)"
                "Bash(jq *)"
                # web
                "WebSearch"
                "WebFetch(domain:github.com)"
                "WebFetch(domain:raw.githubusercontent.com)"
                "WebFetch(domain:nix.dev)"
                "WebFetch(domain:mynixos.com)"
                "WebFetch(domain:wiki.nixos.org)"
                # mcp
                "mcp__plugin_claude-code-home-manager_context7__*"
                "mcp__plugin_claude-code-home-manager_nixos__*"
                "mcp__plugin_claude-code-home-manager_grep-app__*"
                "mcp__plugin_claude-code-home-manager_websearch__*"
                # obsidian: named read tools only (mcpvault is unpinned, a new write tool must not be auto-allowed)
                "mcp__plugin_claude-code-home-manager_obsidian__read_*"
                "mcp__plugin_claude-code-home-manager_obsidian__list_*"
                "mcp__plugin_claude-code-home-manager_obsidian__get_*"
                "mcp__plugin_claude-code-home-manager_obsidian__search_notes"
                "mcp__grafana__*"
                "mcp__plugin_claude-mem_mcp-search__search"
                "mcp__plugin_claude-mem_mcp-search__timeline"
                "mcp__plugin_claude-mem_mcp-search__get_observations"
                "mcp__plugin_claude-mem_mcp-search__smart_*"
              ];
              # Text-match guardrails against mistakes, not a security boundary (/bin/rm, bash -c bypass Bash rules).
              # Use Edit(...) for path rules: Write(...) path rules are ignored.
              deny = [
                # credentials (a Read deny also blocks Edit and cat/head/sed on the path)
                "Read(~/.ssh/**)"
                "Read(~/.gnupg/**)"
                "Read(~/.config/sops/**)"
                "Read(~/.config/op/**)"
                "Read(~/.config/gh/**)"
                "Read(~/.aws/**)"
                "Read(~/.kube/**)"
                "Read(~/.netrc)"
                "Read(~/.git-credentials)"
                "Read(**/.env)"
                "Read(**/.env.*)"
                "Read(**/*.pem)"
                "Read(**/*.key)"
                "Read(**/.git/git-crypt/**)"
                # never deploy (see repo CLAUDE.md)
                "Bash(nixos-rebuild switch*)"
                "Bash(nixos-rebuild boot*)"
                "Bash(nixos-rebuild test*)"
                "Bash(darwin-rebuild switch*)"
                "Bash(darwin-rebuild activate*)"
                "Bash(./rebuild-*)"
                "Bash(sudo *)"
                # secret decryption
                "Bash(sops -d*)"
                "Bash(sops --decrypt*)"
                "Bash(sops decrypt*)"
                "Bash(git-crypt unlock*)"
                "Bash(git-crypt export-key*)"
                "Bash(op *)"
                "Bash(gpg --export-secret*)"
                "Bash(age -d*)"
                "Bash(security find-*-password*)"
                # destructive git / pipe-to-shell
                "Bash(git push --force*)"
                "Bash(git push -f*)"
                "Bash(git reset --hard*)"
                "Bash(git clean -f*)"
                "Bash(git filter-branch*)"
                "Bash(curl * | sh*)"
                "Bash(curl * | bash*)"
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

        zsh.shellAliases =
          let
            secretPath = name: config.sops.secrets."claude-code/provider/${name}".path;
          in
          {
            claude-work = "CLAUDE_CONFIG_DIR=\"$HOME/.claude-work\" claude";
            claude-collana-private = "DISABLE_INTERLEAVED_THINKING=1 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 ANTHROPIC_BASE_URL=\"$(cat ${secretPath "collana/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "collana/auth-token"})\" ANTHROPIC_MODEL=coding ANTHROPIC_CUSTOM_MODEL_OPTION=general ANTHROPIC_DEFAULT_HAIKU_MODEL=coding ANTHROPIC_DEFAULT_SONNET_MODEL=coding ANTHROPIC_DEFAULT_OPUS_MODEL=general CLAUDE_MEM_MODEL=general claude --model coding";
            claude-collana = "CLAUDE_CONFIG_DIR=\"$HOME/.claude-work\" DISABLE_INTERLEAVED_THINKING=1 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 ANTHROPIC_BASE_URL=\"$(cat ${secretPath "collana/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "collana/auth-token"})\" ANTHROPIC_MODEL=coding ANTHROPIC_CUSTOM_MODEL_OPTION=general ANTHROPIC_DEFAULT_HAIKU_MODEL=coding ANTHROPIC_DEFAULT_SONNET_MODEL=coding ANTHROPIC_DEFAULT_OPUS_MODEL=general CLAUDE_MEM_MODEL=general claude --model coding";
            claude-develappers = "CLAUDE_CONFIG_DIR=\"$HOME/.claude-work\" DISABLE_INTERLEAVED_THINKING=1 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 ANTHROPIC_BASE_URL=\"$(cat ${secretPath "develappers/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "develappers/auth-token"})\" ANTHROPIC_MODEL=develappers-coding ANTHROPIC_CUSTOM_MODEL_OPTION=gemma-4-fast ANTHROPIC_DEFAULT_HAIKU_MODEL=gemma-4-fast ANTHROPIC_DEFAULT_SONNET_MODEL=develappers-coding-low-think ANTHROPIC_DEFAULT_OPUS_MODEL=develappers-coding CLAUDE_MEM_MODEL=develappers-coding claude --model develappers-coding";
          };
      };
    };
}
