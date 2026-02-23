#!/usr/bin/env bash
# lib/progress.sh — Progress tracking for Gentoo Trainer

PROGRESS_FILE="${PROGRESS_FILE:-/tmp/gentoo-trainer-progress}"

# Keys stored: CURRENT_MODULE, CURRENT_STEP, START_TIME, and STEP_<id>=done/skipped

# ─── save_progress ───────────────────────────────────────────────────────────
save_progress() {
    local key="$1"
    local value="$2"
    # Create file if not present
    touch "$PROGRESS_FILE" 2>/dev/null || true
    # Remove existing key and append new value
    local tmp
    tmp=$(grep -v "^${key}=" "$PROGRESS_FILE" 2>/dev/null || true)
    printf '%s\n%s=%s\n' "$tmp" "$key" "$value" > "$PROGRESS_FILE"
}

# ─── load_progress ───────────────────────────────────────────────────────────
load_progress() {
    local key="$1"
    if [[ -f "$PROGRESS_FILE" ]]; then
        grep "^${key}=" "$PROGRESS_FILE" 2>/dev/null | tail -1 | cut -d= -f2-
    fi
}

# ─── mark_step_complete ──────────────────────────────────────────────────────
mark_step_complete() {
    local step_id="$1"
    save_progress "STEP_${step_id}" "done"
    save_progress "STEP_${step_id}_TIME" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    log_success "Step ${step_id} marked complete."
}

# ─── mark_step_skipped ───────────────────────────────────────────────────────
mark_step_skipped() {
    local step_id="$1"
    save_progress "STEP_${step_id}" "skipped"
    log_warn "Step ${step_id} marked skipped."
}

# ─── is_step_done ────────────────────────────────────────────────────────────
is_step_done() {
    local step_id="$1"
    local status
    status=$(load_progress "STEP_${step_id}")
    [[ "$status" == "done" ]]
}

# ─── display_progress ────────────────────────────────────────────────────────
display_progress() {
    if [[ ! -f "$PROGRESS_FILE" ]]; then
        log_info "No progress file found."
        return
    fi

    echo ""
    echo -e "${BOLD}┌─ Installation Progress ──────────────────────────────┐${RESET}"

    local total=0 done=0
    local all_steps=(
        "01.1" "01.2" "01.3"
        "02.1" "02.2" "02.3"
        "03.1" "03.2" "03.3" "03.4"
        "04.1" "04.2" "04.3"
        "05.1" "05.2" "05.3"
        "06.1" "06.2" "06.3"
        "07.1" "07.2" "07.3"
        "08.1" "08.2" "08.3"
        "09.1" "09.2"
        "10.1" "10.2" "10.3"
        "11.1" "11.2" "11.3"
        "12.1" "12.2"
        "13.1" "13.2"
        "14.1" "14.2"
    )

    for step in "${all_steps[@]}"; do
        local status
        status=$(load_progress "STEP_${step}")
        (( total++ ))
        if [[ "$status" == "done" ]]; then
            (( done++ ))
            echo -e "${BOLD}│${RESET}  ${GREEN}✔${RESET}  Step ${step}"
        elif [[ "$status" == "skipped" ]]; then
            echo -e "${BOLD}│${RESET}  ${YELLOW}–${RESET}  Step ${step} (skipped)"
        else
            echo -e "${BOLD}│${RESET}  ${RED}○${RESET}  Step ${step}"
        fi
    done

    echo -e "${BOLD}├──────────────────────────────────────────────────────┤${RESET}"
    show_progress_bar "$done" "$total"
    echo -e "${BOLD}└──────────────────────────────────────────────────────┘${RESET}"
    echo ""
}

# ─── verify_system_state ─────────────────────────────────────────────────────
# Check that key system state matches what progress claims was done.
verify_system_state() {
    local issues=0

    if is_step_done "03.4"; then
        if ! mountpoint -q /mnt/gentoo 2>/dev/null; then
            log_warn "Step 03.4 (mount) is marked done but /mnt/gentoo is not mounted."
            (( issues++ ))
        fi
    fi

    if is_step_done "04.3"; then
        if [[ ! -d /mnt/gentoo/etc ]]; then
            log_warn "Step 04.3 (stage3 extract) is marked done but /mnt/gentoo/etc does not exist."
            (( issues++ ))
        fi
    fi

    if [[ $issues -gt 0 ]]; then
        log_warn "$issues state inconsistencies detected. Some steps may need to be repeated."
        return 1
    fi
    return 0
}

# ─── reset_progress ──────────────────────────────────────────────────────────
reset_progress() {
    if [[ -f "$PROGRESS_FILE" ]]; then
        rm -f "$PROGRESS_FILE"
        log_info "Progress file removed."
    fi
}
