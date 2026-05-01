# Build Guide

This repo contains the build *scripts* and *source code* but not the external
binary dependencies (IBM-copyrighted PC-DOS files, SCP ASM, etc.). You must
obtain those and place them at the expected paths.

## Required external materials

### 1. SCP ASM 2.43 + HEX2BIN

The Seattle Computer Products 8086 assembler. Used to assemble our `.ASM`
sources. Place these at:

```
build/tools/ASM.COM
build/tools/HEX2BIN.COM
```

Common archives: search for `86DOS_SCP.7z` or "Seattle Computer Products SCP
ASM" on Internet Archive.

### 2. PC-DOS 1.00 disk image

160 KB raw image of the original 1981 IBM PC-DOS 1.00 floppy. Used as a
base for `hybrid.img` and `selfboot.img` so that COMMAND.COM and friends are
in the right cluster positions.

```
build/refs/PCDOS100.img    (163840 bytes, sha256 29a4c5eb...)
```

The PCjs project archives this; see their published procedures. You can
convert their JSON disk format to flat binary using
[scripts/pcjs2img.py](scripts/pcjs2img.py).

### 3. Paterson source listings

Tim Paterson's 1981-07-07 PC-DOS 1.00 development source. Clone this repo as
a sibling directory:

```
$REPO/../Paterson-Listings/3_source_code/PC-DOS_1.00_dev/86DOS_1981-07-07.ASM
```

That is, `Paterson-Listings/` should be a sibling of this repo (not inside).

```bash
cd ..
git clone https://github.com/DOS-History/Paterson-Listings.git
```

### 4. DOSBox-X

Used to run SCP ASM (a DOS program) on a modern host.

```bash
# macOS
brew install dosbox-x
# Ubuntu
sudo apt install dosbox-x
```

### 5. Python 3

Used by the build scripts for binary patching.

## Building

After all dependencies are in place, from the repo root:

```bash
# Builds build/images/hybrid.img — PC-DOS 1.00 + our IBMDOS overlay.
./scripts/build.sh

# Builds build/images/selfboot.img — boot sector + IBMBIO + IBMDOS all ours.
./scripts/build_full.sh
```

Each script prints intermediate sizes and the final SHA-256.

## Testing in 86Box

Set up an 86Box VM:
- Machine: `ibmpc` (uses 24APR81 BIOS) or `ibmpc82` (uses 27OCT82)
- CPU: 8088 @ 4.77 MHz
- RAM: 256 KB
- Video: CGA
- Floppy 0: type `525_1dd`, file = your built `selfboot.img`

The selfboot output should reach `Enter today's date (m-d-y): _` after
printing `ABCISKXD@@OT@@RC...`.

## Burning to a real 5.25" floppy

See [docs/hardware-test-procedure-ko.txt](docs/hardware-test-procedure-ko.txt)
(Korean) and [docs/burning-procedure-ko.txt](docs/burning-procedure-ko.txt)
for the procedure used in this project. Summary:

1. **Use a real 40-track DD drive.** HD drives (96 TPI, 360 RPM) cannot
   reliably write disks readable by a 5150's DD drive (48 TPI, 300 RPM)
   even with track-doubling and rate translation.

2. **ImageDisk** (`IMD.COM`) is the reliable burner. RAWRITE doesn't know
   the 160 KB SSDD geometry and refuses with `can't figure out how many
   sectors/track`.

3. Convert each image with BIN2IMD first:

   ```
   BIN2IMD HELLO.IMG HELLO.IMD /1 N=40 SM=1-8 SS=512 DM=5
   ```

   - `/1` single-sided
   - `N=40` 40 cylinders (note: `N=` is *cylinders*, not sectors per track)
   - `SM=1-8` sector numbering map
   - `SS=512` sector size
   - `DM=5` 250 kbps MFM Double Density

4. In IMD, set Drive, Cylinders=40, Sides=ONE, Double-Step=OFF (DD native),
   then `W` to write.

5. Verify the burn with DOS DEBUG:

   ```
   -L 100 0 0 1
   -D 100 L 20
   ```

   Expected first bytes:

   - HELLO: `8A E2 FA 33 C0 8E D8 8E ...`
   - HYBRID/PCDOS100: `EB 2F 14 00 00 00 60 00 ...`
   - SELFBOOT: `FA 33 C0 8E D8 8E C0 8E ...`

   All zeros means the burn failed.
