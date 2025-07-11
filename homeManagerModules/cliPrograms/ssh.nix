{ config, ... }:
{
  programs.ssh = {
    enable = true;
    includes = [
      "${config.sops.secrets."ssh-extra-config".path}"
    ];
  };
}
