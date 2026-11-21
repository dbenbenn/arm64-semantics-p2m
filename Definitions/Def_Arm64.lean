/-
Copyright 2026 Google LLC

All code is licensed under the Apache License, Version 2.0 (the "Apache 2.0"); you may not use this file except in compliance with the Apache 2.0 license. You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and
limitations under the License.
-/

/-
MODIFIED for prove2.me (republication of DeepMind's `Arm64.Trusted`, upstream
google-deepmind/code-verification commit 8c8d371f, file `Arm64/Trusted.lean`):
every import of `Arm64.Trusted.<M>` renamed to the bundle `Definitions.Def_Arm64_<M>`.
Also removed `import Arm64.Trusted.Surface.Abi` (Surface syntax layer, not published).
Also removed `import Arm64.Trusted.Surface.CType` (Surface syntax layer, not published).
Also removed `import Arm64.Trusted.Surface.HexCode` (Surface syntax layer, not published).
Also removed `import Arm64.Trusted.Surface.Ascii` (Surface syntax layer, not published).
No other change.
-/

-- Layer 1 (`Arm64/Trusted/ISA/`): instruction-level AArch64 semantics
module

public import Definitions.Def_Arm64_ISA_Syntax
public import Definitions.Def_Arm64_ISA_Decode
public import Definitions.Def_Arm64_ISA_Memory
public import Definitions.Def_Arm64_ISA_State
public import Definitions.Def_Arm64_ISA_Float
public import Definitions.Def_Arm64_ISA_Eval
public import Definitions.Def_Arm64_Syscalls
public import Definitions.Def_Arm64_ISA_Semantics

-- Layer 2 (`Arm64/Trusted/Object/`): relocatable ELF object relocations, placement, and pre-link label provenance
public import Definitions.Def_Arm64_Object_Reloc
public import Definitions.Def_Arm64_Object_Placed
public import Definitions.Def_Arm64_Object_Labels

-- Layer 3 (`Arm64/Trusted/Spec/`): `Init`-only machine-level specification foundation
public import Definitions.Def_Arm64_Spec_AsciiNum
public import Definitions.Def_Arm64_Spec_RustAbi
public import Definitions.Def_Arm64_Spec_RustRuntime
public import Definitions.Def_Arm64_Spec_SepLogic
public import Definitions.Def_Arm64_Spec_Hoare
public import Definitions.Def_Arm64_Spec_Placed

-- Layer 4 (`Arm64/Trusted/Surface/`): surface specification DSLs and literal macros

/-!
# Trusted Computing Base

Umbrella module re-exporting the trusted AArch64 ISA semantics (`Arm64/Trusted/ISA/`), Linux
syscall interface (`Arm64/Trusted/Syscalls/`), ELF object relocation and placement model
(`Arm64/Trusted/Object/`), machine-level specification foundation (`Arm64/Trusted/Spec/`), and
surface specification macros (`Arm64/Trusted/Surface/`). Process-image byte loaders
(`IncludeBytes`, `FileBytes`) are imported via `Arm64.Trusted.Process`, and heap/allocator models
(`RustHeap`, `GlobalAlloc`) are imported directly by the specifications that use them.
-/

@[expose] public section
