{ pkgs, username, ... }:

{
  imports = [
    ./shell.nix
    ./git.nix
    ./vscode.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    
    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    stateVersion = "25.05";

    # Home packages
    packages = with pkgs; [
      direnv
      nix-direnv
      nixfmt-rfc-style # Nix formatter binary
      vscode
    ];
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
