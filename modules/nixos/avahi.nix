_: {
  flake.modules.nixos.avahi =
    { lib, config, ... }:
    {
      # Only enable Avahi on non-container systems (not in LXC/Docker)
      services.avahi.enable = lib.mkDefault (!config.boot.isContainer);
    };
}
