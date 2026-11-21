/-
Copyright 2026 Google LLC

All code is licensed under the Apache License, Version 2.0 (the "Apache 2.0"); you may not use this file except in compliance with the Apache 2.0 license. You may obtain a copy of the License at https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and
limitations under the License.
-/

/-
MODIFIED for prove2.me (republication of DeepMind's `Arm64.Trusted`, upstream
google-deepmind/code-verification commit 8c8d371f, file `Arm64/Trusted/Syscalls/FileIo.lean`):
every import of `Arm64.Trusted.<M>` renamed to the bundle `Definitions.Def_Arm64_<M>`.
No other change.
-/

module

public import Definitions.Def_Arm64_Syscalls_Common
public import Definitions.Def_Arm64_Syscalls_Stdio
public import Definitions.Def_Arm64_Syscalls_Fs_ReadWrite
public import Definitions.Def_Arm64_Syscalls_Fs_Open
public import Definitions.Def_Arm64_Syscalls_Fs_Stat
public import Definitions.Def_Arm64_Syscalls_Fs_Fcntl
public import Definitions.Def_Arm64_Syscalls_Fs_Ioctl

/-!
# File-System and File-Descriptor Syscalls

Re-exports `Arm64.Trusted.Syscalls.Fs.{ReadWrite,Open,Stat,Fcntl,Ioctl}` and bundles their
handlers with `Stdio` into `Syscall.fileIoOnlyTable`, `Syscall.fileIoTable`, and `Syscall.fileIo`.
-/

@[expose] public section

namespace Arm64

namespace Syscall

/-- Dispatch entries specific to file-descriptor and path operations (excluding `Stdio`). -/
def fileIoOnlyTable : List (BitVec 64 × (State → State)) :=
  [(SYS_FCNTL, execFcntl),
   (SYS_IOCTL, execIoctl),
   (SYS_OPENAT, execOpenat),
   (SYS_CLOSE, execClose),
   (SYS_LSEEK, execLseek),
   (SYS_PREAD64, execPread64),
   (SYS_FSTAT, execFstat)]

/-- Dispatch table for stream + file I/O (`Stdio` plus `fcntl`, `ioctl`, `openat`, `close`,
    `lseek`, `pread64`, and `fstat`). -/
def fileIoTable : List (BitVec 64 × (State → State)) :=
  stdioTable ++ fileIoOnlyTable

/-- Bundle permitting standard I/O, process exit, and file-system syscalls (`13` syscalls). -/
def fileIo : State → State := dispatch fileIoTable

end Syscall

end Arm64
