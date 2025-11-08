nixos-rebuild switch --upgrade --flake .#phobos --target-host root@192.168.1.12
nixos-rebuild switch --upgrade --flake .#deimos --target-host root@192.168.1.13

# nixos-rebuild switch --upgrade --flake .#curiosity --target-host root@192.168.1.64
# nixos-rebuild switch --upgrade --flake .#opportunity --target-host root@192.168.1.74