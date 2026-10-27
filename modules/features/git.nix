{
  flake.modules.homeManager.base = {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
    programs.git = {
      enable = true;
      # HM's pre-25.05 default writes an openpgp signing config and pulls in
      # gnupg. Nothing is signed today.
      signing.format = null;
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
