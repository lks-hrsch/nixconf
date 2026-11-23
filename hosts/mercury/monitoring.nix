_: {
  # Mercury's own Gatus check; the other services' checks sit next to their
  # stacks. The Gatus module itself is modules/nixos/gatus.nix.
  gatusChecks.mercury =
    { web, ok, ... }:
    [
      (web "meta" "gatus-mercury" "https://gatus.mercury.lukashirsch.de/health" ok)
    ];

  configurations.nixos."mercury".module =
    { pkgs, ... }:
    let
      # Host /etc/hosts maps these to 127.0.0.1 (configuration.nix), and Go's
      # resolver reads it before Gatus' dns-resolver. Natively 127.0.0.1:443 is
      # Traefik, so only open-webui must point elsewhere (deimos over wg0).
      # Authelia is also needed at startup (OIDC discovery). The file replaces
      # /etc/hosts for Gatus only (localhost is listed here), so it lists every
      # name Gatus needs.
      gatusHosts = pkgs.writeText "gatus-hosts" ''
        127.0.0.1 localhost
        ::1 localhost
        10.10.1.18 open-webui.deimos.mars.lukashirsch.de
        127.0.0.1 netbird.lukashirsch.de authelia.lukashirsch.de
      '';
    in
    {
      gatus.sopsFile = ../../secrets/stacks-mercury.yaml;

      systemd.services.gatus = {
        # OIDC discovery at startup goes through local Traefik (127.0.0.1:443);
        # Gatus panics if it is still down, e.g. when a switch restarts both.
        after = [ "traefik.service" ];
        serviceConfig = {
          # Replaces /etc/hosts for Gatus only, as the container's addHosts did.
          BindReadOnlyPaths = [ "${gatusHosts}:/etc/hosts" ];
          # Wait up to 30 s for the port; never fails, Restart covers the rest.
          ExecStartPre = "${pkgs.bash}/bin/bash -c 'for _ in {1..30}; do (: </dev/tcp/127.0.0.1/443) 2>/dev/null && exit 0; sleep 1; done; exit 0'";
        };
      };

      # Public DNS sends *.deimos.mars to mercury (netbird proxy), which has no
      # prometheus or loki route; pin Alloy's push targets to deimos over wg0.
      networking.hosts."10.10.1.18" = [
        "prometheus.deimos.mars.lukashirsch.de"
        "loki.deimos.mars.lukashirsch.de"
      ];
    };
}
