{
  flake = {
    users.video.name = "video";

    modules.nixos."users-video" =
      _:
      {
        users.groups.video = { };
      };
  };
}
