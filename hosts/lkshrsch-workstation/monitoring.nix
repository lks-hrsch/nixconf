_: {
  configurations.nixos."lkshrsch-workstation".module = {
    alloy = {
      enable = true;
      hostLabel = "workstation-nixos.lukashirsch.de";
      # This host runs no quadlet containers; disabling prevents Alloy from
      # polling the podman socket every 30s, which socket-activates and
      # immediately terminates podman.service ~120 times per hour.
      collectPodman = false;
    };
  };
}
