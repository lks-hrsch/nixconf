_: {
  flake.modules.nixos.yubikey =
    { pkgs, ... }:
    {
      # CCID/PIV/OATH applets; FIDO2 and U2F go over hidraw and need no daemon.
      services.pcscd.enable = true;
      services.udev.packages = [ pkgs.yubikey-personalization ];

      environment.systemPackages = with pkgs; [
        yubikey-manager # ykman: inspect applets, program OTP slots
        libfido2 # fido2-token -L, to confirm both keys are seen
        pam_u2f # pamu2fcfg, to register the keys into u2f_keys
      ];

      security.pam = {
        u2f = {
          # Explicit even though it is the nixpkgs default: this is the line that
          # decides whether the token replaces the password or adds to it.
          control = "sufficient";
          settings.cue = true; # otherwise PAM waits for a touch with no prompt
        };
        # Per-service, never security.pam.u2f.enable — that option defaults every
        # service's u2f.enable, sshd included.
        services = {
          sudo.u2f.enable = true;
          polkit-1.u2f.enable = true; # 1Password "unlock using system authentication"
        };
      };
    };
}
