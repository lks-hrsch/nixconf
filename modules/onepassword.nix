{ config, ... }:
{
  flake =
    let
      common =
        { pkgs, ... }:
        {
          programs._1password = {
            enable = true;
            package = pkgs.unstable._1password-cli;
          };
          programs._1password-gui = {
            enable = true;
            package = pkgs.unstable._1password-gui;
          };
        };
    in
    {
      modules.nixos.onepassword = {
        imports = [ common ];
        programs._1password-gui.polkitPolicyOwners = [ config.flake.users.owner.username ];
      };
      modules.darwin.onepassword = common;
    };
}
