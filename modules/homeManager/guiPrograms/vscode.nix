{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nixfmt-rfc-style
    code-cursor
  ];

  programs.vscode = {
    enable = true;
    profiles.default = {

      extensions = with pkgs.vscode-extensions; [
        pkief.material-icon-theme
        visualstudioexptteam.vscodeintellicode
        christian-kohler.path-intellisense
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh

        # some useful tools
        tomoki1207.pdf # PDF viewer

        # git
        mhutchie.git-graph
        donjayamanne.githistory

        # github
        github.copilot
        github.copilot-chat
        github.vscode-pull-request-github
        github.vscode-github-actions

        # docker
        # ms-azuretools.vscode-docker
        # ms-azuretools.vscode-containers
        # docker.docker

        # nix extensions
        jnoortheen.nix-ide

        # C/C++ extensions
        llvm-vs-code-extensions.vscode-clangd

        # python extensions
        ms-python.python
        charliermarsh.ruff
      ];

      userSettings = {
        "editor.formatOnSave" = true;

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
