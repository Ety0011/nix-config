{ lib, ... }:
{
  flake.modules.darwin.base = {
    homebrew.enable = true;
    # Anything installed but not declared is removed on switch. Not "zap":
    # that also deletes app settings and data.
    homebrew.onActivation.cleanup = "uninstall";
    # After the Nix profiles (order 1000), before /usr/local/bin and Apple's
    # dirs (1200): a brew dependency never shadows a Nix tool (docs/adr/0003).
    # This is the PATH for every shell and VS Code task. Not
    # `homebrew.enableZshIntegration`: its `brew shellenv` puts Homebrew first.
    environment.systemPath = lib.mkOrder 1100 [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ];
    # Homebrew's zsh completions (docker, colima), behind Nix's. /etc/zshrc
    # runs before Home Manager's compinit in ~/.zshrc.
    programs.zsh.interactiveShellInit = "fpath+=(/opt/homebrew/share/zsh/site-functions)";
  };
}
