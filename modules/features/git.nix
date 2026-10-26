{
  flake.modules.homeManager.base = {
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
