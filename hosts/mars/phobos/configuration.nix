# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{
  modulesPath,
  inputs,
  pkgs,
  config,
  ...
}:
{
  imports = [
    inputs.self.outputs.modules.nixos.default
    config.flake.modules.nixos.features
    config.flake.modules.nixos.users
    config.flake.modules.nixos.time
    config.flake.modules.nixos.sops
    config.flake.modules.nixos.ssh
    config.flake.modules.nixos.nixvim
    config.flake.modules.nixos.zsh

    # Include the default incus configuration.
    "${modulesPath}/virtualisation/lxc-container.nix"

    # vpn
    ./vpn.nix
  ];

  nix.settings.sandbox = false;

  # Install LDAP and Kerberos management tools
  environment.systemPackages = with pkgs; [
    openldap # LDAP client tools (ldapsearch, ldapadd, etc.)
    krb5 # Kerberos client tools
    ldapvi # LDAP editor
  ];

  # LDAP Server (OpenLDAP)
  services.openldap = {
    enable = true;
    urlList = [ "ldap:///" ];

    settings = {
      attrs = {
        olcLogLevel = "conns config";
        olcPidFile = "/run/openldap/slapd.pid";
      };
      children = {
        "cn=schema" = {
          includes = [
            "${pkgs.openldap}/etc/schema/core.ldif"
            "${pkgs.openldap}/etc/schema/cosine.ldif"
            "${pkgs.openldap}/etc/schema/inetorgperson.ldif"
            "${pkgs.openldap}/etc/schema/nis.ldif"
          ];
        };
        "olcDatabase={1}mdb" = {
          attrs = {
            objectClass = [
              "olcDatabaseConfig"
              "olcMdbConfig"
            ];
            olcDatabase = "{1}mdb";
            olcDbDirectory = "/var/lib/openldap/db";
            olcSuffix = "dc=phobos,dc=mars,dc=lukashirsch,dc=de";
            olcRootDN = "cn=admin,dc=phobos,dc=mars,dc=lukashirsch,dc=de";
            olcRootPW = "{SSHA}ZUrYQuUfi5WcBWoX26vZyM+EVHLBY/oP";
            olcDbIndex = [
              "objectClass eq"
              "cn,uid eq"
              "uidNumber,gidNumber eq"
              "member,memberUid eq"
            ];
          };
        };
      };
    };
  };

  # Kerberos Server (MIT Kerberos)
  services.kerberos_server = {
    enable = true;
    settings = {
      realms = {
        "MARS.LUKASHIRSCH.DE" = {
          admin_server = "phobos.mars.lukashirsch.de";
          kdc = "phobos.mars.lukashirsch.de";
          kpasswd_server = "phobos.mars.lukashirsch.de";
        };
      };
      libdefaults = {
        default_realm = "MARS.LUKASHIRSCH.DE";
      };
    };
  };

  networking = {
    hostName = "phobos";
    dhcpcd.enable = false;
    useDHCP = false;
    useHostResolvConf = false;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        389 # LDAP
        636 # LDAPS
        88 # Kerberos
        464 # Kerberos admin
        749 # Kerberos admin
      ];
      allowedUDPPorts = [
        88 # Kerberos
        464 # Kerberos admin
      ];
    };
  };

  systemd.network = {
    enable = true;
    networks."50-eth0" = {
      matchConfig.Name = "eth0";
      networkConfig = {
        Address = "192.168.1.12/24";
        Gateway = "192.168.1.1";
        DNS = [
          "192.168.1.1"
          "5.45.99.133" # mercury.lukashirsch.de
          "85.209.49.247" # earth.lukashirsch.de
        ];
        IPv6AcceptRA = true;
      };
      linkConfig.RequiredForOnline = "routable";
    };
  };

  system.stateVersion = "25.05"; # Did you read the comment?
}
