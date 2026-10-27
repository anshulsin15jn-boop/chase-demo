"""Check tracked files/history without printing private content or secret matches."""
import re, subprocess, sys
from pathlib import Path
root = Path(__file__).resolve().parents[1]
def git(*args): return subprocess.check_output(['git', *args], cwd=root)
issues=[]
def inspect(name, data):
    lower=name.lower()
    if any(x in lower for x in ['chasereferences/', 'whatsapp image', '/private/']): issues.append((name,'private reference path'))
    if Path(name).suffix.lower() in {'.png','.jpg','.jpeg','.heic','.webp','.mov','.mp4','.ipa','.p12','.mobileprovision','.key'}: issues.append((name,'unexpected binary or credential file'))
    text=data.decode('utf-8', errors='replace')
    if re.search(r'gh[pousr]_[A-Za-z0-9]{30,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',text): issues.append((name,'credential pattern'))
    # User data is restricted to example.com; Git authors and official source URLs are reviewed separately.
    if name.startswith(('App/','Sources/')):
        for email in re.findall(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}',text):
            if not email.endswith('@example.com'): issues.append((name,'nonfictional email pattern'))
        for phone in re.findall(r'\(\d{3}\) \d{3}-\d{4}',text):
            if not re.fullmatch(r'\(202\) 555-01\d{2}',phone): issues.append((name,'nonfictional phone pattern'))
for path in git('ls-files','-z').decode().split('\0'):
    if path and (root/path).is_file(): inspect(path,(root/path).read_bytes())
for commit in git('rev-list','--all').decode().split():
    for path in git('ls-tree','-r','--name-only',commit).decode().splitlines(): inspect(path,git('show',f'{commit}:{path}'))
if issues:
    for name, category in sorted(set(issues)): print(f'{category}: {name}')
    sys.exit(1)
print('PASS: tracked files and reachable history: no private reference files, credential patterns, or non-demo app contacts found.')
