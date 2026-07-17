_: {
  flake.modules.homeManager.latex =
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
            noto
            notomath # math support for noto fonts
            newtx
            txfonts # txsyc symbol fonts used by newtxmath
            kastrup # binhex.tex (\input by newtxmath)
            xstring # used by newtxmath
          ]
        ))
        ghostscript
        biber
      ];
    };
}
