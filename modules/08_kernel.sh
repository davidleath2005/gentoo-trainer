#!/usr/bin/env bash
# Module: 08 — Kernel Configuration
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel

module_08_kernel() {
    show_chapter_header "Chapter 8" "Configuring the Linux Kernel" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel"

    # ── Step 8.1 — choose kernel path ───────────────────────────────────────
    show_step 1 "Choose kernel installation method"
    show_tip "Gentoo offers three approaches: the binary distribution kernel (fast, no compilation), genkernel (automated compile with sane defaults), or full manual configuration (maximum control but requires kernel knowledge)."

    show_menu "Choose kernel installation method" \
        "Distribution kernel binary (gentoo-kernel-bin) — fastest, no compilation" \
        "Genkernel — automated compilation with hardware auto-detection" \
        "Manual configuration — advanced (make menuconfig)"
    local kernel_method="$MENU_CHOICE"
    save_progress "KERNEL_METHOD" "$kernel_method"

    # ── Step 8.2 — install linux-firmware ───────────────────────────────────
    show_step 2 "Install linux-firmware"
    show_tip "linux-firmware provides binary firmware blobs needed by many hardware components: wireless cards, GPUs, storage controllers, etc. Install it before the kernel so it is available during initramfs generation."

    run_or_type "emerge --ask sys-kernel/linux-firmware" \
        "Install the linux-firmware package which contains binary firmware for a wide range of hardware components." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Installing_firmware_and_microcode"
    mark_step_complete "08.1"

    # ── Step 8.3 — install kernel ────────────────────────────────────────────
    show_step 3 "Install and configure the kernel"

    case "$kernel_method" in
        1)
            show_tip "gentoo-kernel-bin installs a pre-compiled kernel and generates an initramfs automatically. It is the fastest path to a bootable system."
            run_or_type "emerge --ask sys-kernel/gentoo-kernel-bin" \
                "Install the pre-compiled Gentoo distribution kernel. This automatically installs the kernel image, modules, and generates an initramfs." \
                "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Distribution_kernels"
            ;;
        2)
            show_tip "genkernel automates the kernel configuration and compilation process. It produces a kernel with broad hardware support, suitable for most systems."
            run_or_type "emerge --ask sys-kernel/genkernel" \
                "Install the genkernel tool."

            run_or_type "emerge --ask sys-kernel/gentoo-sources" \
                "Install the Gentoo-patched Linux kernel source code." \
                "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Genkernel"

            run_or_type "genkernel all" \
                "Use genkernel to automatically configure, compile, and install the kernel and initramfs. This can take 30-60 minutes."
            ;;
        3)
            show_tip "Manual kernel configuration gives you full control. Use 'make menuconfig' to enable only the drivers your hardware needs, producing a smaller, faster kernel."
            run_or_type "emerge --ask sys-kernel/gentoo-sources" \
                "Install the Gentoo-patched Linux kernel source code."

            run_or_type "eselect kernel list" \
                "List available kernel source versions."

            run_or_type "eselect kernel set 1" \
                "Set the active kernel source to the first (typically only) entry. This creates the /usr/src/linux symlink."

            run_or_type "cd /usr/src/linux && make menuconfig" \
                "Enter the kernel source directory and open the interactive configuration menu. Navigate with arrow keys; space bar toggles options; ? shows help." \
                "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel#Manual_configuration"

            run_or_type "make -j${HW_CPU_CORES}" \
                "Compile the kernel using all available CPU cores. This may take 15-60 minutes depending on your configuration and hardware."

            run_or_type "make modules_install" \
                "Install the compiled kernel modules to /lib/modules/<version>/."

            run_or_type "make install" \
                "Copy the kernel image to /boot."
            ;;
    esac
    mark_step_complete "08.2"
    mark_step_complete "08.3"

    log_success "Module 08 — Kernel installation complete."
}
