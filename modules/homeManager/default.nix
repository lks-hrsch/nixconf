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

  # FIX: warning: Using 'builtins.toFile' to create a file named 'options.json' that references the store path '/nix/store/ws6jqxhhvy2nzjqmp7h8a1546ygrsfk6-source' without a proper context. The resulting file will not have a correct store reference, so this is unreliable and may stop working in the future.
  manual.manpages.enable = false;

  # Note: Linux-specific modules in ./linux should be imported
  # separately by NixOS configurations, not by Darwin configurations
}
