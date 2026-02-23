#!/usr/bin/env bash
# Module: 13 — Users and sudo
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing

module_13_users() {
    show_chapter_header "Chapter 13" "Users and sudo" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing"

    # ── Step 13.1 — create regular user ─────────────────────────────────────
    show_step 1 "Create a regular user account"
    show_tip "Running as root for daily tasks is dangerous — a typo can destroy your system. Create a regular user for everyday use. Add them to the 'wheel' group to allow sudo access."

    echo ""
    printf "  Enter the new username: "
    local username
    read -r username
    save_progress "USERNAME" "$username"

    run_or_type "useradd -m -G users,wheel,audio,video,usb,cdrom,portage -s /bin/bash ${username}" \
        "Create user '${username}' with a home directory (-m), added to common groups (-G), and using bash as their shell (-s /bin/bash)." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing#Adding_a_user_for_daily_use"

    run_or_type "passwd ${username}" \
        "Set the password for '${username}'. You will be prompted to enter and confirm it."
    mark_step_complete "13.1"

    # ── Step 13.2 — install sudo ─────────────────────────────────────────────
    show_step 2 "Install and configure sudo"
    show_tip "sudo allows a regular user to run commands with root privileges when needed. The 'wheel' group is conventionally given sudo access. Only grant sudo to trusted users."

    run_or_type "emerge --ask app-admin/sudo" \
        "Install sudo, the tool that allows users to run commands as root with proper authentication and logging." \
        "https://wiki.gentoo.org/wiki/Sudo"

    run_or_type "visudo" \
        "Open the sudoers file in a safe editor (visudo validates the file before saving). Uncomment the line '%wheel ALL=(ALL:ALL) ALL' to give wheel group members sudo access."

    echo ""
    echo -e "  ${BOLD}Security best practices:${RESET}"
    echo "  • Never share the root password — use sudo instead"
    echo "  • Regularly audit who is in the wheel group: 'getent group wheel'"
    echo "  • Review sudo logs in /var/log/auth.log or /var/log/messages"
    echo ""
    pause_and_continue
    mark_step_complete "13.2"

    log_success "Module 13 — Users and sudo configuration complete."
}
