{
  # Also the git credential helper for github.com, so HTTPS pushes work on
  # typhon too. ~/.config/gh/hosts.yml (the token) stays unmanaged.
  flake.modules.homeManager.base.programs.gh = {
    enable = true;
    settings.aliases.co = "pr checkout";
  };
}
