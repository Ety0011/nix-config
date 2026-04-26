{ inputs, ... }:
{
  flake.modules.darwin."Etiennes-MacBook-Pro" = {
    imports = with inputs.self.modules.darwin; [
      ety
    ];
  };
}
