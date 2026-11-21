/-
Copyright 2026 Google LLC

All code is licensed under the Apache License, Version 2.0 (the "Apache 2.0"); you may not use this file except in compliance with the Apache 2.0 license. You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and
limitations under the License.
-/

/-
MODIFIED for prove2.me (republication of DeepMind's `Arm64.Trusted`, upstream
google-deepmind/code-verification commit 8c8d371f, file `Arm64/Trusted/Syscalls/Misc.lean`):
every import of `Arm64.Trusted.<M>` renamed to the bundle `Definitions.Def_Arm64_<M>`.
No other change.
-/

module

public import Definitions.Def_Arm64_Syscalls_Common
public import Definitions.Def_Arm64_Syscalls_Kernel_Sys

/-!
# Thread Identity, Futex Wake, and Affinity Syscalls

Trusted syscall dispatch bundle (`Syscall.miscTable`, `Syscall.misc`) re-exporting `Kernel.Sys` for
single-thread `set_tid_address`, `futex` (`FUTEX_WAKE` / `FUTEX_WAKE_PRIVATE`),
`sched_getaffinity`, `getpid`, and `gettid`.
-/

@[expose] public section

namespace Arm64

namespace Syscall

/-- Dispatch table for single-thread identity, futex-wake, and CPU-affinity syscalls
    (`set_tid_address`, `futex`, `sched_getaffinity`, `getpid`, `gettid`). -/
def miscTable : List (BitVec 64 × (State → State)) :=
  [(SYS_SET_TID_ADDRESS, execSetTidAddress),
   (SYS_FUTEX, execFutex),
   (SYS_SCHED_GETAFFINITY, execSchedGetaffinity),
   (SYS_GETPID, execGetpid),
   (SYS_GETTID, execGetpid)]

/-- Syscall dispatcher for `miscTable`. -/
def misc : State → State := dispatch miscTable

end Syscall

end Arm64
