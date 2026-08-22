{
  flake = {
    users.games.name = "games";

    modules.nixos."users-games" =
      _:
      {
        users.groups.games = { };
      };
  };
}
