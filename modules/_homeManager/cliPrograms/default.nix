{ pkgs, ... }:
{
  imports = [
    ./gpg.nix
    ./k9s.nix
    ./mcp.nix
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
        csquotes
        inconsolata
        mwe
        enumitem
      ]
    ))
    ghostscript
    biber
  ];
}
