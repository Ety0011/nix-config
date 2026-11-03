{
  description = "C/C++ dev shell: Nix supplies the compiler, CMake, clangd and the libraries";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems =
        f: lib.genAttrs [ "aarch64-darwin" "x86_64-linux" ] (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (
        pkgs:
        let
          # Pinned above the nixpkgs default (LLVM 21): that version's ASan
          # hangs and its TSan crashes on macOS 26. All tools share this version.
          llvm = pkgs.llvmPackages_22;
        in
        {
          default = pkgs.mkShell.override { inherit (llvm) stdenv; } {
            packages = [
              llvm.clang-tools # clangd, clang-format, clang-tidy
              llvm.lldb
              pkgs.cmake
              pkgs.ninja
            ];

            # Libraries the project links; CMake finds them with find_package.
            buildInputs = [ ];

            # cc-wrapper's default flags are invisible in compile_commands.json
            # and change the build: -O2 on Debug builds, and -fwrapv, which
            # drops signed overflow from -fsanitize=undefined.
            hardeningDisable = [ "all" ];

            # DEVELOPER_DIR points at the Nix SDK, so lldb cannot find Apple's
            # debugserver on its own.
            shellHook = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
              export LLDB_DEBUGSERVER_PATH=/Library/Developer/CommandLineTools/Library/PrivateFrameworks/LLDB.framework/Versions/A/Resources/debugserver
            '';
          };
        }
      );

      # Outside git, treefmt would take its config's /nix/store folder as the
      # tree root and walk the whole store. Root it at this folder; run `nix fmt`
      # from nix/.
      formatter = forAllSystems (
        pkgs: pkgs.nixfmt-tree.override { settings.tree-root-file = "flake.nix"; }
      );
    };
}
