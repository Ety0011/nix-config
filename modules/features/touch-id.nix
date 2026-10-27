{
  # Writes /etc/pam.d/sudo_local, which survives macOS updates.
  flake.modules.darwin.base.security.pam.services.sudo_local.touchIdAuth = true;
}
