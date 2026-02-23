#!/usr/bin/env bash
# Module: 07 — Timezone and Locale
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Timezone

module_07_timezone_locale() {
    show_chapter_header "Chapter 7" "Timezone and Locale" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Timezone"

    # ── Step 7.1 — set timezone ─────────────────────────────────────────────
    show_step 1 "Configure timezone"
    show_tip "The timezone is stored as a symlink in /etc/localtime. Valid timezone names are files under /usr/share/zoneinfo/ (e.g. America/New_York, Europe/London, UTC)."

    run_or_type "ls /usr/share/zoneinfo" \
        "List the available timezone regions. Choose a region directory, then list its contents to find your specific timezone."

    echo ""
    printf "  Enter your timezone (e.g. America/New_York or UTC): "
    local timezone
    read -r timezone
    save_progress "TIMEZONE" "$timezone"

    run_or_type "echo \"${timezone}\" > /etc/timezone" \
        "Write the timezone name to /etc/timezone. Portage uses this file when you run emerge to configure packages." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Timezone"

    run_or_type "emerge --config sys-libs/timezone-data" \
        "Apply the timezone setting by regenerating /etc/localtime from the timezone-data package."
    mark_step_complete "07.1"

    # ── Step 7.2 — configure locale ─────────────────────────────────────────
    show_step 2 "Configure locale"
    show_tip "Locales define language, character encoding, and formatting. UTF-8 encoding is strongly recommended. The format is: <language>_<territory>.<encoding> (e.g. en_US.UTF-8)."

    run_or_type "nano /etc/locale.gen" \
        "Edit /etc/locale.gen to uncomment the locales you need. For example, uncomment 'en_US.UTF-8 UTF-8'. Save and exit with Ctrl+O, Ctrl+X." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Locale_generation"

    run_or_type "locale-gen" \
        "Generate all locales listed in /etc/locale.gen. This compiles the locale data files."

    run_or_type "eselect locale list" \
        "Show available locales for the LANG variable."

    echo ""
    printf "  Enter the locale number to set as default (e.g. 4): "
    local locale_num
    read -r locale_num

    run_or_type "eselect locale set ${locale_num}" \
        "Set the system-wide default locale (LANG variable)."

    run_or_type "env-update && source /etc/profile" \
        "Apply the locale and environment changes to the current shell session."
    mark_step_complete "07.2"

    # ── Step 7.3 — set hostname ─────────────────────────────────────────────
    show_step 3 "Set hostname"
    show_tip "The hostname identifies your machine on a network. Choose a short, lowercase name with no spaces (e.g. 'mygentoo')."

    echo ""
    printf "  Enter the desired hostname: "
    local hostname
    read -r hostname
    save_progress "HOSTNAME" "$hostname"

    run_or_type "echo \"${hostname}\" > /etc/hostname" \
        "Write the hostname to /etc/hostname. This file is read by systemd or OpenRC at boot." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Hostname"
    mark_step_complete "07.3"

    log_success "Module 07 — Timezone and locale configuration complete."
}
