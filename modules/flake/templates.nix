# Project templates: `nix flake init -t ~/nix-config#python`. The files live in
# ../../templates, outside modules/, so import-tree never imports them. All
# templates go in this one file: `flake.templates` has no merging option, so a
# second definition elsewhere is an error. Reasons: docs/research/dev-env.md.
{
  flake.templates.python = {
    path = ../../templates/python;
    description = "Python project: Nix supplies uv, uv supplies Python and the dependencies";
    welcomeText = ''
      # Python project

      Next steps:

      ```sh
      direnv allow         # loads uv from flake.nix
      uv init --app        # or --lib; writes pyproject.toml
      uv add --dev ruff basedpyright pytest
      ```

      `.python-version` sets the Python version for uv here and in CI.
    '';
  };
}
