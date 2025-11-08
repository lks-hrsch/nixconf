{ pkgs, ... }:
{
  imports = [
    ./btop.nix
    ./git.nix
    ./gpg.nix
    ./k9s.nix
    ./ssh.nix
    ./starship.nix
    ./tmux.nix
    ./vim.nix
    ./zsh.nix
  ];

  home.packages = with pkgs; [
    azure-cli
    iperf3
    nmap
  ];
}
