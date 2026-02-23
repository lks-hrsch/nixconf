_:
{
  flake = {
    nixosModules.tmux = {
      programs.tmux = {
        enable = true;
      };
    };

    darwinModules.tmux = {
      programs.tmux = {
        enable = true;
      };
    };
  };
}
