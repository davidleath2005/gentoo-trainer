#!/usr/bin/env bash
# Module: 04 — Download, Verify, and Extract Stage3
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage

STAGE3_INIT="openrc"  # openrc | systemd

module_04_stage3() {
    show_chapter_header "Chapter 4" "Installing the Stage3 Tarball" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage"

    require_live

    # ── Step 4.1 — choose variant ───────────────────────────────────────────
    show_step 1 "Choose the stage3 variant"
    show_tip "The stage3 tarball is a minimal pre-built Gentoo base system. You choose between OpenRC (traditional init) and systemd. OpenRC is the Gentoo default and recommended for new users."

    show_menu "Choose init system" \
        "OpenRC  — traditional Gentoo init system (recommended)" \
        "systemd — popular on many other distributions"
    if [[ "$MENU_CHOICE" == "1" ]]; then
        STAGE3_INIT="openrc"
    else
        STAGE3_INIT="systemd"
    fi
    save_progress "STAGE3_INIT" "$STAGE3_INIT"

    run_or_type "cd /mnt/gentoo" \
        "Change to the /mnt/gentoo directory. All stage3 files will be downloaded here."

    show_tip "The stage3 is hosted at downloads.gentoo.org. We use the latest-stage3 symlink to always get the most recent release. Replace the URL with the actual .tar.xz link shown on the Gentoo download page for accuracy."

    local base_url="https://distfiles.gentoo.org/releases/amd64/autobuilds"
    local latest_file

    if [[ "$STAGE3_INIT" == "openrc" ]]; then
        latest_file="latest-stage3-amd64-openrc.txt"
    else
        latest_file="latest-stage3-amd64-systemd.txt"
    fi

    run_or_type "curl -L ${base_url}/${latest_file} | grep -v '^#' | awk '{print \$1}'" \
        "Fetch the manifest file to find the current stage3 filename. The result is the relative path to the tarball." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Downloading_the_stage_tarball"

    echo ""
    echo -e "  ${YELLOW}Please enter the stage3 filename shown above (e.g. 20250101T170321Z/stage3-amd64-openrc-20250101T170321Z.tar.xz):${RESET}"
    printf "  Stage3 path: "
    local stage3_path
    read -r stage3_path
    save_progress "STAGE3_PATH" "$stage3_path"

    run_or_type "wget ${base_url}/${stage3_path}" \
        "Download the stage3 tarball. wget shows a progress bar during the download. This file is typically 150-250 MB." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Downloading_the_stage_tarball"

    run_or_type "wget ${base_url}/${stage3_path}.DIGESTS" \
        "Download the DIGESTS file which contains checksums to verify the tarball's integrity."
    mark_step_complete "04.1"

    # ── Step 4.2 — verify checksum ──────────────────────────────────────────
    show_step 2 "Verify the stage3 checksum"
    show_tip "Always verify checksums before extracting archives. A corrupt or tampered tarball could break your installation in hard-to-diagnose ways."

    local tarball
    tarball=$(basename "$stage3_path")

    run_or_type "grep \"\$(sha512sum \"${tarball}\")\" ${tarball}.DIGESTS" \
        "Compute the SHA-512 hash of the downloaded tarball and check it against the DIGESTS file. If the command prints a matching line, the file is good." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Verifying_the_downloaded_files"
    mark_step_complete "04.2"

    # ── Step 4.3 — extract ──────────────────────────────────────────────────
    show_step 3 "Extract the stage3 tarball"
    show_tip "The --xattrs-include flag preserves extended attributes (used by Portage). --numeric-owner preserves numeric UIDs/GIDs, which is safer than relying on usernames that may not exist yet."

    run_or_type "tar xpvf /mnt/gentoo/${tarball} --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo" \
        "Extract the stage3 tarball into /mnt/gentoo. This creates the base Gentoo filesystem hierarchy." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage#Unpacking_the_stage_tarball"
    mark_step_complete "04.3"

    log_success "Module 04 — Stage3 installation complete."
}
