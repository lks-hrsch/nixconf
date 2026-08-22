{ config, ... }:
{
  flake.modules.darwin.work = _: {
    homebrew = {
      brews = [
        "appium"
        "git-svn"
        "ios-deploy"
        "rbenv"
        "subversion"
      ];

      casks = [
        "fork"
        "google-chrome"
        "keepassxc"
        "openvpn-connect"
        "zoom"
      ];

      masApps = {
        "Windows App" = 1295203466;
        "Slack for Desktop" = 803453959;
        "Xcode" = 497799835;
        "Developer" = 640199958;
      };
    };

    home-manager.users.${config.flake.users.owner.username}.imports = [
      config.flake.modules.homeManager.work
    ];
  };
}
