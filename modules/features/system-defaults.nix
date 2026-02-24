{ ... }:
{
  flake.modules.darwin.system-defaults = {
    system.stateVersion = 6;

    system.defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "bottom";
        minimize-to-application = true; # cleaner dock
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true; # show hidden files
        FXPreferredViewStyle = "clmv"; # column view
        ShowPathbar = true;
        ShowStatusBar = true;
        FXEnableExtensionChangeWarning = false;
      };

      trackpad = {
        Clicking = true; # tap to click
        TrackpadThreeFingerDrag = true;
      };

      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        InitialKeyRepeat = 15;
        KeyRepeat = 2;
        ApplePressAndHoldEnabled = false; # allows key repeat instead of accent menu
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
      };
    };
  };
}
