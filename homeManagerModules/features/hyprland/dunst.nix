{ ... }: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        markup = "full";
        format = ''<b>%s</b>\n%b'';
        sort = "yes";
        shrink = "yes";
        follow = "mouse";

        origin = "top-right";
        offset = "10x10";
        height = "500";
        width = 0;
        padding = 20;
        horizontal_padding = 20;

        frame_width = 6;
        separator_height = 3;

        alignment = "left";
        word_wrap = "yes";
        ignore_newline = "no";
        stack_duplicates = true;
        show_indicators = "yes";
        sticky_history = "yes";
        history_length = 6;

        mouse_left_click = "close_current";
        mouse_middle_click = "do_action, close_current";
        mouse_right_click = "close_all";
      };
      urgency_low = {
        timeout = 5;
      };
      urgency_normal = {
        timeout = 10;
      };
      urgency_critical = {
        timeout = 20;
      };
    };
  };
}
