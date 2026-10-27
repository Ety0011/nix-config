{
  flake.modules.darwin.base = {
    homebrew.enable = true;
    # `brew shellenv` plus Homebrew's zsh completions (docker, colima).
    homebrew.enableZshIntegration = true;
    # Anything installed but not declared is removed on switch. Not "zap":
    # that also deletes app settings and data.
    homebrew.onActivation.cleanup = "uninstall";
    environment.systemPath = [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ];
  };
}
