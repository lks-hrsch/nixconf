{
  flake = {
    users.video.name = "video";

    modules.nixos."users-video" =
      { ... }:
      {
        users.groups.video = { };
      };
  };
}
