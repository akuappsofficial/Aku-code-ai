#!/usr/bin/env bash
set -euo pipefail

# AkuOS 1.0
# Tiny graphical Linux image designed to remain below 50,000,000 bytes (~47.7 MiB).
# Base: TinyCorePure64 17.1 (x86_64)

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/.akuos-build"
DIST="$ROOT/dist"
BASE_NAME="TinyCorePure64-17.1.iso"
BASE_ISO="$WORK/$BASE_NAME"
BASE_URLS=(
  "https://mirror.nju.edu.cn/tinycorelinux/17.x/x86_64/release"
  "https://mirrors.aliyun.com/tinycorelinux/17.x/x86_64/release"
  "https://ftp.icm.edu.pl/packages/linux-tinycorelinux/17.x/x86_64/release"
  "https://www.tinycorelinux.net/17.x/x86_64/release"
)
ISO_OUT="$DIST/AkuOS-1.0-x86_64.iso"
EXTROOT="$WORK/extension"
NEWISO="$WORK/newiso"

rm -rf "$WORK" "$DIST"
mkdir -p "$WORK" "$DIST" "$EXTROOT" "$NEWISO"

echo "[AkuOS] Downloading TinyCorePure64 17.1..."
DOWNLOAD_OK=0
for BASE_URL in "${BASE_URLS[@]}"; do
  echo "[AkuOS] Trying $BASE_URL"
  if curl -fL --retry 3 --retry-delay 2 --connect-timeout 15 -o "$BASE_ISO" "$BASE_URL/$BASE_NAME" && \
     curl -fL --retry 3 --retry-delay 2 --connect-timeout 15 -o "$WORK/base.md5" "$BASE_URL/$BASE_NAME.md5.txt"; then
    if (cd "$WORK" && md5sum -c base.md5); then
      DOWNLOAD_OK=1
      break
    fi
  fi
  rm -f "$BASE_ISO" "$WORK/base.md5"
done
if [ "$DOWNLOAD_OK" -ne 1 ]; then
  echo "[AkuOS] ERROR: Could not download and verify $BASE_NAME from any mirror."
  exit 1
fi

echo "[AkuOS] Extracting base ISO..."
xorriso -osirrox on -indev "$BASE_ISO" -extract / "$NEWISO" >/dev/null 2>&1
chmod -R u+rwX "$NEWISO"

mkdir -p "$EXTROOT/usr/local/bin"
mkdir -p "$EXTROOT/usr/local/share/akuos/icons"
mkdir -p "$EXTROOT/usr/local/share/akuos/wallpapers"
mkdir -p "$EXTROOT/usr/local/share/akuos/sounds"
mkdir -p "$EXTROOT/usr/local/share/applications"
mkdir -p "$EXTROOT/home/tc/.X.d"

# ---------------------------
# SVG source artwork
# ---------------------------
cat > "$EXTROOT/usr/local/share/akuos/icons/computer.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
<rect x="7" y="10" width="50" height="36" rx="5" fill="#11151b" stroke="#b8ff3d" stroke-width="3"/>
<path d="M20 54h24M26 46l-3 8M38 46l3 8" fill="none" stroke="#b8ff3d" stroke-width="3"/>
<path d="M17 20h30v17H17z" fill="#17241c"/>
<path d="M22 28h20M22 33h12" stroke="#b8ff3d" stroke-width="3" stroke-linecap="round"/>
</svg>
EOF

cat > "$EXTROOT/usr/local/share/akuos/icons/terminal.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
<rect x="7" y="10" width="50" height="44" rx="5" fill="#0b0e12" stroke="#b8ff3d" stroke-width="3"/>
<path d="m17 25 8 7-8 7M31 40h16" fill="none" stroke="#b8ff3d" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
EOF

cat > "$EXTROOT/usr/local/share/akuos/icons/network.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
<circle cx="32" cy="47" r="5" fill="#b8ff3d"/>
<path d="M18 37a20 20 0 0 1 28 0M12 29a29 29 0 0 1 40 0M6 21a38 38 0 0 1 52 0" fill="none" stroke="#b8ff3d" stroke-width="4" stroke-linecap="round"/>
</svg>
EOF

cat > "$EXTROOT/usr/local/share/akuos/icons/files.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
<path d="M10 16h17l6 7h21v27H10z" fill="#17241c" stroke="#b8ff3d" stroke-width="3"/>
<path d="M10 24h44" stroke="#b8ff3d" stroke-width="3"/>
</svg>
EOF

cat > "$EXTROOT/usr/local/share/akuos/icons/apps.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
<rect x="9" y="9" width="18" height="18" rx="3" fill="#b8ff3d"/>
<rect x="37" y="9" width="18" height="18" rx="3" fill="#b8ff3d"/>
<rect x="9" y="37" width="18" height="18" rx="3" fill="#b8ff3d"/>
<rect x="37" y="37" width="18" height="18" rx="3" fill="#b8ff3d"/>
</svg>
EOF

cat > "$EXTROOT/usr/local/share/akuos/icons/power.svg" <<'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
<path d="M32 7v25" stroke="#b8ff3d" stroke-width="6" stroke-linecap="round"/>
<path d="M19 14a23 23 0 1 0 26 0" fill="none" stroke="#b8ff3d" stroke-width="6" stroke-linecap="round"/>
</svg>
EOF

# ---------------------------
# Generate tiny PNG launcher icons using Python stdlib only.
# No ImageMagick/Pillow dependency is required.
# ---------------------------
python3 - "$EXTROOT/usr/local/share/akuos/icons" <<'PY'
import os, struct, zlib, sys, math

out=sys.argv[1]
W=H=48

def png(name, kind):
    px=[]
    for y in range(H):
        row=bytearray([0])
        for x in range(W):
            # transparent rounded-square background
            dx=min(x, W-1-x); dy=min(y, H-1-y)
            edge=min(dx,dy)
            if edge < 2:
                a=0
            else:
                a=235
            r,g,b=10,14,18
            if kind=="terminal":
                if 13<x<35 and 18<y<31: r,g,b=184,255,61
            elif kind=="network":
                d=abs(math.hypot(x-24,y-31)-16)
                if d<2 or (y>28 and abs(x-24)<3): r,g,b=184,255,61
            elif kind=="files":
                if 12<x<37 and 17<y<34: r,g,b=184,255,61
            elif kind=="apps":
                if (10<x<19 or 27<x<37) and (10<y<19 or 27<y<37): r,g,b=184,255,61
            elif kind=="power":
                if abs(x-24)<2 and 9<y<27: r,g,b=184,255,61
                if ((x-24)**2+(y-29)**2 < 16**2 and
                    ((x-24)**2+(y-29)**2 > 11**2)): r,g,b=184,255,61
            else:
                if 11<x<37 and 13<y<34: r,g,b=184,255,61
            row += bytes((r,g,b,a))
        px.append(bytes(row))

    raw=b"".join(px)
    def chunk(t,d):
        return struct.pack(">I",len(d))+t+d+struct.pack(">I",zlib.crc32(t+d)&0xffffffff)
    data=b"\x89PNG\r\n\x1a\n"
    data+=chunk(b"IHDR",struct.pack(">IIBBBBB",W,H,8,6,0,0,0))
    data+=chunk(b"IDAT",zlib.compress(raw,9))
    data+=chunk(b"IEND",b"")
    with open(os.path.join(out,name+".png"),"wb") as f:f.write(data)

for n in ["computer","terminal","network","files","apps","power"]:
    png(n,n)
PY

# ---------------------------
# Generate an XBM wallpaper and WAV startup sound.
# ---------------------------
python3 - "$EXTROOT/usr/local/share/akuos/wallpapers" "$EXTROOT/usr/local/share/akuos/sounds" <<'PY'
import os, sys, math, wave, struct

wall=sys.argv[1]
snd=sys.argv[2]

W=128
H=128
bits=[]
for y in range(H):
    for x in range(W):
        # diagonal grid + central AkuOS mark
        grid=((x-y)%16==0 or (x+y)%16==0)
        cx,cy=64,64
        ring=abs(math.hypot(x-cx,y-cy)-28)<2
        dot=(x-cx)**2+(y-cy)**2<5**2
        bits.append(1 if grid or ring or dot else 0)

with open(os.path.join(wall,"aku-grid.xbm"),"w") as f:
    f.write("#define aku_width 128\n#define aku_height 128\n")
    f.write("static unsigned char aku_bits[] = {\n")
    for i in range(0,len(bits),8):
        v=0
        for b in range(8):
            if i+b<len(bits) and bits[i+b]: v|=1<<b
        f.write("0x%02x,"%v)
        if (i//8)%12==11:f.write("\n")
    f.write("};\n")

rate=8000
duration=0.42
samples=int(rate*duration)
with wave.open(os.path.join(snd,"startup.wav"),"wb") as w:
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate)
    for i in range(samples):
        t=i/rate
        env=min(1,t/0.03)*min(1,(duration-t)/0.08)
        freq=660 if t<0.18 else 990
        val=int(15000*env*math.sin(2*math.pi*freq*t))
        w.writeframes(struct.pack("<h",val))
PY

# ---------------------------
# AkuOS helper applications.
# ---------------------------
cat > "$EXTROOT/usr/local/bin/aku-about" <<'EOF'
#!/bin/sh
cat <<'TXT'
╔══════════════════════════════════════╗
║              AkuOS 1.0              ║
║       Tiny Linux • Ventoy Live      ║
╚══════════════════════════════════════╝

Base: TinyCorePure64 17.1
Architecture: x86_64

This system is intentionally tiny.
Use Tiny Core's package system to add
browsers, Wi-Fi firmware, media tools,
development tools and other applications.

Useful commands:
  apps                 package browser
  tce-load -wi NAME    download/install
  ifconfig             network status
  dmesg                hardware messages
  df -h                storage status
  free                 memory status

For Wi-Fi, the exact firmware depends on
your wireless chipset.
TXT
EOF
chmod +x "$EXTROOT/usr/local/bin/aku-about"

cat > "$EXTROOT/usr/local/bin/aku-network" <<'EOF'
#!/bin/sh
if command -v wifi-connect >/dev/null 2>&1; then
  exec wifi-connect
fi
if command -v wifi.sh >/dev/null 2>&1; then
  exec wifi.sh
fi
exec aterm -title "AkuOS Network" -geometry 92x22 -e sh -c '
echo "AkuOS Network"
echo "=============="
echo
echo "Ethernet: try DHCP first:"
echo "  sudo udhcpc -i eth0"
echo
echo "Wi-Fi is hardware-specific."
echo "Once you have Ethernet, install Tiny Core Wi-Fi support with:"
echo "  tce-load -wi wifi-manager"
echo
echo "Then inspect missing firmware with:"
echo "  dmesg | grep -i firmware"
echo
echo "Press Enter to close."
read x
'
EOF
chmod +x "$EXTROOT/usr/local/bin/aku-network"

cat > "$EXTROOT/usr/local/bin/aku-files" <<'EOF'
#!/bin/sh
if command -v fluff >/dev/null 2>&1; then
  exec fluff /home/tc
fi
exec aterm -title "AkuOS Files" -geometry 90x24
EOF
chmod +x "$EXTROOT/usr/local/bin/aku-files"

cat > "$EXTROOT/usr/local/bin/aku-apps" <<'EOF'
#!/bin/sh
if command -v apps >/dev/null 2>&1; then
  exec apps
fi
exec aterm -title "AkuOS Apps" -geometry 90x24 -e sh -c 'echo "Tiny Core package manager is unavailable."; read x'
EOF
chmod +x "$EXTROOT/usr/local/bin/aku-apps"

cat > "$EXTROOT/usr/local/bin/aku-terminal" <<'EOF'
#!/bin/sh
exec aterm -title "AkuOS Terminal" -geometry 96x28
EOF
chmod +x "$EXTROOT/usr/local/bin/aku-terminal"

cat > "$EXTROOT/usr/local/bin/aku-welcome" <<'EOF'
#!/bin/sh
# Apply AkuOS visual identity.
if command -v xsetroot >/dev/null 2>&1; then
  xsetroot -solid '#080b0f'
  xsetroot -bitmap /usr/local/share/akuos/wallpapers/aku-grid.xbm -fg '#b8ff3d' -bg '#080b0f' 2>/dev/null || true
fi

# FLWM title bar colour when supported.
export FLWM_TITLEBAR_COLOR='20:35:20'

# Play the bundled startup effect when ALSA is available.
if command -v aplay >/dev/null 2>&1; then
  (aplay -q /usr/local/share/akuos/sounds/startup.wav >/dev/null 2>&1 || true) &
fi

# Show the welcome window once per graphical session.
if [ ! -e /tmp/akuos-welcomed ]; then
  touch /tmp/akuos-welcomed
  (
    sleep 2
    aterm -title 'Welcome to AkuOS' -geometry 88x24 -e sh -c '
      clear
      printf "\033[1;32m"
      echo "   _  __      _   ___  ____  ____"
      echo "  / |/ /___ _| | / / |/ / / / / /"
      echo " /    / _ \` | |/ /    / /_/ / / "
      echo "/_/|_/\\_,_| |___/_/|_/\\____/_/  "
      printf "\033[0m"
      echo
      echo "  AkuOS 1.0  •  Tiny  •  Fast  •  Yours"
      echo
      echo "  Right-click the desktop for the system menu."
      echo "  Use the dock for Terminal, Files, Network and Apps."
      echo
      echo "  Internet: wired Ethernet works with the base system."
      echo "  Wi-Fi: install the hardware-specific firmware."
      echo
      echo "  Press Enter to close."
      read x
    '
  ) &
fi
EOF
chmod +x "$EXTROOT/usr/local/bin/aku-welcome"

# Desktop-start hook.
cat > "$EXTROOT/home/tc/.X.d/akuos" <<'EOF'
#!/bin/sh
/usr/local/bin/aku-welcome &
EOF
chmod +x "$EXTROOT/home/tc/.X.d/akuos"

# Wbar configuration with our generated PNG icons.
cat > "$EXTROOT/home/tc/.wbar" <<'EOF'
i: /usr/local/share/wbar/osxbarback.png
t: /usr/local/share/fonts/luxisr/12
c:
i: /usr/local/share/akuos/icons/terminal.png
t: Terminal
c: exec /usr/local/bin/aku-terminal
i: /usr/local/share/akuos/icons/files.png
t: Files
c: exec /usr/local/bin/aku-files
i: /usr/local/share/akuos/icons/network.png
t: Network
c: exec /usr/local/bin/aku-network
i: /usr/local/share/akuos/icons/apps.png
t: Apps
c: exec /usr/local/bin/aku-apps
i: /usr/local/share/akuos/icons/power.png
t: Exit
c: exec exittc
EOF

# Desktop menu entries.
for app in terminal files network apps; do
  case "$app" in
    terminal) NAME="AkuOS Terminal"; CMD="/usr/local/bin/aku-terminal"; ICON="/usr/local/share/akuos/icons/terminal.png";;
    files) NAME="AkuOS Files"; CMD="/usr/local/bin/aku-files"; ICON="/usr/local/share/akuos/icons/files.png";;
    network) NAME="AkuOS Network"; CMD="/usr/local/bin/aku-network"; ICON="/usr/local/share/akuos/icons/network.png";;
    apps) NAME="AkuOS Apps"; CMD="/usr/local/bin/aku-apps"; ICON="/usr/local/share/akuos/icons/apps.png";;
  esac
  cat > "$EXTROOT/usr/local/share/applications/aku-$app.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$NAME
Exec=$CMD
X-FullPathIcon=$ICON
Terminal=false
EOF
done

# A tiny release marker.
cat > "$EXTROOT/usr/local/share/akuos/RELEASE" <<'EOF'
AkuOS 1.0
Built from TinyCorePure64 17.1
x86_64
Ventoy-friendly live ISO
EOF

# Build our custom extension.
mkdir -p "$NEWISO/cde/optional"
mksquashfs "$EXTROOT" "$NEWISO/cde/optional/akuos.tcz" -noappend -comp xz -b 1M >/dev/null
printf '%s\n' 'akuos.tcz' > "$NEWISO/cde/onboot.lst"
: > "$NEWISO/cde/copy2fs.flg"

# Tell Tiny Core to scan CD extensions and mirror kernel messages to serial
# so CI can perform a real boot smoke test.
CFG="$NEWISO/boot/isolinux/isolinux.cfg"
if [ -f "$CFG" ]; then
  sed -i -E '/^[[:space:]]*APPEND[[:space:]]/ {
    /(^|[[:space:]])cde([[:space:]]|$)/! s/^[[:space:]]*APPEND[[:space:]]+/&cde /;
    /console=ttyS0/! s/$/ console=ttyS0,115200n8/;
  }' "$CFG"
else
  echo "[AkuOS] ERROR: isolinux.cfg not found"
  exit 1
fi

# Add a small AkuOS label without changing the underlying boot mechanics.
cat > "$NEWISO/AkuOS-README.txt" <<'EOF'
AkuOS 1.0
TinyCorePure64 17.1 base
Ventoy-compatible live ISO
EOF

echo "[AkuOS] Building ISO..."
ISO_ARGS=(
  -as mkisofs -l -J -R -V "AKUOS_1_0"
  -b boot/isolinux/isolinux.bin
  -c boot/isolinux/boot.cat
  -no-emul-boot -boot-load-size 4 -boot-info-table
)
# TinyCorePure64 includes an EFI El Torito image. Preserve it so the rebuilt
# ISO remains usable through Ventoy on UEFI machines as well as legacy BIOS.
if [ -f "$NEWISO/EFI/BOOT/efiboot.img" ]; then
  ISO_ARGS+=( -eltorito-alt-boot -e EFI/BOOT/efiboot.img -no-emul-boot )
fi
# Add GPT/UEFI-friendly metadata without requiring the old isohybrid MBR file.
ISO_ARGS+=( -isohybrid-gpt-basdat -o "$ISO_OUT" "$NEWISO" )
xorriso "${ISO_ARGS[@]}" >/dev/null 2>&1

SIZE=$(stat -c%s "$ISO_OUT")
MIB=$((SIZE / 1024 / 1024))
echo "[AkuOS] ISO size: $SIZE bytes (~$MIB MiB)"

if [ "$SIZE" -ge 50000000 ]; then
  echo "[AkuOS] ERROR: ISO is not below 50 MiB."
  exit 1
fi

sha256sum "$ISO_OUT" > "$DIST/AkuOS-1.0-x86_64.iso.sha256"
echo "[AkuOS] Done: $ISO_OUT"
