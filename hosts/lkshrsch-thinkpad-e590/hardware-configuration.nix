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
        # Enable after Secure Boot keys are enrolled (README step 4) — too
        # early locks the machine out of booting.
        # inputs.lanzaboote.nixosModules.lanzaboote
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
          # Installed with systemd-boot; flipped to lanzaboote per README step 4.
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
        # Once lanzaboote is enabled, uncomment:
        # loader.systemd-boot.enable = lib.mkForce false;
        # lanzaboote = {
        #   enable = true;
        #   pkiBundle = "/var/lib/sbctl";
        # };
      };

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
