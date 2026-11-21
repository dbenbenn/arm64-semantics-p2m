#!/usr/bin/env python3
"""Check every bundle against upstream: identical except import lines, the MODIFIED notice,
the `extern` rename and the interpolated-string desugaring (applied to upstream here too).

Usage: check_bundles.py UPSTREAM_ARM64_SEMANTICS_DIR DEFINITIONS_DIR
"""
import pathlib, re, sys
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from make_bundles import desugar_interp
up = pathlib.Path(sys.argv[1]); dst = pathlib.Path(sys.argv[2])
IMP = re.compile(r"^\s*(public\s+)?(meta\s+)?import\s")
def body(text, drop_notice):
    t = text
    if drop_notice:
        t = re.sub(r"\n/-\nMODIFIED for prove2\.me.*?\n-/\n", "", t, count=1, flags=re.S)
    t = t.replace("`Step.externHook`", "`Step.extern`").replace(
        "  | externHook {s : State}", "  | extern {s : State}")
    return [l for l in t.split("\n") if not IMP.match(l)]
bad = 0; n = 0
for f in sorted(dst.glob("Def_Arm64*.lean")):
    rel = f.stem[len("Def_Arm64"):].lstrip("_")
    cands = [up / "Arm64/Trusted.lean"] if rel == "" else \
        [p for p in (up / "Arm64/Trusted").rglob("*.lean")
         if str(p.relative_to(up / "Arm64/Trusted").with_suffix("")).replace("/", "_") == rel]
    assert len(cands) == 1, (f, cands)
    if body(desugar_interp(cands[0].read_text())[0], False) != body(f.read_text(), True):
        print("DIFFERS:", f.name); bad += 1
    n += 1
print(f"{n} bundles checked, {bad} differ beyond imports and notice")
sys.exit(1 if bad else 0)
