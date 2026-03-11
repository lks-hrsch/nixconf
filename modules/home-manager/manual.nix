_: {
  flake.modules.homeManager.manual = _: {
    # FIX: warning: Using 'builtins.toFile' to create a file named 'options.json' that references the store path '...' without a proper context.
    manual.manpages.enable = false;
  };
}
