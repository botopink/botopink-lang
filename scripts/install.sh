#!/bin/sh
# botopink installer — POSIX, no bashisms.
#
# Bootstraps the toolchain (`botopink` + `botopink-lsp` + `botopink-lib-test`
# + `bpmp`) under `$BPMP_HOME` (default `$HOME/.bpmp`). Detects OS/arch,
# resolves the latest GitHub Release (or `$BOTOPINK_VERSION` if set),
# downloads each archive + its sha256 sidecar, verifies the digest, extracts,
# and lays out `$BPMP_HOME/bin/bpmp` as a stable shim.
#
# Usage:
#   curl --proto '=https' --tlsv1.2 -sSf https://botopink.dev/install.sh | sh
#   sh install.sh [--target <tuple>] [--version <v>] [--install-dir <path>]
#                 [--force] [--modify-path] [--quiet] [--help]
#
# Env (lowest precedence than flags):
#   BOTOPINK_VERSION       — pin a release tag (default: latest)
#   BOTOPINK_INSTALL_DIR   — override $BPMP_HOME (default: $HOME/.bpmp)
#   BOTOPINK_INSTALL_FORCE=1 — overwrite an existing install
#
# Refuses to clobber an existing $BPMP_HOME by default — points the user at
# `bpmp self update` instead. `BOTOPINK_INSTALL_FORCE=1` (or `--force`)
# overrides.
#
# Lines: <300 (read end-to-end as suggested in tasks/v0.beta.18/specs/install-script.md).

set -eu

# ── Logging ────────────────────────────────────────────────────────────────────

QUIET=0
say() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }
err() { printf 'error: %s\n' "$*" >&2; }
warn() { printf 'warning: %s\n' "$*" >&2; }
fail() { err "$1"; exit "${2:-1}"; }

# ── Defaults / flag parsing ───────────────────────────────────────────────────

REPO_OWNER="botopink"
REPO_NAME="botopink-lang"
FLAG_TARGET=""
FLAG_VERSION=""
FLAG_INSTALL_DIR=""
FLAG_FORCE=0
FLAG_MODIFY_PATH=0
FLAG_HELP=0

while [ $# -gt 0 ]; do
    case "$1" in
        --target)         shift; FLAG_TARGET="${1:-}" ;;
        --target=*)       FLAG_TARGET="${1#--target=}" ;;
        --version)        shift; FLAG_VERSION="${1:-}" ;;
        --version=*)      FLAG_VERSION="${1#--version=}" ;;
        --install-dir)    shift; FLAG_INSTALL_DIR="${1:-}" ;;
        --install-dir=*)  FLAG_INSTALL_DIR="${1#--install-dir=}" ;;
        --force)          FLAG_FORCE=1 ;;
        --modify-path)    FLAG_MODIFY_PATH=1 ;;
        --no-modify-path) FLAG_MODIFY_PATH=0 ;;
        --quiet)          QUIET=1 ;;
        -h|--help)        FLAG_HELP=1 ;;
        *) err "unknown flag: $1"; FLAG_HELP=1 ;;
    esac
    shift || true
done

if [ "$FLAG_HELP" -eq 1 ]; then
    cat <<EOF
botopink installer

Usage:
  sh install.sh [--target <tuple>] [--version <v>] [--install-dir <path>]
                [--force] [--modify-path] [--quiet] [--help]

Detected OS/arch is mapped to one of these supported targets:
  linux-x86_64    linux-aarch64
  macos-x86_64    macos-aarch64
  windows-x86_64  (use install.ps1 on Windows)

Env (lower precedence than flags):
  BOTOPINK_VERSION         pin a release tag (default: latest)
  BOTOPINK_INSTALL_DIR     override \$BPMP_HOME (default: \$HOME/.bpmp)
  BOTOPINK_INSTALL_FORCE=1 overwrite an existing install
EOF
    exit 0
fi

# ── OS / arch detection ────────────────────────────────────────────────────────

detect_target() {
    [ -n "$FLAG_TARGET" ] && { printf '%s' "$FLAG_TARGET"; return; }

    _os_raw="$(uname -s)"
    case "$_os_raw" in
        Linux)  _os="linux" ;;
        Darwin) _os="macos" ;;
        *) fail "unsupported OS: $_os_raw (use --target to override)" ;;
    esac

    _arch_raw="$(uname -m)"
    case "$_arch_raw" in
        x86_64|amd64)    _arch="x86_64" ;;
        aarch64|arm64)   _arch="aarch64" ;;
        *) fail "unsupported arch: $_arch_raw (use --target to override)" ;;
    esac
    printf '%s-%s' "$_os" "$_arch"
}

TARGET="$(detect_target)"
say "detected target: $TARGET"

case "$TARGET" in
    linux-x86_64|linux-aarch64|macos-x86_64|macos-aarch64)
        EXT="tar.gz"
        ;;
    *) fail "unsupported target: $TARGET (sh install.sh supports POSIX targets only; use install.ps1 for windows-x86_64)" ;;
esac

# ── Version resolution ────────────────────────────────────────────────────────

VERSION="${FLAG_VERSION:-${BOTOPINK_VERSION:-latest}}"

if [ "$VERSION" = "latest" ]; then
    URL_BASE="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/latest/download"
    say "resolving latest version (via GitHub's releases/latest/download redirect)"
else
    URL_BASE="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${VERSION}"
    say "version pin: $VERSION"
fi

# ── Disk layout ───────────────────────────────────────────────────────────────

BPMP_HOME="${FLAG_INSTALL_DIR:-${BOTOPINK_INSTALL_DIR:-${HOME:-$(getent passwd "$(id -u)" | cut -d: -f6)}/.bpmp}}"
say "install root: $BPMP_HOME"

if [ -e "$BPMP_HOME" ] && [ -n "$(ls -A "$BPMP_HOME" 2>/dev/null || true)" ]; then
    if [ "$FLAG_FORCE" -eq 1 ] || [ "${BOTOPINK_INSTALL_FORCE:-}" = "1" ]; then
        warn "\$BPMP_HOME exists — overwriting (BOTOPINK_INSTALL_FORCE=1)"
    else
        cat >&2 <<EOF
error: \$BPMP_HOME ($BPMP_HOME) already exists.
       To upgrade, run:    bpmp self update
       To start over, run: bpmp self uninstall   (then re-run this installer)
       To force overwrite: BOTOPINK_INSTALL_FORCE=1 sh install.sh
EOF
        exit 1
    fi
fi

# ── Download helpers ──────────────────────────────────────────────────────────

DOWNLOADER=""
if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl --proto =https --tlsv1.2 -sSfL"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget --https-only -qO-"
else
    fail "no downloader found (need curl or wget)"
fi

download_to() {
    # $1 = url, $2 = dest
    if command -v curl >/dev/null 2>&1; then
        curl --proto '=https' --tlsv1.2 -sSfL -o "$2" "$1"
    else
        wget --https-only -q -O "$2" "$1"
    fi
}

# ── sha256 ────────────────────────────────────────────────────────────────────

SHA256_CMD=""
if command -v sha256sum >/dev/null 2>&1; then
    SHA256_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    SHA256_CMD="shasum -a 256"
else
    fail "no sha256 helper found (need sha256sum or shasum)"
fi

sha256_of() { $SHA256_CMD "$1" | awk '{print $1}'; }

verify_sha256() {
    # $1 = archive, $2 = sidecar
    _want="$(awk '{print $1}' "$2" | tr -d '\r\n')"
    _got="$(sha256_of "$1")"
    if [ "$_want" != "$_got" ]; then
        cat >&2 <<EOF
error: sha256 mismatch for $1
       expected: $_want
       got:      $_got
EOF
        exit 1
    fi
    say "  verified sha256 ($_want)"
}

# ── Extract one archive ──────────────────────────────────────────────────────

extract_one() {
    # $1 = archive (tar.gz), $2 = dest dir
    tar -xzf "$1" -C "$2"
}

# ── Main ──────────────────────────────────────────────────────────────────────

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

VERSION_DIR="$BPMP_HOME/botopink/versions/${VERSION}"
mkdir -p "$VERSION_DIR" "$BPMP_HOME/bin" "$BPMP_HOME/botopink/versions"

BINARIES="botopink botopink-lsp botopink-lib-test bpmp"
for bin in $BINARIES; do
    archive_name="${bin}-${VERSION}-${TARGET}.${EXT}"
    sha_name="${archive_name}.sha256"
    url="${URL_BASE}/${archive_name}"
    sha_url="${URL_BASE}/${sha_name}"

    say "downloading $bin … ($url)"
    download_to "$url" "$TMP_DIR/$archive_name"
    download_to "$sha_url" "$TMP_DIR/$sha_name"
    verify_sha256 "$TMP_DIR/$archive_name" "$TMP_DIR/$sha_name"

    extract_one "$TMP_DIR/$archive_name" "$VERSION_DIR"
    chmod +x "$VERSION_DIR/$bin"
done

# Stable symlink: $BPMP_HOME/botopink/versions/stable → <VERSION>
rm -f "$BPMP_HOME/botopink/versions/stable"
ln -s "$VERSION_DIR" "$BPMP_HOME/botopink/versions/stable"
say "linked $BPMP_HOME/botopink/versions/stable → $VERSION"

# bin shim: $BPMP_HOME/bin/bpmp → ../botopink/versions/stable/bpmp
rm -f "$BPMP_HOME/bin/bpmp"
ln -s "../botopink/versions/stable/bpmp" "$BPMP_HOME/bin/bpmp"
say "linked $BPMP_HOME/bin/bpmp → ../botopink/versions/stable/bpmp"

# ── Post-install messaging ───────────────────────────────────────────────────

say ""
say "botopink ${VERSION} installed at ${BPMP_HOME}."

print_path_snippets() {
    case "${SHELL:-}" in
        */fish)
            cat <<EOF

Add to ~/.config/fish/config.fish:
  fish_add_path $BPMP_HOME/bin
EOF
            ;;
        */zsh)
            cat <<EOF

Append to your ~/.zshrc:
  export PATH="$BPMP_HOME/bin:\$PATH"
EOF
            ;;
        *)
            cat <<EOF

Append to your shell rc (bash / zsh / sh):
  export PATH="$BPMP_HOME/bin:\$PATH"
fish:
  fish_add_path $BPMP_HOME/bin
EOF
            ;;
    esac
}

[ "$QUIET" -eq 1 ] || print_path_snippets

# Optional rc append.
if [ "$FLAG_MODIFY_PATH" -eq 1 ]; then
    case "${SHELL:-}" in
        */fish) RCFILE="${HOME}/.config/fish/config.fish"; LINE="fish_add_path $BPMP_HOME/bin" ;;
        */zsh)  RCFILE="${HOME}/.zshrc"; LINE="export PATH=\"$BPMP_HOME/bin:\$PATH\" # botopink" ;;
        *)      RCFILE="${HOME}/.profile"; LINE="export PATH=\"$BPMP_HOME/bin:\$PATH\" # botopink" ;;
    esac
    if [ -f "$RCFILE" ] && grep -qF "$BPMP_HOME/bin" "$RCFILE" 2>/dev/null; then
        say "(--modify-path) $RCFILE already references \$BPMP_HOME/bin — no change"
    else
        printf '\n%s\n' "$LINE" >> "$RCFILE"
        say "(--modify-path) appended to $RCFILE"
    fi
fi

case "$TARGET" in
    macos-*)
        cat <<EOF

note: macOS may quarantine downloaded binaries. If \`botopink --version\` shows
      "killed: 9" or a Gatekeeper popup, run:
        xattr -d com.apple.quarantine $BPMP_HOME/botopink/versions/stable/*
      v0.beta.18 does not codesign the binaries; notarisation is on the roadmap.
EOF
        ;;
esac

say ""
say "Verify with:"
say "  bpmp version"
say "  botopink --version"
