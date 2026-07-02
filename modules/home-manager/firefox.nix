{ config, ... }:
{
  flake.modules.homeManager.firefox =
    {
      pkgs,
      ...
    }:
    {
      programs.firefox = {
        enable = true;
        # On darwin the app must come from Homebrew (signed, in /Applications)
        # so the 1Password extension can integrate with the desktop app;
        # nix-store Firefox fails 1Password's code-sign/location check.
        # Home-manager still manages the profile below either way.
        package = if pkgs.stdenv.isDarwin then null else pkgs.unstable.firefox-bin;
        # macOS Firefox reads from ~/Library/Application Support/Firefox, not ~/.mozilla/firefox
        configPath =
          if pkgs.stdenv.isDarwin then "Library/Application Support/Firefox" else ".mozilla/firefox";

        profiles.${config.flake.users.owner.username} = {
          search = {
            force = true;
            default = "ddg";
            privateDefault = "ddg";
            engines = {
              "bing".metaData.hidden = true;
              "ecosia".metaData.hidden = true;
              "amazondotcom-us".metaData.hidden = true;
              "wikipedia".metaData.hidden = true;
              "perplexity".metaData.hidden = true;

              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "channel";
                        value = "unstable";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = [ "@nix" ];
              };
            };
          };

          settings = {
            "browser.startup.homepage" = "https://start.duckduckgo.com";
            "browser.startup.page" = 3; # open previous windows and tabs
            "browser.newtabpage.activity-stream.showSponsored" = false;
            "browser.aboutConfig.showWarning" = false; # No warning when going to config
            "browser.warnOnQuitShortcut" = false;

            "browser.disableResetPrompt" = true;
            "browser.download.panel.shown" = true;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

            "browser.shell.checkDefaultBrowser" = false;
            "browser.shell.defaultBrowserCheckCount" = 1;
            "browser.bookmarks.restore_default_bookmarks" = false;

            # Native vertical tabs (new sidebar)
            "sidebar.revamp" = true;
            "sidebar.verticalTabs" = true;

            "general.smoothScroll" = true;
            "media.hardware-video-decoding.force-enabled" = true;
            "media.ffmpeg.vaapi.enabled" = true; # Enable hardware acceleration
            "widget.dmabuf.force-enabled" = true;
            "layers.acceleration.force-enabled" = true;
            "gfx.webrender.all" = true;

            "media.av1.enabled" = true;
            "media.hevc.enabled" = false;

            # Disable Pocket
            "extensions.pocket.enabled" = false;
            "extensions.pocket.onSaveRecs" = false;

            # Disable some telemetry
            "app.shield.optoutstudies.enabled" = false;
            "browser.discovery.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.ping-centre.telemetry" = false;
            "datareporting.healthreport.service.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "datareporting.sessions.current.clean" = true;
            "devtools.onboarding.telemetry.logged" = false;
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.bhrPing.enabled" = false;
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.firstShutdownPing.enabled" = false;
            "toolkit.telemetry.hybridContent.enabled" = false;
            "toolkit.telemetry.newProfilePing.enabled" = false;
            "toolkit.telemetry.prompted" = 2;
            "toolkit.telemetry.rejected" = true;
            "toolkit.telemetry.reportingpolicy.firstRun" = false;
            "toolkit.telemetry.server" = "";
            "toolkit.telemetry.shutdownPingSender.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.unifiedIsOptIn" = false;
            "toolkit.telemetry.updatePing.enabled" = false;

            # Disable fx accounts
            "identity.fxaccounts.enabled" = false;

            # Disable "save password" prompt
            "signon.rememberSignons" = false;

            # Disable save/autofill of payment methods and addresses
            "extensions.formautofill.creditCards.enabled" = false;
            "extensions.formautofill.addresses.enabled" = false;

            # Harden
            "privacy.trackingprotection.enabled" = true;
            "dom.security.https_only_mode" = true;
          };
          extensions = {
            # search for addons here: https://github.com/nix-community/nur-combined/blob/main/repos/rycee/pkgs/firefox-addons/addons.json
            packages = with pkgs.firefox-addons; [
              ublock-origin
              youtube-shorts-block
              web-clipper-obsidian
              onepassword-password-manager
            ];
          };
        };
      };
    };
}
