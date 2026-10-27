import sys, zipfile
from pathlib import Path
app=Path(sys.argv[1]); out=Path(sys.argv[2]); out.parent.mkdir(parents=True,exist_ok=True)
assert app.name=='BankingHackathonDemo.app'
with zipfile.ZipFile(out,'w',zipfile.ZIP_DEFLATED) as z:
    for p in sorted(app.rglob('*')):
        if p.is_file():
            n='Payload/'+app.name+'/'+p.relative_to(app).as_posix()
            entry=zipfile.ZipInfo.from_file(p,n); entry.external_attr=(0o100755 if p.name=='BankingHackathonDemo' else 0o100644)<<16; entry.compress_type=zipfile.ZIP_DEFLATED
            z.writestr(entry,p.read_bytes())
print('Packaged unsigned device app into Payload/BankingHackathonDemo.app')
