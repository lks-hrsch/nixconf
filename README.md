# nixconf

- <https://mynixos.com>

``` bash
sudo nix-store --gc
sudo nix-store --optimise

# list generations 
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
nix-env --list-generations --profile ~/.local/state/nix/profiles/home-manager

# delete generations older than 1d
sudo nix-env --delete-generations 1d --profile /nix/var/nix/profiles/system

# complet clean up which deletes all generations
sudo nix-collect-garbage --delete-old
```

on nixos:

``` bash
# update
sudo nix flake update

# apply configuration
sudo nixos-rebuild switch --upgrade --flake ".#workstation-nixos"
```

on darwin:

- <https://github.com/DeterminateSystems/nix-installer>
- <https://docs.determinate.systems/determinate-nix>
- <https://nixcademy.com/posts/nix-on-macos/>

``` bash
# update 
sudo determinate-nixd upgrade

# apply configuration
sudo nix run nix-darwin -- switch --flake ".#lkshrsch-mbp-m3" # initial setup
sudo darwin-rebuild switch --flake ".#lkshrsch-mbp-m3"
```

## working with git-crypt

``` bash
# add a new gpg user
git-crypt add-gpg-user <KEYID>

# unlock the repository
git-crypt unlock
```
