{ config, ... }:
{
  flake = {
    users.apps = {
      username = "apps";
      uid = 568;
      gid = 568;
      description = "apps service account";
    };

    modules = {
      nixos."users-apps" = {
        users.groups.${config.flake.users.apps.username}.gid = config.flake.users.apps.gid;

        users.users.${config.flake.users.apps.username} = {
          inherit (config.flake.users.apps) uid;
          inherit (config.flake.users.apps) description;
          isSystemUser = true;
          group = config.flake.users.apps.username;
        };
      };

      darwin."users-apps" = {
        users.users.${config.flake.users.apps.username} = {
          inherit (config.flake.users.apps) uid;
          inherit (config.flake.users.apps) description;
        };
      };
    };
  };
}
