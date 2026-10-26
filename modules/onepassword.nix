{ config, lib, ... }:
{
  flake =
    let
      common =
        { pkgs, ... }:
        {
          programs._1password = {
            enable = true;
            package = pkgs.unstable._1password-cli;
          };
          programs._1password-gui = {
            enable = true;
            package = pkgs.unstable._1password-gui;
          };
        };
    in
    {
      modules.nixos.onepassword = {
        imports = [ common ];
        programs._1password-gui.polkitPolicyOwners = [ config.flake.users.owner.username ];
        # nixpkgs only patchelfs the main binaries; 8.12.42's chrome_crashpad_handler
        # keeps /lib64 interp + no rpath -> "libglib-2.0.so.0: cannot open shared object file".
        # shortcut: drop once nixpkgs linux.nix patches chrome_crashpad_handler itself.
        nixpkgs.overlays = lib.mkAfter [
          (_: prev: {
            unstable = prev.unstable // {
              _1password-gui = prev.unstable._1password-gui.overrideAttrs (old: {
                postInstall = (old.postInstall or "") + ''
                  d=$out/share/1password
                  patchelf --set-interpreter "$interp" --set-rpath "$(patchelf --print-rpath $d/1password)" $d/chrome_crashpad_handler
                '';
              });
            };
          })
        ];
      };
      modules.darwin.onepassword = common;
    };
}
