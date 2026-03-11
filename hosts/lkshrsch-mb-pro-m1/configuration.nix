{ config, ... }:
{
  configurations.darwin."lkshrsch-mb-pro-m1".module =
    { ... }:
    {
      imports = with config.flake.modules.darwin; [
        base
      ];

      networking = {
        computerName = "lkshrsch-mb-pro-m1";
        hostName = "lkshrsch-mb-pro-m1";
        localHostName = "lkshrsch-mb-pro-m1";
      };

      system.defaults.smb.NetBIOSName = "lkshrsch-mb-pro-m1";
    };
}
