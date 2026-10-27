import json, os, subprocess
state=json.loads(subprocess.check_output(['xcrun','simctl','list','devices','available','--json']))
phones=[d for runtime,devices in state['devices'].items() if 'iOS' in runtime for d in devices if d['name'].startswith('iPhone')]
assert phones,'No installed iPhone simulator'
phones.sort(key=lambda d:(0 if d['name']=='iPhone 16 Pro' else 1 if d['name']=='iPhone 17 Pro' else 2 if 'Pro' in d['name'] and 'Max' not in d['name'] else 3,d['name']))
d=phones[0]
with open(os.environ['GITHUB_ENV'],'a') as f: f.write('SIMULATOR_ID='+d['udid']+'\nSIMULATOR_NAME='+d['name']+'\n')
print('Simulator:',d['name'])
