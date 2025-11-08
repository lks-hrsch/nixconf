{ config, pkgs, ... }:

with config.lib.stylix.colors.withHashtag;

{
  home.packages = with pkgs; [
    obsidian
  ];

  home.file.obsidian-stylix-css = {
    enable = true;
    target = "Obsidian.nosync/private/.obsidian/snippets/obsidian-stylix-css.css";
    text = "
          :root .theme-dark {
              --background-primary:         ${base00};
              --background-primary-alt:     ${base01};
              --background-secondary:       ${base01};
              --background-secondary-alt:   ${base02};
              
              --text-normal:                ${base05}; /*Text body of note*/
              --text-muted:                 ${base05}; /*Text darker for sidebar, toggles, inactive, tags, etc*/
              --text-accent:                ${base0D}; /*Links*/
              --text-accent-hover:          ${base0B}; /*Links hover*/

          }
      ";
  };
}
