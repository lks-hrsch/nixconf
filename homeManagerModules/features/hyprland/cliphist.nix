{ ... }:
{
  services.cliphist = {
    enable = true;
    extraOptions = [
      "-max-dedupe-search"
      "10"
      "-max-items"
      "100"
    ];
    systemdTargets = "graphical-session.target";
  };
}
