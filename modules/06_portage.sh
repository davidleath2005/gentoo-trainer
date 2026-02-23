#!/usr/bin/env bash
# Module: 06 — Portage Configuration
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Portage

module_06_portage() {
    show_chapter_header "Chapter 6" "Configuring Portage" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Portage"

    # ── Step 6.1 — sync portage tree ────────────────────────────────────────
    show_step 1 "Sync the Portage tree"
    show_tip "emerge-webrsync downloads a snapshot of the entire Portage tree. It is faster than emerge --sync for a first sync. After the initial sync, use 'emerge --sync' for incremental updates."

    run_or_type "emerge-webrsync" \
        "Download and install the latest Portage tree snapshot. This may take a few minutes depending on your connection speed." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Portage#Getting_the_Portage_tree"

    run_or_type "eselect news list" \
        "List all Portage news items. News items contain important information about breaking changes or required actions." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Portage#Reading_news_items"

    run_or_type "eselect news read new" \
        "Read any unread Portage news items. Address any action items before continuing."
    mark_step_complete "06.1"

    # ── Step 6.2 — select profile ───────────────────────────────────────────
    show_step 2 "Select a Portage profile"
    show_tip "A Portage profile sets defaults for USE flags, CFLAGS, and package masks. Choose a profile that matches your intended use case. 'default/linux/amd64/23.0' is the standard desktop profile."

    run_or_type "eselect profile list" \
        "Display all available Portage profiles. The active profile is marked with an asterisk." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Portage#Choosing_the_right_profile"

    echo ""
    printf "  Enter the profile number to activate (e.g. 1): "
    local profile_num
    read -r profile_num

    run_or_type "eselect profile set ${profile_num}" \
        "Activate the selected profile. This configures the default USE flags and package settings for the chosen environment."
    mark_step_complete "06.2"

    # ── Step 6.3 — update @world ────────────────────────────────────────────
    show_step 3 "Update the @world set"
    show_tip "After setting a new profile it is good practice to rebuild the world set. This ensures all installed packages reflect the new profile's settings. On a fresh stage3 this mainly updates the profile-specified packages."

    run_or_type "emerge --ask --verbose --update --deep --newuse @world" \
        "Update all installed packages, taking into account new USE flag settings and profile changes. This may take a while to compile." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Portage#Updating_the_%40world_set"
    mark_step_complete "06.3"

    log_success "Module 06 — Portage configuration complete."
}
