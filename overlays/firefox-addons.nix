{ inputs }:
final: prev: {
  firefox-addons = prev.callPackage inputs.firefox-addons { };
}
