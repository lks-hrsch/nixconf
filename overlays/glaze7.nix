# Pins glaze to the last 7.x release (nixpkgs bumped to 8.0.0 on 2026-08-03).
# Hyprland v0.56.2's CMakeLists.txt requires glaze >=7,<8 — see
# modules/desktop/hyprland/base.nix for where this is consumed.
final: prev: {
  glaze7 = (prev.glaze.override {
    enableSSL = false;
    enableInterop = false;
  }).overrideAttrs (_old: {
    version = "7.9.1";
    src = prev.fetchFromGitHub {
      owner = "stephenberry";
      repo = "glaze";
      tag = "v7.9.1";
      hash = "sha256-NRRq5MGF2f5PW0teYnq58ELzson+U6KHVPaY6r30KLA=";
    };
  });
}
