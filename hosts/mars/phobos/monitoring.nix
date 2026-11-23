_: {
  # Phobos's own Gatus check. The Gatus module itself is modules/nixos/gatus.nix.
  gatusChecks.phobos =
    { web, reachable, ... }:
    [
      (web "meta" "gatus-phobos" "https://gatus.phobos.mars.lukashirsch.de" reachable)
    ];

  configurations.nixos."phobos".module = {
    gatus.sopsFile = ../../../secrets/stacks-mars-phobos.yaml;
  };
}
