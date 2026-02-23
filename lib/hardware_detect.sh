#!/usr/bin/env bash
# lib/hardware_detect.sh — Hardware detection for Gentoo Trainer

# Results are stored in these global variables after detect_hardware() runs.
HW_BOOT_MODE=""      # "uefi" or "bios"
HW_DISKS=()          # list of disk device paths
HW_DISK_INFO=""      # human-readable disk table
HW_CPU_MODEL=""      # CPU model string
HW_CPU_CORES=1       # logical CPU core count
HW_CPU_MARCH=""      # recommended -march= flag
HW_RAM_MB=0          # total RAM in MB
HW_NET_IFACES=()     # network interface names
HW_HAS_WIRELESS=0    # 1 if any wireless interface detected

# ─── detect_boot_mode ────────────────────────────────────────────────────────
detect_boot_mode() {
    if [[ -d /sys/firmware/efi ]]; then
        HW_BOOT_MODE="uefi"
    else
        HW_BOOT_MODE="bios"
    fi
}

# ─── detect_disks ────────────────────────────────────────────────────────────
detect_disks() {
    HW_DISKS=()
    HW_DISK_INFO=""
    local line
    while IFS= read -r line; do
        HW_DISKS+=("$line")
    done < <(lsblk -dpno NAME 2>/dev/null | grep -E '^/dev/(sd|nvme|vd|hd)')

    # Build a human-readable table
    local header
    header=$(lsblk -dpno NAME,SIZE,MODEL,TRAN 2>/dev/null | grep -E '(sd|nvme|vd|hd)' || true)
    HW_DISK_INFO="$header"
}

# ─── detect_cpu ──────────────────────────────────────────────────────────────
detect_cpu() {
    HW_CPU_MODEL=$(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //' || echo "Unknown")
    HW_CPU_CORES=$(nproc 2>/dev/null || grep -c '^processor' /proc/cpuinfo 2>/dev/null || echo 1)

    # Determine a safe -march value
    local flags
    flags=$(grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | cut -d: -f2 || echo "")
    if echo "$flags" | grep -qw 'avx512f'; then
        HW_CPU_MARCH="x86-64-v4"
    elif echo "$flags" | grep -qw 'avx2'; then
        HW_CPU_MARCH="x86-64-v3"
    elif echo "$flags" | grep -qw 'sse4_2'; then
        HW_CPU_MARCH="x86-64-v2"
    else
        HW_CPU_MARCH="x86-64"
    fi
}

# ─── detect_ram ──────────────────────────────────────────────────────────────
detect_ram() {
    local mem_kb
    mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "0")
    HW_RAM_MB=$(( mem_kb / 1024 ))
}

# ─── detect_network ──────────────────────────────────────────────────────────
detect_network() {
    HW_NET_IFACES=()
    HW_HAS_WIRELESS=0
    local iface
    while IFS= read -r iface; do
        [[ "$iface" == "lo" ]] && continue
        HW_NET_IFACES+=("$iface")
        # shellcheck disable=SC2034
        if [[ -d /sys/class/net/$iface/wireless ]]; then
            HW_HAS_WIRELESS=1
        fi
    done < <(ls /sys/class/net/ 2>/dev/null)
}

# ─── detect_hardware (main entry) ────────────────────────────────────────────
detect_hardware() {
    detect_boot_mode
    detect_disks
    detect_cpu
    detect_ram
    detect_network
}

# ─── print_hardware_summary ──────────────────────────────────────────────────
print_hardware_summary() {
    local boot_label
    if [[ "$HW_BOOT_MODE" == "uefi" ]]; then
        boot_label="${GREEN}UEFI${RESET}"
    else
        boot_label="${YELLOW}Legacy BIOS${RESET}"
    fi

    echo ""
    echo -e "${BOLD}┌─ Hardware Summary ──────────────────────────────────┐${RESET}"
    echo -e "${BOLD}│${RESET}  Boot mode  : $(echo -e "$boot_label")"
    echo -e "${BOLD}│${RESET}  CPU        : ${HW_CPU_MODEL}"
    echo -e "${BOLD}│${RESET}  Cores      : ${HW_CPU_CORES}  (MAKEOPTS=\"-j${HW_CPU_CORES}\")"
    echo -e "${BOLD}│${RESET}  Arch flag  : -march=${HW_CPU_MARCH}"
    echo -e "${BOLD}│${RESET}  RAM        : ${HW_RAM_MB} MB"
    echo -e "${BOLD}│${RESET}  Network    : ${HW_NET_IFACES[*]:-none detected}"
    if [[ ${#HW_DISKS[@]} -gt 0 ]]; then
        echo -e "${BOLD}│${RESET}  Disks:"
        while IFS= read -r dline; do
            [[ -z "$dline" ]] && continue
            echo -e "${BOLD}│${RESET}    $dline"
        done <<< "$HW_DISK_INFO"
    else
        echo -e "${BOLD}│${RESET}  Disks      : none detected"
    fi
    echo -e "${BOLD}└─────────────────────────────────────────────────────┘${RESET}"
    echo ""
}
