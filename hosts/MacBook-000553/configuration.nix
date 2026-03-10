{ self, ... }:
{
  configurations.darwin."MacBook-000553".module =
    { ... }:
    {
      imports = [
        self.outputs.modules.darwin.base
        self.outputs.modules.darwin.podman
        self.outputs.modules.darwin.work
      ];

      networking = {
        computerName = "MacBook-000553";
        hostName = "MacBook-000553";
        localHostName = "MacBook-000553";
      };

      system.defaults.smb.NetBIOSName = "MacBook-000553";
    };
}
