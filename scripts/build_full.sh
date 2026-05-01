#!/bin/bash
# Build full self-made boot image: our boot + our IBMBIO + our IBMDOS,
# combined with PC-DOS 1.00 COMMAND.COM and FAT/root dir layout.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/work"
SRC="$ROOT/src"
TOOLS="$ROOT/tools"
REFS="$ROOT/refs"
PATERSON="$ROOT/../Paterson-Listings/3_source_code/PC-DOS_1.00_dev"
IMG="$ROOT/images/selfboot.img"

mkdir -p "$WORK" "$ROOT/images"
cp "$TOOLS/ASM.COM" "$TOOLS/HEX2BIN.COM" "$WORK/"

build() {
    local name="$1"
    local src_path="$2"
    awk 'BEGIN{ORS="\r\n"}{print}' "$src_path" > "/tmp/${name}.tmp"
    printf '\x1a' >> "/tmp/${name}.tmp"
    cp "/tmp/${name}.tmp" "$WORK/${name}.ASM"
    rm -f "$WORK/${name}.HEX" "$WORK/${name}.PRN" "$WORK/${name}.COM" 2>/dev/null

    cat > /tmp/dosbox_b.conf <<EOF
[autoexec]
mount c $WORK
c:
ASM ${name}
HEX2BIN ${name}
exit
EOF
    ( dosbox-x -conf /tmp/dosbox_b.conf -nogui -fastlaunch -exit >/dev/null 2>&1 ) &
    local PID=$!
    sleep 7
    kill -9 $PID 2>/dev/null || true
    wait $PID 2>/dev/null || true

    if ! grep -q "Error Count =    0" "$WORK/${name}.PRN"; then
        echo "ASSEMBLY FAILED for $name"
        grep -B1 "ERROR no" "$WORK/${name}.PRN" | head -10
        exit 1
    fi
    echo "$name -> $(stat -f%z "$WORK/${name}.COM") bytes"
}

build BOOT   "$SRC/BOOT.ASM"
build IBMBIO "$SRC/IBMBIO.ASM"
build 86DOS  "$PATERSON/86DOS_1981-07-07.ASM"

python3 - <<EOF
import shutil, struct
shutil.copy("$REFS/PCDOS100.img", "$IMG")

with open("$WORK/BOOT.COM","rb") as f: boot = f.read()
with open("$WORK/IBMBIO.COM","rb") as f: bio = f.read()
with open("$WORK/86DOS.COM","rb") as f: dos = f.read()

print(f"boot={len(boot)} bio={len(bio)} dos={len(dos)}")

# pad to slot sizes
boot   = boot + b"\x00" * (512  - len(boot))
boot   = boot[:510] + b"\x55\xAA"               # boot signature (later 5150 BIOS / clones check)
bio    = bio  + b"\x00" * (2048 - len(bio))    # 4 sectors
dos    = dos  + b"\x00" * (6656 - len(dos))    # 13 sectors

with open("$IMG","r+b") as f:
    f.seek(0x0000); f.write(boot)               # boot sector
    f.seek(0x0E00); f.write(bio)                # LBA 7
    f.seek(0x1600); f.write(dos)                # LBA 11

# update root dir IBMBIO.COM size to match our build (string literal at offset 0x1c)
import struct
with open("$IMG","r+b") as f:
    # entry 0 = IBMBIO.COM at 0x600
    f.seek(0x600 + 28)
    f.write(struct.pack("<I", 329))   # actual file size; cluster chain unchanged
    # entry 1 = IBMDOS.COM at 0x620
    f.seek(0x620 + 28)
    f.write(struct.pack("<I", 6211))

print(f"selfboot image: $IMG")
EOF

shasum -a 256 "$IMG"
