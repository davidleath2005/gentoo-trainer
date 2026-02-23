#!/usr/bin/env bash
# Module: 12 — Bootloader (GRUB2)
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader

module_12_bootloader() {
    show_chapter_header "Chapter 12" "Configuring the Bootloader (GRUB2)" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader"

    # ── Step 12.1 — install GRUB2 ────────────────────────────────────────────
    show_step 1 "Install GRUB2"
    show_tip "GRUB2 is the standard bootloader for Gentoo. The installation differs between UEFI and BIOS systems. On UEFI, grub-install targets the EFI partition; on BIOS it writes the MBR/GPT boot record."

    local target_disk
    target_disk=$(load_progress "TARGET_DISK")
    target_disk="${target_disk:-/dev/sda}"

    if [[ "$HW_BOOT_MODE" == "uefi" ]]; then
        run_or_type "emerge --ask --verbose sys-boot/grub:2[grub_platforms_efi-64]" \
            "Install GRUB2 with EFI 64-bit platform support enabled." \
            "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader#UEFI_systems"

        run_or_type "grub-install --target=x86_64-efi --efi-directory=/boot/efi --removable" \
            "Install GRUB2 to the EFI System Partition. --removable makes it bootable even without the EFI boot entry, useful for some firmware."
    else
        run_or_type "emerge --ask --verbose sys-boot/grub:2" \
            "Install GRUB2 with BIOS/MBR support." \
            "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader#BIOS_systems"

        run_or_type "grub-install ${target_disk}" \
            "Install GRUB2 to the Master Boot Record (or GPT protective MBR) of ${target_disk}."
    fi
    mark_step_complete "12.1"

    # ── Step 12.2 — generate grub.cfg ────────────────────────────────────────
    show_step 2 "Generate GRUB configuration"
    show_tip "grub-mkconfig scans for installed kernels and generates the GRUB menu automatically. It detects all kernels in /boot and creates menu entries for them."

    run_or_type "grub-mkconfig -o /boot/grub/grub.cfg" \
        "Generate the GRUB2 configuration file. This detects available kernels and creates boot menu entries." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader#Generating_the_grub_configuration"

    echo ""
    echo -e "  ${BOLD}Verifying GRUB configuration:${RESET}"
    run_or_type "cat /boot/grub/grub.cfg | grep -A3 'menuentry'" \
        "Display the generated GRUB menu entries to verify that your kernel was detected correctly."
    mark_step_complete "12.2"

    log_success "Module 12 — Bootloader installation complete."
}
