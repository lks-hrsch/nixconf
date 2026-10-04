# Gatus uptime dashboard (OIDC via Authelia). One module, imported by the
# hosts that run an instance. The check lists live in hosts/*/stacks/_gatus-checks.nix
# (git-crypt) and are passed in via `gatus.endpoints`.
# Deimos hostnames only resolve to wg0 IPs via blocky on mercury, so every
# probe pins that resolver.
{ config, lib, ... }:
let
  top = config;
in
{
  # Per-host check lists (functions of the helpers below), contributed from
  # hosts/*/**/monitoring.nix so hostnames stay in git-crypt'd files.
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
      inherit (config.virtualisation.quadlet) networks;

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

      helpers = {
        inherit
          mk
          web
          dns
          tcp
          ok
          reachable
          client
          ;
      };

      settings = {
        # /metrics is registered before the security gate (unauthenticated), so
        # Traefik must not route it; Prometheus scrapes the container directly.
        metrics = true;

        storage = {
          type = "sqlite";
          path = "/data/data.db";
        };

        ui.title = "lukashirsch status";

        security.oidc = {
          issuer-url = "https://authelia.lukashirsch.de";
          redirect-url = "https://${cfg.fqdn}/authorization-code/callback";
          client-id = "gatus";
          client-secret = "\${GATUS_OIDC_CLIENT_SECRET}";
          scopes = [ "openid" ];
        };

        inherit (cfg) endpoints;
      };

      gatusConfig = pkgs.writeText "gatus.yaml" (builtins.toJSON settings);
    in
    {
      options.gatus = {
        endpoints = lib.mkOption {
          type = lib.types.listOf lib.types.attrs;
          default = lib.concatMap (checks: checks helpers) (lib.attrValues top.gatusChecks);
          description = "Gatus endpoints; defaults to every host's gatusChecks.";
        };
        helpers = lib.mkOption {
          type = lib.types.attrs;
          readOnly = true;
          default = helpers;
          description = "Endpoint constructors for check lists.";
        };
        fqdn = lib.mkOption {
          type = lib.types.str;
          description = "Public hostname of this instance, e.g. gatus.<host>.lukashirsch.de.";
        };
        dataDir = lib.mkOption {
          type = lib.types.path;
          description = "Host directory for the SQLite database.";
        };
        sopsFile = lib.mkOption {
          type = lib.types.path;
          description = "sops file holding gatus/oidc_client_secret.";
        };
        owner = lib.mkOption {
          type = lib.types.str;
          default = "root";
          description = "User name owning the secret and data dir.";
        };
        metricsPublish = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          example = "10.10.1.1:8081";
          description = "host:port to publish the container's 8080 on for off-host Prometheus scrapes.";
        };
        uid = lib.mkOption {
          type = lib.types.str;
          default = "0";
          description = "Numeric uid the container process runs as (must match owner).";
        };
      };

      config = {
        sops = {
          secrets."gatus/oidc-client-secret" = {
            inherit (cfg) sopsFile owner;
            key = "gatus/oidc_client_secret";
            mode = "0400";
            restartUnits = [ "gatus.service" ];
          };

          templates."gatus.env" = {
            inherit (cfg) owner;
            mode = "0400";
            restartUnits = [ "gatus.service" ];
            content = ''
              GATUS_OIDC_CLIENT_SECRET=${config.sops.placeholder."gatus/oidc-client-secret"}
            '';
          };
        };

        systemd.tmpfiles.rules = [
          "d ${dirOf cfg.dataDir} 0750 ${cfg.owner} ${cfg.owner} -"
          "d ${cfg.dataDir} 0750 ${cfg.owner} ${cfg.owner} -"
        ];

        virtualisation.quadlet.containers.gatus = {
          containerConfig = {
            image = "ghcr.io/twin/gatus:v5.37.0";
            autoUpdate = "registry";
            user = cfg.uid;
            environmentFiles = [ config.sops.templates."gatus.env".path ];
            networks = [ networks.proxy.ref ];
            networkAliases = [ "gatus" ];
            publishPorts = lib.optional (cfg.metricsPublish != null) "${cfg.metricsPublish}:8080/tcp";
            volumes = [
              "/etc/localtime:/etc/localtime:ro"
              "${gatusConfig}:/config/config.yaml:ro"
              "${cfg.dataDir}:/data"
            ];
            podmanArgs = [
              "--label=traefik.enable=true"
              "--label=traefik.http.routers.gatus.rule=Host(`${cfg.fqdn}`) && !Path(`/metrics`)"
              "--label=traefik.http.routers.gatus.entrypoints=websecure"
              "--label=traefik.http.routers.gatus.tls=true"
              "--label=traefik.http.routers.gatus.tls.certresolver=letsencrypt"
              "--label=traefik.http.services.gatus.loadbalancer.server.port=8080"
            ];
          };
          serviceConfig.Restart = "always";
        };
      };
    };
}
