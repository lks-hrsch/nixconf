{
  flake = {
    users.games.name = "games";

    modules.nixos."users-games" =
      { ... }:
      {
        users.groups.games = { };
      };
  };
}
