{ ... }:
{
  programs.nixvim = {
    enable = true;
    nixpkgs.useGlobalPackages = true;

    # THIS WOULD NEED TO BE SET IN HOMEMANAGER
    # defaultEditor = true;
    # vimdiffAlias = true;

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
}
