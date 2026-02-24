{ inputs, ... }:
{
  flake.modules.nixos.cli = {
    imports = with inputs.self.modules.nixos; [
      nix-settings
      ssh
    ];
  };

  flake.modules.darwin.cli = {
    imports = with inputs.self.modules.darwin; [
      nix-settings
    ];
  };

  flake.modules.homeManager.cli =
    { pkgs, ... }:
    {
      imports = with inputs.self.modules.homeManager; [
        zsh
        git
        ssh
        direnv
        starship
      ];
      home.packages = with pkgs; [ vim ];
    };
}
