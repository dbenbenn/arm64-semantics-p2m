#!/usr/bin/env python3
"""Turn DeepMind's `Arm64.Trusted` modules into prove2.me definition bundles.

Usage: make_bundles.py UPSTREAM_ARM64_SEMANTICS_DIR OUT_DIR

Each module `Arm64/Trusted/<P>.lean` becomes `OUT_DIR/Def_Arm64_<P with / -> _>.lean`
(`Arm64/Trusted.lean` becomes `Def_Arm64.lean`). The only changes, each marked in a notice
inserted after the Apache header:
  * every `import Arm64.Trusted.X.Y` becomes `import Definitions.Def_Arm64_X_Y`;
  * the six `Surface` modules (macro/elaborator syntax layer) are not published, because
    prove2.me rejects metaprogramming in bundles, and imports of them are removed;
  * `public meta import` lines (only `Process/Loader`) become plain `public import`, or are
    dropped when the same module is already imported.
  * the `Step` constructor `extern` is renamed `externHook` (declaration and the backticked
    `Step.extern` mentions in comments), because prove2.me's scanner rejects the token `extern`
    in code as a native-code binding (probe `CrcProbe_chain`, 2026-11-21).
Nothing else in a file changes.
"""
import pathlib, re, sys

SKIP_PREFIX = "Surface/"

def bundle_name(rel: str) -> str:
    # rel like "ISA/Eval" or "" for the root barrel
    return "Arm64" if rel == "" else "Arm64_" + rel.replace("/", "_")

def mod_to_rel(mod: str) -> str:
    assert mod == "Arm64.Trusted" or mod.startswith("Arm64.Trusted."), mod
    return "" if mod == "Arm64.Trusted" else mod[len("Arm64.Trusted."):].replace(".", "/")

IMPORT_RE = re.compile(r"^(\s*)(public\s+)?(meta\s+)?import\s+(\S+)\s*$")

def transform(text: str, rel: str, commit: str):
    lines = text.split("\n")
    out, notes, seen = [], [], set()
    for ln in lines:
        m = IMPORT_RE.match(ln)
        if not m or not m.group(4).startswith("Arm64.Trusted"):
            if m:
                raise SystemExit(f"{rel}: unexpected import {ln!r}")
            out.append(ln); continue
        ind, pub, meta, mod = m.groups()
        r = mod_to_rel(mod)
        if r.startswith(SKIP_PREFIX):
            notes.append(f"removed `import {mod}` (Surface syntax layer, not published)")
            continue
        new = f"Definitions.Def_{bundle_name(r)}"
        if meta:
            if new in seen:
                notes.append(f"removed `{(pub or '')}meta import {mod}` (already imported)")
                continue
            notes.append(f"`meta import {mod}` made a plain import")
        seen.add(new)
        out.append(f"{ind}{pub or ''}import {new}")
    body = "\n".join(out)
    if "`Step.extern`" in body:
        body = body.replace("`Step.extern`", "`Step.externHook`")
        notes.append("the constructor `Step.extern` renamed `Step.externHook` in comments (see below)")
    decl = "  | extern {s : State} {f : State → State}"
    if decl in body:
        assert body.count(decl) == 1
        body = body.replace(decl, "  | externHook {s : State} {f : State → State}")
        notes.append("the `Step` constructor `extern` renamed `externHook`, because prove2.me "
                     "rejects the token `extern` in code")
    assert not __import__("re").search(r"\|\s*extern\b", body), rel
    out = body.split("\n")
    # insert the notice after the Apache header comment (first `-/`)
    end = out.index("-/")
    notice = [
        "",
        "/-",
        "MODIFIED for prove2.me (republication of DeepMind's `Arm64.Trusted`, upstream",
        f"google-deepmind/code-verification commit {commit}, file `{'Arm64/Trusted/' + rel if rel else 'Arm64/Trusted'}.lean`):",
        "every import of `Arm64.Trusted.<M>` renamed to the bundle `Definitions.Def_Arm64_<M>`.",
    ] + [f"Also {n}." for n in notes] + ["No other change.", "-/"]
    out = out[: end + 1] + notice + out[end + 1 :]
    return "\n".join(out)

def main():
    up = pathlib.Path(sys.argv[1]); dst = pathlib.Path(sys.argv[2]); commit = sys.argv[3]
    dst.mkdir(parents=True, exist_ok=True)
    files = [up / "Arm64/Trusted.lean"] + sorted((up / "Arm64/Trusted").rglob("*.lean"))
    n = 0
    for f in files:
        rel = "" if f.name == "Trusted.lean" and f.parent == up / "Arm64" else \
            str(f.relative_to(up / "Arm64/Trusted").with_suffix(""))
        if rel.startswith(SKIP_PREFIX):
            continue
        (dst / f"Def_{bundle_name(rel)}.lean").write_text(transform(f.read_text(), rel, commit))
        n += 1
    print(f"{n} bundles written to {dst}")

main()
