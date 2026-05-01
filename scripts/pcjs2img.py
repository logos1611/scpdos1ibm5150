#!/usr/bin/env python3
import json, struct, sys

def convert(json_path, img_path):
    with open(json_path) as f:
        d = json.load(f)
    cyls = d['diskData']
    sec_size = cyls[0][0][0]['l']
    out = bytearray()
    for cyl in cyls:
        for head in cyl:
            for sec in sorted(head, key=lambda s: s['s']):
                words = sec['d']
                last = words[-1] if words else 0
                full = words + [last] * (sec_size // 4 - len(words))
                buf = b''.join(struct.pack('<i', w) for w in full[:sec_size // 4])
                if len(buf) != sec_size:
                    raise SystemExit(f'sector C{sec["c"]}H{sec["h"]}S{sec["s"]} bad len {len(buf)}')
                out += buf
    with open(img_path, 'wb') as f:
        f.write(out)
    print(f'wrote {img_path} ({len(out)} bytes = {len(out)//1024}KB)')

if __name__ == '__main__':
    convert(sys.argv[1], sys.argv[2])
