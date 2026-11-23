# Gatus uptime dashboard (OIDC via Authelia) on the upstream services.gatus.
# One module, imported by the hosts that run an instance. The check lists are
# contributed per host via `gatusChecks`, each next to the service it checks
# (hosts/*/**/stacks/*.nix, which git-crypt covers), and the instance probes
# every host's checks, minus the `skip` pairs.
# Deimos hostnames only resolve to wg0 IPs via blocky on mercury, so every
# probe pins that resolver.
{ config, lib, ... }:
let
  top = config;
in
{
  # Per-host check lists (functions of the helpers below), contributed from
  # the stack files so the per-service hostnames stay in git-crypt'd files (only
  # the deimos domain and wg0 IP used by the helpers live here). Several files
  # may set the same host; their lists concatenate.
  options.gatusChecks = lib.mkOption {
    type = lib.types.attrsOf (lib.types.functionTo (lib.types.listOf lib.types.attrs));
    default = { };
  };

  config.flake.modules.nixos.gatus =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.gatus;
      # Runs as the shared service account; owns the data dir and the secret.
      owner = "apps";

      client = {
        dns-resolver = "udp://10.10.1.1:53";
        timeout = "10s";
      };

      mk = group: name: url: conditions: {
        inherit
          group
          name
          url
          client
          conditions
          ;
        interval = "60s";
      };

      # HTTPS via Traefik; also tracks cert expiry.
      web =
        group: name: url: extra:
        mk group name url (
          [
            "[CERTIFICATE_EXPIRATION] > 168h"
          ]
          ++ extra
        );

      ok = [ "[STATUS] == 200" ];
      reachable = [ "[STATUS] < 500" ]; # auth-gated or IP-restricted UIs
      tcp =
        group: name: addr:
        mk group name "tcp://${addr}" [ "[CONNECTED] == true" ];
      dns = group: name: server: query: {
        inherit group name;
        url = server;
        dns = {
          query-name = query;
          query-type = "A";
        };
        interval = "60s";
        conditions = [ "[DNS_RCODE] == NOERROR" ];
      };

      # Every deimos web UI is reached through Traefik (https://<name>.deimos…).
      deimosIp = "10.10.1.18";
      deimosDomain = "deimos.mars.lukashirsch.de";
      deimosWeb =
        group: name: path:
        web group name "https://${name}.${deimosDomain}${path}";
      deimosHttp = deimosWeb "deimos";

      helpers = {
        inherit
          mk
          web
          dns
          tcp
          ok
          reachable
          client
          deimosIp
          deimosWeb
          deimosHttp
          ;
      };

      # Hosts whose checks this instance does not run: deimos and phobos cannot
      # reach each other over wg0, and every probe resolves through the pinned
      # 10.10.1.1 resolver, which answers with wg0 addresses.
      skip = {
        deimos = [ "phobos" ];
        phobos = [ "deimos" ];
      };
      probed = lib.filter (h: !(lib.elem h (skip.${config.networking.hostName} or [ ]))) (
        lib.attrNames top.gatusChecks
      );
    in
    {
      options.gatus.sopsFile = lib.mkOption {
        type = lib.types.path;
        description = "sops file holding gatus/oidc_client_secret.";
      };

      config = {
        sops = {
          secrets."gatus/oidc-client-secret" = {
            inherit (cfg) sopsFile;
            inherit owner;
            key = "gatus/oidc_client_secret";
            mode = "0400";
            restartUnits = [ "gatus.service" ];
          };

          templates."gatus.env" = {
            inherit owner;
            mode = "0400";
            restartUnits = [ "gatus.service" ];
            content = ''
              GATUS_OIDC_CLIENT_SECRET=${config.sops.placeholder."gatus/oidc-client-secret"}
            '';
          };
        };

        services.gatus = {
          enable = true;
          package = pkgs.unstable.gatus;
          environmentFile = config.sops.templates."gatus.env".path;
          settings = {
            # /metrics is registered before the security gate (unauthenticated), so
            # Traefik must not route it; Alloy scrapes the service directly.
            metrics = true;

            storage = {
              type = "sqlite";
              # Fixed by the upstream unit's StateDirectory = "gatus", which creates it.
              path = "/var/lib/gatus/data.db";
            };

            web = {
              address = "127.0.0.1";
              port = 8081;
            };

            ui.title = "lukashirsch status";

            security.oidc = {
              issuer-url = "https://authelia.lukashirsch.de";
              redirect-url = "https://gatus.${config.networking.fqdn}/authorization-code/callback";
              client-id = "gatus";
              client-secret = "\${GATUS_OIDC_CLIENT_SECRET}";
              scopes = [ "openid" ];
            };

            endpoints = lib.concatMap (h: top.gatusChecks.${h} helpers) probed;
          };
        };

        systemd.services.gatus = {
          # At boot OIDC discovery via Traefik may not be up yet; keep retrying
          # instead of hitting the start limit.
          startLimitIntervalSec = 0;

          # No tmpfiles rules: StateDirectory creates /var/lib/gatus owned by User.
          serviceConfig = {
            DynamicUser = lib.mkForce false;
            User = lib.mkForce owner;
            Group = lib.mkForce owner;
            StateDirectoryMode = "0750";
            # As the container did; nixpkgs only restarts on failure.
            Restart = lib.mkForce "always";
            RestartSec = 5;
          };
        };

        # Pushed to the Prometheus on deimos; instance is set explicitly (host:port
        # otherwise), 30s as the former pull job.
        environment.etc."alloy/gatus.alloy".text = ''
          prometheus.scrape "gatus" {
            targets         = [{"__address__" = "127.0.0.1:8081", "instance" = "${config.networking.hostName}"}]
            job_name        = "gatus"
            scrape_interval = "30s"
            forward_to      = [prometheus.remote_write.deimos.receiver]
          }
        '';

        services.traefik.routes.gatus = {
          rule = "Host(`gatus.${config.networking.fqdn}`) && !Path(`/metrics`)"; # /metrics is unauthenticated
          url = "http://127.0.0.1:8081";
        };
      };
    };
}
