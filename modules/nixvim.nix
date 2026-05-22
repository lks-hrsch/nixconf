_: {
  flake =
    let
      commonNixvimConfig = {
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
