_: {
  configurations.nixos."mercury".module =
    { config, ... }:
    {
      sops.secrets."root-password-hash" = {
        sopsFile = ../../secrets/secrets-mercury.yaml;
        neededForUsers = true;
        owner = "root";
        group = "root";
        mode = "0400";
      };

      users.users.root.hashedPasswordFile = config.sops.secrets."root-password-hash".path;
    };
}
