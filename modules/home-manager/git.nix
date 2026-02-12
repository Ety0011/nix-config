{ ... }:

{
  # Git configuration
  programs.git = {
    enable = true;
    userName = "Etienne Orio";
    userEmail = "etienne.orio@orio.ch";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };
}
