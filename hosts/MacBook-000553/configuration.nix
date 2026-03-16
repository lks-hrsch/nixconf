{ config, ... }:
{
  configurations.darwin."MacBook-000553".module =
    { ... }:
    {
      imports = with config.flake.modules.darwin; [
        base
        podman
        netbird
        work
      ];

      networking = {
        computerName = "MacBook-000553";
        hostName = "MacBook-000553";
        localHostName = "MacBook-000553";
      };

      system.defaults.smb.NetBIOSName = "MacBook-000553";
    };
}
