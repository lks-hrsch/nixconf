{ ... }:
{
  flake.homeManagerModules.latex =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
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
    };
}
