_: {
  # Deimos checks of the services defined in this file; the others sit next to
  # their stacks. The Gatus module itself is modules/nixos/gatus.nix.
  gatusChecks.deimos =
    {
      web,
      deimosHttp,
      ok,
      ...
    }:
    [
      (deimosHttp "grafana" "/api/health" [ "[BODY].database == ok" ])
      (deimosHttp "loki" "/ready" [ "[STATUS] == any(200, 401)" ]) # basic-auth gated
      (web "meta" "gatus-deimos" "https://gatus.deimos.mars.lukashirsch.de/health" ok)
    ];

  configurations.nixos."deimos".module =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      # Pinned on the proxy bridge in stacks/scrutiny.nix.
      influxdbIp = "172.30.0.101";
      # Prometheus pull jobs, scraped by Alloy and pushed to the local Prometheus
      # (services.prometheus.scrapeConfigs stays empty). Targets are loopback
      # (native services) or pinned proxy IPs. Host metrics arrive the same way
      # from modules/nixos/alloy.nix. Every target sets `instance` explicitly, or
      # Alloy would label it host:port; 30s is the former global scrape_interval.
      scrape =
        {
          job,
          instance,
          address,
          interval ? "30s",
        }:
        ''
          prometheus.scrape "${lib.replaceStrings [ "-" ] [ "_" ] job}" {
            targets         = [{"__address__" = "${address}", "instance" = "${instance}"}]
            job_name        = "${job}"
            scrape_interval = "${interval}"
            forward_to      = [prometheus.remote_write.deimos.receiver]
          }
        '';

      # Community dashboards pinned by hash; the datasource input is bound to the
      # provisioned uid `prometheus`.
      communityDashboard =
        {
          id,
          rev,
          hash,
          subs ? { },
        }:
        pkgs.runCommand "grafana-dashboard-${toString id}.json"
          {
            src = pkgs.fetchurl {
              name = "grafana-dashboard-${toString id}-r${toString rev}.json";
              url = "https://grafana.com/api/dashboards/${toString id}/revisions/${toString rev}/download";
              inherit hash;
            };
          }
          ''
            substitute $src $out ${
              lib.concatStringsSep " " (
                lib.mapAttrsToList (k: v: "--replace-fail ${lib.escapeShellArg k} ${lib.escapeShellArg v}") subs
              )
            }
          '';

      nodeDashboard = communityDashboard {
        id = 1860;
        rev = 45;
        hash = "sha256-GExrdAnzBtp1Ul13cvcZRbEM6iOtFrXXjEaY6g6lGYY=";
        subs."\${ds_prometheus}" = "prometheus";
      };
      traefikDashboard = communityDashboard {
        id = 17346;
        rev = 9;
        hash = "sha256-OtMp0nNxIPMvZ6qwg/JFtVTqXE7IN4/u5xlu9ruffak=";
        subs."\${DS_PROMETHEUS}" = "prometheus";
      };
      blockyDashboard = communityDashboard {
        id = 13768;
        rev = 8;
        hash = "sha256-gwPOcnVC7BXTlhOCRvENAXZfGdQGVCPEUrLCl4ASkVE=";
        subs = {
          "\${DS_PROMETHEUS}" = "prometheus";
          "\${VAR_BLOCKY_URL}" = "http://10.10.1.18:4000";
        };
      };

      gatusDashboard =
        let
          ds = {
            type = "prometheus";
            uid = "prometheus";
          };
          sel = ''{instance=~"$instance",group=~"$group"}'';
          panel =
            id: type: title: pos: extra:
            {
              inherit
                id
                type
                title
                ;
              datasource = ds;
              gridPos = pos;
            }
            // extra;
          target = expr: legend: {
            inherit expr;
            legendFormat = legend;
            datasource = ds;
          };
          var = name: query: {
            inherit name query;
            type = "query";
            datasource = ds;
            definition = query;
            refresh = 2;
            includeAll = true;
            multi = true;
            current = {
              text = "All";
              value = "$__all";
            };
          };
        in
        pkgs.writeText "gatus-dashboard.json" (
          builtins.toJSON {
            uid = "gatus";
            title = "Gatus";
            tags = [ "gatus" ];
            schemaVersion = 39;
            time = {
              from = "now-24h";
              to = "now";
            };
            refresh = "1m";
            templating.list = [
              (var "instance" "label_values(gatus_results_endpoint_success, instance)")
              (var "group" "label_values(gatus_results_endpoint_success, group)")
            ];
            panels = [
              (panel 1 "stat" "Endpoints down"
                {
                  h = 4;
                  w = 6;
                  x = 0;
                  y = 0;
                }
                {
                  targets = [
                    (target "count(gatus_results_endpoint_success${sel} == 0) or vector(0)" "")
                  ];
                  fieldConfig.defaults.thresholds.steps = [
                    {
                      color = "green";
                      value = null;
                    }
                    {
                      color = "red";
                      value = 1;
                    }
                  ];
                }
              )
              (panel 2 "stat" "Endpoints monitored"
                {
                  h = 4;
                  w = 6;
                  x = 6;
                  y = 0;
                }
                {
                  targets = [ (target "count(gatus_results_endpoint_success${sel})" "") ];
                }
              )
              (panel 3 "bargauge" "Certificate expiry (days)"
                {
                  h = 8;
                  w = 12;
                  x = 12;
                  y = 0;
                }
                {
                  targets = [
                    (target "min by (name) (gatus_results_certificate_expiration_seconds${sel}) / 86400" "{{name}}")
                  ];
                  fieldConfig.defaults = {
                    unit = "d";
                    min = 0;
                    max = 90;
                    thresholds.steps = [
                      {
                        color = "red";
                        value = null;
                      }
                      {
                        color = "orange";
                        value = 7;
                      }
                      {
                        color = "green";
                        value = 14;
                      }
                    ];
                  };
                  options = {
                    orientation = "horizontal";
                    displayMode = "basic";
                  };
                }
              )
              (panel 4 "state-timeline" "Endpoint state"
                {
                  h = 8;
                  w = 12;
                  x = 0;
                  y = 4;
                }
                {
                  targets = [
                    (target "max by (group, name) (gatus_results_endpoint_success${sel})" "{{group}}/{{name}}")
                  ];
                  fieldConfig.defaults = {
                    mappings = [
                      {
                        type = "value";
                        options = {
                          "0" = {
                            text = "down";
                            color = "red";
                          };
                          "1" = {
                            text = "up";
                            color = "green";
                          };
                        };
                      }
                    ];
                  };
                }
              )
              (panel 5 "timeseries" "Response time"
                {
                  h = 9;
                  w = 24;
                  x = 0;
                  y = 12;
                }
                {
                  targets = [
                    (target "max by (group, name) (gatus_results_duration_seconds${sel})" "{{group}}/{{name}}")
                  ];
                  fieldConfig.defaults.unit = "s";
                }
              )
            ];
          }
        );
      monitoringSecret =
        extra:
        {
          owner = "apps";
          group = "apps";
          mode = "0400";
        }
        // extra;
    in
    {
      gatus.sopsFile = ../../../secrets/stacks-mars-deimos.yaml;

      sops.secrets = {
        "monitoring/loki_basic_auth_user" = monitoringSecret {
          sopsFile = ../../../secrets/secrets-mars-deimos.yaml;
          key = "monitoring/loki/basic_auth_user";
          restartUnits = [ "alloy.service" ];
        };
        "monitoring/loki_basic_auth_pass" = monitoringSecret {
          sopsFile = ../../../secrets/secrets-mars-deimos.yaml;
          key = "monitoring/loki/basic_auth_password";
          restartUnits = [ "alloy.service" ];
        };
        "monitoring/loki_basic_auth_htpasswd" = monitoringSecret {
          sopsFile = ../../../secrets/secrets-mars-deimos.yaml;
          key = "monitoring/loki/basic_auth_htpasswd";
          restartUnits = [ "traefik.service" ];
        };
        "grafana/datasources/influxdb/scrutiny/org" = monitoringSecret {
          sopsFile = ../../../secrets/stacks-mars-deimos.yaml;
          key = "grafana/datasources/influxdb/scrutiny/org";
          restartUnits = [ "grafana.service" ];
        };
        "grafana/datasources/influxdb/scrutiny/bucket" = monitoringSecret {
          sopsFile = ../../../secrets/stacks-mars-deimos.yaml;
          key = "grafana/datasources/influxdb/scrutiny/bucket";
          restartUnits = [ "grafana.service" ];
        };
        "grafana/datasources/influxdb/scrutiny/token" = monitoringSecret {
          sopsFile = ../../../secrets/stacks-mars-deimos.yaml;
          key = "grafana/datasources/influxdb/scrutiny/token";
          restartUnits = [ "grafana.service" ];
        };
        "grafana/secret_key" = monitoringSecret {
          sopsFile = ../../../secrets/stacks-mars-deimos.yaml;
          key = "grafana/secret_key";
          restartUnits = [ "grafana.service" ];
        };
      };

      sops.templates = {
        "alloy/loki-auth.env" = {
          owner = "apps";
          group = "apps";
          mode = "0400";
          content = ''
            ALLOY_LOKI_USER=${config.sops.placeholder."monitoring/loki_basic_auth_user"}
            ALLOY_LOKI_PASS=${config.sops.placeholder."monitoring/loki_basic_auth_pass"}
          '';
        };

        # Read by native Traefik through the loki-auth middleware's usersFile.
        "traefik/loki-users" = {
          owner = "traefik";
          group = "traefik";
          mode = "0440";
          restartUnits = [ "traefik.service" ];
          content = ''
            ${config.sops.placeholder."monitoring/loki_basic_auth_htpasswd"}
          '';
        };
      };

      # Deimos resolves via public DNS too (-> mercury); pin Alloy's remote-write
      # target to this host.
      networking.hosts."10.10.1.18" = [ "prometheus.deimos.mars.lukashirsch.de" ];

      networking.firewall = {
        allowedTCPPorts = [ 9109 ]; # Graphite from mars (native exporter)
        # Syslog has no auth: on the LAN, accept it from mars only. wg0 and nb-wt0 stay trusted.
        extraInputRules = "ip saddr 192.168.1.16 tcp dport 5140 accept";
      };

      # Alloy merges every *.alloy file in /etc/alloy, so this can use
      # loki.write.deimos from modules/nixos/alloy.nix.
      environment.etc."alloy/mars-syslog.alloy".text = ''
        loki.relabel "mars_syslog" {
          forward_to = []
          rule {
            source_labels = ["__syslog_message_app_name"]
            target_label  = "app"
          }
          rule {
            source_labels = ["__syslog_message_severity"]
            target_label  = "severity"
          }
        }

        loki.source.syslog "mars" {
          listener {
            address  = "0.0.0.0:5140"
            protocol = "tcp"
            labels   = {
              host = "mars",
              job  = "syslog",
            }
          }
          relabel_rules = loki.relabel.mars_syslog.rules
          forward_to    = [loki.write.deimos.receiver]
        }
      '';

      environment.etc."alloy/monitoring.alloy".text = lib.concatMapStringsSep "\n" scrape [
        {
          job = "prometheus";
          instance = "deimos";
          address = "127.0.0.1:9090";
        }
        {
          job = "grafana";
          instance = "deimos";
          address = "127.0.0.1:3000";
        }
        {
          job = "loki";
          instance = "deimos";
          address = "127.0.0.1:3100";
        }
        {
          job = "graphite-exporter";
          instance = "mars";
          address = "192.168.1.13:9108";
          # Matches netdata's update_every, so short disk bursts on mars are not skipped.
          interval = "10s";
        }
      ];

      systemd.tmpfiles.rules = [
        "d /mnt/nvme-pool/apps/loki 0750 568 568 -"
        "d /mnt/nvme-pool/apps/loki/data 0750 568 568 -"
        "d /mnt/nvme-pool/apps/grafana 0755 568 568 -"
        "d /mnt/nvme-pool/apps/prometheus 0750 568 568 -"
        "d /mnt/nvme-pool/apps/prometheus/data 0750 568 568 -"
        "d /var/lib/prometheus2/data 0700 568 568 -"
      ];

      services = {
        grafana = {
          enable = true;
          package = pkgs.unstable.grafana;
          # Parent of data/ and plugins/: the module derives database.path (data/grafana.db),
          # paths.plugins (plugins) and Grafana's paths.data (data) from it.
          dataDir = "/mnt/nvme-pool/apps/grafana";
          settings = {
            server = {
              domain = "grafana.deimos.mars.lukashirsch.de";
              root_url = "https://grafana.deimos.mars.lukashirsch.de";
            }; # http_addr defaults to 127.0.0.1, http_port to 3000
            # Grafana's built-in default key: grafana.db's encrypted fields depend on it.
            security.secret_key = "$__file{${config.sops.secrets."grafana/secret_key".path}}";
            log.mode = "console"; # journald; no log files on nvme-pool
          };
          provision = {
            enable = true;
            datasources.settings = {
              apiVersion = 1;
              # Leftovers from older provisioning; read-only, so the UI cannot delete them.
              deleteDatasources = [
                {
                  name = "Loki";
                  orgId = 1;
                }
                {
                  name = "InfluxDB";
                  orgId = 1;
                }
                {
                  name = "InfluxDB - Scrutiny";
                  orgId = 1;
                }
              ];
              datasources = [
                {
                  name = "prometheus";
                  uid = "prometheus";
                  type = "prometheus";
                  access = "proxy";
                  url = "http://127.0.0.1:9090";
                  isDefault = false;
                  editable = false;
                }
                {
                  name = "loki";
                  type = "loki";
                  access = "proxy";
                  url = "http://127.0.0.1:3100";
                  isDefault = false;
                  editable = false;
                  jsonData.maxLines = 1000;
                }
                {
                  name = "influxdb-scrutiny";
                  type = "influxdb";
                  access = "proxy";
                  url = "http://${influxdbIp}:8086";
                  isDefault = false;
                  editable = false;
                  jsonData = {
                    version = "Flux";
                    organization = "$__file{${config.sops.secrets."grafana/datasources/influxdb/scrutiny/org".path}}";
                    defaultBucket = "$__file{${
                      config.sops.secrets."grafana/datasources/influxdb/scrutiny/bucket".path
                    }}";
                    tlsSkipVerify = true;
                  };
                  secureJsonData.token = "$__file{${
                    config.sops.secrets."grafana/datasources/influxdb/scrutiny/token".path
                  }}";
                }
              ];
            };
            # Provider name stays "gatus": Grafana tracks provisioned dashboards per provider.
            dashboards.settings.providers = [
              {
                name = "gatus";
                type = "file";
                allowUiUpdates = false;
                options.path = pkgs.linkFarm "grafana-dashboards" {
                  "gatus.json" = gatusDashboard;
                  "node-exporter-full.json" = nodeDashboard;
                  "traefik.json" = traefikDashboard;
                  "blocky.json" = blockyDashboard;
                };
              }
            ];
          };
        };

        loki = {
          enable = true;
          user = "apps";
          group = "apps";
          dataDir = "/mnt/nvme-pool/apps/loki/data";
          configuration = {
            auth_enabled = false;
            analytics.reporting_enabled = false; # no usage report to stats.grafana.org
            server = {
              http_listen_address = "127.0.0.1";
              http_listen_port = 3100;
              grpc_listen_address = "127.0.0.1";
              grpc_listen_port = 9096;
              log_level = "warn";
            };
            common = {
              instance_addr = "127.0.0.1";
              path_prefix = "/mnt/nvme-pool/apps/loki/data";
              storage.filesystem = {
                chunks_directory = "/mnt/nvme-pool/apps/loki/data/chunks";
                rules_directory = "/mnt/nvme-pool/apps/loki/data/rules";
              };
              replication_factor = 1;
              ring.kvstore.store = "inmemory";
            };
            schema_config.configs = [
              {
                from = "2026-01-01";
                store = "tsdb";
                object_store = "filesystem";
                schema = "v13";
                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }
            ];
            limits_config = {
              retention_period = "336h";
              reject_old_samples = true;
              reject_old_samples_max_age = "168h";
              allow_structured_metadata = true;
              ingestion_rate_mb = 16;
              ingestion_burst_size_mb = 32;
            };
            compactor = {
              working_directory = "/mnt/nvme-pool/apps/loki/data/compactor";
              retention_enabled = true;
              retention_delete_delay = "2h";
              retention_delete_worker_count = 150;
              delete_request_store = "filesystem";
            };
            query_range.results_cache.cache.embedded_cache = {
              enabled = true;
              max_size_mb = 100;
            };
          };
        };

        prometheus = {
          enable = true;
          package = pkgs.unstable.prometheus;
          listenAddress = "127.0.0.1";
          retentionTime = "90d";
          enableReload = true;
          extraFlags = [ "--web.enable-remote-write-receiver" ]; # Alloy pushes host metrics, behind loki-auth
          globalConfig.scrape_interval = "30s";

          exporters.graphite = {
            enable = true;
            # One address for both ports; only 9109 is opened in the firewall.
            listenAddress = "192.168.1.13";
            extraFlags = [ "--graphite.mapping-strict-match" ];
            # Netdata names from mars become Prometheus metrics. Strict matching drops
            # anything outside truenas.mars.
            mappingSettings.mappings = [
              {
                match = "^truenas\\.mars\\.truenas_disk_temp\\._serial(?:_lunid)?_([^_.]+)(?:_[^.]+)?\\.(.+)$";
                match_type = "regex";
                name = "truenas_disk_temp";
                labels = {
                  serial = "\${1}";
                  dimension = "\${2}";
                };
              }
              {
                match = "^truenas\\.mars\\.truenas_disk_stats\\.(busy|ops)\\._serial(?:_lunid)?_([^_.]+)(?:_[^.]+)?\\.(.+)$";
                match_type = "regex";
                name = "truenas_disk_\${1}";
                labels = {
                  serial = "\${2}";
                  dimension = "\${3}";
                };
              }
              {
                match = "^truenas\\.mars\\.truenas_disk_stats\\._serial(?:_lunid)?_([^_.]+)(?:_[^.]+)?\\.(.+)$";
                match_type = "regex";
                name = "truenas_disk_io";
                labels = {
                  serial = "\${1}";
                  dimension = "\${2}";
                };
              }
              {
                match = "^truenas\\.mars\\.([^.]+)\\.([^.]+)\\.(.+)$";
                match_type = "regex";
                name = "truenas_\${1}_\${2}";
                labels.dimension = "\${3}";
              }
              {
                match = "^truenas\\.mars\\.([^.]+)\\.(.+)$";
                match_type = "regex";
                name = "truenas_\${1}";
                labels.dimension = "\${2}";
              }
            ];
          };
        };
      };

      users.users = {
        # The module sets home = dataDir and createHome = true: chown grafana + chmod 700 on every activation.
        grafana = {
          home = lib.mkForce "/var/empty";
          createHome = lib.mkForce false;
        };
        # services.loki.user = "apps" makes the module redefine users.users.apps
        # (home = dataDir, createHome: chown + chmod 700 on every activation).
        apps = {
          description = lib.mkForce "apps service account";
          home = lib.mkForce "/var/empty";
          createHome = lib.mkForce false;
        };
      };

      systemd.services = {
        grafana.serviceConfig = {
          User = lib.mkForce "apps";
          # As the container did; nixpkgs only restarts on failure.
          Restart = lib.mkForce "always";
          RestartSec = 5;
        };
        prometheus.serviceConfig = {
          User = lib.mkForce "apps";
          # The module hardcodes --storage.tsdb.path=/var/lib/prometheus2/data/; mount the existing TSDB there.
          BindPaths = [ "/mnt/nvme-pool/apps/prometheus/data:/var/lib/prometheus2/data" ];
        };
        # Binds 192.168.1.13: wait for the address, and retry slowly enough not to hit the start limit.
        prometheus-graphite-exporter = {
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          serviceConfig.RestartSec = 5;
        };
      };

      services.traefik = {
        dynamicConfigOptions.http.middlewares.loki-auth.basicAuth.usersFile =
          config.sops.templates."traefik/loki-users".path;
        routes = {
          grafana = {
            hosts = [ "grafana.deimos.mars.lukashirsch.de" ];
            url = "http://127.0.0.1:3000";
          };
          loki = {
            hosts = [ "loki.deimos.mars.lukashirsch.de" ];
            url = "http://127.0.0.1:3100";
            middlewares = [ "loki-auth" ];
          };
          # Remote-write endpoint only; reuses the loki-auth basic-auth middleware.
          prometheus = {
            rule = "Host(`prometheus.deimos.mars.lukashirsch.de`) && Path(`/api/v1/write`)";
            url = "http://127.0.0.1:9090";
            middlewares = [ "loki-auth" ];
          };
        };
      };
    };
}
