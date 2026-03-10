_: {
  flake = {
    modules.nixos.nixvim = {
      programs.nixvim = {
        enable = true;
        nixpkgs.useGlobalPackages = true;
        viAlias = true;
        vimAlias = true;

        colorschemes = {
          catppuccin = {
            enable = true;
            settings.flavour = "mocha";
          };
        };

        plugins = {
          lualine.enable = true;
          nvim-tree.enable = true;
          web-devicons.enable = true;
        };
      };
    };

    modules.darwin.nixvim = {
      programs.nixvim = {
        enable = true;
        nixpkgs.useGlobalPackages = true;
        viAlias = true;
        vimAlias = true;
        colorschemes = {
          catppuccin = {
            enable = true;
            settings.flavour = "mocha";
          };
        };

        plugins = {
          lualine.enable = true;
          nvim-tree.enable = true;
          web-devicons.enable = true;
        };
      };
    };
  };
}
