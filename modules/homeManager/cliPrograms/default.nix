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
    fio
    iperf3
    jq
    nmap
    wget

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
      ]
    ))
    ghostscript
    biber
  ];
}
