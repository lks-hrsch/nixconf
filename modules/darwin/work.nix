{
  self,
  ...
}:
{
  flake.darwinModules.work = {
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
        "microsoft-edge"
        "zoom"
      ];

      masApps = {
        "Windows App" = 1295203466;
        "Slack for Desktop" = 803453959;
        "Xcode" = 497799835;
        "Developer" = 640199958;
      };
    };

    home-manager.users.lkshrsch.imports = [
      self.homeManagerModules.work
    ];
  };
}
