{ config, ... }:
let
  inherit (config.repo.constants) obsidianBasePath;
in
{
  flake.modules.homeManager.mcp =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      tavilyUrl = "https://mcp.tavily.com/mcp/";
      tavilyKey = config.sops.secrets."mcp/tavily/api-key".path;
    in
    {
      programs = {
        # websearch is per client: each reads the secret file differently, and Claude Code sends
        # opencode's {file:...} literally as the token (HTTP 401).
        opencode.settings.mcp.websearch = {
          type = "remote";
          url = tavilyUrl;
          headers.Authorization = "Bearer {file:${tavilyKey}}";
        };
        claude-code.mcpServers.websearch = {
          type = "http";
          url = tavilyUrl;
          headersHelper = toString (
            pkgs.writeShellScript "tavily-mcp-headers" ''
              exec ${lib.getExe pkgs.jq} -n --rawfile key ${tavilyKey} '{Authorization: ("Bearer " + ($key | rtrimstr("\n")))}'
            ''
          );
          description = "Real-time web search with content extraction, crawling, and deep research";
        };

        mcp = {
          enable = true;
          servers = {
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
            # https://github.com/bitbonsai/mcpvault
            obsidian = {
              type = "stdio";
              command = "npx";
              args = [
                "@bitbonsai/mcpvault@latest"
                # Private vault only — the work-develappers vault is not
                # exposed via MCP.
                "${config.home.homeDirectory}/${obsidianBasePath}/private"
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
    };
}
