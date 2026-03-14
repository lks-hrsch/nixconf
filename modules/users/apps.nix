{ config, ... }:
{
  flake.users.apps = {
    username = "apps";
    uid = 568;
    gid = 568;
    description = "apps service account";
  };

  flake.modules.nixos.users = {
    users.groups.${config.flake.users.apps.username}.gid = config.flake.users.apps.gid;

    users.users.${config.flake.users.apps.username} = {
      uid = config.flake.users.apps.uid;
      description = config.flake.users.apps.description;
      isSystemUser = true;
      group = config.flake.users.apps.username;
    };
  };

  flake.modules.darwin.users = {
    users.users.${config.flake.users.apps.username} = {
      uid = config.flake.users.apps.uid;
      description = config.flake.users.apps.description;
    };
  };
}
