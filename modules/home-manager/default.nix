{ pkgs, vars, ... }:
# TODO: Usually home-manager default options are put in a file called home.nix --> I would rename this file
{
  imports = [
    ./shell.nix
    ./git.nix
    ./vscode.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should manage
  home = {
    username = vars.user;
    homeDirectory = "/Users/${vars.user}"; # TODO: This is better put in flake.nix (you can look at mine)

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    stateVersion = "25.05";

    # Home packages
    packages = with pkgs; [
      nixfmt-rfc-style # IDEA: This package is not configurble with home-manager. I would move it to darwin/default.nix
      syncthing # IDEA: This package is not configurble with home-manager. I would move it to darwin/default.nix (or the host specific one)
      rectangle # IDEA: This package is not configurble with home-manager. I would move it to darwin/default.nix (or the host specific one)
    ];
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
