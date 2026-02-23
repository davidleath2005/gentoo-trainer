#!/usr/bin/env bash
# Module: 14 — Finalize and Reboot
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing

module_14_finalize() {
    show_chapter_header "Chapter 14" "Finalize and Reboot" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing"

    # ── Step 14.1 — show installation summary ────────────────────────────────
    show_step 1 "Installation summary"

    local hostname username init_system chosen_fs kernel_method target_disk
    hostname=$(load_progress "HOSTNAME")
    username=$(load_progress "USERNAME")
    init_system=$(load_progress "STAGE3_INIT")
    chosen_fs=$(load_progress "CHOSEN_FS")
    kernel_method=$(load_progress "KERNEL_METHOD")
    target_disk=$(load_progress "TARGET_DISK")

    local kernel_label
    case "$kernel_method" in
        1) kernel_label="Distribution kernel (binary)" ;;
        2) kernel_label="Genkernel (automated compile)" ;;
        3) kernel_label="Manual configuration"         ;;
        *) kernel_label="Unknown"                       ;;
    esac

    echo ""
    echo -e "${BOLD}${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${GREEN}║  🎉  Installation Summary                                ║${RESET}"
    echo -e "${BOLD}${GREEN}╠══════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${GREEN}║${RESET}  Hostname    : ${hostname:-not set}"
    echo -e "${BOLD}${GREEN}║${RESET}  User        : ${username:-not set}"
    echo -e "${BOLD}${GREEN}║${RESET}  Init system : ${init_system:-openrc}"
    echo -e "${BOLD}${GREEN}║${RESET}  Filesystem  : ${chosen_fs:-ext4}"
    echo -e "${BOLD}${GREEN}║${RESET}  Kernel      : ${kernel_label}"
    echo -e "${BOLD}${GREEN}║${RESET}  Boot mode   : ${HW_BOOT_MODE:-unknown}"
    echo -e "${BOLD}${GREEN}║${RESET}  Target disk : ${target_disk:-unknown}"
    echo -e "${BOLD}${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    mark_step_complete "14.1"

    # ── Step 14.2 — exit chroot, unmount, and reboot ─────────────────────────
    show_step 2 "Exit chroot, unmount filesystems, and reboot"
    show_tip "Before rebooting, exit the chroot and unmount all filesystems cleanly. This ensures filesystem journals are flushed and no data is lost."

    run_or_type "exit" \
        "Exit the chroot environment and return to the live CD shell." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing#Exiting_the_chrooted_environment"

    echo ""
    echo -e "  ${YELLOW}Run the following commands from the live CD shell (outside chroot):${RESET}"
    echo ""
    echo -e "  ${GREEN}\$ umount -l /mnt/gentoo/dev{/shm,/pts,}${RESET}"
    echo -e "  ${GREEN}\$ umount -R /mnt/gentoo${RESET}"
    echo -e "  ${GREEN}\$ reboot${RESET}"
    echo ""

    run_or_type "umount -l /mnt/gentoo/dev{/shm,/pts,}" \
        "Lazily unmount the /dev sub-mounts inside the chroot. The -l (lazy) flag defers unmounting until the filesystem is no longer busy."

    run_or_type "umount -R /mnt/gentoo" \
        "Recursively unmount all filesystems mounted under /mnt/gentoo."

    echo ""
    echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════╗${RESET}"
    echo -e "${BOLD}${CYAN}  ║  🎉  Congratulations! Gentoo installation complete!  ║${RESET}"
    echo -e "${BOLD}${CYAN}  ╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  Your first boot checklist:                           ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  ✔ Log in as root (or your new user)                  ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  ✔ Verify network: ping gentoo.org                    ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  ✔ Update the system: emerge -uDN @world               ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  ✔ Review /var/log/messages for any issues             ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ╠══════════════════════════════════════════════════════╣${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  Next steps (optional):                               ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  • Install a desktop: emerge plasma-meta / gnome-meta  ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  • Install X.org: emerge xorg-server                   ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ║${RESET}  • Read the Gentoo wiki: wiki.gentoo.org               ${BOLD}${CYAN}║${RESET}"
    echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════╝${RESET}"
    echo ""

    printf "  Type %bReboot%b to restart into your new Gentoo system: " "${BOLD}" "${RESET}"
    local input
    read -r input
    if [[ "$input" == "Reboot" || "$input" == "reboot" ]]; then
        log_info "Rebooting..."
        reboot
    else
        log_info "Run 'reboot' when you are ready to restart."
    fi
    mark_step_complete "14.2"

    log_success "Module 14 — Finalization complete. Enjoy your Gentoo system!"
}
