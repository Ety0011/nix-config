{ inputs, ... }:
let
  userName = "ety";
in
{
  flake.modules.nixos.${userName} = {
    users.users.${userName} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
    };
    home-manager.users.${userName}.imports = [
      inputs.self.modules.homeManager.${userName}
    ];
  };

  flake.modules.darwin.${userName} = {
    system.primaryUser = userName;
    users.users.${userName} = {
      name = userName;
      home = "/Users/${userName}";
    };
    home-manager.users.${userName}.imports = [
      inputs.self.modules.homeManager.${userName}
    ];

    homebrew = {
      enable = true;
      onActivation.cleanup = "zap"; # Optional: removes apps not in this list
      brews = [
        "direnv"
      ];
      casks = [
        "unity-hub"
        "microsoft-teams"
      ];
    };
  };

  flake.modules.homeManager.${userName} =
    {
      pkgs,
      lib,
      ...
    }:
    {
      home.username = lib.mkDefault userName;
      home.homeDirectory = lib.mkDefault (
        if pkgs.stdenv.isDarwin then "/Users/${userName}" else "/home/${userName}"
      );
      home.stateVersion = "24.11";
      programs.home-manager.enable = true;

      home.packages = with pkgs; [
        nixfmt
        lldb
      ];
      imports = with inputs.self.modules.homeManager; [
        cli
      ];
    };
}
