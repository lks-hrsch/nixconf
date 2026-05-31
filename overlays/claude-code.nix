final: prev:
let
  manifest = builtins.fromJSON (builtins.readFile ./claude-code-manifest.json);
  baseUrl = "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases";
  platformKey = "${prev.stdenv.hostPlatform.node.platform}-${prev.stdenv.hostPlatform.node.arch}";
  entry = manifest.platforms.${platformKey};
in
{
  claude-code = prev.claude-code.overrideAttrs (_old: {
    inherit (manifest) version;
    src = prev.fetchurl {
      url = "${baseUrl}/${manifest.version}/${platformKey}/claude";
      sha256 = entry.checksum;
    };
  });
}
