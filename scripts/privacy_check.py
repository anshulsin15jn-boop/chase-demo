"""Audit source, index and reachable history without printing private values.

Runtime input remains local and may contain any supported name, phone or email.
Only committed demo fixtures are constrained to synthetic contacts. The supplied
standalone icon is the sole approved bitmap asset exception.
"""
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[1]
def git(*args):
    return subprocess.check_output(['git', *args], cwd=root)

manifest = root / 'Assets/approved-icon-sha256.json'
approved = json.loads(manifest.read_text()) if manifest.exists() else {}
issues = []
def inspect(name, data):
    lower = name.lower()
    if any(value in lower for value in ['chasereferences/', 'whatsapp image', '/private/', 'image(4)']):
        issues.append((name, 'private comparison/reference path'))
    image = data.startswith((b'\x89PNG\r\n\x1a\n', b'\xff\xd8\xff', b'GIF8'))
    image_extension = Path(name).suffix.lower() in {'.png', '.jpg', '.jpeg', '.heic', '.webp'}
    if image or image_extension:
        if name not in approved or hashlib.sha256(data).hexdigest() != approved[name]:
            issues.append((name, 'bitmap is not the reviewed standalone icon'))
        return
    if Path(name).suffix.lower() in {'.mov', '.mp4', '.ipa', '.p12', '.mobileprovision', '.key', '.cer'}:
        issues.append((name, 'unexpected artifact or credential file'))
    text = data.decode('utf-8', errors='replace')
    if re.search(r'gh[pousr]_[A-Za-z0-9]{30,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----', text):
        issues.append((name, 'credential pattern'))
    if re.search(r'data:image/(?:png|jpeg);base64,', text):
        issues.append((name, 'embedded bitmap data'))
    if name.startswith(('App/', 'Sources/')) and not name.startswith('App/Assets.xcassets/'):
        for email in re.findall(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', text):
            if not email.endswith('@example.com'):
                issues.append((name, 'non-synthetic hardcoded fixture email'))
        for digits in re.findall(r'phoneDigits:\s*"([0-9]+)"', text):
            if not re.fullmatch(r'20255501\d{2}', digits):
                issues.append((name, 'non-synthetic hardcoded fixture phone'))
        for phone in re.findall(r'\(\d{3}\) \d{3}-\d{4}', text):
            if not re.fullmatch(r'\(202\) 555-01\d{2}', phone):
                issues.append((name, 'non-synthetic hardcoded fixture phone'))

blobs = set()
for row in git('ls-files', '--stage', '-z').decode().split('\0'):
    if not row:
        continue
    metadata, name = row.split('\t', 1)
    blobs.add((metadata.split()[1], name))
    path = root / name
    if path.is_file():
        inspect(name, path.read_bytes())
for commit in git('rev-list', '--all').decode().split():
    for row in git('ls-tree', '-r', '-z', commit).decode().split('\0'):
        if row:
            metadata, name = row.split('\t', 1)
            if metadata.split()[1] == 'blob':
                blobs.add((metadata.split()[2], name))
cache = {}
for oid, name in blobs:
    if oid not in cache:
        cache[oid] = git('cat-file', 'blob', oid)
    inspect(name, cache[oid])
if issues:
    for name, category in sorted(set(issues)):
        print(f'{category}: {name}')
    sys.exit(1)
print('PASS: working tree, staged files and reachable history contain only approved icon images, synthetic app fixtures, and no credential patterns.')
