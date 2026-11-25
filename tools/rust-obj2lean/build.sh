#!/bin/sh
# Build DeepMind's rust-obj2lean (google-deepmind/code-verification, commit 8c8d371f, Apache 2.0) with
# skip-note-sections.patch applied: the one change this repository's missions needed. It makes the
# placed-library exporter skip ELF note sections (SHT_NOTE, e.g. `.note.gnu.property`, which GCC emits
# with -mbranch-protection) the way it already skips `.eh_frame`, and adds a regression test.
# Usage: tools/rust-obj2lean/build.sh [WORKDIR]   (needs git and a Rust toolchain; prints the binary's path)
set -eu
HERE=$(cd "$(dirname "$0")" && pwd)
W=${1:-$HERE/work}
UPSTREAM=https://github.com/google-deepmind/code-verification
COMMIT=8c8d371f1962ac73435c8eb148678991f5c3470d
if [ ! -d "$W/code-verification/.git" ]; then
  mkdir -p "$W"
  git clone -q "$UPSTREAM" "$W/code-verification"
fi
cd "$W/code-verification"
git checkout -q "$COMMIT"
git apply --check "$HERE/skip-note-sections.patch" 2>/dev/null && git apply "$HERE/skip-note-sections.patch"
cd arm64-semantics/tools
cargo build --release -p rust-obj2lean >&2
echo "$W/code-verification/arm64-semantics/tools/target/release/rust-obj2lean"
