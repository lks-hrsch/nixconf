{ config, pkgs, lib, ... }:
let
  # Platform-specific 1Password agent socket path
  onePasswordAgent = 
    if pkgs.stdenv.isLinux then
      "~/.1password/agent.sock"
    else
      ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
in
{
  programs.ssh = {
    enable = true;

    includes = [
      "${config.sops.secrets."ssh-extra-config".path}"
    ];
    
    matchBlocks = {
      "*" = {
        identityAgent = onePasswordAgent;
        compression = true;
      };
    };
  };
}
