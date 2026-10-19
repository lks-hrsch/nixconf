{ config, ... }:
{
  flake.modules.homeManager.vscode =
    { pkgs, lib, ... }:
    let
      # resolves each id to the newest marketplace release whose engine range accepts our VS Code build
      extensionsFor = pkgs.nix4vscode.forVscodeVersion pkgs.unstable.vscode.version;

      # extensions for all profiles
      # to pin a specific version append it to the id, e.g. "publisher.name.1.2.3"
      defaultExtensions = [
        "pkief.material-icon-theme"
        "christian-kohler.path-intellisense"
        "ms-vscode-remote.remote-containers"
        "ms-vscode-remote.remote-ssh"
        "ms-vscode-remote.remote-ssh-edit"

        # some useful tools
        "tomoki1207.pdf" # PDF viewer
        "davidanson.vscode-markdownlint"
        "tamasfe.even-better-toml"
        "ms-azuretools.vscode-containers"
        "mermaidchart.vscode-mermaid-chart"

        # git
        "mhutchie.git-graph"
        "donjayamanne.githistory"

        "github.vscode-pull-request-github"
        "github.vscode-github-actions"

        # AI Tools
        "anthropic.claude-code"
        "sst-dev.opencode"

        # nix extensions
        "jnoortheen.nix-ide"

        # yaml
        "redhat.vscode-yaml"
      ];

      # settings for all profiles
      defaultSettings = {
        "telemetry.editStats.enabled" = false;
        "telemetry.feedback.enabled" = false;
        "telemetry.telemetryLevel" = "off";

        "update.mode" = "none";

        "editor.formatOnSave" = true;
        "editor.formatOnPaste" = true;
        "editor.aiStats.enabled" = true;
        "workbench.editorLargeFileConfirmation" = 100; # 100 MB

        "diffEditor.ignoreTrimWhitespace" = false;

        # "git.autofetch" = "all";

        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
        "nix.formatterPath" = lib.getExe pkgs.nixfmt;
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = {
              "command" = [ (lib.getExe pkgs.nixfmt) ];
            };
          };
        };

        "github.gitProtocol" = "ssh";

        "github.copilot.chat.rateLimitAutoSwitchToAuto" = true;
        "github.copilot.nextEditSuggestions.enabled" = true;
        "github.copilot.nextEditSuggestions.extendedRange" = true;
        "github.copilot.nextEditSuggestions.fixes" = true;
        "github.copilot.chat.codesearch.enabled" = true;
        "github.copilot.chat.githubMcpServer.enabled" = true;
        "github.copilot.chat.newWorkspace.useContext7" = true;
        "github.copilot.chat.gpt54ConcisePrompt.enabled" = true;
        "github.copilot.chat.gpt54LargePrompt.enabled" = true;
        "github.copilot.chat.switchAgent.enabled" = true;
        "github.copilot.chat.agent.backgroundTodoAgent.enabled" = true;

        "chat.disableAIFeatures" = false;
        "chat.mcp.gallery.enabled" = true;
        "chat.mcp.discovery.enabled" = {
          "claude-desktop" = true;
          "cursor-global" = true;
          "cursor-workspace" = true;
        };
        "chat.tools.compressOutput.enabled" = true;

        "claudeCode.hideOnboarding" = true;
        "claudeCode.useTerminal" = true;
      };
    in
    {
      home.packages = with pkgs; [
        nil
        nixfmt

        # for MCP
        uv
        nodejs_24

        # for Python
        unstable.pyrefly
        unstable.ruff

        # for YAML
        unstable.yaml-language-server
      ];

      programs = {
        gh = {
          enable = true;
        };

        vscode = {
          enable = true;
          package = pkgs.unstable.vscode;

          profiles = {
            default = {
              extensions = extensionsFor defaultExtensions;
              userSettings = defaultSettings;
              enableMcpIntegration = true;
            };

            "${config.flake.users.owner.username}" = {
              extensions = extensionsFor (
                defaultExtensions
                ++ [
                  # Add additional extensions specific to the owner profile here
                  # C/C++ extensions
                  "llvm-vs-code-extensions.vscode-clangd"
                  # vadimcn.vscode-lldb

                  # Rust extensions
                  "rust-lang.rust-analyzer"
                  "tauri-apps.tauri-vscode"

                  # python extensions
                  "ms-python.python"
                  "ms-python.vscode-pylance"
                  "ms-python.debugpy"
                  "meta.pyrefly"
                  "charliermarsh.ruff"
                  "ms-toolsai.jupyter"
                  "ms-toolsai.jupyter-keymap"
                  "ms-toolsai.jupyter-renderers"
                  "ms-toolsai.vscode-jupyter-slideshow"
                  "ms-toolsai.vscode-jupyter-cell-tags"
                  "ms-toolsai.vscode-jupyter-powertoys"

                  # web development
                  "ms-vscode.vscode-typescript-next"
                  "bradlc.vscode-tailwindcss"
                  "biomejs.biome"
                  "ms-playwright.playwright"
                ]
              );
              userSettings = defaultSettings // {
                # Add additional settings specific to the owner profile here
                "playwright.pickLocatorCopyToClipboard" = true;
                "playwright.reuseBrowser" = true;

                "python.analysis.aiCodeActions" = {
                  "implementAbstractClasses" = true;
                  "generateSymbol" = true;
                  "convertFormatString" = true;
                };
              };
              enableMcpIntegration = true;
            };
          };
        };
      };
    };
}
