{ ... }:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    enableBashIntegration = true;
    settings = {
      hostname.ssh_only = false;
      username.show_always = true;
    };
  };
}
