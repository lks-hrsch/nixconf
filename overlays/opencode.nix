final: prev:
let
  manifest = builtins.fromJSON (builtins.readFile ./opencode-manifest.json);
  inherit (prev.stdenv.hostPlatform) system;
  entry = manifest.platforms.${system};
  baseUrl = "https://github.com/anomalyco/opencode/releases/download/v${manifest.version}";
  isZip = prev.lib.hasSuffix ".zip" entry.filename;
in
{
  opencode = prev.stdenvNoCC.mkDerivation {
    pname = "opencode";
    inherit (manifest) version;
    src = prev.fetchurl {
      url = "${baseUrl}/${entry.filename}";
      inherit (entry) sha256;
    };
    nativeBuildInputs = [ prev.makeBinaryWrapper ]
      ++ prev.lib.optionals isZip [ prev.unzip ];
    sourceRoot = ".";
    installPhase = ''
      runHook preInstall
      install -Dm755 opencode $out/bin/opencode
      wrapProgram $out/bin/opencode \
        --prefix PATH : ${prev.lib.makeBinPath (
          [ prev.ripgrep ]
          ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [ prev.sysctl ]
        )}
      runHook postInstall
    '';
    inherit (prev.opencode) meta;
  };
}
