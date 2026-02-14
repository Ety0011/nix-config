{
  description = "Ety nix-darwin system flake";

  # --- INPUTS ---
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util.url = "github:hraban/mac-app-util";
  };

  # --- OUTPUTS ---
  # This function takes the inputs above and produces the actual system configuration.
  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      home-manager,
      mac-app-util,
      ...
    }:
    let
      # --- 1. FIND HOSTS ---
      # Dinamically find every host using the folder name

      hostsDir = ./hosts;

      # builtins.readDir returns a list of files and their types (file or directory).
      # Filter this list to keep ONLY directories.
      rawHostList = nixpkgs.lib.filterAttrs (name: type: type == "directory") (builtins.readDir hostsDir);

      # Get just the names of the folders (e.g., ["Etiennes-MacBook-Pro"])
      hostNames = builtins.attrNames rawHostList;

      # --- 2. THE BUILDER FUNCTION ---
      # This function runs once for every host name found above.
      # It creates the specific configuration for that machine.
      makeSystem =
        hostname:
        let
          # IMPORT VARIABLES
          # We read the 'variables.nix' file inside the specific host folder.
          # This gives us access to vars.user, vars.system, etc.
          vars = import "${hostsDir}/${hostname}/variables.nix";
        in
        nix-darwin.lib.darwinSystem {
          # Use the CPU architecture defined in variables.nix (e.g., "aarch64-darwin")
          system = vars.system;

          # PASS VARIABLES DOWN
          # This is the "magic" that lets other files see your variables.
          # We pass 'vars' so modules/darwin/default.nix can say "networking.hostName = vars.hostname"
          specialArgs = {
            inherit inputs self vars;
          };

          modules = [
            # A. Common Configuration
            # This applies to every computer you own (networking logic, nix settings)
            ./modules/darwin

            # B. Host-Specific Configuration
            # This imports the specific configuration.nix for THIS computer.
            # It installs machine-specific packages (Docker, etc.) and sets the State Version.
            ./hosts/${hostname}/configuration.nix

            # C. Utilities
            # Helper to make spotlight work with Nix apps
            mac-app-util.darwinModules.default

            # D. Home Manager
            # This sets up your personal environment (dotfiles, shell)
            home-manager.darwinModules.home-manager
            (
              { pkgs, ... }:
              {
                home-manager.sharedModules = [
                  mac-app-util.homeManagerModules.default
                ];
                home-manager.useGlobalPkgs = true;
                home-manager.useUserPackages = true;
                home-manager.backupFileExtension = "backup"; # IDEA: I would change it to "hm-backup" or something similar to be more clear

                # We must pass 'vars' to Home Manager too, so it knows your username!
                home-manager.extraSpecialArgs = { inherit inputs vars; };

                # Dynamically configure the user
                # This says: "Configure the user named [vars.user] using the file at ./modules/home-manager"
                home-manager.users.${vars.user} = import ./modules/home-manager;
              }
            )
          ];
        };
    in
    {
      # --- FINAL OUTPUT ---
      # nixpkgs.lib.genAttrs takes our list of hostnames and runs 'makeSystem' for each one.
      # The result is a set of configurations: { Etiennes-MacBook-Pro = ...; }
      darwinConfigurations = nixpkgs.lib.genAttrs hostNames makeSystem;
    };
}
