{ vars, ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = vars.gitUserName;
        email = vars.gitUserEmail;
      };
      init.defaultBranch = "main";
      pull.rebase = false;
    };
    ignores = [
      ".direnv/"
      ".envrc"
      ".venv/"
      ".DS_Store"
    ];
  };
}
