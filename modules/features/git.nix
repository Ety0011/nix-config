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
      # Only files no repo ever tracks. Never .envrc, .env, .vscode/, .venv:
      # a global match silently drops a file from every repo and template
      # (docs/research/gitignore.md §3.2). Each repo's .gitignore lists the rest.
      ignores = [ ".DS_Store" ];
      settings = {
        init.defaultBranch = "main";
        pull.rebase = false;
        push.autoSetupRemote = true;
      };
    };
  };
}
