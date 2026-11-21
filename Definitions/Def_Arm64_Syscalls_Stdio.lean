/-
Copyright 2026 Google LLC

All code is licensed under the Apache License, Version 2.0 (the "Apache 2.0"); you may not use this file except in compliance with the Apache 2.0 license. You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and
limitations under the License.
-/

/-
MODIFIED for prove2.me (republication of DeepMind's `Arm64.Trusted`, upstream
google-deepmind/code-verification commit 8c8d371f, file `Arm64/Trusted/Syscalls/Stdio.lean`):
every import of `Arm64.Trusted.<M>` renamed to the bundle `Definitions.Def_Arm64_<M>`.
No other change.
-/

module

public import Definitions.Def_Arm64_Syscalls_Common
public import Definitions.Def_Arm64_Syscalls_Fs_ReadWrite
public import Definitions.Def_Arm64_Syscalls_Fs_ReadWritev
public import Definitions.Def_Arm64_Syscalls_Kernel_Exit

/-!
# Standard I/O and Process Exit Syscalls

Re-exports [`Fs/ReadWrite.lean`](Fs/ReadWrite.lean), [`Fs/ReadWritev.lean`](Fs/ReadWritev.lean),
and [`Kernel/Exit.lean`](Kernel/Exit.lean), and defines the syscall dispatch tables and bundles
`Syscall.stdioWrite` and `Syscall.stdioCli`.
-/

@[expose] public section

namespace Arm64

namespace Syscall

/-- Single-entry dispatch table for `write` (`64`) only. -/
def stdioWriteTable : List (BitVec 64 × (State → State)) :=
  [(SYS_WRITE, execWrite)]

/-- Dispatch table for standard stream I/O and process termination (`read`, `write`, `readv`,
    `writev`, `exit`, `exit_group`). -/
def stdioTable : List (BitVec 64 × (State → State)) :=
  [(SYS_READ, execRead),
   (SYS_WRITE, execWrite),
   (SYS_READV, execReadv),
   (SYS_WRITEV, execWritev),
   (SYS_EXIT, execExit),
   (SYS_EXIT_GROUP, execExit)]

/-- Bundle permitting only `write` (`64`). -/
def stdioWrite : State → State := dispatch stdioWriteTable

/-- Bundle permitting `read` (`63`), `write` (`64`), `readv` (`65`), `writev` (`66`), `exit` (`93`),
    and `exit_group` (`94`). -/
def stdioCli : State → State := dispatch stdioTable

end Syscall

end Arm64
