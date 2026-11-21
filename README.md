# DeepMind's AArch64/Linux semantics as prove2.me definition bundles

This repo republishes the trusted Lean semantics `Arm64.Trusted` from
[google-deepmind/code-verification](https://github.com/google-deepmind/code-verification)
(Apache 2.0, upstream commit
[`8c8d371f`](https://github.com/google-deepmind/code-verification/tree/8c8d371f1962ac73435c8eb148678991f5c3470d/arm64-semantics/Arm64/Trusted), 2026-11-19) as
[prove2.me](https://prove2.me) definition bundles. It is meant as a **reusable library** for
prove2.me machine-code verification missions. The first mission to use it is zlib 1.3.1 CRC-32
on AArch64.

This is a derived copy, not a fork: the bundles are generated from that upstream commit, and
anyone can regenerate and check them (see [Tools](#tools)):

```
# from this repository's root
git clone https://github.com/google-deepmind/code-verification
git -C code-verification checkout 8c8d371f1962ac73435c8eb148678991f5c3470d
python3 tools/make_bundles.py code-verification/arm64-semantics Definitions 8c8d371f   # regenerate
python3 tools/check_bundles.py code-verification/arm64-semantics Definitions           # textual diff
python3 tools/compare_consts.py code-verification/arm64-semantics                      # elaborated constants
```

## What is published

**56 bundles, one per upstream module**, named after the module path:

- `Arm64/Trusted/ISA/Eval.lean` becomes the bundle `Arm64_ISA_Eval`, imported as
  `Definitions.Def_Arm64_ISA_Eval`.
- The upstream barrel `Arm64/Trusted.lean` becomes `Arm64`.
- `Syscalls.lean` and `Process.lean` become `Arm64_Syscalls` and `Arm64_Process`.

**The Lean namespace is upstream's `Arm64`, unchanged.** Definitions keep their upstream names,
such as `Arm64.Step` and `Arm64.Obj.PlacedLib.subroutineOk`, so specifications written against
upstream read the same here. Nothing in the library is specific to zlib or CRC.

Each file differs from upstream only as stated in a `MODIFIED for prove2.me` notice placed after
its Apache header:

1. **Imports.** Every `import Arm64.Trusted.<M>` becomes `import Definitions.Def_Arm64_<M>`.
2. **The `Surface` layer is not published.** These are upstream's six modules of `macro`/`syntax`/`elab`
   specification DSLs and file loaders (`Abi`, `CType`, `HexCode`, `Ascii`, `IncludeBytes`,
   `FileBytes`). prove2.me rejects metaprogramming in every submission, bundles included; a
   private probe on 2026-11-21 showed this. Imports of them are removed from the two barrels
   (`Arm64`, `Arm64_Process`). Nothing else imports them. Their elaborators only produce terms the
   published modules define, so a specification written with the DSL can be written out
   directly.
3. **`Step.extern` is renamed `Step.externHook`.** prove2.me's scanner rejects the token `extern`
   in code as a native-code binding, even as a constructor name. A private probe showed this
   too. The rename also covers the four backticked mentions in comments.
4. **Interpolated strings are written out.** The 69 `s!"…"` error messages, in `ISA_Decode`,
   `ISA_Eval`, `Process_Loader` and `Process_Overrides`, become their exact elaboration
   `(toString "…" ++ toString (e) ++ … : String)`. prove2.me rejects interpolated strings
   ("interpolations embed executable terms the guard cannot scan"), as the dry run found.
5. **One `meta import` is removed.** `Process/Loader` had `public meta import` of a module it
   already imports publicly, and the duplicate is dropped.

## Tools

- `tools/make_bundles.py UPSTREAM_DIR Definitions COMMIT` regenerates `Definitions/` from an
  upstream checkout. `UPSTREAM_DIR` is the `arm64-semantics` folder.
- `tools/check_bundles.py UPSTREAM_DIR Definitions` checks that every bundle equals its
  upstream file apart from the changes above.
- `tools/compare_consts.py UPSTREAM_LEAN_PROJECT` elaborates both sides and compares every
  constant's type and value. On 2026-11-21 all 5,962 constants matched. The comparison ignores
  hygienic binder names, module-name prefixes and the `extern` rename, none of which changes a
  term.
- `lake build` builds all 56 bundles on prove2.me's Lean `v4.33.1`, in about 25 s. The library
  needs no Mathlib.
- `tools/dryrun_publish.py` publishes the bundles privately under the throwaway prefix
  `P2mProbeArm64`, dependencies first, so the platform's compile and scanner can be tested
  before a real Submit.

## Later upstream versions

Published bundles are frozen, so a later upstream revision cannot replace these. It would go
up under a new prefix, such as `Arm64v2_…`, beside this one. Missions pin the version they
import.

## License

Apache License 2.0. Upstream's `LICENSE` is included unchanged. Every file keeps upstream's
copyright header (Google LLC) and carries the modification notice that section 4(b) of the
license requires.
