{ hostVars, ... }:
{
  system = {
    defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "bottom";
      };
      finder = {
        AppleShowAllExtensions = true;
        FXPreferredViewStyle = "clmv";
        ShowPathbar = true;
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
      };
    };

    stateVersion = hostVars.stateVersion;
  };
}
