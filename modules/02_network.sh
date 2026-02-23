#!/usr/bin/env bash
# Module: 02 — Network Configuration
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Networking

module_02_network() {
    show_chapter_header "Chapter 2" "Network Configuration" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Networking"

    require_live

    # ── Step 2.1 — list interfaces ──────────────────────────────────────────
    show_step 1 "Identify network interfaces"
    show_tip "Modern Linux uses predictable interface names (e.g. enp3s0 for wired, wlan0 or wlp2s0 for wireless). The 'ip' command is the modern replacement for 'ifconfig'."

    run_or_type "ip link show" \
        "List all network interfaces and their current state (UP/DOWN). Identify your wired (en*) or wireless (wl*) interface name." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Networking#Automatic_network_detection"

    echo ""
    echo -e "  Detected interfaces: ${CYAN}${HW_NET_IFACES[*]:-none}${RESET}"

    if [[ ${HW_HAS_WIRELESS} -eq 1 ]]; then
        echo ""
        echo -e "  ${YELLOW}Wireless interface detected.${RESET}"
        show_menu "How do you want to connect?" \
            "Wired (Ethernet) — use DHCP" \
            "Wireless — use iwctl" \
            "Network is already configured — skip"
    else
        show_menu "How do you want to connect?" \
            "Wired (Ethernet) — use DHCP" \
            "Network is already configured — skip"
    fi

    case "$MENU_CHOICE" in
        1)
            # Wired DHCP
            local iface=""
            for i in "${HW_NET_IFACES[@]}"; do
                if [[ "$i" =~ ^e ]]; then
                    iface="$i"
                    break
                fi
            done
            if [[ -z "$iface" ]]; then
                printf "  Enter your wired interface name: "
                read -r iface
            fi
            run_or_type "dhcpcd ${iface}" \
                "Start the DHCP client on interface ${iface}. This will automatically request an IP address from your router." \
                "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Networking#DHCP"
            ;;
        2)
            if [[ ${HW_HAS_WIRELESS} -eq 1 ]]; then
                show_tip "iwctl is the interactive wireless configuration tool on the Gentoo live CD. Type 'station wlan0 connect SSID' once inside."
                run_or_type "iwctl" \
                    "Open the interactive wireless configuration tool (iwd). Inside, use: 'station <iface> connect <SSID>' then quit with Ctrl+D or 'quit'." \
                    "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Networking#Wireless"
            fi
            ;;
        *)
            log_info "Skipping network setup."
            ;;
    esac
    mark_step_complete "02.1"

    # ── Step 2.2 — verify connectivity ──────────────────────────────────────
    show_step 2 "Verify internet connectivity"
    show_tip "We ping a well-known address to confirm we have outbound internet access. DNS resolution is tested at the same time."

    run_or_type "ping -c 3 gentoo.org" \
        "Send 3 ICMP echo requests to gentoo.org. If all three succeed you have working internet access and DNS resolution." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Networking#Testing_the_network"
    mark_step_complete "02.2"

    # ── Step 2.3 — sync clock ───────────────────────────────────────────────
    show_step 3 "Synchronise system clock"
    show_tip "An accurate clock is required for SSL certificates. If the clock was already set in Module 01, you can skip this."

    run_or_type "ntpd -gq" \
        "Force a one-shot NTP time synchronisation. -g allows large adjustments; -q exits after syncing." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Networking#Optional:_Syncing_the_clock"
    mark_step_complete "02.3"

    log_success "Module 02 — Network Configuration complete."
}
