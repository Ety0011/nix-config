{
  flake.modules.darwin.base.system.defaults = {
    dock = {
      autohide = true;
      show-recents = false;
      mru-spaces = false;
      orientation = "bottom";
      minimize-to-application = true;
    };
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "clmv";
      ShowPathbar = true;
      ShowStatusBar = true;
      FXEnableExtensionChangeWarning = false;
    };
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      ApplePressAndHoldEnabled = false;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false;
    };
  };
}
