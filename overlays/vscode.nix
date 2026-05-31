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
    # VSCode 1.122+ moved the bundled ripgrep from `@vscode/ripgrep/bin/rg`
    # to `@vscode/ripgrep-universal/bin/<plat>/rg`. The nixpkgs builder still
    # hardcodes the old path in postPatch, so its `rm` fails. Patch the
    # already-rendered postPatch string to point at the new location.
    # `entry.plat` (linux-x64 / linux-arm64 / darwin-arm64) matches the
    # ripgrep-universal subdir name for every system we ship.
    postPatch = builtins.replaceStrings
      [ "@vscode/ripgrep/bin/rg" ]
      [ "@vscode/ripgrep-universal/bin/${entry.plat}/rg" ]
      old.postPatch;
    # 1.122 ships the Copilot extension with both glibc and musl native
    # binaries. The musl `copilot` wants libc.musl-*.so.1, which is absent on
    # glibc NixOS — autoPatchelf hard-fails on it. The glibc variant is the one
    # that actually runs, so ignore the unsatisfiable musl dep.
    autoPatchelfIgnoreMissingDeps =
      (old.autoPatchelfIgnoreMissingDeps or [ ]) ++ [ "libc.musl-x86_64.so.1" ];
  });
}
