_: {
  # Headless-server power policy for this M1 in clamshell mode.
  #
  # On Apple Silicon, `pmset disablesleep 1` is the only setting that defeats
  # lid-close sleep with no external display — nix-darwin's native power.sleep.*
  # module uses `systemsetup`, which can't set it. Activation scripts run as
  # root, so pmset works without sudo. pmset values persist across reboot; the
  # activation script re-asserts them idempotently (also covers OS upgrades).
  #
  # The Mac stays awake but the display still sleeps (displaysleep is left
  # untouched — system sleep and display sleep are independent).
  #
  # Host-specific (lives here, not in modules/), matching the per-host stack
  # layout already used by llama-cpp.nix / meridian.nix.
  configurations.darwin."lkshrsch-mb-pro-m1".module = _: {
    # Native nix-darwin power module (systemsetup-based). System sleep only —
    # deliberately NOT setting `display` so the screen still sleeps.
    power.sleep = {
      computer = "never";
      harddisk = "never";
    };
    # NOTE: do NOT set power.restartAfterPowerFailure here — nix-darwin's
    # system/checks.nix aborts activation on notebooks ("Not supported").

    # The actual fix: pmset keys nix-darwin doesn't expose. `-a` = all power
    # sources. disablesleep is the load-bearing one for clamshell — it's the
    # only setting currently missing (SleepDisabled is 0 today). We leave
    # `displaysleep` alone so the screen keeps sleeping on its own timer.
    #
    # Must use the `postActivation` hook: nix-darwin only concatenates a fixed
    # set of named activation fragments into the root `activate` script, so an
    # arbitrary name would be silently dropped. postActivation runs as root.
    system.activationScripts.postActivation.text = ''
      echo "configuring headless power policy via pmset..." >&2
      /usr/bin/pmset -a disablesleep 1   # master veto: lid-close no longer sleeps the Mac
      /usr/bin/pmset -a sleep 0          # no idle system sleep
      /usr/bin/pmset -a disksleep 0      # don't spin down disk
      /usr/bin/pmset -a ttyskeepawake 1  # stay awake while an ssh/tty session is active
      /usr/bin/pmset -a womp 1           # wake on Ethernet magic packet (safety net)
      /usr/bin/pmset -a tcpkeepalive 1   # keep TCP alive (irrelevant once never sleeping, but safe)
      # NOTE: displaysleep intentionally left untouched — the screen should still sleep.
    '';

    # Redundant fallback: caffeinate as a root daemon, relaunched if it dies.
    # Largely redundant once the machine never sleeps, but requested as
    # belt-and-suspenders. -s prevents system sleep (AC only), -i idle system
    # sleep, -m disk. Deliberately NO `-d`, so the display still sleeps.
    launchd.daemons.caffeinate.serviceConfig = {
      ProgramArguments = [
        "/usr/bin/caffeinate"
        "-s"
        "-i"
        "-m"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      StandardOutPath = "/Users/lkshrsch/Library/Logs/caffeinate.log";
      StandardErrorPath = "/Users/lkshrsch/Library/Logs/caffeinate.err.log";
    };
  };
}
