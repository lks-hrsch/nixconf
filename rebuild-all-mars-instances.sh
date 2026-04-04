# nixos-rebuild switch --flake .#phobos --target-host root@192.168.1.12
nixos-rebuild switch --flake .#deimos --target-host root@192.168.1.13

# nixos-rebuild switch --flake .#curiosity --target-host root@192.168.1.64
# nixos-rebuild switch --flake .#opportunity --target-host root@192.168.1.74

nixos-rebuild switch --flake .#mercury --target-host root@mercury.netbird.lukashirsch.de