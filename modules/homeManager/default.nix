{ ... }:
{
  imports = [
    # Cross-platform features
    ./features/sops.nix
    ./features/stylix.nix

    # CLI programs (cross-platform)
    ./cliPrograms

    # GUI programs (cross-platform)
    ./guiPrograms
  ];

  # Note: Linux-specific modules in ./linux should be imported
  # separately by NixOS configurations, not by Darwin configurations
}
