{ ... }:
{
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        url = "https://mcp.context7.com/mcp";
        # headers = {
        #   "CONTEXT7_API_KEY" = "YOUR_API_KEY"
        # };
      };
      time = {
        command = "uvx";
        args = [
          "mcp-server-time"
          "--local-timezone=Europe/Berlin"
        ];
      };
      nixos = {
        command = "uvx";
        args = [ "mcp-nixos" ];
      };
      obsidian = {
        command = "npx";
        args = [
          "@mauricio.wolff/mcp-obsidian@latest"
          "/Users/lkshrsch/Obsidian.nosync/private"
        ];
      };
    };
  };
}
