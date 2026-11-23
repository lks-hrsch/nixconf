# Server role (mercury, deimos, phobos): the native Traefik edge, Gatus,
# container logs and Podman metrics. Alloy itself comes with `base`; the
# host-specific parts (sops secrets, ACME seed, middlewares) stay in each
# host's traefik.nix and monitoring.nix; the proxy network in stacks/default.nix.
{ config, ... }:
let
  top = config;
in
{
  flake.modules.nixos.server =
    { config, lib, ... }:
    {
      imports = with top.flake.modules.nixos; [
        traefik
        gatus
      ];

      services.alloy.containerLogs = true;

      networking.firewall.allowedTCPPorts = [
        80 # Traefik HTTP / ACME redirect
        443 # Traefik HTTPS
      ];

      # The middleware is defined per host (admin networks differ).
      services.traefik.routes.traefik-dashboard = {
        hosts = [ "traefik.${config.networking.fqdn}" ];
        service = "api@internal";
        middlewares = [ "internal-ipallowlist" ];
      };

      # Root, so cAdvisor can use the rootful Podman socket and cgroups and the
      # journal includes user journals (rootless containers).
      systemd.services.alloy.serviceConfig = {
        DynamicUser = lib.mkForce false;
        User = lib.mkForce "root";
      };

      environment.etc."alloy/cadvisor.alloy".text = ''
        // Container metrics from the rootful Podman socket (Docker-compatible API).
        prometheus.exporter.cadvisor "podman" {
          docker_host = "unix:///run/podman/podman.sock"
        }

        prometheus.scrape "cadvisor" {
          targets         = prometheus.exporter.cadvisor.podman.targets
          job_name        = "cadvisor"
          scrape_interval = "30s"
          forward_to      = [prometheus.relabel.cadvisor.receiver]
        }

        // The exporter's targets carry their own job="integrations/cadvisor",
        // which overrides job_name above, so job is set explicitly here.
        prometheus.relabel "cadvisor" {
          forward_to = [prometheus.remote_write.deimos.receiver]
          rule {
            target_label = "job"
            replacement  = "cadvisor"
          }
          rule {
            target_label = "instance"
            replacement  = "${config.networking.hostName}"
          }
        }
      '';
    };
}
