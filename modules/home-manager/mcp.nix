_: {
  flake.modules.homeManager.mcp =
    { config, ... }:
    {
      programs.mcp = {
        enable = true;
        servers = {
          websearch = {
            type = "http";
            url = "https://mcp.tavily.com/mcp/";
            headers = {
              "Authorization" = "Bearer {file:${config.sops.secrets."mcp/tavily/api-key".path}}";
            };
            description = "Real-time web search with content extraction, crawling, and deep research";
          };
          context7 = {
            type = "http";
            url = "https://mcp.context7.com/mcp";
            # headers = {
            #   "CONTEXT7_API_KEY" = "YOUR_API_KEY"
            # };
            description = "Up-to-date code documentation from source repositories, version-specific";
          };
          grep-app = {
            type = "http";
            url = "https://mcp.grep.app";
            description = "Code search across public GitHub repositories with caching & batch operations";
          };
          obsidian = {
            type = "stdio";
            command = "npx";
            args = [
              "@mauricio.wolff/mcp-obsidian@latest"
              "${config.home.homeDirectory}/Obsidian.nosync/private"
            ];
            description = "Secure access to local Obsidian vault for notes management";
          };
          nixos = {
            type = "stdio";
            command = "uvx";
            args = [ "mcp-nixos" ];
            description = "Real-time NixOS ecosystem search (130K+ packages, 23K+ system options)";
          };
        };
      };
    };
}
