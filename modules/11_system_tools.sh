#!/usr/bin/env bash
# Module: 11 — System Tools
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools

module_11_system_tools() {
    show_chapter_header "Chapter 11" "System Tools Installation" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools"

    local init_system
    init_system=$(load_progress "STAGE3_INIT")
    init_system="${init_system:-openrc}"

    # ── Step 11.1 — system logger ────────────────────────────────────────────
    show_step 1 "Install a system logger"
    show_tip "The system logger collects messages from the kernel and running services, writing them to log files in /var/log. Without a logger, important messages are lost after reboot."

    show_menu "Choose a system logger" \
        "sysklogd — classic, minimal logger (recommended for beginners)" \
        "syslog-ng — modern, powerful logger with filtering support"
    local logger_choice="$MENU_CHOICE"

    case "$logger_choice" in
        1)
            run_or_type "emerge --ask app-admin/sysklogd" \
                "Install sysklogd, the traditional Unix system logger." \
                "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools#System_logger"
            if [[ "$init_system" == "openrc" ]]; then
                run_or_type "rc-update add sysklogd default" \
                    "Enable sysklogd to start at boot."
            else
                run_or_type "systemctl enable sysklogd" \
                    "Enable sysklogd to start at boot under systemd."
            fi
            ;;
        2)
            run_or_type "emerge --ask app-admin/syslog-ng" \
                "Install syslog-ng, a modern and highly configurable system logger."
            if [[ "$init_system" == "openrc" ]]; then
                run_or_type "rc-update add syslog-ng default" \
                    "Enable syslog-ng to start at boot."
            else
                run_or_type "systemctl enable syslog-ng" \
                    "Enable syslog-ng to start at boot under systemd."
            fi
            ;;
    esac
    mark_step_complete "11.1"

    # ── Step 11.2 — cron daemon ──────────────────────────────────────────────
    show_step 2 "Install a cron daemon (optional)"
    show_tip "Cron runs scheduled tasks at specified times. It is useful for automated maintenance tasks like log rotation and package updates. On minimal servers, you can skip it."

    printf "  Install a cron daemon? [Y/n]: "
    local install_cron
    read -r install_cron
    if [[ "${install_cron,,}" != "n" ]]; then
        run_or_type "emerge --ask sys-process/cronie" \
            "Install cronie, a modern cron daemon compatible with traditional cron syntax." \
            "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools#Cron_daemon"
        if [[ "$init_system" == "openrc" ]]; then
            run_or_type "rc-update add cronie default" \
                "Enable cronie to start at boot."
        else
            run_or_type "systemctl enable cronie" \
                "Enable cronie to start at boot under systemd."
        fi
    fi
    mark_step_complete "11.2"

    # ── Step 11.3 — filesystem and networking tools ──────────────────────────
    show_step 3 "Install filesystem and networking tools"
    show_tip "These utility packages provide essential tools like e2fsck (ext4 filesystem checking), xfsprogs (XFS tools), and various network utilities."

    local chosen_fs
    chosen_fs=$(load_progress "CHOSEN_FS")
    chosen_fs="${chosen_fs:-ext4}"

    case "$chosen_fs" in
        ext4)
            run_or_type "emerge --ask sys-fs/e2fsprogs" \
                "Install e2fsprogs: tools for ext2/ext3/ext4 filesystems including e2fsck, resize2fs, and tune2fs." \
                "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools#Filesystem_tools"
            ;;
        xfs)
            run_or_type "emerge --ask sys-fs/xfsprogs" \
                "Install xfsprogs: tools for XFS filesystems including xfs_repair and xfs_growfs."
            ;;
        btrfs)
            run_or_type "emerge --ask sys-fs/btrfs-progs" \
                "Install btrfs-progs: tools for Btrfs filesystems including btrfs check and btrfs balance."
            ;;
    esac

    run_or_type "emerge --ask net-misc/wget net-misc/curl" \
        "Install wget and curl — essential tools for downloading files from the internet."
    mark_step_complete "11.3"

    log_success "Module 11 — System tools installation complete."
}
