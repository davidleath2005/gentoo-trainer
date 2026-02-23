#!/usr/bin/env bash
# lib/ui.sh — UI helpers for Gentoo Trainer

# ─── show_banner ─────────────────────────────────────────────────────────────
show_banner() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo '╔══════════════════════════════════════════════════════════════════╗'
    echo '║          ██████╗ ███████╗███╗   ██╗████████╗ ██████╗  ██████╗  ║'
    echo '║         ██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██╔═══██╗██╔═══██╗ ║'
    echo '║         ██║  ███╗█████╗  ██╔██╗ ██║   ██║   ██║   ██║██║   ██║ ║'
    echo '║         ██║   ██║██╔══╝  ██║╚██╗██║   ██║   ██║   ██║██║   ██║ ║'
    echo '║         ╚██████╔╝███████╗██║ ╚████║   ██║   ╚██████╔╝╚██████╔╝ ║'
    echo '║          ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝  ╚═════╝  ║'
    echo '║                    T R A I N E R  v1.0                          ║'
    echo '╠══════════════════════════════════════════════════════════════════╣'
    echo '║  Interactive Gentoo Linux Installation Trainer                  ║'
    echo '║  Following the official AMD64 Handbook step by step             ║'
    echo '╚══════════════════════════════════════════════════════════════════╝'
    echo -e "${RESET}"
}

# ─── show_chapter_header ─────────────────────────────────────────────────────
# Usage: show_chapter_header "Chapter N" "Title" "handbook_url"
show_chapter_header() {
    local chapter="$1"
    local title="$2"
    local url="${3:-}"
    local width=65

    echo ""
    echo -e "${BOLD}${BLUE}"
    printf '╔%s╗\n' "$(printf '═%.0s' $(seq 1 $width))"
    printf '║  %-*s║\n' $((width - 1)) "${chapter}: ${title}"
    if [[ -n "$url" ]]; then
        printf '║  %-*s║\n' $((width - 1)) "📖 $url"
    fi
    printf '╚%s╝\n' "$(printf '═%.0s' $(seq 1 $width))"
    echo -e "${RESET}"
    echo ""
}

# ─── show_step ───────────────────────────────────────────────────────────────
# Usage: show_step <number> "description"
show_step() {
    local num="$1"
    local desc="$2"
    echo ""
    echo -e "${BOLD}${YELLOW}  ▶ Step ${num}${RESET} — ${desc}"
    echo -e "  $(printf '─%.0s' $(seq 1 60))"
}

# ─── show_tip ────────────────────────────────────────────────────────────────
# Usage: show_tip "tip text"
show_tip() {
    local tip="$1"
    local width=63
    echo ""
    printf "${YELLOW}  ╭%s╮${RESET}\n" "$(printf '─%.0s' $(seq 1 $width))"
    printf "${YELLOW}  │${RESET}  ${BOLD}💡 TIP${RESET}%-*s${YELLOW}│${RESET}\n" $((width - 6)) ""

    local wrapped
    wrapped=$(echo "$tip" | fold -sw $((width - 4)))
    while IFS= read -r line; do
        printf "${YELLOW}  │${RESET}  %-*s${YELLOW}│${RESET}\n" $((width - 2)) "$line"
    done <<< "$wrapped"

    printf "${YELLOW}  ╰%s╯${RESET}\n" "$(printf '─%.0s' $(seq 1 $width))"
    echo ""
}

# ─── show_menu ───────────────────────────────────────────────────────────────
# Usage: show_menu "title" option1 option2 ...
# Sets MENU_CHOICE to the number (1-based) the user picked.
show_menu() {
    local title="$1"
    shift
    local options=("$@")
    echo ""
    echo -e "${BOLD}  ${title}${RESET}"
    local i=1
    for opt in "${options[@]}"; do
        echo -e "    ${CYAN}[$i]${RESET}  $opt"
        (( i++ ))
    done
    echo ""
    while true; do
        printf "  Enter choice [1-%d]: " "${#options[@]}"
        local input
        read -r input
        if [[ "$input" =~ ^[0-9]+$ ]] && (( input >= 1 && input <= ${#options[@]} )); then
            # shellcheck disable=SC2034  # MENU_CHOICE is read by callers
            MENU_CHOICE="$input"
            return 0
        fi
        echo "  Invalid choice. Please enter a number between 1 and ${#options[@]}."
    done
}

# ─── show_progress_bar ───────────────────────────────────────────────────────
# Usage: show_progress_bar <done> <total>
show_progress_bar() {
    local done="$1"
    local total="$2"
    local bar_width=40
    local filled=$(( done * bar_width / total ))
    local empty=$(( bar_width - filled ))
    local pct=$(( done * 100 / total ))

    local bar=""
    bar+="${GREEN}"
    bar+="$(printf '█%.0s' $(seq 1 $filled))"
    bar+="${RESET}"
    bar+="$(printf '░%.0s' $(seq 1 $empty))"

    printf "${BOLD}│${RESET}  Progress: [%s] %d/%d (%d%%)\n" "$bar" "$done" "$total" "$pct"
}

# ─── pause_and_continue ──────────────────────────────────────────────────────
pause_and_continue() {
    echo ""
    printf "  Press %bEnter%b to continue..." "${BOLD}" "${RESET}"
    read -r
    echo ""
}

# ─── spinner ─────────────────────────────────────────────────────────────────
# Usage: start_spinner "message"; ...; stop_spinner
_SPINNER_PID=""

start_spinner() {
    local message="${1:-Working...}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    (
        local i=0
        while true; do
            local c="${spin:$((i % ${#spin})):1}"
            printf "\r  ${CYAN}${c}${RESET}  %s " "$message"
            sleep 0.1
            (( i++ ))
        done
    ) &
    _SPINNER_PID=$!
    disown "$_SPINNER_PID" 2>/dev/null || true
}

stop_spinner() {
    if [[ -n "$_SPINNER_PID" ]]; then
        kill "$_SPINNER_PID" 2>/dev/null || true
        _SPINNER_PID=""
        printf "\r  \033[K"
    fi
}
