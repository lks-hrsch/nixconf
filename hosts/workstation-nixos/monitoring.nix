_: {
  configurations.nixos."workstation-nixos".module =
    {
      config,
      pkgs,
      ...
    }:
    let
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
    in
    {
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

      alloy = {
        enable = true;
        hostLabel = "workstation-nixos.lukashirsch.de";
        basicAuthEnvFile = config.sops.templates."alloy/loki-auth.env".path;
        # This host runs no quadlet containers; disabling prevents Alloy from
        # polling the podman socket every 30s, which socket-activates and
        # immediately terminates podman.service ~120 times per hour.
        collectPodman = false;
      };
    };
}
