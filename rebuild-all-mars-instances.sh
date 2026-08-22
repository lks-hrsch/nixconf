# nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#phobos --build-host root@192.168.1.12 --target-host root@192.168.1.12 --option sandbox false
nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#deimos --build-host root@192.168.1.13 --target-host root@192.168.1.13 --option sandbox false

# nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#curiosity --build-host root@192.168.1.64 --target-host root@192.168.1.64 --option sandbox false
# nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#opportunity --build-host root@192.168.1.74 --target-host root@192.168.1.74 --option sandbox false

nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#mercury --build-host root@mercury.netbird.lukashirsch.de --target-host root@mercury.netbird.lukashirsch.de
