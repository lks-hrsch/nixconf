{
  flake = {
    users.renderer.name = "renderer";

    modules.nixos."users-renderer" =
      { ... }:
      {
        users.groups.renderer = { };
      };
  };
}
