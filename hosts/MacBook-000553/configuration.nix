{ self, ... }:
{
  configurations.darwin."MacBook-000553".module =
    { ... }:
    {
      imports = with self.outputs.modules.darwin; [
        base
        podman
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
