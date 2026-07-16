final: prev:
let
  manifest = builtins.fromJSON (builtins.readFile ./vscode-manifest.json);
  inherit (prev.stdenv.hostPlatform) system;
  entry = manifest.platforms.${system};
  fmt = if prev.stdenv.hostPlatform.isDarwin then "zip" else "tar.gz";
  dlVer = prev.lib.versions.pad 3 manifest.version;
in
{
  vscode = prev.vscode.overrideAttrs (old: {
    inherit (manifest) version;
    src = prev.fetchurl {
      name = "VSCode_${dlVer}_${entry.plat}.${fmt}";
      url = "https://update.code.visualstudio.com/${dlVer}/${entry.plat}/stable";
      inherit (entry) sha256;
    };
    # VSCode's ripgrep-universal binary (bundled since 1.122+) has shipped
    # under BOTH `node_modules/` and `node_modules.asar.unpacked/` across
    # different releases — nixpkgs' own generic.nix (currently pinned to
    # vscode 1.127.0) assumes a single cutoff (asar.unpacked only pre-1.94.0
    # on darwin) that no longer holds: VSCode 1.129.0's darwin-arm64 build
    # ships ripgrep-universal under node_modules.asar.unpacked despite being
    # well past 1.94.0, so nixpkgs' hardcoded `chmod +x .../node_modules/...`
    # target 404s. Downstream consumers (e.g. cline/cline's extension.ts) hit
    # the same inconsistency and probe both locations instead of trusting a
    # version cutoff — do the same here. Covers both the pre-1.122
    # (`@vscode/ripgrep/bin/rg`) and current (`.../ripgrep-universal/bin/
    # <plat>/rg`) relative paths so this keeps working if nixpkgs' own vscode
    # pin ever moves back across that boundary.
    postPatch =
      let
        appDir = if prev.stdenv.hostPlatform.isDarwin then "Contents/Resources/app" else "resources/app";
        probe = rgRelPath: ''
          for base in "${appDir}/node_modules" "${appDir}/node_modules.asar.unpacked"; do
            if [ -f "$base/${rgRelPath}" ]; then
              chmod +x "$base/${rgRelPath}"
            fi
          done
        '';
      in
      builtins.replaceStrings
        [
          "chmod +x ${appDir}/node_modules/@vscode/ripgrep/bin/rg"
          "chmod +x ${appDir}/node_modules/@vscode/ripgrep-universal/bin/${entry.plat}/rg"
        ]
        [
          (probe "@vscode/ripgrep/bin/rg")
          (probe "@vscode/ripgrep-universal/bin/${entry.plat}/rg")
        ]
        old.postPatch;
    # 1.122 ships the Copilot extension with both glibc and musl native
    # binaries. The musl `copilot` wants libc.musl-*.so.1, which is absent on
    # glibc NixOS — autoPatchelf hard-fails on it. The glibc variant is the one
    # that actually runs, so ignore the unsatisfiable musl dep.
    autoPatchelfIgnoreMissingDeps =
      (old.autoPatchelfIgnoreMissingDeps or [ ]) ++ [ "libc.musl-x86_64.so.1" ];
    # 1.125 adds a Copilot computer-use binary (computer.node) that requires
    # libXtst, libjpeg8, pipewire, and libei for screen capture / input emulation.
    # These are Linux-only; guard so the overlay doesn't break darwin builds.
    buildInputs = (old.buildInputs or [ ]) ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [
      prev.libxtst
      prev.libjpeg8
      prev.pipewire
      prev.libei
    ];
  });
}
