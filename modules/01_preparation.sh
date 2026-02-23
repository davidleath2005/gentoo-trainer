#!/usr/bin/env bash
# Module: 01 — Preparation
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media

module_01_preparation() {
    show_chapter_header "Chapter 1" "Preparation" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media"

    # ── Step 1.1 — verify root ──────────────────────────────────────────────
    show_step 1 "Verify we are running as root"
    show_tip "All installation commands require root privileges. The live CD boots you as root automatically."
    check_root
    log_success "Running as root."
    mark_step_complete "01.1"

    # ── Step 1.2 — check date/time ──────────────────────────────────────────
    show_step 2 "Verify system date and time"
    show_tip "An incorrect system clock causes SSL certificate errors when downloading files. Always check the date before continuing."

    run_or_type "date" \
        "Display the current system date and time. Verify it looks correct — SSL/TLS downloads will fail if the clock is badly wrong." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media#Verify_the_system_date_and_time"

    echo ""
    printf "  Does the date look correct? [Y/n]: "
    local date_ok
    read -r date_ok
    if [[ "${date_ok,,}" == "n" ]]; then
        run_or_type "ntpd -gq" \
            "Synchronise the system clock using NTP (Network Time Protocol). The -g flag allows large time corrections; -q quits after the first sync." \
            "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media#Optional:_Syncing_the_clock"
    fi
    mark_step_complete "01.2"

    # ── Step 1.3 — overview ─────────────────────────────────────────────────
    show_step 3 "Installation overview"
    show_tip "Understanding the big picture helps you follow the details. The Gentoo installation has these major phases."
    cat <<'EOF'

  Gentoo Installation Overview
  ─────────────────────────────
  1. Partition & format the target disk
  2. Download and extract the stage3 tarball (the base system)
  3. Configure make.conf (compiler flags, USE flags)
  4. Chroot into the new system
  5. Sync Portage and select a profile
  6. Configure timezone and locale
  7. Build or install a kernel
  8. Generate /etc/fstab
  9. Configure networking
  10. Install system tools (logger, cron, etc.)
  11. Install and configure GRUB bootloader
  12. Create users
  13. Reboot into your new Gentoo system!

EOF
    pause_and_continue
    mark_step_complete "01.3"

    log_success "Module 01 — Preparation complete."
}
