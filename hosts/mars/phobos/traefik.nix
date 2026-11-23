_: {
  # Traefik serves only the dashboard here.
  gatusChecks.phobos =
    { web, reachable, ... }:
    [
      (web "phobos" "traefik-phobos" "https://traefik.phobos.mars.lukashirsch.de" reachable)
    ];

  configurations.nixos."phobos".module =
    { config, ... }:
    {
      sops = {
        secrets = {
          "mars-phobos/traefik/cloudflare-dns-api-token" = {
            sopsFile = ../../../secrets/stacks-mars-phobos.yaml;
            key = "traefik/cloudflare-dns-api-token";
            owner = "root";
            group = "root";
            mode = "0400";
            restartUnits = [ "traefik.service" ];
          };
          "mars-phobos/traefik/email" = {
            sopsFile = ../../../secrets/stacks-mars-phobos.yaml;
            key = "traefik/email";
            owner = "root";
            group = "root";
            mode = "0400";
            restartUnits = [ "traefik.service" ];
          };
        };

        templates."mars-phobos/traefik.env" = {
          owner = "root";
          group = "root";
          mode = "0400";
          content = ''
            TZ="${config.time.timeZone}"
            CF_DNS_API_TOKEN=${config.sops.placeholder."mars-phobos/traefik/cloudflare-dns-api-token"}
            ACME_EMAIL=${config.sops.placeholder."mars-phobos/traefik/email"}
          '';
        };
      };

      services.traefik = {
        environmentFiles = [ config.sops.templates."mars-phobos/traefik.env".path ];
        staticConfigOptions = {
          certificatesResolvers.letsencrypt.acme.dnsChallenge.propagation = {
            # The router's DNS Override sends every LAN port-53 query to
            # Blocky, so lego's direct check against Cloudflare's
            # nameservers gets REFUSED and times out. Skip it and wait;
            # Let's Encrypt still validates from the internet.
            disableChecks = true;
            delayBeforeChecks = "60s";
          };
        };
        # Combined allowlist for UIs without their own login.
        dynamicConfigOptions.http.middlewares.internal-ipallowlist.ipAllowList.sourceRange = [
          "192.168.1.0/24" # local
          "10.10.1.0/24" # wg0
          "10.10.10.0/24" # wt0
        ];
      };
    };
}
