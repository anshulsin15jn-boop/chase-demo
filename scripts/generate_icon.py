"""Validate the approved supplied artwork and prebuilt opaque AppIcon sizes.

The historical script name is retained for the existing workflow. It no longer
generates replacement artwork or adds lettering.
"""
import hashlib
import json
import struct
from pathlib import Path

root = Path(__file__).resolve().parents[1]
catalog = root / 'App/Assets.xcassets/AppIcon.appiconset'
approved = json.loads((root / 'Assets/approved-icon-sha256.json').read_text())
entries = json.loads((catalog / 'Contents.json').read_text())['images']
assert len(entries) == 9
for entry in entries:
    path = catalog / entry['filename']
    data = path.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
    width, height, depth, color = struct.unpack_from('>IIBB', data, 16)
    expected = int(entry['size'].split('x')[0]) * int(entry['scale'][0])
    assert (width, height) == (expected, expected)
    assert depth == 8 and color == 2, 'App icons must be opaque RGB PNGs'
    offset = 8
    while offset < len(data):
        length = struct.unpack_from('>I', data, offset)[0]
        assert data[offset + 4:offset + 8] != b'tRNS', 'No transparent color key'
        offset += length + 12
    relative = path.relative_to(root).as_posix()
    assert hashlib.sha256(data).hexdigest() == approved[relative], 'Artwork changed without approval'
    assert entry['idiom'] == ('ios-marketing' if width == 1024 else 'iphone')
master = root / 'Assets/IconArtwork.png'
assert hashlib.sha256(master.read_bytes()).hexdigest() == approved['Assets/IconArtwork.png']
print('PASS: supplied artwork and all 9 opaque AppIcon sizes match the reviewed catalog.')
