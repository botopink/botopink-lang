#!/usr/bin/env bash
# macos-sim.sh — run a command on Linux the way the macos-14 CI row runs it.
#
#   scripts/macos-sim.sh [--tools <dir>] <command> [<arg>…]
#
# What a stock macOS runner differs in, reproduced here (scripts/AGENTS.md
# § Portability is the list of the constructs each one broke):
#
#   bash      3.2.57, built once from the gnu.org tarball into <dir>
#             (default `$HOME/.cache/botopink-macos-sim`), first on PATH as `bash`;
#   awk       BWK awk (macOS's) when `nawk` / `original-awk` is installed, else
#             the host's awk, and the launcher says so;
#   xargs     BSD's: an empty argument is dropped, even under -0;
#   GNU-only  `timeout`, `gtimeout`, `nproc`, `sha256sum`, `sha1sum`, `md5sum`,
#             `realpath`, `tac`, `stdbuf`, `setsid`, `flock`, `truncate` are not
#             on PATH (`shasum`, perl's, stays — macOS ships it);
#   flags     `sed -i` without a suffix, `sed -r`, `stat -c`, `date -d` / `%N`,
#             `grep -P`, `find -printf`, `cp -T`, `du -b`, `base64 -w`, `ln -r`,
#             `head -n -<k>`, `install -D`, `readlink -f`… — refused with
#             `macos-sim: <tool> <flag> is GNU-only`, exit 64;
#   TMPDIR    reached through a symbolic link and ending in `/`, as macOS's
#             `/var/folders/…/T/` is (`/var` → `/private/var`).
#
# Not reproduced: BSD sed/grep regex dialects beyond the refused flags, APFS's
# case-insensitivity, the absence of /proc (every reader of it already guards).
set -euo pipefail

tools="${BOTOPINK_MACOS_SIM:-$HOME/.cache/botopink-macos-sim}"
if [ "${1:-}" = "--tools" ]; then tools="$2"; shift 2; fi
[ $# -gt 0 ] || { echo "usage: scripts/macos-sim.sh [--tools <dir>] <command> [<arg>…]" >&2; exit 2; }
mkdir -p "$tools"
tools="$(cd "$tools" && pwd -P)"

# ── bash 3.2.57 ──────────────────────────────────────────────────────────────
bash32="$tools/bash-3.2.57/bash"
if [ ! -x "$bash32" ]; then
    echo "macos-sim: building bash 3.2.57 into $tools (once)" >&2
    ( cd "$tools" &&
      curl -sSfL https://ftp.gnu.org/gnu/bash/bash-3.2.57.tar.gz | tar xz &&
      cd bash-3.2.57 &&
      CC="gcc -std=gnu89 -Wno-error -Wno-implicit-function-declaration -Wno-implicit-int -Wno-int-conversion -Wno-incompatible-pointer-types" \
          ./configure --without-bash-malloc >/dev/null &&
      make -j4 >/dev/null 2>&1 ) || { echo "macos-sim: could not build bash 3.2.57" >&2; exit 1; }
fi

# ── the PATH: every tool of the host's PATH but the GNU-only ones ────────────
bin="$tools/bin"
rm -rf "$bin"
mkdir -p "$bin"
gnu_only=" timeout gtimeout nproc sha256sum sha1sum md5sum sha512sum realpath tac stdbuf setsid flock truncate "
IFS=: read -r -a dirs <<<"$PATH"
for d in "${dirs[@]}"; do
    [ -d "$d" ] || continue
    for f in "$d"/*; do
        n="${f##*/}"
        [ -x "$f" ] && [ ! -d "$f" ] || continue
        case "$gnu_only" in *" $n "*) continue ;; esac
        [ -e "$bin/$n" ] || ln -s "$f" "$bin/$n"
    done
done
real() { # the host's <tool>, before the wrappers replace it
    local t; t="$(readlink "$bin/$1")" || { echo "macos-sim: no $1 on PATH" >&2; exit 1; }; echo "$t"
}
rm -f "$bin/bash"; ln -s "$bash32" "$bin/bash"
awk_bwk=""
for a in nawk original-awk bwk-awk; do [ -e "$bin/$a" ] && { awk_bwk="$(real "$a")"; break; }; done
if [ -n "$awk_bwk" ]; then rm -f "$bin/awk"; ln -s "$awk_bwk" "$bin/awk"
else echo "macos-sim: no BWK awk (nawk) installed — awk is the host's" >&2; fi

# wrap <tool> <body> — a /bin/sh wrapper that may refuse, then runs the host's tool
wrap() {
    local t="$1" r; r="$(real "$1")"
    rm -f "$bin/$t"
    { printf '#!/bin/sh\nREAL=%s\n' "'$r'"
      printf 'gnu() { echo "macos-sim: $(basename "$0") $1 is GNU-only (macOS refuses it)" >&2; exit 64; }\n'
      printf '%s\n' "$2"
      printf 'exec "$REAL" "$@"\n'; } >"$bin/$t"
    chmod +x "$bin/$t"
}
long='for a in "$@"; do case "$a" in --) break ;; --*) gnu "$a" ;; esac; done'
wrap xargs '
case " $* " in
  *" -0"*|*" -r0"*) "'"$(real sed)"'" -z "/^\$/d" | "$REAL" "$@"; exit $? ;;
esac'
wrap sed '
prev=""
for a in "$@"; do
  case "$a" in
    -i) gnu "-i without a suffix (write -i.bak)" ;;
    -r|-[a-zA-Z]*r) [ "$prev" = "-e" ] || gnu "$a (write -E)" ;;
    -z|--*) gnu "$a" ;;
    *\\x[0-9a-fA-F]*) gnu "a \\x escape in the script ($a)" ;;
  esac
  prev="$a"
done'
wrap grep '
for a in "$@"; do case "$a" in -P|-[a-zA-Z]*P*|--perl-regexp) gnu "$a" ;; *\\x[0-9a-fA-F]*) gnu "a \\x escape in the pattern ($a)" ;; esac; done'
wrap stat 'for a in "$@"; do case "$a" in -c|--*) gnu "$a" ;; esac; done'
wrap date 'for a in "$@"; do case "$a" in -d|--*) gnu "$a" ;; +*%N*) gnu "%N" ;; esac; done'
wrap find 'for a in "$@"; do case "$a" in -printf|-fprintf|-regextype|-readable|-executable) gnu "$a" ;; esac; done'
wrap cp 'for a in "$@"; do case "$a" in -T|-[a-zA-Z]*T*|--*) gnu "$a" ;; esac; done'
wrap du 'for a in "$@"; do case "$a" in -b|-[a-zA-Z]*b*|--*) gnu "$a" ;; esac; done'
wrap base64 'for a in "$@"; do case "$a" in -w*|--*) gnu "$a" ;; esac; done'
wrap ln 'for a in "$@"; do case "$a" in -r|-[a-zA-Z]*r*|--*) gnu "$a" ;; esac; done'
wrap install 'for a in "$@"; do case "$a" in -D|--*) gnu "$a" ;; esac; done'
wrap head 'prev=""; for a in "$@"; do case "$prev$a" in -n-*|-c-*|--*) gnu "$prev $a" ;; esac; prev="$a"; done'
wrap readlink 'for a in "$@"; do case "$a" in -f|-e|-m|--*) gnu "$a" ;; esac; done'
wrap mktemp "$long"
wrap sort "$long"
wrap ps "$long"

# ── TMPDIR through a symbolic link, with a trailing slash ────────────────────
mkdir -p "$tools/private/var/T"
rm -f "$tools/var"; ln -s "$tools/private/var" "$tools/var"
export TMPDIR="$tools/var/T/"
export PATH="$bin"
export BOTOPINK_MACOS_SIM="$tools"
exec "$bin/bash" -c 'exec "$@"' macos-sim "$@"
