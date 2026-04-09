_: {
  flake.modules.homeManager.mcp =
    { config, ... }:
    {
      programs.mcp = {
        enable = true;
        servers = {
          sequential-thinking = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-sequential-thinking"
            ];
            description = "Dynamic problem-solving through sequential reasoning steps, enabling structured thought revision and complex multi-step analysis";
          };
          time = {
            type = "stdio";
            command = "uvx";
            args = [
              "mcp-server-time"
              "--local-timezone=Europe/Berlin"
            ];
            description = "Time awareness tools: current time, timezone conversion, and timestamp utilities (local timezone: Europe/Berlin)";
          };
          context7 = {
            type = "http";
            url = "https://mcp.context7.com/mcp";
            # headers = {
            #   "CONTEXT7_API_KEY" = "YOUR_API_KEY"
            # };
            description = "Fetches up-to-date, version-specific library documentation and code examples directly from source to prevent hallucinated APIs";
          };
          microsoft-learn = {
            type = "http";
            url = "https://learn.microsoft.com/api/mcp";
            description = "Real-time access to Microsoft Learn documentation, code samples, and best practices for Azure services and Microsoft technologies, ensuring accurate and current information without hallucination";
          };
          memory = {
            type = "stdio";
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-memory"
            ];
            description = "Persistent memory across sessions";
          };
          obsidian = {
            type = "stdio";
            command = "npx";
            args = [
              "@mauricio.wolff/mcp-obsidian@latest"
              "${config.home.homeDirectory}/Obsidian.nosync/private"
            ];
            description = "Read and manage notes in the local Obsidian private vault";
          };
          nixos = {
            type = "stdio";
            command = "uvx";
            args = [ "mcp-nixos" ];
            description = "Real-time NixOS package search, configuration options, Home Manager settings, and nix-darwin documentation";
          };
        };
      };
    };
}
