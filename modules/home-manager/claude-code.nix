_: {
  flake.modules.homeManager.claude-code =
    { pkgs, config, ... }:
    {
      programs.claude-code = {
        enable = true;
        # enableMcpIntegration = true; # TODO - currently not in home manager 25.11 check it later
        mcpServers = config.programs.mcp.servers;
        package = pkgs.unstable.claude-code;
      };
    };
}
