{ lib }:
config: name:
{
  address,
  peers,
  dns ? [ ],
  mtu ? null,
  autostart ? true,
}:
{
  inherit autostart address;
  peers = map (
    peer:
    {
      presharedKeyFile = config.sops.secrets."${name}/preshared-key".path;
    }
    // peer
  ) peers;
  privateKeyFile = config.sops.secrets."${name}/private-key".path;
}
// lib.optionalAttrs (dns != [ ]) { inherit dns; }
// lib.optionalAttrs (mtu != null) { inherit mtu; }
