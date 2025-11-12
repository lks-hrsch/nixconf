{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nil
    nixfmt-rfc-style
    nixpkgs-fmt
    code-cursor
  ];

  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-marketplace-release; [
        pkief.material-icon-theme
        visualstudioexptteam.vscodeintellicode
        christian-kohler.path-intellisense
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit

        # some useful tools
        tomoki1207.pdf # PDF viewer
        davidanson.vscode-markdownlint
        tamasfe.even-better-toml
        ms-azuretools.vscode-containers

        # git
        mhutchie.git-graph
        donjayamanne.githistory

        # github
        github.copilot
        github.copilot-chat
        github.vscode-pull-request-github
        github.vscode-github-actions

        # nix extensions
        jnoortheen.nix-ide

        # C/C++ extensions
        llvm-vs-code-extensions.vscode-clangd
        # vadimcn.vscode-lldb

        # Rust extensions
        rust-lang.rust-analyzer
        tauri-apps.tauri-vscode

        # python extensions
        ms-python.python
        ms-python.vscode-pylance
        charliermarsh.ruff
        ms-toolsai.jupyter-keymap
        ms-toolsai.jupyter-renderers
        ms-toolsai.vscode-jupyter-cell-tags
        ms-toolsai.vscode-jupyter-powertoys

        # web development
        ms-vscode.vscode-typescript-next
        bradlc.vscode-tailwindcss
        biomejs.biome
        ms-playwright.playwright
      ];

      userSettings = {
        "telemetry.editStats.enabled" = false;
        "telemetry.feedback.enabled" = false;
        "telemetry.telemetryLevel" = "off";

        "editor.formatOnSave" = true;
        "editor.formatOnPaste" = true;

        "git.autofetch" = "all";

        "nix.formatterPath" = "nixpkgs-fmt";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = {
              "command" = [ "nixfmt" ];
            };
          };
        };

        "github.copilot.enable" = {
          "*" = true;
        };
        "github.copilot.nextEditSuggestions.enabled" = true;
        "github.copilot.nextEditSuggestions.fixes" = true;
        "github.copilot.chat.agent.thinkingTool" = false;
        "github.copilot.chat.edits.temporalContext.enabled" = false;
        "github.copilot.chat.codesearch.enabled" = true;
        "github.copilot.chat.languageContext.fix.typescript.enabled" = false;
        "github.copilot.chat.useResponsesApi" = false;

        "playwright.pickLocatorCopyToClipboard" = true;
        "playwright.reuseBrowser" = true;
      };
    };
  };
}
