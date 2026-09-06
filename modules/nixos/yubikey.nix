{ config, ... }:
let
  inherit (config.flake.users.owner) username;
in
{
  flake.modules.nixos.yubikey =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      # CCID/PIV/OATH applets; FIDO2 and U2F go over hidraw and need no daemon.
      services.pcscd.enable = true;
      services.udev.packages = [ pkgs.yubikey-personalization ];

      environment.systemPackages = with pkgs; [
        yubikey-manager # ykman: inspect applets, program OTP slots
        libfido2 # fido2-token -L, to confirm both keys are seen
        pam_u2f # pamu2fcfg, to re-derive an entry below after adding a key
      ];

      security.pam = {
        u2f = {
          # Explicit even though it is the nixpkgs default: this is the line that
          # decides whether the token replaces the password or adds to it.
          control = "sufficient";
          settings = {
            cue = true; # otherwise PAM waits for a touch with no prompt
            # pamu2fcfg defaults origin/appid to pam://$HOSTNAME, binding a
            # credential to one machine. Pinned so the authfile below works on
            # every host that imports this module, survives a hostname rename.
            origin = "pam://lkshrsch";
            appid = "pam://lkshrsch";
            # Declarative instead of ~/.config/Yubico/u2f_keys: same file on every
            # host that imports this module, no per-machine `pamu2fcfg` step. Each
            # line is `username:keyhandle,pubkey,cosetype,options[:...]` — public
            # key material only (no secret half), same trust level as an SSH
            # authorized_keys entry, safe to commit.
            authfile = pkgs.writeText "u2f-mappings" ''
              ${username}:iBPqNL7isPeQMLTFTlUXFZIenV/o06K0zEOfnb3ZkBgnVf51MTdqOt8c6+pIAhXzDC1bySNUBQRczeGRK4TW/Q==,igqTqJNMseTBYp6yQ9OAo0V9w3CB1OADQHV7jDR5fHMWpf/DTdNwYzbIs+GZQbyjxyRkZ7DTIi2RhVOX+oc4+g==,es256,+presence:IGozUhEPNxA+hxIOxB09HyAXZXopTna79C/7xZD6GezG2CsUHYHNxCVJnZLT7KWzhUsyQbX9e6iTpzeBUkHNtg==,kBHEFlwIyBMAVUmpD2eGjdJv2cm4g3pmZmJrSabfsk8OfWw0TCr9tiCf3Pp6ch7xANL7ojAI8fs8weTdluKjkw==,es256,+presence
            '';
          };
        };
        # Per-service, never security.pam.u2f.enable — that option defaults every
        # service's u2f.enable, sshd included.
        services = {
          sudo.u2f.enable = true;
          polkit-1.u2f.enable = true; # 1Password "unlock using system authentication"

          # required, not "sufficient" above — sufficient skips pam_unix/gnome_keyring, leaving the login keyring locked
          greetd = lib.mkIf config.services.greetd.enable {
            u2f.enable = true;
            u2f.control = "required";
          };
        };
      };
    };
}
