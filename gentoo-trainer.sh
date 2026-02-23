#!/usr/bin/env bash
# gentoo-trainer.sh — Interactive Gentoo Linux Installation Trainer
# Follows the official Gentoo Handbook (AMD64) step by step.
#
# Usage: bash gentoo-trainer.sh
#
# https://github.com/davidleath2005/gentoo-trainer

set -euo pipefail

# ─── Resolve script directory ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Source libraries ────────────────────────────────────────────────────────
# shellcheck source=lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"
# shellcheck source=lib/ui.sh
source "${SCRIPT_DIR}/lib/ui.sh"
# shellcheck source=lib/hardware_detect.sh
source "${SCRIPT_DIR}/lib/hardware_detect.sh"
# shellcheck source=lib/progress.sh
source "${SCRIPT_DIR}/lib/progress.sh"

# ─── Source modules ──────────────────────────────────────────────────────────
# shellcheck source=modules/01_preparation.sh
source "${SCRIPT_DIR}/modules/01_preparation.sh"
# shellcheck source=modules/02_network.sh
source "${SCRIPT_DIR}/modules/02_network.sh"
# shellcheck source=modules/03_disks.sh
source "${SCRIPT_DIR}/modules/03_disks.sh"
# shellcheck source=modules/04_stage3.sh
source "${SCRIPT_DIR}/modules/04_stage3.sh"
# shellcheck source=modules/05_chroot.sh
source "${SCRIPT_DIR}/modules/05_chroot.sh"
# shellcheck source=modules/06_portage.sh
source "${SCRIPT_DIR}/modules/06_portage.sh"
# shellcheck source=modules/07_timezone_locale.sh
source "${SCRIPT_DIR}/modules/07_timezone_locale.sh"
# shellcheck source=modules/08_kernel.sh
source "${SCRIPT_DIR}/modules/08_kernel.sh"
# shellcheck source=modules/09_fstab.sh
source "${SCRIPT_DIR}/modules/09_fstab.sh"
# shellcheck source=modules/10_networking.sh
source "${SCRIPT_DIR}/modules/10_networking.sh"
# shellcheck source=modules/11_system_tools.sh
source "${SCRIPT_DIR}/modules/11_system_tools.sh"
# shellcheck source=modules/12_bootloader.sh
source "${SCRIPT_DIR}/modules/12_bootloader.sh"
# shellcheck source=modules/13_users.sh
source "${SCRIPT_DIR}/modules/13_users.sh"
# shellcheck source=modules/14_finalize.sh
source "${SCRIPT_DIR}/modules/14_finalize.sh"

# ─── Module list ─────────────────────────────────────────────────────────────
MODULES=(
    "module_01_preparation:01 — Preparation"
    "module_02_network:02 — Network Configuration"
    "module_03_disks:03 — Disk Partitioning & Formatting"
    "module_04_stage3:04 — Stage3 Download & Extraction"
    "module_05_chroot:05 — Chroot Setup"
    "module_06_portage:06 — Portage Configuration"
    "module_07_timezone_locale:07 — Timezone & Locale"
    "module_08_kernel:08 — Kernel Configuration"
    "module_09_fstab:09 — fstab Generation"
    "module_10_networking:10 — System Networking"
    "module_11_system_tools:11 — System Tools"
    "module_12_bootloader:12 — Bootloader (GRUB2)"
    "module_13_users:13 — Users & sudo"
    "module_14_finalize:14 — Finalize & Reboot"
)

# ─── run_modules_from ────────────────────────────────────────────────────────
run_modules_from() {
    local start_index="${1:-0}"
    local idx=0
    for entry in "${MODULES[@]}"; do
        local func="${entry%%:*}"
        local label="${entry##*:}"
        if (( idx >= start_index )); then
            log_info "Starting module: $label"
            "$func"
        fi
        (( idx++ ))
    done
}

# ─── jump_to_step menu ───────────────────────────────────────────────────────
jump_to_step() {
    local labels=()
    for entry in "${MODULES[@]}"; do
        labels+=("${entry##*:}")
    done
    show_menu "Jump to module" "${labels[@]}"
    run_modules_from $(( MENU_CHOICE - 1 ))
}

# ─── main ────────────────────────────────────────────────────────────────────
main() {
    show_banner

    check_root

    # Hardware detection
    log_info "Detecting hardware..."
    detect_hardware
    print_hardware_summary

    # Check for saved progress
    if [[ -f "$PROGRESS_FILE" ]]; then
        echo -e "  ${YELLOW}Saved progress found.${RESET}"
        display_progress

        verify_system_state || true

        show_menu "A previous session was found. What would you like to do?" \
            "Resume from last saved point" \
            "Start fresh (delete saved progress)" \
            "Jump to a specific module" \
            "View progress report only" \
            "Quit"

        case "$MENU_CHOICE" in
            1)
                # Resume: find first incomplete module
                local start_idx=0
                local idx=0
                for entry in "${MODULES[@]}"; do
                    local func="${entry%%:*}"
                    # Map module function to first step ID
                    local first_step
                    first_step=$(printf '%02d' $((idx + 1))).1
                    if ! is_step_done "$first_step"; then
                        start_idx=$idx
                        break
                    fi
                    (( idx++ ))
                done
                run_modules_from "$start_idx"
                ;;
            2)
                reset_progress
                run_modules_from 0
                ;;
            3)
                jump_to_step
                ;;
            4)
                display_progress
                main
                ;;
            5)
                log_info "Goodbye!"
                exit 0
                ;;
        esac
    else
        # No progress — show main menu
        show_menu "Welcome to Gentoo Trainer! What would you like to do?" \
            "Start the installation (from the beginning)" \
            "Jump to a specific module" \
            "View hardware summary" \
            "Quit"

        case "$MENU_CHOICE" in
            1)
                run_modules_from 0
                ;;
            2)
                jump_to_step
                ;;
            3)
                print_hardware_summary
                pause_and_continue
                main
                ;;
            4)
                log_info "Goodbye!"
                exit 0
                ;;
        esac
    fi
}

main "$@"
