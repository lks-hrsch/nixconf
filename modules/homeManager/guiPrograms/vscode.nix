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
    mutableExtensionsDir = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        pkief.material-icon-theme
        visualstudioexptteam.vscodeintellicode
        christian-kohler.path-intellisense
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh

        # some useful tools
        tomoki1207.pdf # PDF viewer
        davidanson.vscode-markdownlint
        tamasfe.even-better-toml

        # git
        mhutchie.git-graph
        donjayamanne.githistory

        # github
        github.copilot
        # github.copilot-chat
        github.vscode-pull-request-github
        github.vscode-github-actions

        # nix extensions
        jnoortheen.nix-ide

        # C/C++ extensions
        llvm-vs-code-extensions.vscode-clangd
        vadimcn.vscode-lldb

        # Rust extensions
        rust-lang.rust-analyzer
        tauri-apps.tauri-vscode

        # python extensions
        ms-python.python
        charliermarsh.ruff

        # web development
        bradlc.vscode-tailwindcss
        biomejs.biome
      ];

      userSettings = {
        "editor.formatOnSave" = true;

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
        "github.copilot.chat.codesearch.enabled" = true;
      };
    };
  };
}
