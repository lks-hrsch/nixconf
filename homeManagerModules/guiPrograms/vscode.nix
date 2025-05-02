{ pkgs, ... }: {
  home.packages = with pkgs; [
    nixfmt-rfc-style
  ];

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      pkief.material-icon-theme
      github.copilot
      github.copilot-chat
      visualstudioexptteam.vscodeintellicode
      christian-kohler.path-intellisense
      mhutchie.git-graph
      ms-vscode-remote.remote-containers
      ms-vscode-remote.remote-ssh

      # nix extensions
      jnoortheen.nix-ide

      # C/C++ extensions
      llvm-vs-code-extensions.vscode-clangd
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
    };
  };
}
