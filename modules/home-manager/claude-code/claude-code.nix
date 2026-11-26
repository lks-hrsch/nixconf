{ config, ... }:
let
  inherit (config.repo.constants) obsidianBasePath;
in
{
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
      # anthropics/claude-plugins-official, pinned to latest main as of 2026-11-25
      official = pkgs.fetchFromGitHub {
        owner = "anthropics";
        repo = "claude-plugins-official";
        rev = "0fbfda5a91f4adc311daca25acc99132f40f0b6e";
        hash = "sha256-J9pxacOMDz6wEHJHo5d0JhLfR/95hhJwUz1RmHqRvcI=";
      };
      inherit (import ../../../overlays/claude-plugin-sources.nix pkgs) superpowers ponytail caveman;
      # Copy of a plugin without the skills it lists
      trimPlugin =
        name: src: skills: extra:
        pkgs.runCommand name { nativeBuildInputs = [ pkgs.jq ]; } ''
          cp -r ${src} $out
          chmod -R u+w $out
          ${lib.concatMapStringsSep "\n" (s: "rm -r $out/skills/${s}") skills}
          ${extra}
        '';

      # ponytail
      ponytail-customised =
        trimPlugin "ponytail-customised" ponytail
          [
            "ponytail-gain"
            "ponytail-help"
            "ponytail-review"
            "ponytail-audit"
          ]
          ''
            jq '.hooks -= ["./hooks/claude-band.json"]' ${ponytail}/.claude-plugin/plugin.json > $out/.claude-plugin/plugin.json
          '';

      # caveman
      caveman-customised = trimPlugin "caveman-customised" caveman [
        "caveman-setup"
        "caveman-discover"
        "caveman-evidence-review"
        "caveman-manage"
        "caveman-optimize"
        "caveman-learn"
        "caveman-help"
        "caveman-stats"
        "caveman-compress"
        "investigate-first"
        "lean-build"
        "migration"
        "safe-refactor"
        "surgical-patch"
        "verify-and-stop"
        "caveman-explore"
      ] "";

      # claude-mem
      claude-mem = pkgs.fetchFromGitHub {
        owner = "thedotmack";
        repo = "claude-mem";
        rev = "94474143a3d5bb6f1f25d8049194d675d724310e"; # v17.0.0
        hash = "sha256-zt7icqLVWPic95njXydN17N3vjBEvitrRAJqy7I7iH0=";
      };
      claude-mem-plugin = pkgs.stdenvNoCC.mkDerivation {
        pname = "claude-mem-plugin";
        version = "17.0.0";
        src = "${claude-mem}/plugin";
        nativeBuildInputs = [ pkgs.unstable.bun ];
        nodeOs = pkgs.stdenv.hostPlatform.node.platform;
        nodeCpu = pkgs.stdenv.hostPlatform.node.arch;
        buildPhase = ''
          export HOME=$TMPDIR
          bun install --frozen-lockfile --production --ignore-scripts --no-progress --os=$nodeOs --cpu=$nodeCpu
        '';
        installPhase = "cp -r . $out";
        dontFixup = true;
        outputHashMode = "recursive";
        outputHash =
          {
            aarch64-darwin = "sha256-1as5pVbV+EsG6pv2AI7e/QCdNse5AgyYnE3l9Ckulpo=";
            x86_64-linux = "sha256-xaGeD8QM9JCHVznwAX2hhoGJnMLtSaN5C8fV4dmxPfM=";
          }
          .${pkgs.stdenv.hostPlatform.system};
      };
      claude-mem-customised = trimPlugin "claude-mem-plugin-trimmed" claude-mem-plugin [
        # maintainer or release workflows for the claude-mem repo itself
        "version-bump"
        "release"
        "build-and-release"
        "childhood"
        "oh-my-issues"
        "ccs-align"
        # need cmem Pro or the Screenpipe app
        "cloud-sync"
        "screenpipe"
        # duplicates of superpowers' plan/execute skills and the built-in /steward
        "make-plan"
        "do"
        "build"
        "babysit"
        # never used
        "wowerpoint"
        "design-is"
        "agent-cost-report"
        "owner-goals"
        "request-progress"
        "timeline-report"
        "weekly-digests"
        "knowledge-agent"
        "what-the"
        "standup"
        "pathfinder"
        "how-it-works"
      ] "";
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
            # Tier models default to haiku/sonnet, which Claude Code expands to full Anthropic IDs the gateway rejects.
            run ${lib.getExe pkgs.jq} \
              '.CLAUDE_MEM_PROVIDER = "claude" | .CLAUDE_MEM_CLAUDE_AUTH_METHOD = "gateway" | .CLAUDE_MEM_MODEL = "coding" | .CLAUDE_MEM_TIER_SIMPLE_MODEL = "coding" | .CLAUDE_MEM_TIER_FAST_MODEL = "coding" | .CLAUDE_MEM_TIER_SMART_MODEL = "coding" | .CLAUDE_CODE_PATH = "${config.home.profileDirectory}/bin/claude"' \
              "$settings" > "$settings.tmp" && run mv "$settings.tmp" "$settings"
          fi
        '';

        # Mirrors settings.env below for processes outliving the session that spawned them: the
        # claude-mem worker keeps the env of whichever session started it, and its observer needs this.
        sessionVariables = {
          CLAUDE_CODE_CERT_STORE = "bundled";
          CLAUDE_MEM_TELEMETRY = "0";
          CLAUDE_MEM_DELIVERABLES_ENABLED = "false";
          CLAUDE_MEM_AUTO_UPDATE = "false";
          DISABLE_AUTOUPDATER = "1";
        };

        packages = with pkgs; [
          nodejs_24
          # claude-mem compiles its launcher with this: macOS 27 kills binaries from Bun older than 1.4.1.
          unstable.bun
          # claude-mem smart_outline/smart_search shell out to it (0.26 or newer)
          unstable.tree-sitter
          # for the security-guidance and claude-security plugin hooks
          (unstable.python3.withPackages (ps: [ ps.claude-agent-sdk ]))
        ];

        file = {
          ".claude/statusline-command.sh" = statusline;

          # claude-mem gateway credentials, symlinked out of the Nix store
          ".claude-mem/.env".source =
            config.lib.file.mkOutOfStoreSymlink
              config.sops.secrets."claude-mem/env".path;

          # ~/.claude-work: CLAUDE_CONFIG_DIR for claude-work/-collana/-develappers — mirrors the
          # base setup so those sessions get the same settings, statusline and skills.
          ".claude-work/statusline-command.sh" = statusline;
          # Same settings, but work runs Sonnet with an Opus advisor.
          ".claude-work/settings.json".source =
            pkgs.runCommand "claude-work-settings.json" { nativeBuildInputs = [ pkgs.jq ]; }
              ''
                jq '.model = "sonnet" | .advisorModel = "opus"' \
                  ${config.home.file."${config.programs.claude-code.configDir}/settings.json".source} > $out
              '';
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
        claude-code = {
          enable = true;
          enableMcpIntegration = true;
          # wrapper prefixes LD_LIBRARY_PATH with alsa-lib, inherited by every shell it spawns;
          # stable alsa-lib keeps stable binaries (ffmpeg) off unstable's newer glibc
          package = pkgs.unstable.claude-code.override { inherit (pkgs) alsa-lib; };
          marketplaces = {
            inherit superpowers;
            inherit claude-mem;
            inherit ponytail;
            inherit caveman;
          };

          plugins = [
            "${official}/plugins/claude-md-management"
            "${official}/plugins/claude-security"
            "${official}/plugins/code-modernization"
            "${official}/plugins/code-simplifier"
            "${official}/plugins/security-guidance"
            # superpowers is an external plugin referenced by the official marketplace
            superpowers
            # claude-mem
            claude-mem-customised
            # ponytail: lazy-senior-dev ruleset; /ponytail, /ponytail-debt
            ponytail-customised
            # caveman — ultra-compressed prose mode; /caveman, active by default
            caveman-customised
          ];

          hooks.reflect = builtins.readFile ./hooks/reflect.sh;
          hooks.obsidian = builtins.readFile ./hooks/obsidian.sh;

          lspServers = {
            typescript = {
              command = lib.getExe pkgs.unstable.typescript-language-server;
              args = [ "--stdio" ];
              # Prefers the project's typescript; TypeScript 7 ships no tsserver, so fall back to 5.
              initializationOptions.tsserver.fallbackPath = "${pkgs.unstable.typescript_5}/lib/node_modules/typescript/lib/tsserver.js";
              extensionToLanguage = {
                ".ts" = "typescript";
                ".tsx" = "typescriptreact";
                ".mts" = "typescript";
                ".cts" = "typescript";
                ".js" = "javascript";
                ".jsx" = "javascriptreact";
                ".mjs" = "javascript";
                ".cjs" = "javascript";
              };
            };
            pyright = {
              command = lib.getExe' pkgs.unstable.pyright "pyright-langserver";
              args = [ "--stdio" ];
              extensionToLanguage = {
                ".py" = "python";
                ".pyi" = "python";
              };
            };
            # Uses the cargo/rustc on PATH (devshell or rustup) for the sysroot.
            rust-analyzer = {
              command = lib.getExe pkgs.unstable.rust-analyzer;
              extensionToLanguage.".rs" = "rust";
            };
            # Same server as VS Code (vscode.nix).
            nil = {
              command = lib.getExe pkgs.unstable.nil;
              extensionToLanguage.".nix" = "nix";
            };
          }
          // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
            # Xcode's sourcekit-lsp, matching the selected toolchain.
            sourcekit-lsp = {
              command = "/usr/bin/xcrun";
              args = [ "sourcekit-lsp" ];
              extensionToLanguage.".swift" = "swift";
            };
          };

          settings = {
            outputStyle = "Concise";
            skillListingBudgetFraction = 0.05;
            model = "opus";
            # Fable advises Opus sessions and Sonnet subagents; ~/.claude-work/settings.json overrides it.
            # Gateway models have no advisor rank, so it stays off there.
            advisorModel = "fable";
            # Top-level effortLevel only applies to legacy/custom models (gateway aliases);
            effortLevel = "xhigh";
            modelSettings = {
              "claude-opus-5-5".effortLevel = "high";
              "claude-sonnet-5-5".effortLevel = "xhigh";
              "claude-haiku-5-5".effortLevel = "xhigh";
              "claude-fable-5-1".effortLevel = "high";
              "claude-fable-5-2".effortLevel = "high";
            };

            # /reflect in a background fork before each compaction and at each session end.
            hooks =
              let
                reflect = [
                  {
                    hooks = [
                      {
                        type = "command";
                        command = "${config.home.homeDirectory}/.claude/hooks/reflect";
                        timeout = 10;
                      }
                    ];
                  }
                ];
              in
              {
                PreCompact = reflect;
                SessionEnd = reflect;
                # Names Obsidian notes whose filename matches the prompt; silent otherwise.
                # Not an mcp_tool hook: only a command's stdout reaches Claude as context.
                UserPromptSubmit = [
                  {
                    hooks = [
                      {
                        type = "command";
                        command = "OBSIDIAN_VAULT=${config.home.homeDirectory}/${obsidianBasePath}/private ${config.home.homeDirectory}/.claude/hooks/obsidian";
                        timeout = 5;
                      }
                    ];
                  }
                ];
              };

            spinnerTipsEnabled = false;
            teammateMode = "auto";
            preferredNotifChannel = "terminal_bell";
            cleanupPeriodDays = 30;

            # Claude Code's macOS system-store lookup fails on this machine (no TLS interception;
            # Apple curl + bundled store verify fine). Remove once the bug is fixed.
            env = {
              CLAUDE_CODE_CERT_STORE = "bundled";
              CLAUDE_CODE_SUBAGENT_MODEL = "sonnet"; # Subagents without an explicit model; a per-call model still wins.
              CLAUDE_MEM_TELEMETRY = "0"; # Not global DO_NOT_TRACK: it costs the security-guidance plugin its sign-in.
              CLAUDE_MEM_DELIVERABLES_ENABLED = "false"; # The v15.3.0 Stop hook copies written files to ~/.claude-mem/deliverables, *.key included.
              CLAUDE_MEM_AUTO_UPDATE = "false"; # v15.14.0 auto-update rewrites ~/.claude/plugins behind the Nix pin.
              CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"; # Named subagents now launch as teammates.
              DISABLE_AUTOUPDATER = "1";
            };

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
              defaultMode = "auto";
            };
            statusLine = {
              type = "command";
              command = "bash ~/.claude/statusline-command.sh";
            };
            promptSuggestionEnabled = false;
            autoMemoryEnabled = true;
            autoDreamEnabled = true;
            remoteControlAtStartup = true;
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
            claude-collana-private = "DISABLE_INTERLEAVED_THINKING=1 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 ANTHROPIC_BASE_URL=\"$(cat ${secretPath "collana/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "collana/auth-token"})\" ANTHROPIC_MODEL=coding ANTHROPIC_CUSTOM_MODEL_OPTION=general ANTHROPIC_DEFAULT_HAIKU_MODEL=coding ANTHROPIC_DEFAULT_SONNET_MODEL=coding ANTHROPIC_DEFAULT_OPUS_MODEL=general claude --teammate-mode in-process --model coding";
            claude-collana = "CLAUDE_CONFIG_DIR=\"$HOME/.claude-work\" DISABLE_INTERLEAVED_THINKING=1 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 ANTHROPIC_BASE_URL=\"$(cat ${secretPath "collana/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "collana/auth-token"})\" ANTHROPIC_MODEL=coding ANTHROPIC_CUSTOM_MODEL_OPTION=general ANTHROPIC_DEFAULT_HAIKU_MODEL=coding ANTHROPIC_DEFAULT_SONNET_MODEL=coding ANTHROPIC_DEFAULT_OPUS_MODEL=general claude --teammate-mode in-process --model coding";
            claude-develappers = "CLAUDE_CONFIG_DIR=\"$HOME/.claude-work\" DISABLE_INTERLEAVED_THINKING=1 CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1 ANTHROPIC_BASE_URL=\"$(cat ${secretPath "develappers/base-url"})\" ANTHROPIC_AUTH_TOKEN=\"$(cat ${secretPath "develappers/auth-token"})\" ANTHROPIC_MODEL=develappers-coding ANTHROPIC_CUSTOM_MODEL_OPTION=gemma-4-fast ANTHROPIC_DEFAULT_HAIKU_MODEL=gemma-4-fast ANTHROPIC_DEFAULT_SONNET_MODEL=develappers-coding-low-think ANTHROPIC_DEFAULT_OPUS_MODEL=develappers-coding claude --teammate-mode in-process --model develappers-coding";
          };
      };
    };
}
