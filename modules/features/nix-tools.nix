{ ... }:
{
  # Nix development tooling as its own feature so it can be imported
  # independently from the rest of the CLI stack.
  flake.modules.homeManager.nixTools =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        nixd # Nix language server
        nixfmt-rfc-style # canonical nixfmt (RFC 166)
      ];
    };
}
