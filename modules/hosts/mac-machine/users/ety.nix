{ inputs, ... }:
{
  # TODO: why is this called ety when its clearly just users in this host?
  flake.modules.darwin."Etiennes-MacBook-Pro" = {
    imports = with inputs.self.modules.darwin; [
      ety
    ];
  };
}
