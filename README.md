# PC-DOS 1.00 on Real IBM 5150

> Re-creating the 1981 PC-DOS 1.00 boot chain (boot sector + IBMBIO + IBMDOS) from
> Tim Paterson's source listings, and booting it on a real IBM 5150 with the
> original 04/24/81 BIOS.

[한국어 문서](PROJECT.md) — 자세한 개발 과정 기록 (Korean detailed log)

## What this project does

Builds a bootable IBM 5150 floppy image where every code layer below COMMAND.COM
is reconstructed from period sources or hand-written:

| Layer | Source | This project's contribution |
|-------|--------|------------------------------|
| Boot sector | Tim Paterson interface | **Hand-written** ([src/BOOT.ASM](src/BOOT.ASM), 132 bytes) |
| IBMBIO | 86-DOS DOSIO.ASM reference | **Hand-written** ([src/IBMBIO.ASM](src/IBMBIO.ASM), ~400 bytes) |
| IBMDOS kernel | Paterson 1981-07-07 dev source | Built with SCP ASM 2.43 (6211 bytes) |
| COMMAND.COM | IBM 1981 (you must provide) | Used as-is |

The resulting `selfboot.img` boots end-to-end on a 1981 IBM 5150 with the
original BIOS_5150_24APR81 ROM:

```
ABCISKXD@@OT@@RC@@@@@@@@@@
Enter today's date (m-d-y): _
```

Each letter is a debug marker — A/B/C from the boot sector, I/S/K/X/D from
IBMBIO, @ on every BIOSREAD, O/T/R during COMMAND.COM load, final C before
the FAR jump into COMMAND.

## What is and isn't in this repo

**Included** (our original work, MIT-licensed):
- `src/` — Boot sector, IBMBIO, and a diagnostic HELLO.ASM
- `scripts/` — Build scripts (Bash + Python) using SCP ASM via DOSBox-X
- `images/HELLO.IMG` — Pre-built diagnostic boot image (no IBM code, just our
  HELLO.ASM padded with zeros + 0xAA55 signature)
- `docs/` — Korean test/burn procedures we wrote
- [`PROJECT.md`](PROJECT.md) — Full Korean-language project journal

**Not included** (you must obtain separately):
- `IBMDOS.COM` source listings — clone the
  [Paterson-Listings](https://github.com/DOS-History/Paterson-Listings) repo
- `PCDOS100.img` — the original 1981 IBM PC-DOS 1.00 floppy image. PCjs has it
  archived; obtain via their published procedures
- `IBMBIO.COM`, `COMMAND.COM` — extract from your own PC-DOS 1.00 disk
- SCP ASM 2.43 / HEX2BIN — Seattle Computer Products assembler
- `RAWRITE3.COM` / `IMD.COM` / `BIN2IMD.COM` — floppy burners (FreeDOS / Dunfield)
- `BIOS_5150_*.bin` — IBM 5150 ROM images (for emulator)

These are excluded because the binaries remain under their original
copyrights (IBM, Microsoft, Sydex, Gilles Vollant, etc.). The build scripts
expect them at known paths (see [`BUILD.md`](BUILD.md)).

## Quick start

```bash
# Prerequisites:
#   - macOS or Linux
#   - DOSBox-X (for running SCP ASM)
#   - Python 3
#
#   And in build/refs/:
#     - PCDOS100.img        (PCjs-derived, raw 160KB)
#     - SCP ASM tooling extracted in build/tools/

# Build hybrid.img (PC-DOS 1.00 boot + our IBMDOS):
./scripts/build.sh

# Build selfboot.img (full self-built stack):
./scripts/build_full.sh
```

See [`BUILD.md`](BUILD.md) for paths, dependencies, and burning to floppy.

## Hardware tested

- IBM 5150, U33 ROM part number `1501476` = BIOS dated 04/24/81
  (the original first-revision 5150 ROM from August 1981)
- 5.25" single-sided DD drive (40 cyl × 1 head × 8 spt × 512 B = 160 KB)
- Sony SFD-500P 5.25" DD drive in a 486 PC for floppy creation

## Why

Bit-perfect reproduction of the 1981 PC boot stack as a learning exercise.
The Paterson source has been publicly archived; the IBM-specific glue
(IBMBIO, boot sector) was reconstructed from references and from reading
86-DOS source for register-level conventions.

86Box emulator passes were the first checkpoint, but the more interesting
fact is that the same image boots on real 1981 hardware on the original
BIOS — meaning this is the same byte-level boot sequence a 1981 user would
have seen.

## License

Our original work in this repository is MIT-licensed. See [`LICENSE`](LICENSE).

This license covers only files we authored (src/*.ASM, scripts/*, docs/*,
markdown files). External dependencies retain their own copyrights — see
each upstream's terms.

## Acknowledgements

- Tim Paterson — original 86-DOS / PC-DOS author whose listings made this possible
- [DOS-History/Paterson-Listings](https://github.com/DOS-History/Paterson-Listings) — preserving the listings
- [PCjs](https://www.pcjs.org/) — comprehensive vintage PC software archive
- [86Box](https://86box.net/) — accurate IBM 5150 emulation
- [Dave Dunfield](http://dunfield.classiccmp.org/) — ImageDisk
