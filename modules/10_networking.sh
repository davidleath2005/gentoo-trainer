#!/usr/bin/env bash
# Module: 10 — System Networking Configuration
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Networking_information

module_10_networking() {
    show_chapter_header "Chapter 10" "System Networking Configuration" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Networking_information"

    # ── Step 10.1 — configure /etc/hosts ────────────────────────────────────
    show_step 1 "Configure /etc/hosts"
    show_tip "/etc/hosts maps hostnames to IP addresses locally, before DNS is consulted. At minimum, add an entry for your own hostname so local processes can resolve it."

    local hostname
    hostname=$(load_progress "HOSTNAME")
    hostname="${hostname:-mygentoo}"

    run_or_type "nano /etc/hosts" \
        "Edit /etc/hosts. Add a line: '127.0.1.1  ${hostname}.local ${hostname}'. The loopback entry '127.0.0.1 localhost' should already be present." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#The_hosts_file"
    mark_step_complete "10.1"

    # ── Step 10.2 — install network manager ─────────────────────────────────
    show_step 2 "Install a network manager"
    show_tip "dhcpcd is a lightweight DHCP client — ideal for simple setups. NetworkManager is more feature-rich and better for laptops with multiple connection types."

    show_menu "Choose a network manager" \
        "dhcpcd — simple DHCP client (recommended for desktops/servers)" \
        "NetworkManager — full-featured (recommended for laptops)"
    local nm_choice="$MENU_CHOICE"

    case "$nm_choice" in
        1)
            run_or_type "emerge --ask net-misc/dhcpcd" \
                "Install dhcpcd, a DHCP client daemon that automatically configures network interfaces." \
                "https://wiki.gentoo.org/wiki/Dhcpcd"

            local init_system
            init_system=$(load_progress "STAGE3_INIT")
            init_system="${init_system:-openrc}"

            if [[ "$init_system" == "openrc" ]]; then
                run_or_type "rc-update add dhcpcd default" \
                    "Add dhcpcd to the default runlevel so it starts automatically at boot."
            else
                run_or_type "systemctl enable dhcpcd" \
                    "Enable dhcpcd to start automatically at boot under systemd."
            fi
            ;;
        2)
            run_or_type "emerge --ask net-misc/networkmanager" \
                "Install NetworkManager, a versatile network management daemon." \
                "https://wiki.gentoo.org/wiki/NetworkManager"

            local init_system
            init_system=$(load_progress "STAGE3_INIT")
            init_system="${init_system:-openrc}"

            if [[ "$init_system" == "openrc" ]]; then
                run_or_type "rc-update add NetworkManager default" \
                    "Add NetworkManager to the default runlevel."
            else
                run_or_type "systemctl enable NetworkManager" \
                    "Enable NetworkManager to start at boot under systemd."
            fi
            ;;
    esac
    mark_step_complete "10.2"

    # ── Step 10.3 — set root password ────────────────────────────────────────
    show_step 3 "Set the root password"
    show_tip "Setting a strong root password is critical for system security. Root is the superuser — it has unrestricted access to everything."

    run_or_type "passwd" \
        "Set the root account password. You will be prompted to enter and confirm the new password. The password is not echoed to the screen." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System#Setting_the_root_password"
    mark_step_complete "10.3"

    log_success "Module 10 — System networking configuration complete."
}
