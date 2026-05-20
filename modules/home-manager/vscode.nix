{ config, ... }:
{
  flake.modules.homeManager.vscode =
    { pkgs, ... }:
    let
      vscodeVersion = "1.121.0";
      vscodePackage =
        if pkgs.stdenv.hostPlatform.isDarwin then
          pkgs.unstable.vscode.overrideAttrs (old: rec {
            version = vscodeVersion;
            src = pkgs.fetchurl {
              name = "VSCode_${version}_darwin-arm64.zip";
              url = "https://update.code.visualstudio.com/${version}/darwin-arm64/stable";
              sha256 = "sha256-8ixVOUe4EcNX/z0jnux1hXOhnG1JuhbssH2BARqU80o=";
            };
          })
        else
          pkgs.unstable.vscode.overrideAttrs (old: rec {
            version = vscodeVersion;
            src = pkgs.fetchurl {
              name = "VSCode_${version}_linux-x64.tar.gz";
              url = "https://update.code.visualstudio.com/${version}/linux-x64/stable";
              sha256 = "sha256-jPJMxBRBRT4R6P4a6eWNMpcOI9ztOZg1xLCQQmPWaCA=";
            };
          });
      marketplace = pkgs.vscode-marketplace-release;

      # extensions for all profiles
      # if they are not working properly append pkgs.unstable.vscode-extensions. in front of the extension id
      defaultExtensions = with marketplace; [
        pkief.material-icon-theme
        christian-kohler.path-intellisense
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit

        # some useful tools
        tomoki1207.pdf # PDF viewer
        davidanson.vscode-markdownlint
        tamasfe.even-better-toml
        ms-azuretools.vscode-containers
        mermaidchart.vscode-mermaid-chart

        # git
        mhutchie.git-graph
        donjayamanne.githistory

        github.vscode-pull-request-github
        github.vscode-github-actions

        # AI Tools
        anthropic.claude-code
        sst-dev.opencode

        # nix extensions
        jnoortheen.nix-ide
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

        "nix.formatterPath" = "nixfmt";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = {
              "command" = [ "nixfmt" ];
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
        nixfmt-rfc-style
        nixpkgs-fmt

        # for MCP
        uv
        nodejs_24
      ];

      programs = {
        gh = {
          enable = true;
        };

        vscode = {
          enable = true;
          package = vscodePackage;

          profiles = {
            default = {
              extensions = defaultExtensions;
              userSettings = defaultSettings;
              enableMcpIntegration = true;
            };

            "${config.flake.users.owner.username}" = {
              extensions =
                defaultExtensions
                ++ (with marketplace; [
                  # Add additional extensions specific to the owner profile here
                  # C/C++ extensions
                  llvm-vs-code-extensions.vscode-clangd
                  # vadimcn.vscode-lldb

                  # Rust extensions
                  rust-lang.rust-analyzer
                  tauri-apps.tauri-vscode

                  # python extensions
                  ms-python.python
                  ms-python.vscode-pylance
                  ms-python.debugpy
                  charliermarsh.ruff
                  ms-toolsai.jupyter
                  ms-toolsai.jupyter-keymap
                  ms-toolsai.jupyter-renderers
                  ms-toolsai.vscode-jupyter-slideshow
                  ms-toolsai.vscode-jupyter-cell-tags
                  ms-toolsai.vscode-jupyter-powertoys

                  # web development
                  ms-vscode.vscode-typescript-next
                  bradlc.vscode-tailwindcss
                  biomejs.biome
                  # ms-playwright.playwright
                ])
                ++ [
                  (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
                    mktplcRef = {
                      publisher = "ms-playwright";
                      name = "playwright";
                      version = "1.1.17";
                      sha256 = "1w3gih8igk3hairqi90pd919rqf4vadk0mm49xs92k7kp3v15158";
                    };
                  })
                ];
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
