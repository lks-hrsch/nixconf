_: {
  # Imported by every NixOS host: enables upstream services.alloy and writes the
  # base files under /etc/alloy. Other modules add their own *.alloy files there
  # and forward to prometheus.remote_write.deimos.receiver or
  # loki.write.deimos.receiver. Component names must be unique across files.
  flake.modules.nixos.alloy =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.services.alloy;
      inherit (config.networking) fqdn;

      # Shared by every host importing this module: same Loki basic-auth
      # secrets, same sops file, one canonical path regardless of which
      # host's directory depth it used to be interpolated from.
      monitoringSecret =
        extra:
        {
          sopsFile = ../../secrets/secrets-mars-deimos.yaml;
          owner = "apps";
          group = "apps";
          mode = "0400";
          restartUnits = [ "alloy.service" ];
        }
        // extra;

      # Continuation lines of a multi-line value spliced into an indented block.
      indent = lib.replaceStrings [ "\n" ] [ "\n  " ];

      containerRule =
        if cfg.containerLogs then
          ''
            // conmon writes CONTAINER_NAME to the journal for every container
            // log line (journald log driver); Alloy exposes it as
            // __journal_<lowercased field name>.
            rule {
              source_labels = ["__journal_container_name"]
              target_label  = "container"
            }''
        else
          ''
            // Only servers ship container logs (services.alloy.containerLogs).
            rule {
              source_labels = ["__journal_container_name"]
              regex         = ".+"
              action        = "drop"
            }'';

      journalAlloy = ''
        // Systemd journal (all units on the host).
        loki.source.journal "host" {
          max_age       = "12h"
          relabel_rules = loki.relabel.journal_units.rules
          forward_to    = [loki.process.host_journal.receiver]
          labels        = {
            host = "${fqdn}",
            job  = "systemd",
          }
        }

        // Rules-only relabel block: forward_to is empty by design;
        // loki.source.journal consumes the rules directly. __journal_*
        // fields only exist at this relabeling stage, so the container-line
        // handling must happen here rather than in loki.process below.
        loki.relabel "journal_units" {
          forward_to = []
          rule {
            source_labels = ["__journal__systemd_unit"]
            target_label  = "unit"
          }
          ${indent containerRule}
        }

        // Drop Alloy's own output to avoid feedback loops.
        loki.process "host_journal" {
          forward_to = [loki.write.deimos.receiver]
          stage.match {
            selector = "{unit=\"alloy.service\"}"
            action   = "drop"
          }
        }
      '';

      nodeAlloy = ''
        // Host metrics (pushed to Prometheus on deimos).
        prometheus.exporter.unix "host" {
          disable_collectors = [${lib.concatMapStringsSep ", " (c: ''"${c}"'') cfg.disabledCollectors}]
        }

        prometheus.scrape "node" {
          targets         = prometheus.exporter.unix.host.targets
          job_name        = "node"
          scrape_interval = "30s"
          forward_to      = [prometheus.relabel.host.receiver]
        }

        // The unix exporter's targets carry their own job="integrations/unix",
        // which overrides job_name above, so job is set explicitly here.
        prometheus.relabel "host" {
          forward_to = [prometheus.remote_write.deimos.receiver]
          rule {
            target_label = "job"
            replacement  = "node"
          }
          rule {
            target_label = "instance"
            replacement  = "${fqdn}"
          }
        }
      '';

      writeAlloy = ''
        // Sinks: Loki and Prometheus on deimos, shared basic auth.
        loki.write "deimos" {
          endpoint {
            url = "https://loki.deimos.mars.lukashirsch.de/loki/api/v1/push"
            basic_auth {
              username = sys.env("ALLOY_LOKI_USER")
              password = sys.env("ALLOY_LOKI_PASS")
            }
          }
        }

        prometheus.remote_write "deimos" {
          endpoint {
            url = "https://prometheus.deimos.mars.lukashirsch.de/api/v1/write"
            basic_auth {
              username = sys.env("ALLOY_LOKI_USER")
              password = sys.env("ALLOY_LOKI_PASS")
            }
          }
        }
      '';
    in
    {
      options.services.alloy = {
        disabledCollectors = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [
            "hwmon"
            "zfs"
          ];
          description = "node_exporter collectors to disable (e.g. host-wide ones inside an LXC).";
        };

        containerLogs = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Ship container logs from the journal with a `container` label.
            When false, journal lines carrying a container name are dropped.
          '';
        };
      };

      config = {
        sops = {
          secrets = {
            "monitoring/loki_basic_auth_user" = monitoringSecret {
              key = "monitoring/loki/basic_auth_user";
            };
            "monitoring/loki_basic_auth_pass" = monitoringSecret {
              key = "monitoring/loki/basic_auth_password";
            };
          };

          templates."alloy/loki-auth.env" = {
            owner = "apps";
            group = "apps";
            mode = "0400";
            content = ''
              ALLOY_LOKI_USER=${config.sops.placeholder."monitoring/loki_basic_auth_user"}
              ALLOY_LOKI_PASS=${config.sops.placeholder."monitoring/loki_basic_auth_pass"}
            '';
          };
        };

        services.alloy = {
          enable = true;
          environmentFile = config.sops.templates."alloy/loki-auth.env".path;
        };

        # configPath defaults to /etc/alloy and auto-derives reloadTriggers
        # (SIGHUP) from every *.alloy file placed here; a hand-rolled
        # restartTriggers would instead force a full restart on every change.
        environment.etc = {
          "alloy/journal.alloy".text = journalAlloy;
          "alloy/node.alloy".text = nodeAlloy;
          "alloy/write.alloy".text = writeAlloy;
        };
      };
    };
}
