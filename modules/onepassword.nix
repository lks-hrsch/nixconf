{ config, ... }:
{
  flake = {
    modules.nixos.onepassword =
      {
        pkgs,
        ...
      }:
      {
        environment.systemPackages = with pkgs.unstable; [
          _1password-cli
          _1password-gui
        ];

        programs._1password = {
          enable = true;
          package = pkgs.unstable._1password-cli;
        };
        programs._1password-gui = {
          enable = true;
          package = pkgs.unstable._1password-gui;
          polkitPolicyOwners = [ config.flake.users.owner.username ];
        };
      };

    modules.darwin.onepassword =
      {
        pkgs,
        ...
      }:
      # Assuming desktop feature or equivalent check for Darwin if needed
      {
        environment.systemPackages = with pkgs.unstable; [
          _1password-cli
          _1password-gui
        ];

        # 1Password CLI/GUI configuration for Darwin might differ or be handled via Homebrew/DMG
        # NixOS module options might not exist on Darwin.
        # Minimal package installation for now.
      };
  };
}
