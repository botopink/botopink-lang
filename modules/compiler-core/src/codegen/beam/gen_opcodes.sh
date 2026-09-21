#!/usr/bin/env bash
# gen_opcodes.sh — regenerate `opcodes.zig`, the BEAM opcode table `beam_file.zig`
# assembles against.
#
# The table is pinned to ONE OTP release (decision 86: OTP 28, CI's floor) and
# read off that release's `lib/compiler/src/genop.tab` — the file OTP itself
# generates `beam_opcodes.erl` from. Every line `N: [-]name/arity` becomes one
# row; the `# OTP NN` section markers give each row the release it appeared in;
# a leading `-` marks an opcode the loader no longer accepts (obsolete).
#
#   scripts:  modules/compiler-core/src/codegen/beam/gen_opcodes.sh [genop.tab]
#
# Without an argument the tag's file is fetched from GitHub
# (`erlang/otp` at `OTP-<release>.0`). With `erl` on PATH every row is
# cross-checked against the installed `beam_opcodes:opname/1`: a name or arity
# that disagrees for an opcode both know is a hard failure, because the table
# would then assemble an instruction the running VM reads differently. Opcodes
# the installed release knows and the pinned one does not are reported and
# left out — that is the point of the pin.
#
# Output: `opcodes.zig` beside this script, `zig fmt`-clean. Re-run only when
# the pin moves; the result is checked in.
set -euo pipefail

otp_release=28
here="$(cd "$(dirname "$0")" && pwd)"
out="$here/opcodes.zig"

genop="${1-}"
if [ -z "$genop" ]; then
    genop="$(mktemp "${TMPDIR:-/tmp}/genop.XXXXXXXX.tab")"
    trap 'rm -f "$genop"' EXIT
    url="https://raw.githubusercontent.com/erlang/otp/OTP-${otp_release}.0/lib/compiler/src/genop.tab"
    curl -sSfL --max-time 60 -o "$genop" "$url" || { echo "gen_opcodes: cannot fetch $url" >&2; exit 1; }
fi
grep -q '^BEAM_FORMAT_NUMBER=0$' "$genop" || { echo "gen_opcodes: $genop is not a genop.tab with format number 0" >&2; exit 1; }

# rows: "<number> <name> <arity> <since> <obsolete 0|1>", one per opcode, sorted.
rows="$(awk '
    /^# OTP [0-9]+/ { since = $3; next }
    /^[0-9]+:/ {
        n = $1; sub(":", "", n)
        spec = $2
        obsolete = 0
        if (substr(spec, 1, 1) == "-") { obsolete = 1; spec = substr(spec, 2) }
        split(spec, parts, "/")
        printf "%d %s %d %d %d\n", n, parts[1], parts[2], since, obsolete
    }
' since=0 "$genop" | sort -n)"
max="$(printf '%s\n' "$rows" | tail -1 | cut -d' ' -f1)"
count="$(printf '%s\n' "$rows" | wc -l | tr -d ' ')"
[ "$count" -eq "$max" ] || { echo "gen_opcodes: opcode numbers are not dense (1..$max but $count rows)" >&2; exit 1; }

# Cross-check against the installed release, when there is one.
if command -v erl >/dev/null 2>&1; then
    installed="$(erl -noshell -eval '
        lists:foreach(fun(N) ->
            try {Name, Ar} = beam_opcodes:opname(N), io:format("~p ~s ~p~n", [N, Name, Ar])
            catch _:_ -> ok end
        end, lists:seq(1, 512)), halt().' 2>/dev/null)"
    installed_release="$(erl -noshell -eval 'io:format("~s", [erlang:system_info(otp_release)]), halt().' 2>/dev/null)"
    bad=0
    while read -r n name arity _since _obs; do
        got="$(printf '%s\n' "$installed" | awk -v n="$n" '$1 == n { print $2, $3 }')"
        [ -n "$got" ] || continue
        if [ "$got" != "$name $arity" ]; then
            echo "gen_opcodes: opcode $n is $name/$arity in OTP $otp_release but $got in the installed OTP $installed_release" >&2
            bad=1
        fi
    done <<< "$rows"
    [ "$bad" -eq 0 ] || exit 1
    extra="$(printf '%s\n' "$installed" | awk -v max="$max" '$1 > max { printf " %s/%s(%s)", $2, $3, $1 }')"
    [ -z "$extra" ] || echo "gen_opcodes: installed OTP $installed_release also knows:$extra — left out (pin is OTP $otp_release)" >&2
fi

zig_ident() {
    case "$1" in
        return|catch|try|error|test|if|for|while|and|or|fn|var|const|switch|struct|enum|union) printf '@"%s"' "$1" ;;
        *) printf '%s' "$1" ;;
    esac
}

{
    cat <<EOF
//! The BEAM opcode table \`beam_file.zig\` assembles against — **generated, do not edit**.
//!
//! Pinned to **Erlang/OTP ${otp_release}** (decision 86: CI's floor), read off that release's
//! \`lib/compiler/src/genop.tab\` (\`BEAM_FORMAT_NUMBER=0\`, ${max} opcodes) by
//! \`gen_opcodes.sh\` beside this file, which also cross-checks every row against the
//! installed \`beam_opcodes:opname/1\`. Numbers are stable across releases — a release
//! only appends — so a module that uses only opcodes at or below a release's highest
//! loads on that release and every later one; the \`Code\` chunk's \`opcode_max\` is the
//! loader's version check.
//!
//! \`since\` is the release an opcode appeared in (0 = predates the OTP numbering, R5–R17);
//! \`obsolete\` marks the ones \`genop.tab\` lists with a leading \`-\`, which no current
//! loader accepts. \`emittable\` is decision 86's subset: not obsolete, and present since
//! OTP \`stable_floor\` (24) — what the assembler refuses to write outside of.

/// The release whose \`genop.tab\` this table is.
pub const otp_release: u16 = ${otp_release};
/// \`BEAM_FORMAT_NUMBER\` — the \`Code\` chunk's instruction-set word.
pub const format_number: u32 = 0;
/// The highest opcode of the pinned release.
pub const opcode_max: u8 = ${max};
/// Decision 86: the assembler emits only opcodes present since this release.
pub const stable_floor: u8 = 24;

pub const Info = struct {
    name: []const u8,
    arity: u8,
    /// OTP release the opcode appeared in; 0 for the pre-OTP-20 core.
    since: u8,
    obsolete: bool,
};

/// One variant per opcode of the pinned release, valued by its number.
pub const Op = enum(u8) {
EOF
    printf '%s\n' "$rows" | while read -r n name _arity _since _obs; do
        printf '    %s = %s,\n' "$(zig_ident "$name")" "$n"
    done
    cat <<'EOF'

    pub fn info(self: Op) Info {
        return table[@intFromEnum(self)];
    }

    /// Decision 86's subset: not obsolete, present since `stable_floor`.
    pub fn emittable(self: Op) bool {
        const i = self.info();
        return !i.obsolete and i.since <= stable_floor;
    }
};

/// Indexed by opcode number; index 0 is unused.
pub const table = [_]Info{
    .{ .name = "", .arity = 0, .since = 0, .obsolete = true },
EOF
    printf '%s\n' "$rows" | while read -r _n name arity since obs; do
        printf '    .{ .name = "%s", .arity = %s, .since = %s, .obsolete = %s },\n' \
            "$name" "$arity" "$since" "$([ "$obs" -eq 1 ] && echo true || echo false)"
    done
    cat <<'EOF'
};

const std = @import("std");

test "opcodes: the table is dense, numbered by index, and the enum agrees with it" {
    try std.testing.expectEqual(@as(usize, opcode_max + 1), table.len);
    inline for (@typeInfo(Op).@"enum".fields) |f| {
        const op: Op = @enumFromInt(f.value);
        try std.testing.expectEqualStrings(f.name, op.info().name);
    }
    try std.testing.expectEqual(@as(u8, 1), Op.label.info().arity);
    try std.testing.expectEqual(@as(u8, 3), Op.func_info.info().arity);
    try std.testing.expectEqual(@as(u8, 0), Op.int_code_end.info().arity);
}

test "opcodes: the emittable subset is decision 86's" {
    // Present since OTP 24, so in.
    try std.testing.expect(Op.make_fun3.emittable());
    try std.testing.expect(Op.init_yregs.emittable());
    try std.testing.expect(Op.call_ext.emittable());
    // Appeared after the floor, so out — even though the pinned release knows them.
    try std.testing.expect(!Op.bs_create_bin.emittable());
    try std.testing.expect(!Op.update_record.emittable());
    try std.testing.expect(!Op.debug_line.emittable());
    // Obsolete before the floor, so out.
    try std.testing.expect(!Op.allocate_zero.emittable());
    try std.testing.expect(!Op.put_tuple.emittable());
    try std.testing.expect(!Op.fclearerror.emittable());
}
EOF
} > "$out"

zig fmt "$out" >/dev/null
emittable="$(printf '%s\n' "$rows" | awk '$5 == 0 && $4 <= 24' | wc -l | tr -d ' ')"
echo "gen_opcodes: wrote $out — OTP $otp_release, $max opcodes, $emittable emittable (not obsolete, since <= OTP 24)"
