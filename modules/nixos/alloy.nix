{ config, lib, ... }:
{
  flake.modules.nixos.alloy =
    { config, lib, pkgs, ... }:
    let
      cfg = config.my.alloy;

      alloyConfig = ''
        // ---------- Sources ----------

        // Systemd journal (all units on the host).
        loki.source.journal "host" {
          max_age       = "12h"
          relabel_rules = loki.relabel.journal_units.rules
          forward_to    = [loki.process.host_journal.receiver]
          labels        = {
            host = "${cfg.hostLabel}",
            job  = "systemd",
          }
        }

        // Rules-only relabel block: forward_to is empty by design;
        // loki.source.journal consumes the rules directly.
        loki.relabel "journal_units" {
          forward_to = []
          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }
        }

        // Drop journal entries that came from Podman containers (they are
        // collected with richer metadata via the Podman socket below) and
        // drop Alloy's own output to avoid feedback loops.
        loki.process "host_journal" {
          forward_to = [loki.write.alloy.receiver]
          stage.match {
            selector = "{__journal__podman_container_id=~\".+\"}"
            action   = "drop"
          }
          stage.match {
            selector = "{unit=\"alloy.service\"}"
            action   = "drop"
          }
        }
      '' + lib.optionalString cfg.collectPodman ''

        // Podman containers via Docker-compatible socket. Provides richer
        // labels (container, image) than the journal.
        discovery.docker "podman" {
          host             = "unix:///run/podman/podman.sock"
          refresh_interval = "30s"
        }

        discovery.relabel "podman" {
          targets = discovery.docker.podman.targets
          rule {
            source_labels = ["__meta_docker_container_name"]
            regex         = "/(.+)"
            target_label  = "container"
          }
          rule {
            target_label = "host"
            replacement  = "${cfg.hostLabel}"
          }
          rule {
            target_label = "job"
            replacement  = "podman"
          }
        }

        loki.source.docker "podman" {
          host          = "unix:///run/podman/podman.sock"
          targets       = discovery.relabel.podman.output
          forward_to    = [loki.process.podman.receiver]
          relabel_rules = discovery.relabel.podman.rules
        }

        loki.process "podman" {
          forward_to = [loki.write.alloy.receiver]
          stage.match {
            selector = "{container=\"alloy\"}"
            action   = "drop"
          }
        }
      '' + ''

        // ---------- Sink ----------

        loki.write "alloy" {
          endpoint {
            url = "${cfg.lokiEndpoint}"
            basic_auth {
              username = sys.env("ALLOY_LOKI_USER")
              password = sys.env("ALLOY_LOKI_PASS")
            }
          }
        }
      '';
    in
    {
      options.my.alloy = {
        enable = lib.mkEnableOption "Grafana Alloy log collector";

        hostLabel = lib.mkOption {
          type = lib.types.str;
          description = "Value of the `host` Loki label, typically the FQDN.";
          example = "deimos.mars.lukashirsch.de";
        };

        lokiEndpoint = lib.mkOption {
          type = lib.types.str;
          default = "https://loki.deimos.mars.lukashirsch.de/loki/api/v1/push";
          description = "Loki push URL (HTTPS, basic auth).";
        };

        basicAuthEnvFile = lib.mkOption {
          type = lib.types.path;
          description = ''
            Path to an env file (typically a SOPS template) that defines
            ALLOY_LOKI_USER and ALLOY_LOKI_PASS. Loaded by systemd via
            EnvironmentFile and read by Alloy via sys.env().
          '';
        };

        collectPodman = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = ''
            When true, Alloy also reads the Podman socket and is added to
            the `podman` group. Disable on hosts without Podman.
          '';
        };
      };

      config = lib.mkIf cfg.enable {
        services.alloy = {
          enable = true;
          extraFlags = [ "--stability.level=public-preview" ];
        };

        environment.etc."alloy/config.alloy".text = alloyConfig;

        systemd.services.alloy.serviceConfig.EnvironmentFile =
          cfg.basicAuthEnvFile;

        systemd.services.alloy.serviceConfig.SupplementaryGroups =
          lib.mkIf cfg.collectPodman [ "podman" ];

        systemd.services.alloy.restartTriggers = [ alloyConfig ];
      };
    };
}
