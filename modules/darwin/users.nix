{ vars, hostname, ... }:
{
  system.primaryUser = vars.username;
  users.users.${vars.username} = {
    name = vars.username;
    home = "/Users/${vars.username}";
  };
}
