#!/usr/bin/env python3
"""Check that the bundles elaborate to the same constants as upstream.

Usage: compare_consts.py UPSTREAM_LEAN_PROJECT_DIR
  UPSTREAM_LEAN_PROJECT_DIR: a built lake project containing upstream `Arm64.Trusted` (e.g.
  ~/claude/crc32-pilot/lean, whose copy is byte-identical to upstream 8c8d371f).
Dumps every constant of the non-Surface modules (name, type, value as `Expr.dbgToString`) on
both sides, normalizes module-name prefixes (`Arm64.Trusted.X.Y` vs `Definitions.Def_Arm64_X_Y`)
and the intended rename `Step.extern` -> `Step.externHook`, and reports any difference.
"""
import hashlib, pathlib, re, subprocess, sys
ROOT = pathlib.Path(__file__).resolve().parent.parent
UP = pathlib.Path(sys.argv[1]).resolve()
mods = sorted(f.stem[len('Def_'):] for f in (ROOT / 'Definitions').glob('Def_*.lean'))
def upmod(n): return 'Arm64.Trusted' if n == 'Arm64' else 'Arm64.Trusted.' + n[len('Arm64_'):].replace('_', '.')
# module names with underscores (none expected upstream) would break this mapping
DUMP = r'''
open Lean in
#eval show CoreM Unit from do
  let env ← getEnv
  let mut lines : Array String := #[]
  for (n, ci) in env.constants.toList do
    match env.getModuleIdxFor? n with
    | some idx =>
      let m := (env.header.moduleNames[idx.toNat]!).toString
      if PRED then
        let v := match ci.value? with | some e => e.dbgToString | none => "-"
        lines := lines.push (n.toString ++ "\t" ++ ci.type.dbgToString ++ "\t" ++ v)
    | none => pure ()
  IO.FS.writeFile "OUT" ("\n".intercalate (lines.qsort (· < ·)).toList)
'''
def run(proj, imports, pred, out):
    b = subprocess.run(['lake', 'build'] + ['+' + i for i in imports], cwd=proj, capture_output=True, text=True)
    if b.returncode: sys.exit(b.stdout[-3000:] + b.stderr[-3000:])
    f = proj / '_compare_dump.lean'
    f.write_text('\n'.join(['import Lean'] + [f'import {i}' for i in imports]) + '\n' + DUMP.replace('PRED', pred).replace('OUT', str(out)))
    r = subprocess.run(['lake', 'env', 'lean', str(f)], cwd=proj, capture_output=True, text=True)
    f.unlink()
    if r.returncode: sys.exit(r.stdout[-3000:] + r.stderr[-3000:])
tmp = ROOT / '.lake' / 'compare'; tmp.mkdir(parents=True, exist_ok=True)
run(UP, [upmod(m) for m in mods if m != 'Arm64'], '(m.startsWith "Arm64.Trusted") && !(m.startsWith "Arm64.Trusted.Surface")', tmp / 'up.txt')
run(ROOT, [f'Definitions.Def_{m}' for m in mods], 'm.startsWith "Definitions.Def_Arm64"', tmp / 'new.txt')
def norm(s):
    s = re.sub(r'Definitions\.Def_Arm64((?:_[A-Za-z]+)*)', lambda m: 'Arm64.Trusted' + m.group(1).replace('_', '.'), s)
    return s
HYG = re.compile(r"\._@\.[A-Za-z0-9_.]*?\._hyg\.\d+")
def common(s):
    # binder names do not affect the term; hygienic suffixes carry module names and counters
    return HYG.sub("._hyg", s)
def load(p, is_new):
    d = {}
    for l in p.read_text().split('\n'):
        if not l: continue
        n, t, v = l.split('\t', 2)
        if is_new:
            n, t, v = [re.sub(r"\bexternHook\b", "extern", norm(x)).replace("_aux_Definitions_Def_Arm64_", "_aux_Arm64_Trusted_") for x in (n, t, v)]
        n, t, v = n, common(t), common(v)
        d[n] = (t, v)
    return d
a, b = load(tmp / 'up.txt', False), load(tmp / 'new.txt', True)
onlya = sorted(set(a) - set(b)); onlyb = sorted(set(b) - set(a))
diff = [n for n in sorted(set(a) & set(b)) if a[n] != b[n]]
print(f'upstream {len(a)} constants, bundles {len(b)}; only upstream {len(onlya)}, only bundles {len(onlyb)}, differing {len(diff)}')
for n in onlya[:20]: print('  only upstream:', n)
for n in onlyb[:20]: print('  only bundles:', n)
for n in diff[:20]: print('  differs:', n)
sys.exit(1 if (onlya or onlyb or diff) else 0)
