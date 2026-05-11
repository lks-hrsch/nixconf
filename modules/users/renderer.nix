{
  flake = {
    users.renderer.name = "renderer";

    modules.nixos."users-renderer" =
      _:
      {
        users.groups.renderer = { };
      };
  };
}
