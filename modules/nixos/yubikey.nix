{ config, ... }:
{
  flake.modules.nixos.yubikey =
    { pkgs, ... }:
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
            # Declarative instead of ~/.config/Yubico/u2f_keys: same file on every
            # host that imports this module, no per-machine `pamu2fcfg` step. Each
            # line is `username:keyhandle,pubkey,cosetype,options[:...]` — public
            # key material only (no secret half), same trust level as an SSH
            # authorized_keys entry, safe to commit.
            authfile = pkgs.writeText "u2f-mappings" ''
              ${config.flake.users.owner.username}:zGgSjwdn8pn1BKc/F2O2d0K2a6jVrDIW2SEBX21W7yV+pfiXacFEkpXwk+rpmD8qvNGx+0MPfck3M3kK3YJCRw==,xvkw9hYFacoKkue42dgKVqv1QkQL83+Cxlear7CpSg2VmGOabWf/uXPW4J5vcFuC5cQfCR0xfRPzfkxxd5eluw==,es256,+presence:x8aZBEdw4FzGq0M+TDkcNoufMgeDK52oVVo695mO9fiCxaYdexhf0DsBjtLhyDmXrwR6rCol0M58KnPIQLHgIw==,fSsC1qCW8pw34UUBp0f+tc2pKdx+uyVg/DjlAH6lWlZXK+gkmnNdnQy2khKeUw+XTqcCnR/7hTDfjbF+iae4iQ==,es256,+presence
            '';
          };
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
