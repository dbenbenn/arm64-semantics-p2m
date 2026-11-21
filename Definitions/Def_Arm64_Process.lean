/-
Copyright 2026 Google LLC

All code is licensed under the Apache License, Version 2.0 (the "Apache 2.0"); you may not use this file except in compliance with the Apache 2.0 license. You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and
limitations under the License.
-/

/-
MODIFIED for prove2.me (republication of DeepMind's `Arm64.Trusted`, upstream
google-deepmind/code-verification commit 8c8d371f, file `Arm64/Trusted/Process.lean`):
every import of `Arm64.Trusted.<M>` renamed to the bundle `Definitions.Def_Arm64_<M>`.
Also removed `import Arm64.Trusted.Surface.FileBytes` (Surface syntax layer, not published).
No other change.
-/

module

public import Definitions.Def_Arm64_Process_Types
public import Definitions.Def_Arm64_Process_Assumptions
public import Definitions.Def_Arm64_Process_Loader
public import Definitions.Def_Arm64_Process_Semantics

/-!
# Trusted Static ELF64 Process Semantics

Re-exports `Arm64.Trusted.Process.Types`, `Arm64.Trusted.Process.Assumptions`,
`Arm64.Trusted.Process.Loader`, `Arm64.Trusted.Process.Semantics`, and the compile-time
`file_bytes% "path" sha256 "<hex>"` elaborator (`Arm64.Trusted.Surface.FileBytes`). Kept separate
from `Arm64/Trusted.lean` so subroutine-level specifications do not depend on the whole-binary
ELF64 loader.

Library-level and hook-override modules (`Arm64.Trusted.Process.Placed`,
`Arm64.Trusted.Process.OverrideWellBehaved`, and `Arm64.Trusted.Process.Overrides`) are omitted
from this barrel so whole-process specifications without library contracts or overrides remain
independent of Hoare and separation-logic definitions.
-/

@[expose] public section
