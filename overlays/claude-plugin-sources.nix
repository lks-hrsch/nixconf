# Shared GitHub source pins for claude-code.nix + opencode.nix. Plain data, not a
# module (import-tree would eval it) — imported with `pkgs` by whichever module needs it.
pkgs: {
  # obra/superpowers — repo root is both the marketplace and the plugin
  superpowers = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "8ca22dba9a94f28898bbce59f2537ff4d87c747d"; # v6.4.2
    hash = "sha256-BWPiXoXV+jePP+wn/Z+Af4iehIL7oei00plaWaTzq8s=";
  };
  # DietrichGebert/ponytail — repo root is both the marketplace and the plugin
  ponytail = pkgs.fetchFromGitHub {
    owner = "DietrichGebert";
    repo = "ponytail";
    rev = "ef8ca48fed2321ab6668b2a954f23b1af97d7f6d"; # v4.10.3
    hash = "sha256-aypYnQf+zkKGj+dfs+qFKTFIvaick9p0XJNtPkSwIB0=";
  };
  # JuliusBrussee/caveman — repo root is both marketplace and plugin. v2.0.0 added a
  # BSL-1.1 component (self-host free, resale licensed); /caveman itself stays MIT — fine for personal use.
  caveman = pkgs.fetchFromGitHub {
    owner = "JuliusBrussee";
    repo = "caveman";
    rev = "8b0c1d3699b8d83e87fe4605b378da20c41555e0"; # v2.7.0
    hash = "sha256-dsGzPscjy7FfaovfYML2q+RmuBJwwEJ9sjeHi+Niv6Y=";
  };
}
