#!/bin/sh
# release-pack.sh — package every `zig-out/bin/<binary>` for one target.
#
# Usage:
#   scripts/release-pack.sh <target> <version> <ext>
#
# Reads `zig-out/bin/{botopink,botopink-lsp,botopink-lib-test,bpmp}` (omits any
# missing binary; `bpmp` lands later in v0.beta.18) and writes:
#
#   dist/<binary>-<version>-<target>.<ext>
#   dist/<binary>-<version>-<target>.<ext>.sha256   (single 64-hex-char line)
#
# `<ext>` is `tar.gz` (POSIX) or `zip` (Windows). Each archive carries exactly
# one file at top level — no embedded directory — matching the layout the
# install script expects. The executable bit is preserved on POSIX targets;
# on Windows the archive carries `<binary>.exe`.
#
# Portable POSIX shell — no bashisms. Runs under dash/ash/bash/git-bash; on
# Windows runners GitHub's `windows-2022` image ships `bash` + `sha256sum` +
# `zip`/`tar` via git-for-windows.

set -eu

if [ "$#" -ne 3 ]; then
    printf 'usage: %s <target> <version> <ext>\n' "$0" >&2
    exit 2
fi

target="$1"
version="$2"
ext="$3"

case "$ext" in
    tar.gz|zip) ;;
    *) printf 'error: <ext> must be tar.gz or zip (got %s)\n' "$ext" >&2; exit 2 ;;
esac

bin_dir="zig-out/bin"
out_dir="dist"
mkdir -p "$out_dir"

# Pick the sha256 helper available on this runner. `sha256sum` on Linux/Windows
# (git-bash), `shasum -a 256` on macOS. Fail loudly if neither is present —
# refusing to ship un-verified archives.
sha256_cmd=""
if command -v sha256sum >/dev/null 2>&1; then
    sha256_cmd="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    sha256_cmd="shasum -a 256"
else
    printf 'error: no sha256 helper found (need sha256sum or shasum)\n' >&2
    exit 1
fi

# Compute the sha256 of a file as a single 64-hex-char line (no path suffix).
sha256_hex() {
    $sha256_cmd "$1" | awk '{print $1}'
}

# `<binary>` files we attempt to pack. Order matters only for log output.
binaries="botopink botopink-lsp botopink-lib-test bpmp"

windows_suffix=""
case "$target" in
    windows-*) windows_suffix=".exe" ;;
esac

packed_any=0
for bin in $binaries; do
    src="$bin_dir/$bin$windows_suffix"
    # Some binaries (notably `bpmp`) land partway through v0.beta.18.
    # Skip missing entries silently — the workflow's matrix declares which
    # binaries the release should ship and the absence is visible in the
    # final asset count if a tag goes out missing one.
    if [ ! -f "$src" ]; then
        printf 'skip: %s (not built)\n' "$src"
        continue
    fi

    archive_base="$bin-$version-$target"
    archive="$out_dir/$archive_base.$ext"

    # Stage the binary under its bare name (matching the executable that ends
    # up on `$PATH`). We pack from a scratch dir so the archive carries the
    # file at top level — no embedded directory.
    stage_dir="$out_dir/.stage-$bin-$target"
    rm -rf "$stage_dir"
    mkdir -p "$stage_dir"
    cp "$src" "$stage_dir/$bin$windows_suffix"

    case "$ext" in
        tar.gz)
            # `-C` so the archive is rooted at the staged file, no parent dir.
            tar -czf "$archive" -C "$stage_dir" "$bin$windows_suffix"
            ;;
        zip)
            # `zip -j` drops paths so the archive contents are flat.
            (cd "$stage_dir" && zip -q -j "../../$archive" "$bin$windows_suffix")
            ;;
    esac

    rm -rf "$stage_dir"

    digest="$(sha256_hex "$archive")"
    printf '%s\n' "$digest" > "$archive.sha256"

    printf 'pack: %s (sha256 %s)\n' "$archive" "$digest"
    packed_any=$((packed_any + 1))
done

if [ "$packed_any" -eq 0 ]; then
    printf 'error: no binaries found under %s\n' "$bin_dir" >&2
    exit 1
fi

printf 'release-pack: %d archive(s) under %s/\n' "$packed_any" "$out_dir"
