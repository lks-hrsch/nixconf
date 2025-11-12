{ config, ... }:
{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    authorizedKeysFiles = [ config.sops.secrets."ssh-public-key".path ];
  };
}
