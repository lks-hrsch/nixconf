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

        update.auto = {
          enable = true;
          onCalendar = "weekly";
        };
      };
    };
}
