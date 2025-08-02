### Key Improvements & Structure:

1. **Modular Design**:
   - Tagged tasks for selective execution
   - Handlers for service management
   - Error handling with `ignore_errors` where appropriate

2. **Kali-Specific Optimizations**:
   - Wayland compatibility maintained
   - Kernel hardening parameters applied
   - Driver installation for Alfa adapters
   - GRUB theme integration

3. **Security Enhancements**:
   - Fail2ban configuration with systemd backend
   - UFW firewall rules
   - Kernel parameter hardening
   - AppArmor enforcement

4. **Idempotency**:
   - Safe package installation with filtered lists
   - Conditional task execution
   - State management for services

5. **User Experience**:
   - Terminal emulator configuration (kitty)
   - Font installation
   - Theme customization
   - Dotfiles management with stow

### Usage Instructions:

1. **Save** as `ansible-bootstrap-kali.yml`
2. **Run** with:
   ```bash
   sudo apt update
   sudo apt install -y ansible git
   ansible-playbook ansible-bootstrap-kali.yml
   ```

### Post-Installation:

1. Reboot to apply:
   - Kernel parameters
   - GRUB theme
   - Driver changes
2. Verify Wayland session:
   ```bash
   echo $XDG_SESSION_TYPE
   ```
3. Check kernel hardening:
   ```bash
   sysctl -a | grep -e kptr_restrict -e dmesg_restrict
   ```

This playbook follows Kali's best practices while automating your entire bootstrap process. The structure allows easy maintenance and extension for future updates.
