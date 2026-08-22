_: {
  flake.modules.homeManager.latex =
    { pkgs, lib, ... }:
    {
      home.packages =
        with pkgs;
        [
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
              pdfpc
              hyperxmp
              luacode
              ifmtarg
              zref
              helvetic # urw-base35 Helvetica — needed by acl.sty's [review] line numbers
              placeins # Control float placement
            ]
          ))
          ghostscript
          biber
        ]
        # nixpkgs pdfpc on aarch64-darwin crashes on first render (libc++/poppler ABI
        # mismatch against the system libc++). Homebrew's build is self-consistent —
        # see modules/darwin/homebrew.nix.
        ++ lib.optionals stdenv.isLinux [ pdfpc ];
    };
}
