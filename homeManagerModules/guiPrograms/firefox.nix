{ pkgs, firefox-addons-allow-unfree, ... }:
{
  programs.firefox = {
    enable = true;

    profiles.lkshrsch = {
      search.engines = {
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
          definedAliases = [ "@n" ];
        };
      };

      search.force = true;

      settings = {
        "browser.startup.homepage" = "https://start.duckduckgo.com";

        "browser.disableResetPrompt" = true;
        "browser.download.panel.shown" = true;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

        "browser.shell.checkDefaultBrowser" = false;
        "browser.shell.defaultBrowserCheckCount" = 1;
        "browser.bookmarks.restore_default_bookmarks" = false;

        "general.smoothScroll" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "widget.dmabuf.force-enabled" = true;

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

        # Harden
        "privacy.trackingprotection.enabled" = true;
        "dom.security.https_only_mode" = true;
      };
      extensions = {
        packages = with firefox-addons-allow-unfree; [
          ublock-origin
          youtube-shorts-block
          onepassword-password-manager
        ];
      };
    };
  };
}
