_: {
  gatusChecks.mercury =
    { web, reachable, ... }:
    [
      (web "mercury" "traefik-mercury" "https://traefik.mercury.lukashirsch.de/" reachable)
    ];

  configurations.nixos."mercury".module =
    { config, ... }:
    {
      sops = {
        secrets = {
          "mercury/traefik/cloudflare-dns-api-token" = {
            sopsFile = ../../secrets/stacks-mercury.yaml;
            key = "traefik/cloudflare-dns-api-token";
            owner = "root";
            group = "root";
            mode = "0400";
            restartUnits = [ "traefik.service" ];
          };
          "mercury/traefik/email" = {
            sopsFile = ../../secrets/stacks-mercury.yaml;
            key = "traefik/email";
            owner = "root";
            group = "root";
            mode = "0400";
            restartUnits = [ "traefik.service" ];
          };
        };

        templates."mercury/traefik.env" = {
          owner = "root";
          group = "root";
          mode = "0400";
          content = ''
            TZ="${config.time.timeZone}"
            CF_DNS_API_TOKEN=${config.sops.placeholder."mercury/traefik/cloudflare-dns-api-token"}
            ACME_EMAIL=${config.sops.placeholder."mercury/traefik/email"}
          '';
        };
      };

      services.traefik = {
        environmentFiles = [ config.sops.templates."mercury/traefik.env".path ];
        staticConfigOptions = {
          entryPoints = {
            websecure.transport.respondingTimeouts = {
              readTimeout = "0s";
              writeTimeout = "0s";
              idleTimeout = "60s";
            };
            mqtts = {
              address = ":8883";
              transport.respondingTimeouts = {
                readTimeout = "0s";
                writeTimeout = "0s";
                idleTimeout = "60s";
              };
            };
          };
          serversTransport.forwardingTimeouts = {
            responseHeaderTimeout = "0s";
            idleConnTimeout = "0s";
          };
          certificatesResolvers.letsencrypt.acme.dnsChallenge.propagation.delayBeforeChecks = "20s";
        };
        dynamicConfigOptions = {
          # Admin UIs: wg0, NetBird (wt0) and the proxy bridge.
          http.middlewares.internal-ipallowlist.ipAllowList.sourceRange = [
            "10.10.1.0/24" # wg0
            "10.10.10.0/24" # wt0
            "172.30.0.0/24" # proxy bridge
          ];
          tls.options.default.minVersion = "VersionTLS12";
        };
      };
    };
}
