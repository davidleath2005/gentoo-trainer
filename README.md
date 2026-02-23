# 🐧 Gentoo Trainer

> **An interactive, educational Bash script that guides you through a real Gentoo Linux installation — step by step, following the official Handbook.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Shell: Bash 4+](https://img.shields.io/badge/Shell-Bash%204%2B-blue.svg)](https://www.gnu.org/software/bash/)
[![Handbook: AMD64](https://img.shields.io/badge/Handbook-AMD64-orange.svg)](https://wiki.gentoo.org/wiki/Handbook:AMD64)

---

## What Is This?

**Gentoo Trainer** is a fully interactive Bash script that walks you through installing Gentoo Linux on real hardware. It is primarily an **educational tool** — every command is explained before it runs, you can choose to type each command yourself to practice, and the script tracks your progress so you can resume an interrupted session.

Unlike a fully automated installer, Gentoo Trainer is designed to help you *understand* what you are doing at each step. When you finish, you will have both a working Gentoo system and a solid grasp of how it was built.

---

## Feature Highlights

- 📖 **Handbook-faithful** — follows the official [Gentoo Handbook (AMD64)](https://wiki.gentoo.org/wiki/Handbook:AMD64) chapter by chapter
- 🎓 **Educational** — every command comes with a plain-English explanation and a Handbook reference
- ⌨️ **Type-it-yourself mode** — practice commands by typing them yourself; the script validates your input before running it
- 💾 **Progress tracking** — saves your progress so you can safely resume an interrupted installation
- 🖥️ **Hardware-aware** — auto-detects UEFI vs BIOS, NVMe vs SATA, CPU details, RAM, and network interfaces, then adapts commands accordingly
- ⚠️ **Safe** — all destructive operations (partitioning, formatting) require extra confirmation
- 🔧 **Customizable** — choose OpenRC vs systemd, filesystem type, kernel configuration method, and more

---

## Interface Preview

```
╔══════════════════════════════════════════════════════════════════╗
║          ██████╗ ███████╗███╗   ██╗████████╗ ██████╗  ██████╗  ║
║         ██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝██╔═══██╗██╔═══██╗ ║
║         ██║  ███╗█████╗  ██╔██╗ ██║   ██║   ██║   ██║██║   ██║ ║
║         ██║   ██║██╔══╝  ██║╚██╗██║   ██║   ██║   ██║██║   ██║ ║
║         ╚██████╔╝███████╗██║ ╚████║   ██║   ╚██████╔╝╚██████╔╝ ║
║          ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝  ╚═════╝  ║
║                    T R A I N E R  v1.0                          ║
╚══════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────┐
│  📋 COMMAND                                                     │
│  $ fdisk -l                                                     │
├─────────────────────────────────────────────────────────────────┤
│  💡 EXPLANATION                                                 │
│  Lists all available disks and their partition tables.          │
│  This helps us identify the target disk for installation.       │
├─────────────────────────────────────────────────────────────────┤
│  📖 HANDBOOK  §  Preparing the Disks                           │
│  https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks │
└─────────────────────────────────────────────────────────────────┘

  [A] Auto-run    [T] Type it yourself    [S] Skip    [E] Explain more
  Choice:
```

---

## Requirements

- Booted from the **Gentoo minimal install CD** (amd64)
- Internet connection (wired preferred; wireless supported via `iwctl`)
- A target disk with at least **20 GB** of free space
- Basic familiarity with the Linux command line

---

## Quick Start

1. **Boot the Gentoo minimal install CD** on your target machine.

2. **Download Gentoo Trainer:**
   ```bash
   curl -O https://raw.githubusercontent.com/davidleath2005/gentoo-trainer/main/gentoo-trainer.sh
   chmod +x gentoo-trainer.sh
   ```

3. **Run the trainer:**
   ```bash
   bash gentoo-trainer.sh
   ```

   The script will detect your hardware, check the environment, and guide you through each step interactively.

---

## Resuming an Interrupted Installation

If your session is interrupted, simply re-run the script:

```bash
bash gentoo-trainer.sh
```

The trainer will detect the saved progress file at `/tmp/gentoo-trainer-progress` and offer to resume from where you left off. It will also verify that the system state (mounts, extracted files, etc.) matches what was previously completed before continuing.

---

## Modules / Chapters

| Module | Title | Handbook Section |
|--------|-------|-----------------|
| 01 | Preparation | Booting & environment checks |
| 02 | Network Configuration | Configuring the network |
| 03 | Disk Partitioning & Formatting | Preparing the disks |
| 04 | Stage3 Download & Extraction | Installing the stage file |
| 05 | Chroot Setup | Preparing for chroot |
| 06 | Portage Configuration | Configuring Portage |
| 07 | Timezone & Locale | Timezone and locale |
| 08 | Kernel Configuration | Configuring the Linux kernel |
| 09 | fstab Generation | Configuring the system |
| 10 | System Networking | Networking information |
| 11 | System Tools | System tools installation |
| 12 | Bootloader (GRUB2) | Configuring the bootloader |
| 13 | Users & sudo | Finalizing |
| 14 | Finalize & Reboot | Rebooting the system |

---

## Customization Options

During the guided installation you will be asked to choose:

- **Init system**: OpenRC (default) or systemd
- **Filesystem**: ext4, xfs, or btrfs (pros and cons explained)
- **Swap**: partition, swapfile, or none
- **Kernel**: distribution kernel binary (easiest), genkernel (automated compile), or manual `make menuconfig`
- **USE flags**: guided selection based on your goals (desktop, server, minimal)
- **Network manager**: dhcpcd or NetworkManager
- **System logger**: sysklogd or syslog-ng
- **Partition layout**: simple (one root) or separate `/home`

---

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-improvement`)
3. Write shellcheck-clean Bash
4. Submit a pull request with a clear description of your changes

Please keep the educational spirit of the project — commands should always be explained, not just run silently.

---

## License

This project is licensed under the [MIT License](LICENSE). Copyright © 2026 davidleath2005.

---

## Links

- 📘 [Official Gentoo Handbook (AMD64)](https://wiki.gentoo.org/wiki/Handbook:AMD64)
- 🌐 [Gentoo Linux](https://www.gentoo.org/)
- 💬 [Gentoo Forums](https://forums.gentoo.org/)
- 🔎 [Gentoo Packages](https://packages.gentoo.org/)

---

## FAQ

**Is this safe to run on real hardware?**
Yes — but it will partition and format the disk you choose. Always back up important data. The script warns you explicitly before any destructive operation and requires you to type `YES` to confirm.

**Can I use this in a virtual machine?**
Absolutely. A VM is an excellent way to practice without risking data.

**What if something goes wrong mid-installation?**
The progress tracker saves your state. You can re-run the script and resume. For catastrophic failures, the script will never automatically reboot without your explicit confirmation.

**Does this install a desktop environment?**
The trainer covers the base system as defined by the Gentoo Handbook. After a successful installation, Module 14 provides tips and pointers for installing a desktop environment as a next step.

**Is this an official Gentoo project?**
No. This is an independent educational tool. Always consult the [official Gentoo Handbook](https://wiki.gentoo.org/wiki/Handbook:AMD64) as the authoritative source.

---

## Credits & Acknowledgments

- The [Gentoo developers and community](https://www.gentoo.org/inside-gentoo/developers/) for the outstanding Handbook documentation
- All contributors to this project