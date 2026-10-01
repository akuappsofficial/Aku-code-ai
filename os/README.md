# AkuOS 1.0

A tiny, Ventoy-friendly 64-bit Linux desktop built on TinyCorePure64 17.1.

## Target

- x86_64 PCs
- Ventoy / USB live boot
- ISO target under 50 MiB
- GUI desktop
- real Linux filesystem and processes
- USB keyboard/mouse and storage support from the Linux kernel
- wired networking support from the base system
- Tiny Core package system for adding software
- custom AkuOS icons, wallpaper, launcher bar and startup sound asset

## Important size/design trade-off

The base ISO is kept tiny by **not** bundling a full browser or every Wi-Fi firmware package. Wi-Fi support depends on the wireless chipset firmware. After boot, Tiny Core's package system can add the required driver/firmware and applications.

This is intentional: bundling every firmware package and a modern browser would push the ISO well beyond the 50 MiB target.

## Build

The GitHub Actions workflow downloads the official TinyCorePure64 17.1 base image, adds the AkuOS extension and rebuilds the ISO.

The official TinyCorePure64 17.1 image is about 42 MiB, leaving room for the custom AkuOS layer while staying under the 50 MiB target.

## Ventoy

Copy the generated `AkuOS-1.0-x86_64.iso` to the root of a Ventoy USB and select it from the Ventoy menu.

For maximum hardware compatibility, use a modern x86_64 PC and give the VM/PC at least 512 MiB RAM.

## Output

The workflow artifact is named:

`AkuOS-1.0-x86_64`
