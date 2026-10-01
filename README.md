# AKU OS

AKU OS is a from-scratch experimental x86 operating system.

## v0.1
- Multiboot-compatible kernel
- Boots from an ISO
- Designed for Ventoy
- VGA text console
- PS/2 keyboard input
- Tiny interactive shell

GitHub Actions builds `aku-os.iso` automatically.

## Boot with Ventoy
1. Open the GitHub Actions workflow **Build AKU OS ISO**.
2. Run it manually.
3. Download the `aku-os-iso` artifact.
4. Copy `aku-os.iso` to a Ventoy USB.
5. Boot the computer and select AKU OS.

Windows .exe compatibility and GTA San Andreas support are future goals, not v0.1 features.
