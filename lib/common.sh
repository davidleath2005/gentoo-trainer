#!/usr/bin/env bash
# lib/common.sh — Shared utility functions for Gentoo Trainer
# shellcheck disable=SC2034

# ─── Colour Constants ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ─── Logging ─────────────────────────────────────────────────────────────────
log_info() {
    echo -e "${BLUE}[INFO]${RESET}  $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET}  $*"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*" >&2
}

log_success() {
    echo -e "${GREEN}[OK]${RESET}    $*"
}

# ─── explain_command ─────────────────────────────────────────────────────────
# Usage: explain_command "command" "explanation" ["handbook_ref"]
explain_command() {
    local cmd="$1"
    local explanation="$2"
    local handbook_ref="${3:-}"
    local width=65

    echo ""
    printf "${CYAN}┌%s┐${RESET}\n" "$(printf '─%.0s' $(seq 1 $width))"
    printf "${CYAN}│${RESET}  ${BOLD}%-*s${RESET}${CYAN}│${RESET}\n" $((width - 2)) "📋 COMMAND"
    printf "${CYAN}│${RESET}  ${GREEN}\$ %-*s${RESET}${CYAN}│${RESET}\n" $((width - 5)) "$cmd"
    printf "${CYAN}├%s┤${RESET}\n" "$(printf '─%.0s' $(seq 1 $width))"
    printf "${CYAN}│${RESET}  ${BOLD}%-*s${RESET}${CYAN}│${RESET}\n" $((width - 2)) "💡 EXPLANATION"

    # Word-wrap the explanation at (width-4) chars
    local wrapped
    wrapped=$(echo "$explanation" | fold -sw $((width - 4)))
    while IFS= read -r line; do
        printf "${CYAN}│${RESET}  %-*s${CYAN}│${RESET}\n" $((width - 2)) "$line"
    done <<< "$wrapped"

    if [[ -n "$handbook_ref" ]]; then
        printf "${CYAN}├%s┤${RESET}\n" "$(printf '─%.0s' $(seq 1 $width))"
        printf "${CYAN}│${RESET}  ${BOLD}%-*s${RESET}${CYAN}│${RESET}\n" $((width - 2)) "📖 HANDBOOK REFERENCE"
        printf "${CYAN}│${RESET}  %-*s${CYAN}│${RESET}\n" $((width - 2)) "$handbook_ref"
    fi

    printf "${CYAN}└%s┘${RESET}\n" "$(printf '─%.0s' $(seq 1 $width))"
    echo ""
}

# ─── run_or_type ─────────────────────────────────────────────────────────────
# Usage: run_or_type "command" "explanation" ["handbook_ref"] ["extra_detail"]
run_or_type() {
    local cmd="$1"
    local explanation="$2"
    local handbook_ref="${3:-}"
    local extra_detail="${4:-}"

    explain_command "$cmd" "$explanation" "$handbook_ref"

    while true; do
        echo -e "  ${BOLD}[A]${RESET} Auto-run  ${BOLD}[T]${RESET} Type it yourself  ${BOLD}[S]${RESET} Skip  ${BOLD}[E]${RESET} Explain more"
        printf "  Choice: "
        local choice
        read -r choice
        case "${choice,,}" in
            a)
                log_info "Running: $cmd"
                eval "$cmd"
                local rc=$?
                if [[ $rc -eq 0 ]]; then
                    log_success "Command completed successfully."
                else
                    log_error "Command exited with code $rc."
                fi
                return $rc
                ;;
            t)
                echo ""
                echo -e "  ${YELLOW}Type the command below and press Enter:${RESET}"
                printf "  \$ "
                local user_input
                read -r user_input
                # Fuzzy tolerance: strip leading/trailing whitespace, collapse spaces
                local normalised_cmd normalised_input
                normalised_cmd=$(echo "$cmd"   | tr -s ' ' | sed 's/^ //;s/ $//')
                normalised_input=$(echo "$user_input" | tr -s ' ' | sed 's/^ //;s/ $//')
                if [[ "$normalised_input" == "$normalised_cmd" ]]; then
                    log_success "Correct! Running your command..."
                    eval "$user_input"
                    local rc=$?
                    if [[ $rc -eq 0 ]]; then
                        log_success "Command completed successfully."
                    else
                        log_error "Command exited with code $rc."
                    fi
                    return $rc
                else
                    log_warn "Input didn't match exactly. Expected:"
                    echo -e "    ${GREEN}\$ $normalised_cmd${RESET}"
                    echo -e "  You typed:"
                    echo -e "    ${YELLOW}\$ $normalised_input${RESET}"
                    printf "  Run your version anyway? [y/N]: "
                    local confirm
                    read -r confirm
                    if [[ "${confirm,,}" == "y" ]]; then
                        eval "$user_input"
                        return $?
                    fi
                fi
                ;;
            s)
                log_warn "Skipped: $cmd"
                return 0
                ;;
            e)
                echo ""
                if [[ -n "$extra_detail" ]]; then
                    echo -e "${BOLD}Detailed explanation:${RESET}"
                    echo "$extra_detail"
                else
                    echo -e "${BOLD}Detailed explanation:${RESET}"
                    echo "$explanation"
                fi
                echo ""
                ;;
            *)
                echo "  Please enter A, T, S, or E."
                ;;
        esac
    done
}

# ─── confirm_destructive ─────────────────────────────────────────────────────
# Usage: confirm_destructive "description of what will be destroyed"
# Returns 0 if confirmed, 1 if not.
confirm_destructive() {
    local description="$1"
    echo ""
    echo -e "${RED}${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}${BOLD}║  ⚠️  WARNING — DESTRUCTIVE OPERATION                    ║${RESET}"
    echo -e "${RED}${BOLD}╠══════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${RED}${BOLD}║${RESET}  $description"
    echo -e "${RED}${BOLD}║${RESET}  ${YELLOW}This CANNOT be undone.${RESET}"
    echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
    printf "  Type %bYES%b (all caps) to continue, or anything else to abort: " "${BOLD}" "${RESET}"
    local input
    read -r input
    if [[ "$input" == "YES" ]]; then
        return 0
    else
        log_warn "Aborted by user."
        return 1
    fi
}

# ─── check_root ──────────────────────────────────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root."
        log_info  "Try: sudo bash gentoo-trainer.sh"
        exit 1
    fi
}

# ─── require_live ────────────────────────────────────────────────────────────
require_live() {
    if [[ ! -f /etc/gentoo-release ]] && [[ ! -f /run/livecd ]]; then
        log_warn "This module is designed to run from the Gentoo live environment."
        log_warn "Continuing anyway — be careful."
    fi
}

# ─── require_chroot ──────────────────────────────────────────────────────────
require_chroot() {
    # A simple heuristic: if /proc/1/root resolves to a path that differs from /
    # we are likely inside a chroot.
    if ! ls /proc/1/root &>/dev/null; then
        log_warn "Cannot determine chroot status. Continuing."
        return
    fi
    local root_dev outside_dev
    root_dev=$(stat -c '%d' / 2>/dev/null || echo "0")
    outside_dev=$(stat -c '%d' /proc/1/root 2>/dev/null || echo "0")
    if [[ "$root_dev" == "$outside_dev" ]]; then
        log_error "This module must be run inside the chroot environment."
        log_info  "Run: chroot /mnt/gentoo /bin/bash"
        exit 1
    fi
}
