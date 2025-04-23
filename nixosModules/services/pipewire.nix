{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    rnnoise-plugin
  ];

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
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

  # make pipewire realtime-capable
  # https://mynixos.com/nixpkgs/option/security.rtkit.enable
  security.rtkit.enable = true;
}
