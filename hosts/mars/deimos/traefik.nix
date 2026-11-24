_: {
  gatusChecks.deimos =
    { deimosHttp, ok, ... }:
    [
      # ok, not reachable: a 403 from internal-ipallowlist must fail the check.
      (deimosHttp "traefik" "/dashboard/" ok)
    ];

  configurations.nixos."deimos".module =
    { config, ... }:
    {
      sops = {
        secrets = {
          "mars-deimos/traefik/cloudflare-dns-api-token" = {
            sopsFile = ../../../secrets/stacks-mars-deimos.yaml;
            key = "traefik/cloudflare-dns-api-token";
            owner = "root";
            group = "root";
            mode = "0400";
            restartUnits = [ "traefik.service" ];
          };
          "mars-deimos/traefik/email" = {
            sopsFile = ../../../secrets/stacks-mars-deimos.yaml;
            key = "traefik/email";
            owner = "root";
            group = "root";
            mode = "0400";
            restartUnits = [ "traefik.service" ];
          };
        };

        templates."mars-deimos/traefik.env" = {
          owner = "root";
          group = "root";
          mode = "0400";
          content = ''
            TZ="${config.time.timeZone}"
            CF_DNS_API_TOKEN=${config.sops.placeholder."mars-deimos/traefik/cloudflare-dns-api-token"}
            ACME_EMAIL=${config.sops.placeholder."mars-deimos/traefik/email"}
          '';
        };
      };

      services.traefik = {
        environmentFiles = [ config.sops.templates."mars-deimos/traefik.env".path ];
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
          "172.30.0.0/24" # proxy bridge
        ];
      };
    };
}
