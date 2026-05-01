#!/bin/bash
# Build hybrid PC-DOS 1.00 floppy image with kernel assembled from
# Paterson-Listings 86DOS_1981-07-07.ASM. Reproduces images/hybrid.img.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/../Paterson-Listings/3_source_code/PC-DOS_1.00_dev/86DOS_1981-07-07.ASM"
TOOLS="$ROOT/tools"
WORK="$ROOT/work"
REFS="$ROOT/refs"
IMG="$ROOT/images/hybrid.img"

mkdir -p "$WORK" "$ROOT/images"
cp "$TOOLS/ASM.COM" "$TOOLS/HEX2BIN.COM" "$WORK/"
cp "$SRC" "$WORK/86DOS.ASM"

cat >/tmp/dosbox_build.conf <<EOF
[autoexec]
mount c $WORK
c:
ASM 86DOS
HEX2BIN 86DOS
exit
EOF

dosbox-x -conf /tmp/dosbox_build.conf -nogui -fastlaunch -exit >/dev/null 2>&1

if ! grep -q "Error Count =    0" "$WORK/86DOS.PRN"; then
    echo "ASSEMBLY FAILED — see $WORK/86DOS.PRN"
    exit 1
fi

KERN_SIZE=$(stat -f%z "$WORK/86DOS.COM")
echo "kernel built: $KERN_SIZE bytes"

python3 - <<EOF
import shutil, struct
shutil.copy("$REFS/PCDOS100.img", "$IMG")
with open("$WORK/86DOS.COM","rb") as f: k = f.read()
padded = k + b"\x00" * (6400 - len(k))
with open("$IMG","r+b") as f:
    f.seek(0x1600)  # cluster 6 = LBA 11 = byte 0x1600
    f.write(padded)
    f.seek(510); f.write(b"\x55\xAA")   # boot signature
print(f"hybrid image: $IMG ({6400} bytes overlay)")
EOF

shasum -a 256 "$IMG"
echo "OK — burn this to a 160KB SSDD 5.25\" floppy"
