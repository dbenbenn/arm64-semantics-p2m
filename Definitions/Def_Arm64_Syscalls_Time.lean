/-
Copyright 2026 Google LLC

All code is licensed under the Apache License, Version 2.0 (the "Apache 2.0"); you may not use this file except in compliance with the Apache 2.0 license. You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and
limitations under the License.
-/

/-
MODIFIED for prove2.me (republication of DeepMind's `Arm64.Trusted`, upstream
google-deepmind/code-verification commit 8c8d371f, file `Arm64/Trusted/Syscalls/Time.lean`):
every import of `Arm64.Trusted.<M>` renamed to the bundle `Definitions.Def_Arm64_<M>`.
No other change.
-/

module

public import Definitions.Def_Arm64_Syscalls_Common
public import Definitions.Def_Arm64_Syscalls_Kernel_Time

/-!
# Clock and Time Syscalls

Re-exports [`Arm64.Trusted.Syscalls.Kernel.Time`](Kernel/Time.lean) (`kernel/time/posix-timers.c`:
`clock_gettime`) and defines the POSIX clock syscall dispatch table `Syscall.timeTable` and handler
`Syscall.time`.
-/

@[expose] public section

namespace Arm64

namespace Syscall

/-- Dispatch table for POSIX clock queries (`clock_gettime`). -/
def timeTable : List (BitVec 64 × (State → State)) :=
  [(SYS_CLOCK_GETTIME, execClockGettime)]

/-- Syscall dispatch handler for `clock_gettime`. -/
def time : State → State := dispatch timeTable

end Syscall

end Arm64
