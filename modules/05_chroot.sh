#!/usr/bin/env bash
# Module: 05 — Chroot Setup
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base

module_05_chroot() {
    show_chapter_header "Chapter 5" "Preparing for Chroot" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base"

    require_live

    # ── Step 5.1 — configure make.conf ──────────────────────────────────────
    show_step 1 "Configure make.conf"
    show_tip "make.conf is Portage's main configuration file. CFLAGS control compiler optimisations. MAKEOPTS sets the number of parallel compile jobs — use the number of CPU cores."

    local makeopts="-j${HW_CPU_CORES}"
    local cflags="-march=${HW_CPU_MARCH} -O2 -pipe"

    cat <<EOF

  Suggested make.conf settings for your hardware:
  ─────────────────────────────────────────────────
  CFLAGS="${cflags}"
  CXXFLAGS="\${CFLAGS}"
  MAKEOPTS="${makeopts}"

EOF

    run_or_type "nano /mnt/gentoo/etc/portage/make.conf" \
        "Open make.conf in the nano text editor. Add or update CFLAGS, CXXFLAGS, and MAKEOPTS with the values shown above. Save with Ctrl+O then exit with Ctrl+X." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Configuring_compile_options"

    save_progress "CFLAGS"   "$cflags"
    save_progress "MAKEOPTS" "$makeopts"
    mark_step_complete "05.1"

    # ── Step 5.2 — copy DNS and mount pseudo-filesystems ────────────────────
    show_step 2 "Copy DNS info and mount pseudo-filesystems"
    show_tip "We copy /etc/resolv.conf so the chroot environment can resolve DNS names. The pseudo-filesystems (proc, sys, dev) give chrooted processes access to kernel and device information."

    run_or_type "cp --dereference /etc/resolv.conf /mnt/gentoo/etc/" \
        "Copy DNS resolver configuration into the new root so network access works inside the chroot." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Copy_DNS_info"

    run_or_type "mount --types proc /proc /mnt/gentoo/proc" \
        "Mount the proc pseudo-filesystem. It exposes kernel and process information to programs." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Mounting_the_necessary_filesystems"

    run_or_type "mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys" \
        "Bind-mount /sys (sysfs) into the chroot with recursive slave propagation. This makes device and kernel info available inside."

    run_or_type "mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev" \
        "Bind-mount /dev into the chroot so device nodes are accessible inside."

    run_or_type "mount --bind /run /mnt/gentoo/run" \
        "Bind-mount /run so runtime files (like D-Bus sockets) are accessible inside the chroot."
    mark_step_complete "05.2"

    # ── Step 5.3 — enter chroot ─────────────────────────────────────────────
    show_step 3 "Enter the chroot environment"
    show_tip "chroot changes the apparent root directory for the process. After this command, '/' refers to /mnt/gentoo. All subsequent installation commands run inside the new Gentoo system."

    echo ""
    echo -e "  ${YELLOW}${BOLD}IMPORTANT:${RESET} The next command will enter the chroot."
    echo -e "  ${YELLOW}You will need to re-run the remaining modules from inside the chroot.${RESET}"
    echo -e "  ${YELLOW}After entering, run the gentoo-trainer.sh script again.${RESET}"
    echo ""

    run_or_type "chroot /mnt/gentoo /bin/bash" \
        "Change root into /mnt/gentoo running /bin/bash. From this point, all commands operate on the new Gentoo system. Run the trainer script again inside the chroot to continue." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base#Entering_the_new_environment"

    mark_step_complete "05.3"
    log_success "Module 05 — Chroot setup complete."
}
