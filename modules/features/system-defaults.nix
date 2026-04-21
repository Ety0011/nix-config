{ ... }:
{
  flake.modules.darwin.system-defaults = {
    system.defaults = {
      dock = {
        autohide = true;
        show-recents = false;
        orientation = "bottom";
        minimize-to-application = true;
      };

      finder = {
        AppleShowAllExtensions = true;
        AppleShowAllFiles = true;
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
        ApplePressAndHoldEnabled = false; # key repeat instead of accent menu
        NSAutomaticSpellingCorrectionEnabled = false;
        NSAutomaticCapitalizationEnabled = false;
        NSAutomaticDashSubstitutionEnabled = false;
        NSAutomaticQuoteSubstitutionEnabled = false;
      };
    };
  };
}
