_: {
  flake.modules.nixos.pipewire =
    {
      lib,
      config,
      pkgs,
      ...
    }:
    {
      environment.systemPackages = with pkgs; [
        rnnoise-plugin
      ];

      # Enable sound.
      # hardware.pulseaudio.enable = true;
      # OR
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        # Disabled via mkForce: steam.nix sets this to true, but the i686 PipeWire
        # now pulls libcamera → numpy → lapack → openblas (i686) which Hydra
        # doesn't cache, causing a multi-hour local build. 32-bit audio clients
        # still work via pipewire-pulse.
        alsa.support32Bit = lib.mkForce false;
        pulse.enable = true;
        wireplumber.enable = true;

        # AirPlay/RAOP configurations
        # opens UDP ports 6001-6002
        raopOpenFirewall = true;
        extraConfig.pipewire = {
          "10-airplay" = {
            context.modules = [
              {
                name = "libpipewire-module-raop-discover";

                # increase the buffer size if you get dropouts/glitches
                # args = {
                #   "raop.latency.ms" = 500;
                # };
              }
            ];
          };
        };
      };

      services.upower.enable = true;

      # make pipewire realtime-capable
      # https://mynixos.com/nixpkgs/option/security.rtkit.enable
      security.rtkit.enable = true;
    };
}
