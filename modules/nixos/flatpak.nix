{ inputs, ... }:
{
  flake.modules.nixos.flatpak =
    { ... }:
    {
      imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];

      services.flatpak = {
        enable = true;
        uninstallUnmanaged = true;

        packages = [
          "com.discordapp.Discord"
          "com.felipekinoshita.Kana"
          "com.geekbench.Geekbench6"
          "com.github.tchx84.Flatseal"
          "com.rustdesk.RustDesk"
          "com.spotify.Client"
          "org.jellyfin.JellyfinDesktop"
          "org.kde.okular"
          "org.signal.Signal"
          "org.videolan.VLC"
        ];

        update = {
          onActivation = true;
          auto = {
            enable = true;
            onCalendar = "weekly";
          };
        };
      };

      # nix-flatpak orders this after network.target, which is up long before DNS resolves
      systemd.services.flatpak-managed-install = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
      };
    };
}
