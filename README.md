# nixconf

``` bash
sudo nix-store --optimise
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
