# nixconf

``` bash
sudo nix-store --optimise
sudo nixos-rebuild switch --upgrade --flake ".#workstation-nixos"
```

``` bash
sudo nix flake update
```

## working with git-crypt

``` bash
# add a new gpg user
git-crypt add-gpg-user <KEYID>

# unlock the repository
git-crypt unlock
```