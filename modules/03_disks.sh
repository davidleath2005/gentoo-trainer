#!/usr/bin/env bash
# Module: 03 — Disk Partitioning, Formatting, and Mounting
# Handbook Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks

# Exported after user selection
TARGET_DISK=""
BOOT_PART=""
SWAP_PART=""
ROOT_PART=""
# shellcheck disable=SC2034  # HOME_PART reserved for future separate-/home layout
HOME_PART=""
CHOSEN_FS="ext4"
SWAP_TYPE="partition"   # partition | file | none

module_03_disks() {
    show_chapter_header "Chapter 3" "Preparing the Disks" \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks"

    require_live

    # ── Step 3.1 — select disk ──────────────────────────────────────────────
    show_step 1 "Select the target disk"
    show_tip "All data on the chosen disk will be erased. Double-check the disk name (e.g. /dev/sda or /dev/nvme0n1) before confirming."

    run_or_type "fdisk -l" \
        "List all disks and their partitions. Use this to identify the disk you want to install Gentoo on." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Partition_scheme"

    echo ""
    if [[ ${#HW_DISKS[@]} -gt 0 ]]; then
        show_menu "Select the target disk for installation" "${HW_DISKS[@]}"
        TARGET_DISK="${HW_DISKS[$((MENU_CHOICE - 1))]}"
    else
        printf "  Enter the target disk (e.g. /dev/sda): "
        read -r TARGET_DISK
    fi
    log_info "Target disk: ${TARGET_DISK}"
    save_progress "TARGET_DISK" "$TARGET_DISK"
    mark_step_complete "03.1"

    # ── Step 3.2 — partition layout ─────────────────────────────────────────
    show_step 2 "Partition the disk"
    show_tip "GPT (GUID Partition Table) is required for UEFI systems and is recommended even on BIOS systems for disks larger than 2 TB. MBR is used on older BIOS systems."

    local swap_size="4G"

    if [[ "$HW_BOOT_MODE" == "uefi" ]]; then
        log_info "UEFI system detected — will use GPT + EFI System Partition."
        log_info "Partition plan:"
        echo "  ${TARGET_DISK}p1  512M  EFI System Partition  (FAT32, /boot/efi)"
        echo "  ${TARGET_DISK}p2  ${swap_size}  Linux swap"
        echo "  ${TARGET_DISK}p3  rest  Linux root"
    else
        log_info "BIOS system detected — will use GPT with a BIOS boot partition."
        echo "  ${TARGET_DISK}1  1M    BIOS boot partition  (no filesystem)"
        echo "  ${TARGET_DISK}2  ${swap_size}  Linux swap"
        echo "  ${TARGET_DISK}3  rest  Linux root"
    fi

    show_menu "Choose a partition layout" \
        "Simple (single root partition + swap)" \
        "Separate /home partition"
    local layout_choice="$MENU_CHOICE"

    show_menu "Choose root filesystem" \
        "ext4  — mature, reliable, good all-rounder (recommended)" \
        "xfs   — great for large files and servers" \
        "btrfs — modern with snapshots and compression"
    case "$MENU_CHOICE" in
        1) CHOSEN_FS="ext4" ;;
        2) CHOSEN_FS="xfs"  ;;
        3) CHOSEN_FS="btrfs";;
    esac

    show_menu "Choose swap type" \
        "Swap partition (traditional, recommended)" \
        "Swap file (flexible, created after mounting root)" \
        "No swap (not recommended for < 8 GB RAM)"
    case "$MENU_CHOICE" in
        1) SWAP_TYPE="partition" ;;
        2) SWAP_TYPE="file"      ;;
        3) SWAP_TYPE="none"      ;;
    esac

    save_progress "CHOSEN_FS"    "$CHOSEN_FS"
    save_progress "SWAP_TYPE"    "$SWAP_TYPE"
    save_progress "LAYOUT"       "$layout_choice"

    confirm_destructive "All data on ${TARGET_DISK} will be permanently erased!" || return 1

    if [[ "$HW_BOOT_MODE" == "uefi" ]]; then
        run_or_type "parted -s ${TARGET_DISK} mklabel gpt" \
            "Create a new GPT partition table on ${TARGET_DISK}. This erases all existing partitions." \
            "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Default_partitioning_scheme"

        run_or_type "parted -s ${TARGET_DISK} mkpart ESP fat32 1MiB 513MiB" \
            "Create the 512 MiB EFI System Partition (ESP). FAT32 is required by the UEFI specification."

        run_or_type "parted -s ${TARGET_DISK} set 1 esp on" \
            "Mark the first partition as an EFI System Partition using the 'esp' flag."

        if [[ "$SWAP_TYPE" == "partition" ]]; then
            run_or_type "parted -s ${TARGET_DISK} mkpart primary linux-swap 513MiB 4609MiB" \
                "Create a 4 GiB swap partition."
            run_or_type "parted -s ${TARGET_DISK} mkpart primary ${CHOSEN_FS} 4609MiB 100%" \
                "Create the root partition using the rest of the disk."
        else
            run_or_type "parted -s ${TARGET_DISK} mkpart primary ${CHOSEN_FS} 513MiB 100%" \
                "Create the root partition using the rest of the disk."
        fi
    else
        run_or_type "parted -s ${TARGET_DISK} mklabel gpt" \
            "Create a new GPT partition table on ${TARGET_DISK}."

        run_or_type "parted -s ${TARGET_DISK} mkpart primary 1MiB 2MiB" \
            "Create a 1 MiB BIOS boot partition required by GRUB on GPT+BIOS systems."

        run_or_type "parted -s ${TARGET_DISK} set 1 bios_grub on" \
            "Mark the first partition as a BIOS boot partition."

        if [[ "$SWAP_TYPE" == "partition" ]]; then
            run_or_type "parted -s ${TARGET_DISK} mkpart primary linux-swap 2MiB 4098MiB" \
                "Create a 4 GiB swap partition."
            run_or_type "parted -s ${TARGET_DISK} mkpart primary ${CHOSEN_FS} 4098MiB 100%" \
                "Create the root partition."
        else
            run_or_type "parted -s ${TARGET_DISK} mkpart primary ${CHOSEN_FS} 2MiB 100%" \
                "Create the root partition."
        fi
    fi
    mark_step_complete "03.2"

    # ── Step 3.3 — format ───────────────────────────────────────────────────
    show_step 3 "Format the partitions"
    show_tip "Formatting creates a filesystem on each partition. We use mkfs tools matched to the filesystem type we chose."

    # Derive partition names (nvme uses p-suffix, others don't)
    local p=""
    if [[ "$TARGET_DISK" =~ nvme ]]; then
        p="p"
    fi

    if [[ "$HW_BOOT_MODE" == "uefi" ]]; then
        BOOT_PART="${TARGET_DISK}${p}1"
        run_or_type "mkfs.fat -F32 ${BOOT_PART}" \
            "Format the EFI System Partition as FAT32. The -F32 flag explicitly selects FAT32 over FAT16." \
            "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Creating_file_systems"
        if [[ "$SWAP_TYPE" == "partition" ]]; then
            SWAP_PART="${TARGET_DISK}${p}2"
            ROOT_PART="${TARGET_DISK}${p}3"
        else
            ROOT_PART="${TARGET_DISK}${p}2"
        fi
    else
        # BIOS: p1 is bios_grub (no format), then swap/root
        if [[ "$SWAP_TYPE" == "partition" ]]; then
            SWAP_PART="${TARGET_DISK}${p}2"
            ROOT_PART="${TARGET_DISK}${p}3"
        else
            ROOT_PART="${TARGET_DISK}${p}2"
        fi
    fi

    if [[ "$SWAP_TYPE" == "partition" && -n "$SWAP_PART" ]]; then
        run_or_type "mkswap ${SWAP_PART}" \
            "Set up the swap partition. mkswap writes the swap signature so Linux can use it as virtual memory." \
            "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Creating_file_systems"
        run_or_type "swapon ${SWAP_PART}" \
            "Activate the swap partition immediately so the live system can use it during installation."
    fi

    case "$CHOSEN_FS" in
        ext4)
            run_or_type "mkfs.ext4 ${ROOT_PART}" \
                "Format the root partition as ext4. ext4 is the default filesystem for many Linux distributions — mature and reliable." \
                "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Creating_file_systems"
            ;;
        xfs)
            run_or_type "mkfs.xfs ${ROOT_PART}" \
                "Format the root partition as XFS. XFS excels with large files and high-throughput workloads."
            ;;
        btrfs)
            run_or_type "mkfs.btrfs ${ROOT_PART}" \
                "Format the root partition as Btrfs. Btrfs supports snapshots, transparent compression, and checksums."
            ;;
    esac

    save_progress "BOOT_PART" "$BOOT_PART"
    save_progress "SWAP_PART" "$SWAP_PART"
    save_progress "ROOT_PART" "$ROOT_PART"
    mark_step_complete "03.3"

    # ── Step 3.4 — mount ────────────────────────────────────────────────────
    show_step 4 "Mount the partitions"
    show_tip "We mount the new root filesystem at /mnt/gentoo so we can copy files into it. All further work will be done here."

    run_or_type "mount ${ROOT_PART} /mnt/gentoo" \
        "Mount the root partition at /mnt/gentoo. This is the installation target directory." \
        "https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks#Mounting_the_root_partition"

    if [[ "$HW_BOOT_MODE" == "uefi" && -n "$BOOT_PART" ]]; then
        run_or_type "mkdir -p /mnt/gentoo/boot/efi" \
            "Create the EFI mount point inside the new root filesystem."
        run_or_type "mount ${BOOT_PART} /mnt/gentoo/boot/efi" \
            "Mount the EFI System Partition at /mnt/gentoo/boot/efi."
    fi

    mark_step_complete "03.4"
    log_success "Module 03 — Disk preparation complete."
}
