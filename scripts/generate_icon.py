"""Generate an original geometric demo icon without using reference assets."""
import json, struct, zlib
from pathlib import Path
size=1024
rows=[]
for y in range(size):
    row=bytearray()
    for x in range(size):
        roof=200<=y<=380 and abs(x-512)<=(y-180)*1.5
        columns=420<=y<=680 and any(a<=x<=a+60 for a in [260,400,540,680])
        base=730<=y<=785 and 210<=x<=810
        stripe=835<=y<=865 and 350<=x<=674
        color=(255,255,255) if roof or columns or base or stripe else (0,72+int(y/32),150+int(y/24))
        row.extend(color)
    rows.append(b'\0'+row)
def chunk(kind,data): return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
image=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('>IIBBBBB',size,size,8,2,0,0,0))+chunk(b'IDAT',zlib.compress(b''.join(rows)))+chunk(b'IEND',b'')
p=Path('App/Assets.xcassets/AppIcon.appiconset');p.mkdir(parents=True,exist_ok=True)
(p/'AppIcon.png').write_bytes(image)
(p/'Contents.json').write_text(json.dumps({'images':[{'filename':'AppIcon.png','idiom':'universal','platform':'ios','size':'1024x1024'}],'info':{'author':'demo','version':1}}))
(p.parent/'Contents.json').write_text(json.dumps({'info':{'author':'demo','version':1}}))
print('Generated original geometric app icon.')
