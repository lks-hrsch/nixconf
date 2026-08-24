# nixconf

- <https://mynixos.com>

``` bash
sudo nix-store --gc
sudo nix-store --optimise
sudo nix-store --verify --check-contents --repair

# list generations 
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
nix-env --list-generations --profile ~/.local/state/nix/profiles/home-manager

# delete generations older than 14d
sudo nix-env --delete-generations 14d --profile /nix/var/nix/profiles/system
nix-env --delete-generations 14d --profile ~/.local/state/nix/profiles/home-manager

# complet clean up which deletes all generations
sudo nix-collect-garbage --delete-old
```

on nixos:

``` bash
# update
sudo nix flake update

# apply configuration
sudo nixos-rebuild switch --upgrade --flake ".#lkshrsch-workstation"
```

build a nixos on nixos:

``` bash
nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#mercury --target-host root@10.10.1.1

nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#deimos --target-host root@192.168.1.13
```

on darwin:

- <https://github.com/DeterminateSystems/nix-installer>
- <https://docs.determinate.systems/determinate-nix>
- <https://nixcademy.com/posts/nix-on-macos/>

``` bash
# update 
sudo determinate-nixd upgrade
sudo nix flake update

# apply configuration
sudo nix run nix-darwin -- switch --flake ".#MacBook-000553" # initial setup
sudo darwin-rebuild switch --flake ".#MacBook-000553"
```

build a nixos on darwin:

<!-- https://github.com/NixOS/nixpkgs/issues/439945 -->

``` bash
nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#mercury --build-host root@10.10.1.1 --target-host root@10.10.1.1 --option sandbox false

nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#deimos --build-host root@10.10.1.18 --target-host root@10.10.1.18 --option sandbox false
nix run nixpkgs#nixos-rebuild-ng -- switch --flake .#deimos --build-host root@192.168.1.13 --target-host root@192.168.1.13 --option sandbox false
```

## working with git-crypt

``` bash
# add a new gpg user
gpg --armor --export <KEYID> > new-public-key.asc
gpg --import new-public-key.asc
gpg --edit-key <KEYID>
# Type: trust
# Select trust level (usually 5 for ultimate if you verified it)
# Type: quit
git-crypt add-gpg-user <KEYID>

# unlock the repository
git-crypt unlock
```

## working with sops

``` bash
# edit secrets
SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt sops secrets/secrets.yaml
```

## updating claude-code

`overlays/claude-code-manifest.json` pins the version. To bump it, fetch the
new manifest from the official CDN and commit it:

``` bash
# pin a specific version
curl -fsSL \
  "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/2.1.158/manifest.json" \
  > overlays/claude-code-manifest.json

# or track the upstream 'stable' pointer
VER=$(curl -fsSL "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/stable")
curl -fsSL "https://storage.googleapis.com/claude-code-dist-86c565f3-f756-42ad-8dfa-d59b1c096819/claude-code-releases/${VER}/manifest.json" \
  > overlays/claude-code-manifest.json
```

No hash juggling needed — all platform checksums are inside the manifest.
Then rebuild as normal (`sudo nixos-rebuild switch ...` or `darwin-rebuild switch ...`).

## updating opencode

`overlays/opencode-manifest.json` pins the version. Binary releases are fetched
from the anomalyco/opencode GitHub releases. Updating requires computing hashes
for each platform tarball/zip:

``` bash
VER=1.15.XX   # new version
BASE="https://github.com/anomalyco/opencode/releases/download/v${VER}"
for ASSET in opencode-linux-x64.tar.gz opencode-linux-arm64.tar.gz opencode-darwin-arm64.zip; do
  echo "${ASSET}:"
  nix-prefetch-url "${BASE}/${ASSET}" 2>/dev/null | xargs -I{} nix hash convert --hash-algo sha256 --from nix32 {}
done
# paste sha256 values into overlays/opencode-manifest.json
```

## updating vscode

`overlays/vscode-manifest.json` pins the version. Updating requires computing
hashes for each platform archive:

``` bash
VER=1.122.X   # new version
for PLAT in linux-x64 linux-arm64 darwin-arm64; do
  echo "${PLAT}:"
  nix-prefetch-url "https://update.code.visualstudio.com/${VER}/${PLAT}/stable" 2>/dev/null \
    | xargs -I{} nix hash convert --hash-algo sha256 --from nix32 {}
done
# paste sha256 values into overlays/vscode-manifest.json
```

## linting

``` bash
❯ nix run nixpkgs#statix -- check overlays
❯ nix run nixpkgs#statix -- fix overlays  
```
