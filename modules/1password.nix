{ ... }:
{
  flake = {
    nixosModules."1password" =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      lib.mkIf config.features.desktop.enable {
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
          polkitPolicyOwners = [ "lkshrsch" ];
        };
      };

    darwinModules."1password" =
      {
        config,
        lib,
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
