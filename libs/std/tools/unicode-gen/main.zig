//! The generator of std's normalization tables (decision 333 (A)) and of
//! std-wasm's case mapping (decision 443).
//!
//! `zig build gen-unicode` runs this with three arguments — this directory,
//! the output file (`libs/std/src/unicode_tables.bp`) and std-wasm's case
//! tables (`modules/std-wasm/src/case_tables.zig`) — and it:
//!
//!   1. checks every file `manifest.json` names against its SHA-256 (a file
//!      that differs, is missing or is not named is an error: the tables come
//!      from one pinned Unicode version and nothing else);
//!   2. reads `UnicodeData.txt` (canonical combining classes, canonical and
//!      compatibility decomposition mappings), `CompositionExclusions.txt` and
//!      `DerivedNormalizationProps.txt`;
//!   3. derives the full composition exclusions (the listed exclusions, the
//!      singletons, the non-starter decompositions — UAX #15 §5) and refuses to
//!      write anything unless they are exactly `Full_Composition_Exclusion`;
//!   4. writes the botopink module: `combiningClass`, `canonicalDecomposition`,
//!      `compatibilityDecomposition` and `primaryComposite`, each a `case`
//!      split into leaf functions of at most `leaf_arms` arms (a single `case`
//!      of two thousand arms is past the beam assembler's limit for one
//!      function), already at the formatter's canonical form;
//!   5. reads `UnicodeData.txt`'s simple case mappings (upper, lower, title)
//!      and `SpecialCasing.txt`'s unconditional full ones, and writes std-wasm's
//!      `case_tables.zig`: per direction a `switch` over the code point
//!      (runs of one offset, stepping by one or two), and the full mappings of
//!      more than one code point packed 21 bits each. Code, not data: a
//!      `--target wasm` program links the tables only where it maps case,
//!      and no other std-wasm function carries them (`std_wasm_link.zig`
//!      places std-wasm's data whenever a linked function reads it). The
//!      conditional mappings (`Final_Sigma`, the language-specific ones) are
//!      left out — OTP's `string:uppercase` / `lowercase` apply none, and a
//!      wasm program answers OTP's (decision 443).
//!
//! Hangul syllables are not in the tables: `unicode.bp` decomposes and composes
//! them by the algorithm (Unicode §3.12). `NormalizationTest.txt` is vendored
//! beside the data files and hashed here, but read by std's conformance test,
//! not by the generator.

const std = @import("std");

const leaf_arms = 64;

/// `botopink format`'s line width (`format.zig` `LINE_WIDTH`): the generated
/// file is written at the formatter's canonical form, which
/// `scripts/format-check.sh` holds it to.
const format_width = 80;

const data_files = [_][]const u8{
    "UnicodeData.txt",
    "CompositionExclusions.txt",
    "DerivedNormalizationProps.txt",
    "NormalizationTest.txt",
    "SpecialCasing.txt",
};

pub fn main(init: std.process.Init) void {
    run(init) catch |err| {
        std.debug.print("unicode-gen: {s}\n", .{@errorName(err)});
        std.process.exit(1);
    };
}

fn fail(comptime fmt: []const u8, args: anytype) error{Refused} {
    std.debug.print("unicode-gen: " ++ fmt ++ "\n", args);
    return error.Refused;
}

fn run(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;
    const argv = try init.minimal.args.toSlice(arena);
    if (argv.len != 4) return fail("usage: unicode-gen <tools/unicode-gen dir> <out .bp> <out case_tables.zig>", .{});
    const dir = argv[1];
    const out_path = argv[2];
    const case_path = argv[3];
    const cwd = std.Io.Dir.cwd();

    const read = struct {
        fn file(a: std.mem.Allocator, i: std.Io, d: []const u8, name: []const u8) ![]const u8 {
            const p = try std.fmt.allocPrint(a, "{s}/{s}", .{ d, name });
            return std.Io.Dir.cwd().readFileAlloc(i, p, a, .unlimited) catch |err|
                return fail("cannot read {s}: {s}", .{ p, @errorName(err) });
        }
    };

    // ── 1. the manifest pins the version and every file's hash ──────────────
    const manifest_text = try read.file(arena, io, dir, "manifest.json");
    const parsed = std.json.parseFromSlice(std.json.Value, arena, manifest_text, .{}) catch
        return fail("manifest.json is not JSON", .{});
    const root = switch (parsed.value) {
        .object => |o| o,
        else => return fail("manifest.json is not an object", .{}),
    };
    const version = switch (root.get("version") orelse return fail("manifest.json has no \"version\"", .{})) {
        .string => |s| s,
        else => return fail("manifest.json \"version\" is not a string", .{}),
    };
    const files = switch (root.get("files") orelse return fail("manifest.json has no \"files\"", .{})) {
        .object => |o| o,
        else => return fail("manifest.json \"files\" is not an object", .{}),
    };
    if (files.count() != data_files.len) return fail("manifest.json names {d} files, expected {d}", .{ files.count(), data_files.len });
    var texts: [data_files.len][]const u8 = undefined;
    for (data_files, 0..) |name, i| {
        const want = switch (files.get(name) orelse return fail("manifest.json does not name {s}", .{name})) {
            .string => |s| s,
            else => return fail("manifest.json hash of {s} is not a string", .{name}),
        };
        texts[i] = try read.file(arena, io, dir, name);
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(texts[i], &digest, .{});
        const got = std.fmt.bytesToHex(digest, .lower);
        if (!std.mem.eql(u8, &got, want)) return fail("{s}: SHA-256 {s}, manifest.json pins {s}", .{ name, &got, want });
        // Every file but UnicodeData.txt names its version on its first line.
        if (i != 0) {
            const header = try std.fmt.allocPrint(arena, "-{s}.txt", .{version});
            if (std.mem.indexOf(u8, std.mem.sliceTo(texts[i], '\n'), header) == null)
                return fail("{s}: first line does not name version {s}", .{ name, version });
        }
    }

    // ── 2. UnicodeData.txt ──────────────────────────────────────────────────
    var ccc = std.AutoHashMapUnmanaged(u21, u8).empty;
    var simple_case: [3]std.AutoHashMapUnmanaged(u21, u21) = .{ .empty, .empty, .empty };
    var canonical = std.AutoHashMapUnmanaged(u21, []const u21).empty;
    var compat = std.AutoHashMapUnmanaged(u21, []const u21).empty;
    var lines = std.mem.splitScalar(u8, texts[0], '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        var fields: [15][]const u8 = undefined;
        var n: usize = 0;
        var it = std.mem.splitScalar(u8, line, ';');
        while (it.next()) |f| : (n += 1) {
            if (n == fields.len) return fail("UnicodeData.txt: more than 15 fields: {s}", .{line});
            fields[n] = f;
        }
        if (n != fields.len) return fail("UnicodeData.txt: {d} fields: {s}", .{ n, line });
        const cp = try parseCp(fields[0]);
        const class = std.fmt.parseInt(u8, fields[3], 10) catch return fail("UnicodeData.txt: bad class: {s}", .{line});
        const is_range = std.mem.endsWith(u8, fields[1], ", First>") or std.mem.endsWith(u8, fields[1], ", Last>");
        if (is_range) {
            // The ranges (CJK, Hangul, Tangut, …) carry no class and no mapping.
            if (class != 0 or fields[5].len != 0) return fail("UnicodeData.txt: a range entry with a class or a mapping: {s}", .{line});
            continue;
        }
        if (class != 0) try ccc.put(arena, cp, class);
        // Fields 12, 13, 14: the simple uppercase, lowercase and titlecase mappings.
        for (0..3) |k| if (fields[12 + k].len != 0) try simple_case[k].put(arena, cp, try parseCp(fields[12 + k]));
        if (fields[5].len == 0) continue;
        var mapping = fields[5];
        const tagged = mapping[0] == '<';
        if (tagged) {
            const close = std.mem.indexOfScalar(u8, mapping, '>') orelse return fail("UnicodeData.txt: bad tag: {s}", .{line});
            mapping = std.mem.trim(u8, mapping[close + 1 ..], " ");
        }
        var cps: std.ArrayListUnmanaged(u21) = .empty;
        var parts = std.mem.tokenizeScalar(u8, mapping, ' ');
        while (parts.next()) |p| try cps.append(arena, try parseCp(p));
        if (cps.items.len == 0) return fail("UnicodeData.txt: empty mapping: {s}", .{line});
        try (if (tagged) &compat else &canonical).put(arena, cp, cps.items);
    }

    // ── 3. the exclusions, derived and checked ──────────────────────────────
    var listed = std.AutoHashMapUnmanaged(u21, void).empty;
    try readCodePointList(arena, texts[1], null, &listed);
    var full = std.AutoHashMapUnmanaged(u21, void).empty;
    try readCodePointList(arena, texts[2], "Full_Composition_Exclusion", &full);
    var derived = std.AutoHashMapUnmanaged(u21, void).empty;
    {
        var it = listed.keyIterator();
        while (it.next()) |cp| {
            if (!canonical.contains(cp.*)) return fail("CompositionExclusions.txt: U+{X:0>4} has no canonical decomposition", .{cp.*});
            try derived.put(arena, cp.*, {});
        }
        var dit = canonical.iterator();
        while (dit.next()) |e| {
            const singleton = e.value_ptr.len == 1;
            const non_starter = (ccc.get(e.key_ptr.*) orelse 0) != 0 or (ccc.get(e.value_ptr.*[0]) orelse 0) != 0;
            if (singleton or non_starter) try derived.put(arena, e.key_ptr.*, {});
            if (e.value_ptr.len > 2) return fail("UnicodeData.txt: U+{X:0>4} has a canonical mapping of {d} code points", .{ e.key_ptr.*, e.value_ptr.len });
        }
    }
    if (derived.count() != full.count()) return fail("derived exclusions: {d}, Full_Composition_Exclusion: {d}", .{ derived.count(), full.count() });
    {
        var it = full.keyIterator();
        while (it.next()) |cp| if (!derived.contains(cp.*)) return fail("U+{X:0>4} is Full_Composition_Exclusion but not derived", .{cp.*});
    }

    // ── 4. the module ───────────────────────────────────────────────────────
    var out: std.ArrayListUnmanaged(u8) = .empty;
    const w = Out{ .list = &out, .alloc = arena };
    try w.print(
        \\//// std/unicode_tables — GENERATED by `zig build gen-unicode`
        \\//// (`libs/std/tools/unicode-gen/main.zig`) from the Unicode {s} Character
        \\//// Database files vendored beside the generator, each pinned by its
        \\//// SHA-256 in `manifest.json`. Never edit this file: a Unicode bump
        \\//// replaces the files and the hashes and reruns the generator (decision
        \\//// 333 (A); `libs/std/AGENTS.md` § unicode).
        \\////
        \\//// The data `unicode.normalize` reads: the canonical combining class of a
        \\//// code point, its one-level canonical decomposition mapping, its
        \\//// one-level compatibility mapping (a tagged mapping only, so a code point
        \\//// with a canonical mapping answers `[]` here) and the primary composite
        \\//// of a pair, excluded compositions left out (`0` for none). Hangul
        \\//// syllables are algorithmic and in none of the four. Each function is a
        \\//// `case` over the code point that dispatches to leaf functions of at
        \\//// most {d} arms.
        \\
        \\// The Unicode version these tables were generated from.
        \\pub fn version() -> string {{
        \\    return "{s}";
        \\}}
        \\
    , .{ version, leaf_arms, version });

    // combining classes, as runs of one class
    var class_rows: std.ArrayListUnmanaged(Row) = .empty;
    {
        const keys = try sortedKeys(arena, u8, ccc);
        for (keys) |cp| {
            const class = ccc.get(cp).?;
            if (class_rows.items.len > 0) {
                const last = &class_rows.items[class_rows.items.len - 1];
                if (last.hi + 1 == cp and last.class == class) {
                    last.hi = cp;
                    continue;
                }
            }
            try class_rows.append(arena, .{ .lo = cp, .hi = cp, .class = class });
        }
    }
    try writeTable(w, "combiningClass", "i32", "0", class_rows.items,
        \\// The canonical combining class of `cp` (0 for a starter and for every
        \\// code point the data does not list).
    );

    for ([_]struct { name: []const u8, map: *const std.AutoHashMapUnmanaged(u21, []const u21), doc: []const u8 }{
        .{ .name = "canonicalDecomposition", .map = &canonical, .doc =
        \\// The canonical decomposition mapping of `cp`, one level (`[]` when it has
        \\// none). A mapped code point may map again: the caller recurses.
        },
        .{ .name = "compatibilityDecomposition", .map = &compat, .doc =
        \\// The compatibility decomposition mapping of `cp` — a TAGGED mapping only,
        \\// one level (`[]` when it has none, a canonical mapping included).
        },
    }) |t| {
        const keys = try sortedKeys(arena, []const u21, t.map.*);
        var rows: std.ArrayListUnmanaged(Row) = try .initCapacity(arena, keys.len);
        for (keys) |cp| rows.appendAssumeCapacity(.{ .lo = cp, .hi = cp, .mapping = t.map.get(cp).? });
        try writeTable(w, t.name, "Array<i32>", "[]", rows.items, t.doc);
    }

    // primary composites: (first, second) → composite, by first
    var pairs: std.ArrayListUnmanaged(Pair) = .empty;
    {
        var it = canonical.iterator();
        while (it.next()) |e| {
            if (derived.contains(e.key_ptr.*)) continue;
            try pairs.append(arena, .{ .first = e.value_ptr.*[0], .second = e.value_ptr.*[1], .composite = e.key_ptr.* });
        }
        std.mem.sort(Pair, pairs.items, {}, Pair.lessThan);
    }
    try writeComposites(w, pairs.items);

    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = out_path, .data = out.items });
    _ = cwd;

    // ── 5. std-wasm's case tables ───────────────────────────────────────────
    var full_case: [3]std.AutoHashMapUnmanaged(u21, []const u21) = .{ .empty, .empty, .empty };
    try readSpecialCasing(arena, texts[4], &full_case);
    var case_out: std.ArrayListUnmanaged(u8) = .empty;
    const cw = Out{ .list = &case_out, .alloc = arena };
    const case_counts = try writeCaseTables(cw, version, &simple_case, &full_case);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = case_path, .data = case_out.items });
    std.debug.print(
        "unicode-gen: Unicode {s} → {s} ({d} bytes): {d} class runs, {d} canonical and {d} compatibility mappings, {d} composites ({d} excluded)\n",
        .{ version, out_path, out.items.len, class_rows.items.len, canonical.count(), compat.count(), pairs.items.len, derived.count() },
    );
    std.debug.print(
        "unicode-gen: Unicode {s} → {s} ({d} bytes): {d} / {d} / {d} upper / lower / title runs, {d} / {d} / {d} full mappings\n",
        .{ version, case_path, case_out.items.len, case_counts[0], case_counts[1], case_counts[2], case_counts[3], case_counts[4], case_counts[5] },
    );
}

/// `SpecialCasing.txt`'s unconditional entries — `<code>; <lower>; <title>;
/// <upper>; # …` with no condition field — into `full[k]` (`k`: 0 upper,
/// 1 lower, 2 title). A conditional entry (`Final_Sigma`, a language tag) is
/// skipped: no target std-wasm answers like applies it (decision 443).
fn readSpecialCasing(arena: std.mem.Allocator, text: []const u8, full: *[3]std.AutoHashMapUnmanaged(u21, []const u21)) !void {
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw[0 .. std.mem.indexOfScalar(u8, raw, '#') orelse raw.len], " \t\r");
        if (line.len == 0) continue;
        var fields: [6][]const u8 = undefined;
        var n: usize = 0;
        var it = std.mem.splitScalar(u8, line, ';');
        while (it.next()) |f| : (n += 1) {
            if (n == fields.len) return fail("SpecialCasing.txt: too many fields: {s}", .{line});
            fields[n] = std.mem.trim(u8, f, " \t");
        }
        if (n < 4) return fail("SpecialCasing.txt: {d} fields: {s}", .{ n, line });
        if (n > 4 and fields[4].len != 0) continue; // a condition
        const cp = try parseCp(fields[0]);
        // The file orders lower, title, upper; `full` orders upper, lower, title.
        for ([_]usize{ 3, 1, 2 }, 0..) |field, k| {
            var cps: std.ArrayListUnmanaged(u21) = .empty;
            var parts = std.mem.tokenizeScalar(u8, fields[field], ' ');
            while (parts.next()) |p| try cps.append(arena, try parseCp(p));
            if (cps.items.len == 0 or cps.items.len > 3) return fail("SpecialCasing.txt: a mapping of {d} code points: {s}", .{ cps.items.len, line });
            try full[k].put(arena, cp, cps.items);
        }
    }
}

/// One run of the simple mapping: every code point of `lo..=hi` stepping by
/// `step` maps to itself plus `delta` (the others in between map to themselves).
const CaseRun = struct { lo: u21, hi: u21, delta: i32, step: u21 };

/// std-wasm's `case_tables.zig`. Answers the run and full-mapping counts.
fn writeCaseTables(
    w: Out,
    version: []const u8,
    simple: *const [3]std.AutoHashMapUnmanaged(u21, u21),
    full: *const [3]std.AutoHashMapUnmanaged(u21, []const u21),
) ![6]usize {
    try w.print(
        \\//! std-wasm's case mapping tables — GENERATED by `zig build gen-unicode`
        \\//! (`libs/std/tools/unicode-gen/main.zig`) from the Unicode {s} Character
        \\//! Database files vendored beside the generator, each pinned by its SHA-256
        \\//! in `manifest.json`. Never edit this file (decision 443; `libs/std/AGENTS.md`
        \\//! § unicode).
        \\//!
        \\//! Per direction, the simple mapping of `UnicodeData.txt` as a `switch` over
        \\//! the code point, and the unconditional full mappings of `SpecialCasing.txt`
        \\//! that are more than the simple one, packed 21 bits per code point (`0`
        \\//! for none). Code, not data: only a program that maps case links them.
        \\
        \\/// The Unicode version these tables were generated from.
        \\pub const version = "{s}";
        \\
    , .{ version, version });
    var counts: [6]usize = undefined;
    const names = [_][]const u8{ "upper", "lower", "title" };
    for (names, 0..) |name, k| {
        const keys = try sortedKeys(w.alloc, u21, simple[k]);
        var runs: std.ArrayListUnmanaged(CaseRun) = .empty;
        for (keys) |cp| {
            const delta = @as(i32, simple[k].get(cp).?) - @as(i32, cp);
            if (runs.items.len > 0) {
                const last = &runs.items[runs.items.len - 1];
                if (last.delta == delta and cp - last.hi == last.step) {
                    last.hi = cp;
                    continue;
                }
                if (last.delta == delta and last.lo == last.hi and (cp - last.hi == 1 or cp - last.hi == 2)) {
                    last.step = cp - last.hi;
                    last.hi = cp;
                    continue;
                }
            }
            try runs.append(w.alloc, .{ .lo = cp, .hi = cp, .delta = delta, .step = 1 });
        }
        counts[k] = runs.items.len;
        try w.print(
            \\
            \\/// The simple {s}case mapping of `cp` (`cp` itself when it has none).
            \\pub fn {s}Simple(cp: u21) u21 {{
            \\    return switch (cp) {{
            \\
        , .{ name, name });
        for (runs.items) |r| {
            var expr_buf: [64]u8 = undefined;
            const expr = if (r.delta >= 0)
                try std.fmt.bufPrint(&expr_buf, "cp + {d}", .{r.delta})
            else
                try std.fmt.bufPrint(&expr_buf, "cp - {d}", .{-r.delta});
            if (r.lo == r.hi) {
                try w.print("        0x{X} => {s},\n", .{ r.lo, expr });
            } else if (r.step == 1) {
                try w.print("        0x{X}...0x{X} => {s},\n", .{ r.lo, r.hi, expr });
            } else {
                try w.print("        0x{X}...0x{X} => if ((cp - 0x{X}) % 2 == 0) {s} else cp,\n", .{ r.lo, r.hi, r.lo, expr });
            }
        }
        try w.print("        else => cp,\n    }};\n}}\n", .{});

        // The full mappings that are more than the simple one.
        const fkeys = try sortedKeys(w.alloc, []const u21, full[k]);
        var n_full: usize = 0;
        try w.print(
            \\
            \\/// The full {s}case mapping of `cp` when it is more than the simple one:
            \\/// up to three code points, the first in the low 21 bits; `0` for none.
            \\pub fn {s}Full(cp: u21) u64 {{
            \\    return switch (cp) {{
            \\
        , .{ name, name });
        for (fkeys) |cp| {
            const m = full[k].get(cp).?;
            if (m.len == 1 and m[0] == (simple[k].get(cp) orelse cp)) continue;
            var v: u64 = 0;
            for (m, 0..) |c, i| v |= @as(u64, c) << @intCast(21 * i);
            try w.print("        0x{X} => 0x{X},\n", .{ cp, v });
            n_full += 1;
        }
        try w.print("        else => 0,\n    }};\n}}\n", .{});
        counts[3 + k] = n_full;
    }
    return counts;
}

const Out = struct {
    list: *std.ArrayListUnmanaged(u8),
    alloc: std.mem.Allocator,

    fn print(self: Out, comptime fmt: []const u8, args: anytype) !void {
        try self.list.print(self.alloc, fmt, args);
    }
};

const Row = struct {
    lo: u21,
    hi: u21,
    class: u8 = 0,
    mapping: []const u21 = &.{},
};

const Pair = struct {
    first: u21,
    second: u21,
    composite: u21,

    fn lessThan(_: void, a: Pair, b: Pair) bool {
        if (a.first != b.first) return a.first < b.first;
        return a.second < b.second;
    }
};

fn parseCp(text: []const u8) !u21 {
    const t = std.mem.trim(u8, text, " \t");
    const v = std.fmt.parseInt(u32, t, 16) catch return fail("not a code point: \"{s}\"", .{t});
    if (v > 0x10FFFF) return fail("past U+10FFFF: {s}", .{t});
    return @intCast(v);
}

/// The code points of a UCD property file, `XXXX` or `XXXX..YYYY` before the
/// first `;` (or the `#` when `property` is null, `CompositionExclusions.txt`'s
/// shape), on the lines whose property field is `property`.
fn readCodePointList(
    arena: std.mem.Allocator,
    text: []const u8,
    property: ?[]const u8,
    set: *std.AutoHashMapUnmanaged(u21, void),
) !void {
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw[0 .. std.mem.indexOfScalar(u8, raw, '#') orelse raw.len], " \t\r");
        if (line.len == 0) continue;
        var fields = std.mem.splitScalar(u8, line, ';');
        const range = std.mem.trim(u8, fields.first(), " \t");
        if (property) |want| {
            const got = std.mem.trim(u8, fields.next() orelse continue, " \t");
            if (!std.mem.eql(u8, got, want)) continue;
        } else if (fields.next() != null) return fail("a code point list line with a field: {s}", .{line});
        var lo: u21 = undefined;
        var hi: u21 = undefined;
        if (std.mem.indexOf(u8, range, "..")) |dots| {
            lo = try parseCp(range[0..dots]);
            hi = try parseCp(range[dots + 2 ..]);
        } else {
            lo = try parseCp(range);
            hi = lo;
        }
        var cp = lo;
        while (cp <= hi) : (cp += 1) try set.put(arena, cp, {});
    }
}

fn sortedKeys(arena: std.mem.Allocator, comptime V: type, map: std.AutoHashMapUnmanaged(u21, V)) ![]u21 {
    var keys: std.ArrayListUnmanaged(u21) = try .initCapacity(arena, map.count());
    var it = map.keyIterator();
    while (it.next()) |k| keys.appendAssumeCapacity(k.*);
    std.mem.sort(u21, keys.items, {}, std.sort.asc(u21));
    return keys.items;
}

fn writePattern(w: Out, lo: u21, hi: u21) !void {
    if (lo == hi) try w.print("{d}", .{lo}) else try w.print("{d}...{d}", .{ lo, hi });
}

/// `pub fn <name>(cp: i32) -> <ty>`: a `case` over the leaves' spans, then one
/// leaf function per `leaf_arms` rows.
fn writeTable(w: Out, name: []const u8, ty: []const u8, default: []const u8, rows: []const Row, doc: []const u8) !void {
    const leaves = (rows.len + leaf_arms - 1) / leaf_arms;
    try w.print("\n{s}\npub fn {s}(cp: i32) -> {s} {{\n    return case cp {{\n", .{ doc, name, ty });
    for (0..leaves) |i| {
        const first = rows[i * leaf_arms];
        const hi = if (i + 1 < leaves) rows[(i + 1) * leaf_arms].lo - 1 else rows[rows.len - 1].hi;
        try w.print("        ", .{});
        try writePattern(w, first.lo, hi);
        try w.print(" -> {s}{d}(cp);\n", .{ name, i });
    }
    try w.print("        _ -> {s};\n    }};\n}}\n", .{default});
    for (0..leaves) |i| {
        const leaf = rows[i * leaf_arms .. @min(rows.len, (i + 1) * leaf_arms)];
        try w.print("\nfn {s}{d}(cp: i32) -> {s} {{\n    return case cp {{\n", .{ name, i, ty });
        for (leaf) |r| {
            try w.print("        ", .{});
            try writePattern(w, r.lo, r.hi);
            if (r.mapping.len == 0) {
                try w.print(" -> {d};\n", .{r.class});
            } else {
                // The formatter's spelling: one line when it fits its 80
                // columns, else one element per line.
                var flat: std.ArrayListUnmanaged(u8) = .empty;
                defer flat.deinit(w.alloc);
                for (r.mapping, 0..) |cp, j| try flat.print(w.alloc, "{s}{d}", .{ if (j == 0) "" else ", ", cp });
                const pattern_len = std.fmt.count("{d}", .{r.lo});
                if ("        ".len + pattern_len + " -> [".len + flat.items.len + "];".len <= format_width) {
                    try w.print(" -> [{s}];\n", .{flat.items});
                } else {
                    try w.print(" -> [\n", .{});
                    for (r.mapping) |cp| try w.print("            {d},\n", .{cp});
                    try w.print("        ];\n", .{});
                }
            }
        }
        try w.print("        _ -> {s};\n    }};\n}}\n", .{default});
    }
}

/// `pub fn primaryComposite(first: i32, second: i32) -> i32`: a `case` over
/// `first` dispatching to leaves that hold whole groups of one `first`, each
/// group a nested `case` over `second`.
fn writeComposites(w: Out, pairs: []const Pair) !void {
    // leaf boundaries: a leaf closes once it holds `leaf_arms` pairs, never
    // inside a group of one `first`.
    var starts: std.ArrayListUnmanaged(usize) = .empty;
    defer starts.deinit(w.alloc);
    var count: usize = 0;
    for (pairs, 0..) |p, i| {
        const new_group = i == 0 or pairs[i - 1].first != p.first;
        if (i == 0 or (new_group and count >= leaf_arms)) {
            try starts.append(w.alloc, i);
            count = 0;
        }
        count += 1;
    }
    try w.print(
        \\
        \\// The primary composite of `first` followed by `second` — the code point
        \\// whose canonical mapping is the pair and which is not excluded from
        \\// composition —, or 0 when there is none.
        \\pub fn primaryComposite(first: i32, second: i32) -> i32 {{
        \\    return case first {{
        \\
    , .{});
    for (starts.items, 0..) |s, i| {
        const lo = pairs[s].first;
        const hi = if (i + 1 < starts.items.len) pairs[starts.items[i + 1]].first - 1 else pairs[pairs.len - 1].first;
        try w.print("        ", .{});
        try writePattern(w, lo, hi);
        try w.print(" -> primaryComposite{d}(first, second);\n", .{i});
    }
    try w.print("        _ -> 0;\n    }};\n}}\n", .{});
    for (starts.items, 0..) |s, i| {
        const end = if (i + 1 < starts.items.len) starts.items[i + 1] else pairs.len;
        try w.print("\nfn primaryComposite{d}(first: i32, second: i32) -> i32 {{\n    return case first {{\n", .{i});
        var j = s;
        while (j < end) {
            const first = pairs[j].first;
            try w.print("        {d} -> case second {{\n", .{first});
            while (j < end and pairs[j].first == first) : (j += 1)
                try w.print("            {d} -> {d};\n", .{ pairs[j].second, pairs[j].composite });
            try w.print("            _ -> 0;\n        }};\n", .{});
        }
        try w.print("        _ -> 0;\n    }};\n}}\n", .{});
    }
}
