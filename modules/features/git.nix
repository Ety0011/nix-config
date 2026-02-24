{ ... }:
let
  userName = "Etienne";
  userEmail = "etienne.orio@orio.ch";
in
{
  flake.modules.homeManager.git = {
    programs.delta = {
      enable = true;
      enableGitIntegration = true; # now must be explicit
    };

    programs.git = {
      enable = true;
      ignores = [
        ".direnv/"
        ".envrc"
        ".venv/"
        ".DS_Store"
        "*.swp"
      ];

      settings = {
        # replaces extraConfig
        user = {
          name = userName; # replaces userName
          email = userEmail; # replaces userEmail
        };
        init.defaultBranch = "main";
        pull.rebase = false;
        push.autoSetupRemote = true;
      };
    };
  };
}
