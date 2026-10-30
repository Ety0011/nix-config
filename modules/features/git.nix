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
      # No global ignores: each repo's .gitignore says what it skips, so
      # collaborators and `nix flake init` see the same files you do.
      settings = {
        init.defaultBranch = "main";
        pull.rebase = false;
        push.autoSetupRemote = true;
      };
    };
  };
}
