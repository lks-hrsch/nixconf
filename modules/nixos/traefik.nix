# Native Traefik, a thin extension of upstream services.traefik (the server
# role: mercury, deimos, phobos). Hosts import flake.modules.nixos.traefik for
# the shared static defaults and the services.traefik.routes option; each
# feature file declares its routes next to its container, with the pinned proxy
# IP in a local let binding. Dynamic config changes restart Traefik (upstream
# behavior).
_: {
  flake.modules.nixos.traefik =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.services.traefik;
      inherit (lib) mkOption types;

      routeToDynamic = name: r: [
        {
          http.routers.${name} = {
            rule =
              if r.rule != null then r.rule else lib.concatMapStringsSep " || " (h: "Host(`${h}`)") r.hosts;
            entryPoints = [ "websecure" ];
            service = if r.service != null then r.service else name;
            tls.certResolver = "letsencrypt";
          }
          // lib.optionalAttrs (r.middlewares != [ ]) { inherit (r) middlewares; }
          // lib.optionalAttrs (r.priority != null) { inherit (r) priority; };
        }
        (lib.optionalAttrs (r.service == null) {
          http.services.${name}.loadBalancer = {
            servers = [ { inherit (r) url; } ];
          }
          // lib.optionalAttrs (r.serversTransport != null) { inherit (r) serversTransport; };
        })
      ];

      route = types.submodule {
        options = {
          hosts = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Host() matchers joined with ||, in this order (the rule length is the default priority).";
          };
          rule = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Verbatim rule; overrides hosts.";
          };
          url = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Backend URL, e.g. http://172.30.0.142:8096 or h2c://172.30.0.137:80. Generates a service named after the route.";
          };
          service = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Existing service (api@internal or one written in dynamicConfigOptions); no service is generated.";
          };
          middlewares = mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          priority = mkOption {
            type = types.nullOr types.int;
            default = null;
          };
          serversTransport = mkOption {
            type = types.nullOr types.str;
            default = null;
          };
        };
      };
    in
    {
      options.services.traefik.routes = mkOption {
        type = types.attrsOf route;
        default = { };
        description = "One HTTP router (websecure, letsencrypt) plus its service per entry.";
      };

      config = {
        services.traefik = {
          enable = true;
          package = pkgs.unstable.traefik;
          # The upstream module adds providers.file for the dynamic config itself.
          staticConfigOptions = {
            log.level = "INFO";
            accessLog = { };
            api.dashboard = true;
            ping = { };
            metrics.prometheus = {
              entryPoint = "metrics";
              addEntryPointsLabels = true;
              addRoutersLabels = true;
              addServicesLabels = true;
            };
            entryPoints = {
              # Declared, so api/ping do not open Traefik's default :8080 on every interface.
              traefik.address = "127.0.0.1:8180";
              web = {
                address = ":80";
                http.redirections.entryPoint = {
                  to = "websecure";
                  scheme = "https";
                };
              };
              websecure.address = ":443";
              metrics.address = "127.0.0.1:8082";
            };
            certificatesResolvers.letsencrypt.acme = {
              email = "\${ACME_EMAIL}"; # filled by the module's envsubst ExecStartPre
              storage = "/var/lib/traefik/acme.json";
              dnsChallenge = {
                provider = "cloudflare";
                resolvers = [
                  "1.1.1.1:53"
                  "8.8.8.8:53"
                ];
              };
            };
          };
          dynamicConfigOptions = lib.mkMerge (lib.concatLists (lib.mapAttrsToList routeToDynamic cfg.routes));
        };

        # Pushed to the Prometheus on deimos; instance is set explicitly (host:port
        # otherwise), 30s as the former pull job.
        environment.etc."alloy/traefik.alloy".text = ''
          prometheus.scrape "traefik" {
            targets         = [{"__address__" = "127.0.0.1:8082", "instance" = "${config.networking.hostName}"}]
            job_name        = "traefik"
            scrape_interval = "30s"
            forward_to      = [prometheus.remote_write.deimos.receiver]
          }
        '';

        systemd.services.traefik = {
          # A crash loop must never leave the edge down until the next day.
          startLimitIntervalSec = lib.mkForce 0;
          serviceConfig = {
            Restart = lib.mkForce "always";
            RestartSec = 5;
            # Counts threads of the traefik user; Go needs more than the module's 64.
            LimitNPROC = lib.mkForce 4096;
          };
        };

        assertions = lib.mapAttrsToList (n: r: {
          assertion =
            lib.count (x: x != null) [
              r.url
              r.service
            ] == 1
            && (r.rule != null || r.hosts != [ ]);
          message = "services.traefik.routes.${n}: set exactly one of url, service; set hosts or rule.";
        }) cfg.routes;
      };
    };
}
