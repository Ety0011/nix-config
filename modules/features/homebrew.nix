{
  flake.modules.darwin.base = {
    homebrew.enable = true;
    # Keep "none" until every cask and brew on helios is declared; anything
    # stricter uninstalls what is missing.
    homebrew.onActivation.cleanup = "none";
    environment.systemPath = [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ];
  };
}
