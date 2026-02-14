{ vars, ... }:

{
  # Git configuration
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

    /*
      # IDEA: THis is an example on how you can set a system wide git ignore. Basically you don't have to put these in any more gitignore
      ignores = [
        ".direnv/"
        ".envrc"
        ".venv/"
        "result"
        "*.swp"
        ".DS_Store"
      ];
    */
  };
}
