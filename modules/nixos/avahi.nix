_: {
  flake.modules.nixos.avahi =
    { lib, config, ... }:
    {
      services = {
        avahi = {
          # Only enable Avahi on non-container systems (not in LXC/Docker)
          enable = lib.mkDefault (!config.boot.isContainer);

          # Publish this host's hostname and addresses via mDNS so that
          # <hostname>.local resolves from other machines on the LAN.
          # Gated on !isContainer for the same reason as avahi.enable above.
          publish = lib.mkIf (!config.boot.isContainer) {
            enable = true;
            addresses = true;
            workstation = true;
          };

          nssmdns4 = lib.mkIf (!config.boot.isContainer) true;
        };

        # When avahi owns mDNS, prevent systemd-resolved from running a competing
        # mDNS responder (which causes intermittent .local resolution failures).
        resolved = lib.mkIf config.services.avahi.enable {
          settings.Resolve = {
            MulticastDNS = "no";
            LLMNR = "no";
          };
        };
      };
    };
}
