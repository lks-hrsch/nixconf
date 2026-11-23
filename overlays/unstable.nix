{ nixpkgs-unstable }:
_final: prev: {
  unstable = import nixpkgs-unstable {
    inherit (prev.stdenv.hostPlatform) system;
    inherit (prev) config;
    overlays = [
      # claude-code from the upstream release manifest when it is newer than nixpkgs-unstable's.
      # Bump: B=https://downloads.claude.ai/claude-code-releases; \
      #   curl -fsSL "$B/$(curl -fsSL $B/latest)/manifest.zst.json" -o overlays/claude-code-manifest.json
      (_: p: {
        claude-code =
          let
            manifest = p.lib.importJSON ./claude-code-manifest.json;
          in
          if p.lib.versionOlder p.claude-code.version manifest.version then
            p.claude-code.override { inherit manifest; }
          else
            p.claude-code;
      })
      # nixpkgs' Traefik 3.7.16 is affected by repository advisories GHSA-xv5x-242w-7hf7 (backend transport
      # leak via unauthenticated NTLM/Negotiate headers, fixed in 3.7.17), GHSA-p956-6gvv-mxqp (ForwardAuth
      # NTLM bypass) and GHSA-rr42-h8r2-f28g (BasicAuth CPU amplification), both fixed in 3.7.18. Mercury is
      # the public edge and uses ForwardAuth; deimos uses BasicAuth. 3.7.19 needs Go >= 1.27 while the
      # nixpkgs expression builds with buildGo126Module, so swap the builder too (only while the
      # expression still takes that argument).
      # TODO: remove once nixpkgs-unstable has traefik >= 3.7.19: `nix flake update nixpkgs-unstable`, rebuild.
      (_: p: {
        traefik =
          if p.lib.versionOlder p.traefik.version "3.7.19" then
            (p.traefik.override (
              args: p.lib.optionalAttrs (args ? buildGo126Module) { buildGo126Module = p.buildGo127Module; }
            )).overrideAttrs
              (
                finalAttrs: _: {
                  version = "3.7.19";
                  src = p.fetchzip {
                    url = "https://github.com/traefik/traefik/releases/download/v${finalAttrs.version}/traefik-v${finalAttrs.version}.src.tar.gz";
                    hash = "sha256-grTFxMe8iNVrUSRA7H5qGXbiBvR6vHswFk9tWZ0ZxEo=";
                    stripRoot = false;
                  };
                  vendorHash = "sha256-ejWXi6Zl4N8pC6XTGkPbldS/KddWNgnHSDgnVDlpnxU=";
                }
              )
          else
            p.traefik;
      })
    ];
  };
}
