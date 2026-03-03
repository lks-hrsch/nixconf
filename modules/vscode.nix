_: {
  flake.homeManagerModules.vscode =
    { pkgs, ... }:
    let
      # vscodePackage = pkgs.unstable.vscode;
      vscodePackage = pkgs.unstable.vscode.overrideAttrs (old: rec {
        version = "1.109.5";
        src = pkgs.fetchurl {
          name = "VSCode_${version}_darwin-arm64.zip"; # This .zip extension fixes the unpack error
          url = "https://update.code.visualstudio.com/${version}/darwin-arm64/stable";
          sha256 = "sha256-ckwFJ4P2hCy7TTUS+peUNad00ydk4RnAthkggrbYzAQ=";
        };
      });
      vsCodeVersion = vscodePackage.version;
      extensionsCompatible = pkgs.forVSCodeVersion vsCodeVersion;
      marketplace = extensionsCompatible.vscode-marketplace;

      # extensions for all profiles
      # if they are not working properly append pkgs.unstable.vscode-extensions. in front of the extension id
      defaultExtensions = with marketplace; [
        pkief.material-icon-theme
        christian-kohler.path-intellisense
        ms-vscode-remote.remote-containers
        ms-vscode-remote.remote-ssh
        ms-vscode-remote.remote-ssh-edit

        # some useful tools
        tomoki1207.pdf # PDF viewer
        davidanson.vscode-markdownlint
        tamasfe.even-better-toml
        ms-azuretools.vscode-containers

        # git
        mhutchie.git-graph
        donjayamanne.githistory

        # github
        github.copilot-chat
        github.vscode-pull-request-github
        github.vscode-github-actions

        # nix extensions
        jnoortheen.nix-ide
      ];

      # settings for all profiles
      defaultSettings = {
        "telemetry.editStats.enabled" = false;
        "telemetry.feedback.enabled" = false;
        "telemetry.telemetryLevel" = "off";

        "update.mode" = "none";

        "editor.formatOnSave" = true;
        "editor.formatOnPaste" = true;
        "workbench.editorLargeFileConfirmation" = 100; # 100 MB

        "git.autofetch" = "all";

        "nix.formatterPath" = "nixfmt";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";
        "nix.serverSettings" = {
          "nil" = {
            "formatting" = {
              "command" = [ "nixfmt" ];
            };
          };
        };

        "github.copilot.nextEditSuggestions.enabled" = true;
        "github.copilot.nextEditSuggestions.fixes" = true;
        "github.copilot.chat.editor.temporalContext.enabled" = true;
        "github.copilot.chat.edits.temporalContext.enabled" = true;
        "github.copilot.chat.codesearch.enabled" = true;
        "github.copilot.chat.useResponsesApi" = true;
        "github.copilot.chat.githubMcpServer.enabled" = true;
        "github.copilot.chat.newWorkspace.useContext7" = true;

        "chat.mcp.gallery.enabled" = true;
        "chat.mcp.discovery.enabled" = {
          "claude-desktop" = true;
          "cursor-global" = true;
          "cursor-workspace" = true;
        };
      };
    in
    {
      home.packages = with pkgs; [
        nil
        nixfmt-rfc-style
        nixpkgs-fmt

        # for MCP
        uv
        nodejs_24
      ];

      programs.vscode = {
        enable = true;
        package = vscodePackage;

        profiles = {
          default = {
            extensions = defaultExtensions;
            userSettings = defaultSettings;
            enableMcpIntegration = true;
          };

          lkshrsch = {
            extensions =
              defaultExtensions
              ++ (with marketplace; [
                # Add additional extensions specific to lkshrsch profile here
                # C/C++ extensions
                llvm-vs-code-extensions.vscode-clangd
                # vadimcn.vscode-lldb

                # Rust extensions
                rust-lang.rust-analyzer
                tauri-apps.tauri-vscode

                # python extensions
                ms-python.python
                ms-python.vscode-pylance
                ms-python.debugpy
                charliermarsh.ruff
                ms-toolsai.jupyter
                ms-toolsai.jupyter-keymap
                ms-toolsai.jupyter-renderers
                ms-toolsai.vscode-jupyter-slideshow
                ms-toolsai.vscode-jupyter-cell-tags
                ms-toolsai.vscode-jupyter-powertoys

                # web development
                ms-vscode.vscode-typescript-next
                bradlc.vscode-tailwindcss
                biomejs.biome
                # ms-playwright.playwright
              ])
              ++ [
                (pkgs.vscode-utils.buildVscodeMarketplaceExtension {
                  mktplcRef = {
                    publisher = "ms-playwright";
                    name = "playwright";
                    version = "1.1.17";
                    sha256 = "1w3gih8igk3hairqi90pd919rqf4vadk0mm49xs92k7kp3v15158";
                  };
                })
              ];
            userSettings = defaultSettings // {
              # Add additional settings specific to lkshrsch profile here
              "playwright.pickLocatorCopyToClipboard" = true;
              "playwright.reuseBrowser" = true;
            };
            enableMcpIntegration = true;
          };
        };
      };
    };
}
