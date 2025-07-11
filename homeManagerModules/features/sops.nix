{ ... }:
{
  sops = {
    age.keyFile = "/home/lkshrsch/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    defaultSopsFormat = "yaml";

    secrets = {
      "ssh-extra-config" = { };
      "git/user-lks-hrsch" = { };
    };
  };
}
