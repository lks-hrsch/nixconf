# Shared GitHub source pins for claude-code.nix + opencode.nix. Plain data, not a
# module (import-tree would eval it) — imported with `pkgs` by whichever module needs it.
pkgs: {
  # obra/superpowers — repo root is both the marketplace and the plugin
  superpowers = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "b36e0829c6d0140e93cfef2ca599b1b07d4a7797"; # v6.3.0
    hash = "sha256-EsGNO0dULWf5Bx6bGrCv2kI2Z8aKH0kRvGiuN23wChQ=";
  };
  # DietrichGebert/ponytail — repo root is both the marketplace and the plugin
  ponytail = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "1d95ff7d39de12d87014ea40d4e22201bddc501b"; # v4.10.0
    hash = "sha256-PES5XrSYx0VBXWVHEDRykGy0SAmJfV/luzy8Gfg0aAQ=";
  };
  # JuliusBrussee/caveman — repo root is both marketplace and plugin. v2.0.0 added a
  # BSL-1.1 component (self-host free, resale licensed); /caveman itself stays MIT — fine for personal use.
  caveman = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "b82c0ad42c2bedc1f2cd78e414dadfaffbaaeec3"; # v2.6.0
    hash = "sha256-tEQDv0sIsCzdzaq/tdUSN8nb2xmQJkmjPtq8wKChqvQ=";
  };
}
