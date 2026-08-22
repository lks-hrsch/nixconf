_: {
  flake =
    let
      commonNixvimConfig =
        { pkgs, ... }:
        {
          programs.nixvim = {
            enable = true;
            nixpkgs.useGlobalPackages = true;
            extraPackages = [ pkgs.unstable.yaml-language-server ];
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
              blink-cmp.enable = true;

              lsp = {
                enable = true;
                servers = {
                  pyrefly = {
                    enable = true;
                    cmd = [ "pyrefly" "lsp" ];
                    filetypes = [ "python" ];
                    rootMarkers = [ "pyrefly.toml" "pyproject.toml" ".git" ];
                  };
                  ruff = {
                    enable = true;
                  };
                  yamlls = {
                    enable = true;
                  };
                };
              };
            };
          };
        };
    in
    {
      modules.nixos.nixvim = commonNixvimConfig;
      modules.darwin.nixvim = commonNixvimConfig;
    };
}
