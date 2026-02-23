_:
final: prev: {
  pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
    (python-final: python-prev: {
      setproctitle = python-prev.setproctitle.overrideAttrs (old: {
        doCheck = false;
        doInstallCheck = false;
      });
    })
  ];
}
