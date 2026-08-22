{ config, inputs, ... }:
{
  configurations.nixos."lkshrsch-thinkpad-e590".module =
    {
      pkgs,
      lib,
      config,
      modulesPath,
      ...
    }:
    {
      imports = [
        (modulesPath + "/installer/scan/not-detected.nix")
        "${inputs.nixos-hardware}/lenovo/thinkpad" # trackpoint + TLP
        "${inputs.nixos-hardware}/common/cpu/intel/whiskey-lake"
        "${inputs.nixos-hardware}/common/gpu/intel/whiskey-lake"
        "${inputs.nixos-hardware}/common/pc/ssd"
        inputs.lanzaboote.nixosModules.lanzaboote
      ];

      hardware = {
        facter.reportPath =
          if builtins.pathExists ./facter.json then
            ./facter.json
          else
            throw "Missing hosts/lkshrsch-thinkpad-e590/facter.json. Run nixos-anywhere with --generate-hardware-config nixos-facter hosts/lkshrsch-thinkpad-e590/facter.json.";

        cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
        graphics.enable = true;
        gpgSmartcards.enable = true;
      };

      boot = {
        initrd = {
          availableKernelModules = [
            "nvme"
            "xhci_pci"
            "ahci"
            "usb_storage"
            "usbhid"
            "sd_mod"
            "rtsx_pci_sdmmc" # built-in SD card reader
          ];
          systemd.enable = true; # required for TPM2/FIDO2 LUKS unlock
        };

        loader = {
          # lanzaboote replaces systemd-boot entirely — it installs its own
          # signed stub. Both enabled at once is a hard eval error.
          systemd-boot.enable = false;
          efi.canTouchEfiVariables = true;
        };

        # Keys come from `sbctl create-keys` (README step 6); the bundle must
        # exist on the target before this ever gets deployed, or the generation
        # it builds is unsigned and will not boot with Secure Boot on.
        lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
        };
      };

      # Secure Boot key management. Not pulled in by lanzaboote's module, but
      # needed for the initial `create-keys`/`enroll-keys` and for `sbctl
      # verify` after every generation change.
      environment.systemPackages = [ pkgs.sbctl ];

      security.tpm2 = {
        enable = true;
        pkcs11.enable = true;
        tctiEnvironment.enable = true;
      };

      # NOTE: the cryptdata (SATA) crypttab entry lived here and is currently
      # removed along with the rest of the SATA config — see
      # _sata-disabled.nix for the full block and the open question about why
      # it never unlocked. Restore both together.

      services = {
        udev.packages = [ pkgs.yubikey-personalization ];
        logind.settings.Login.HandleLidSwitch = "suspend";
        power-profiles-daemon.enable = true;
      };

      powerManagement.enable = true;
    };
}
