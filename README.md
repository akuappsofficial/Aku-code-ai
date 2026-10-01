# AKU OS v1.0

AKU OS is an experimental x86 operating system built from scratch.

## Desktop v1.0
- GRUB Multiboot boot
- 1024x768x32 framebuffer desktop
- Custom vector-style icons drawn by the kernel
- Files, Terminal, Settings and Games desktop panels
- Built-in terminal screen
- Keyboard desktop navigation
- Dark futuristic UI
- Ventoy-ready ISO build
- Automatic GitHub Actions ISO artifact

## Keyboard
- **1** — Files/Desktop
- **2** — Terminal
- **3** — Settings
- **4** — Games
- **Esc** — Return to desktop

## Build
GitHub Actions builds `aku-os.iso` and publishes it as the `aku-os-v1.0-iso` artifact.

Copy that ISO to a Ventoy USB and boot it.

## Important
This is a real bootable OS development project, but v1.0 is still an experimental desktop foundation. It does **not** yet provide Windows Win32 compatibility, NTFS, modern GPU drivers, networking, audio, or GTA San Andreas support. Those require substantial additional kernel, driver, graphics and compatibility work.
