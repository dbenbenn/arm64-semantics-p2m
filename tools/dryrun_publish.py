#!/usr/bin/env python3
"""Private dry run: publish every bundle under the probe prefix P2mProbeArm64, dependencies first.

Writes dryrun/state.json (name -> job/status/error) and updates the monitor section
`arm64-dryrun`. Resumable: names already PUBLISHED are skipped.
"""
import json, os, pathlib, re, sys, time
sys.path.insert(0, os.path.expanduser('~/.claude/skills/prove2me/scripts'))
sys.path.insert(0, os.path.expanduser('~/.claude/skills/monitor'))
import p2m, section

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / 'Definitions'; ST = ROOT / 'dryrun/state.json'
PFX_OLD, PFX_NEW = 'Arm64', 'P2mProbeArm64'
IMP = re.compile(r'^\s*public\s+import\s+Definitions\.Def_(\S+)\s*$', re.M)

def probe_name(n): return PFX_NEW + n[len(PFX_OLD):]
mods = {f.stem[len('Def_'):]: f.read_text() for f in sorted(SRC.glob('Def_*.lean'))}
deps = {n: IMP.findall(t) for n, t in mods.items()}
state = json.loads(ST.read_text()) if ST.exists() else {}
def save(): ST.write_text(json.dumps(state, indent=1, sort_keys=True))
def mon(st='running', alert=None):
    done = sum(1 for v in state.values() if v.get('status') == 'PUBLISHED')
    bad = [k for k, v in state.items() if v.get('status') in ('FAILED', 'ERROR')]
    section.publish('arm64-dryrun', title='Arm64 semantics: private publish dry run (56 bundles)',
        state=st, phases=[{'name': 'Bundles published', 'done': done, 'total': len(mods),
                           'note': f'{len(bad)} failed' if bad else ''}],
        alerts=[alert] if alert else [], owner='Claude session 569e7719',
        processes=[{'label': 'dry run', 'match': r'dryrun_publish\.py'}], heartbeat_secs=120)

def body(n):
    t = mods[n].replace('Definitions.Def_Arm64', 'Definitions.Def_' + PFX_NEW)
    return {"definition_name": probe_name(n),
            "definition_title": f"Private dry run: {n}",
            "definition": t,
            "natural_language_statement": "Private dry run of republishing DeepMind's Arm64.Trusted semantics. To be deprecated.",
            "source": "google-deepmind/code-verification 8c8d371f (Apache 2.0); private dry run.",
            "private": True}

while True:
    pending = [n for n in mods if state.get(n, {}).get('status') != 'PUBLISHED']
    if not pending: mon('done'); print('all published'); break
    failed = [n for n in pending if state.get(n, {}).get('status') in ('FAILED', 'ERROR')]
    inflight = [n for n in pending if state.get(n, {}).get('status') not in (None, 'PUBLISHED', 'FAILED', 'ERROR')]
    for n in inflight:
        r = p2m.call('GET', f"/publish-jobs/{state[n]['job_id']}")
        state[n]['status'] = r.get('status'); state[n]['error'] = r.get('error_message', '')
        if r.get('theorem_id'): state[n]['id'] = r['theorem_id']
    ready = [n for n in pending if n not in state or state[n].get('status') is None]
    ready = [n for n in ready if all(state.get(d, {}).get('status') == 'PUBLISHED' for d in deps[n])]
    for n in ready:
        r = p2m.call('POST', '/submit-definition', body(n))
        state[n] = {'job_id': r.get('job_id'), 'status': r.get('status'), 'error': r.get('message', '') if not r.get('job_id') else ''}
        if not r.get('job_id'): state[n]['status'] = 'ERROR'; state[n]['error'] = json.dumps(r)[:1000]
        time.sleep(2)
    save()
    failed = [n for n in mods if state.get(n, {}).get('status') in ('FAILED', 'ERROR')]
    blocked = [n for n in mods if n not in state and any(d in failed or (d in state and state[d].get('status') in ('FAILED','ERROR')) for d in deps[n])]
    stuck = not [n for n in mods if state.get(n, {}).get('status') not in (None, 'PUBLISHED', 'FAILED', 'ERROR')] and not ready
    if failed and stuck:
        mon('failed', f'{len(failed)} bundles failed: ' + ', '.join(failed)); print('FAILED', failed); break
    mon(); time.sleep(30)
