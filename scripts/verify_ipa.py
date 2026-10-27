"""Validate an unsigned ARM64 iPhone IPA, including Mach-O platform metadata."""
import hashlib, json, plistlib, struct, sys, zipfile
from pathlib import Path
p=Path(sys.argv[1])
with zipfile.ZipFile(p) as z:
    names=z.namelist()
    assert all(n.startswith('Payload/') and '..' not in n.split('/') for n in names), 'Unexpected archive entry'
    roots={n.split('/')[1] for n in names if n.count('/')>=1 and n.split('/')[1]}
    assert roots=={'BankingHackathonDemo.app'}, 'Expected one app in Payload'
    base='Payload/BankingHackathonDemo.app/'
    info=plistlib.loads(z.read(base+'Info.plist'))
    assert info['CFBundleIdentifier']=='io.hackathon.fictionalbank.chaselookalike'
    assert info['CFBundleDisplayName']=='Hackathon Demo'
    assert info['CFBundlePackageType']=='APPL'
    assert info['CFBundleSupportedPlatforms']==['iPhoneOS']
    assert info['DTPlatformName']=='iphoneos'
    assert info['MinimumOSVersion']=='17.0'
    assert info['UIDeviceFamily']==[1], 'Expected iPhone-only device family; got '+repr(info['UIDeviceFamily'])
    assert not any('_CodeSignature/' in n or n.endswith('embedded.mobileprovision') for n in names)
    assert not any(n.lower().endswith(('.jpeg','.jpg','.heic','.webp')) for n in names), 'Unexpected reference-like image'
    binary=z.read(base+info['CFBundleExecutable'])
    assert struct.unpack_from('<I',binary)[0]==0xfeedfacf, 'Expected thin 64-bit Mach-O'
    _,cpu,_,kind,ncmds,_,_,_=struct.unpack_from('<8I',binary)
    assert cpu==0x0100000c and kind==2, 'Expected ARM64 executable'
    cursor=32; platforms=[]
    for _ in range(ncmds):
        cmd,size=struct.unpack_from('<II',binary,cursor)
        if cmd==0x32: platforms.append(struct.unpack_from('<I',binary,cursor+8)[0])
        cursor+=size
    assert platforms==[2], 'Executable must target physical iOS, not iOS Simulator'
    assert b'DEMO CHECKING (...7264)' in binary and b'maple@example.com' in binary, 'Expected synthetic fixtures'
    assert not any(k.startswith('NSCamera') or 'Entitlement' in k for k in info), 'Unexpected capability'
report={'file':p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bundle_id':info['CFBundleIdentifier'],'display_name':info['CFBundleDisplayName'],'platform':'iPhoneOS','architecture':'arm64','macho_platform':'iOS (2)','minimum_ios':info['MinimumOSVersion'],'signed':False,'archive_entries':len(names),'fixture_check':'synthetic account and example.com contact present'}
print(json.dumps(report,indent=2))
if len(sys.argv)>2: Path(sys.argv[2]).write_text(json.dumps(report,indent=2)+'\n')
