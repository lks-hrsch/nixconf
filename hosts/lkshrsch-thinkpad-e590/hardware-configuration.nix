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
          systemd-boot.enable = false; # lanzaboote installs its own signed stub
          efi.canTouchEfiVariables = true;
        };

        # pkiBundle must already exist on the target (`sbctl create-keys`,
        # README step 6) or the generation builds unsigned.
        lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
        };
      };

      # Not pulled in by lanzaboote's module; needed for `sbctl verify`.
      environment.systemPackages = [ pkgs.sbctl ];

      security.tpm2 = {
        enable = true;
        pkcs11.enable = true;
        tctiEnvironment.enable = true;
      };

      # The cryptdata (SATA) crypttab entry belongs here — removed with the
      # rest of the SATA config, see _sata-disabled.nix. Restore both together.

      services = {
        udev.packages = [ pkgs.yubikey-personalization ];
        logind.settings.Login.HandleLidSwitch = "suspend";
        power-profiles-daemon.enable = true;
      };

      powerManagement.enable = true;
    };
}
