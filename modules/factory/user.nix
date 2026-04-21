{ self, ... }:
{
  # Factory Aspect: generates the triple of nixos / darwin / homeManager account
  # modules for a given username and admin flag.
  #
  # Usage in a user file (e.g. modules/users/ety/ety.nix):
  #
  #   flake.modules = lib.mkMerge [
  #     (self.factory.user "ety" true)
  #     {
  #       nixos.ety  = { /* host-specific extras */ };
  #       darwin.ety = { /* host-specific extras */ };
  #       homeManager.ety = { /* user-specific extras */ };
  #     }
  #   ];

  config.flake.factory.user =
    username: isAdmin:
    {
      nixos.${username} =
        { lib, pkgs, ... }:
        {
          users.users.${username} = {
            isNormalUser = true;
            home = "/home/${username}";
            extraGroups =
              [ "networkmanager" ]
              ++ lib.optionals isAdmin [ "wheel" ];
            shell = pkgs.zsh;
          };
          programs.zsh.enable = true;

          home-manager.users.${username} = {
            imports = [ self.modules.homeManager.${username} ];
          };
        };

      darwin.${username} =
        { lib, pkgs, ... }:
        {
          users.users.${username} = {
            name = username;
            home = "/Users/${username}";
            shell = pkgs.zsh;
          };

          system.primaryUser = lib.mkIf isAdmin username;

          programs.zsh.enable = true;

          home-manager.users.${username} = {
            imports = [ self.modules.homeManager.${username} ];
          };
        };

      homeManager.${username} = {
        home.username = username;
      };
    };
}
