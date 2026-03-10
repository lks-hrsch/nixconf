{ self, ... }:
{
  configurations.darwin."lkshrsch-mb-pro-m1".module =
    { ... }:
    {
      imports = [
        self.outputs.modules.darwin.base
      ];

      networking = {
        computerName = "lkshrsch-mb-pro-m1";
        hostName = "lkshrsch-mb-pro-m1";
        localHostName = "lkshrsch-mb-pro-m1";
      };

      system.defaults.smb.NetBIOSName = "lkshrsch-mb-pro-m1";
    };
}
