{ pkgs, ... }:
{
  imports = [
    ./btop.nix
    ./direnv.nix
    ./fastfetch.nix
    ./git.nix
    ./gpg.nix
    ./k9s.nix
    ./ssh.nix
    ./starship.nix
    ./tmux.nix
    ./vim.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    azure-cli
    jq
    wget
    nmap
    iperf3
    smartmontools

    # latex
    (texliveSmall.withPackages (
      ps: with ps; [
        tudscr
        luainputenc
        fontaxes
        lualatex-math
        latexmk
        datetime2
        biblatex
        bbm
        bbm-macros
        minted # syntax highlighting
      ]
    ))
    ghostscript
    biber
  ];
}
