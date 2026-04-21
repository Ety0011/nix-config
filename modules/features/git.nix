{ ... }:
{
  # Generic git feature module — no hardcoded identity.
  # Each user module sets programs.git.settings.user.name / .email separately.
  flake.modules.homeManager.git = {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
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
        init.defaultBranch = "main";
        pull.rebase = false;
        push.autoSetupRemote = true;
      };
    };
  };
}
