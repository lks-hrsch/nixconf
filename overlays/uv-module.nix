# Extends home-manager's built-in `programs.uv` (modules/programs/uv.nix,
# present at this repo's pinned rev af2beae5f0 on release-26.05) with just the
# `tool.packages`/`tool.prune` piece, backported from nix-community/home-manager
# commit c51ac59e5 (2026-06-17, refined 6eba758fe 2026-06-22), which targets
# release-26.11 and isn't in release-26.05 yet.
#
# Deliberately does NOT redeclare `enable`/`package`/`settings` — those already
# exist upstream at this pin; redeclaring them is a duplicate-option eval error.
# This file only adds the missing `tool` namespace and reads the existing
# `cfg.enable`/`cfg.package` to drive its own activation script.
#
# Lives under overlays/ alongside the repo's other temporary upstream
# workarounds, even though this is a home-manager module rather than a
# nixpkgs `final: prev:` overlay — overlays/ isn't scanned by import-tree, so
# this file is never auto-imported; it's manually imported by
# modules/home-manager/claude-code/claude-code.nix instead.
#
# TODO: once this repo's home-manager input reaches release-26.11 (or later),
# delete this file and drop its `imports` entry in claude-code.nix — the
# upstream `programs.uv.tool.*` option takes over unchanged.
{
  config,
  lib,
  ...
}:

let
  inherit (lib)
    mkOption
    types
    optionalString
    escapeShellArg
    escapeShellArgs
    concatMapStringsSep
    ;

  cfg = config.programs.uv;
  toolCfg = cfg.tool;
in
{
  options.programs.uv.tool = {
    packages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [
        "ruff"
        "black==24.1.0"
        "poetry[plugin]"
      ];
      description = ''
        Tools to install with `uv tool` during activation. Each entry is passed
        verbatim to {command}`uv tool install`, so version specifiers and extras
        work (e.g. `"black==24.1.0"`, `"poetry[plugin]"`).

        On every activation {command}`uv tool upgrade` is run for the listed
        tools, which upgrades them to the latest version allowed by the
        constraints they were installed with. Tools that are not listed are
        left untouched. See <https://docs.astral.sh/uv/concepts/tools/> for
        more information.
      '';
    };

    prune = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to make the set of installed tools fully declarative.

        When enabled, installed tools whose package name is no longer listed in
        {option}`programs.uv.tool.packages` are uninstalled before the listed
        tools are installed, so the set is fully declarative.

        ::: {.warning}
        Tools installed manually with {command}`uv tool install` are also
        removed, since they are not listed here.
        :::
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # `uv tool install` drops shims in ~/.local/bin, which nothing else in this
    # repo puts on PATH — without this, installed tools (e.g. graphify) only
    # resolve via absolute path, not in a normal login shell.
    home.sessionPath = lib.mkIf (toolCfg.packages != [ ]) [ "$HOME/.local/bin" ];

    home.activation.uvTool = lib.mkIf (toolCfg.packages != [ ] || toolCfg.prune) (
      let
        uvBin = if cfg.package != null then lib.getExe cfg.package else "uv";

        # PEP 503 normalization: collapse every run of `-`, `_`, `.` to a
        # single `-`, then lowercase — uv keys its tool directory by this
        # normalized name, so pruning has to compare against the same form.
        canonicalName =
          name:
          lib.toLower (
            lib.concatMapStrings (x: if builtins.isList x then "-" else x) (builtins.split "[-_.]+" name)
          );

        # Requested tool names to keep: leading PEP 508 name (dropping extras
        # and version specifiers), PEP 503 normalized.
        toolName =
          spec:
          let
            m = builtins.match "([A-Za-z0-9._-]+).*" spec;
          in
          canonicalName (if m == null then spec else builtins.head m);
        toolKeep = lib.unique (map toolName toolCfg.packages);
      in
      # Run after linkGeneration so uv sees the freshly linked state.
      lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        ${optionalString toolCfg.prune ''
          # Diff uv's tool dir listing against the requested (normalized)
          # names and uninstall whatever isn't requested anymore. Kept tools
          # are left for the install/upgrade step below.
          uvToolDir=$(${uvBin} tool dir)
          if [ -d "$uvToolDir" ]; then
            ls -1 "$uvToolDir" | sort -u \
              | comm -23 - <(printf '%s\n' ${escapeShellArgs toolKeep} | sort -u) \
              | while read -r uvTool; do
                  run ${uvBin} tool uninstall $VERBOSE_ARG "$uvTool"
                done
          fi
        ''}
        ${concatMapStringsSep "\n" (
          t: "run ${uvBin} tool install $VERBOSE_ARG ${escapeShellArg t}"
        ) toolCfg.packages}
        ${optionalString (toolCfg.packages != [ ]) ''
          run ${uvBin} tool upgrade $VERBOSE_ARG ${escapeShellArgs toolCfg.packages}
        ''}
      ''
    );
  };
}
