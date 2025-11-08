{ lib, ... }: {
  programs.hyprlock = {
    enable = true;
    settings = {
      input-field = lib.mkDefault [
        {
          monitor = "DP-3";
          size = "300, 30";
          position = "0, -470";
          halign = "center";
          valign = "center";
        }
      ];

      label = [
        {
          monitor = "DP-3";
          text = "cmd[update:1000] echo \"$(date +\"%A, %B %d\")\"";
          color = "rgba(0, 0, 0, 1)";
          font_size = 24;
          position = "0, 400";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "DP-3";
          text = "cmd[update:1000] echo \"$(date +\"%k:%M\")\"";
          color = "rgba(0, 0, 0, 1)";
          font_size = 93;
          position = "0, 253";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "DP-3";
          text = "$USER";
          color = "rgba(0, 0, 0, 1)";
          font_size = 20;
          position = "0, -407";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "DP-3";
          text = "Touch Id or Enter Password";
          color = "rgba(0, 0, 0, 1)";
          font_size = 10;
          position = "0, -440";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
