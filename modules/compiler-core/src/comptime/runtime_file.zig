//! Decision 805 (1)–(3) — the build's reusable intermediate, `<pkg>.bpr`: one
//! package's resolved tree as the compiler holds it once comptime has run,
//! in the compiler's own binary format, uncompressed. `botopink build
//! --emit-runtime <dir>` writes one per package of the program's closure
//! (`compiler-cli` `build.zig`); `botopink build` / `run` over a `.bpr` read
//! the program back and emit it with no lexer, parser, check or comptime.
//!
//! A `.bpr` is no botopink and no reader's: it is the level B entry's
//! encoding (`analysis_entry.zig`, the same generic binary writer over the
//! Zig types, the same skips) inside a container of its own, so a field
//! added to the analysis is carried without anyone remembering to.
//!
//! The root's bytes may differ between a build that had level B warm and a
//! cold one (the encoder's identity table follows the live tree's aliasing);
//! the decoded tree is the same.
//!
//! ## The file
//!
//! ```text
//! magic        8 bytes   "BPRUNTM\x00"
//! entry                  an `analysis_entry.pack` container whose key is the
//!                        compiler's stamp (`Stamp`), its sections:
//!   META                 `Meta`
//!   STRINGS
//!   ANALYSIS             one `Unit` per module, in META's module order
//! ```
//!
//! **The compiler** (805 (2)): the key is the stamp of the compiler that wrote
//! the file — the CLI's `sha256(version, source hash)` — and a reader of
//! another stamp refuses it (`error.OtherCompiler`) before decoding a byte:
//! the encoding follows the compiler's own types, so another compiler's file
//! is never read nor rebuilt silently.
//!
//! **The package** (805 (1)): a file holds one package's modules — a
//! dependency's (its import name), a loaded file's, an embedded std module's
//! (one file per module, as level B files them), or the root package's —
//! and nothing of its dependants, so a dependency's file serves every program
//! that reaches it. Only the root package's file says what the program is:
//! `Meta.program`, every module of the closure in the build's order with the
//! file it lives in, and `Meta.deps`, the dependency packages the build's
//! module table names (`crossModule.Packages`).
const std = @import("std");
const entry = @import("./analysis_entry.zig");
const comptimeMod = @import("../comptime.zig");

/// The first eight bytes of every `.bpr`.
pub const MAGIC = "BPRUNTM\x00";

/// The extension of the file, `<dir>/<group>.bpr`.
pub const EXT = ".bpr";

/// The compiler that writes and reads a file: a hash of its version and its
/// sources, the CLI's to compute.
pub const Stamp = [32]u8;

/// Where one module of the program lives.
pub const Placed = struct {
    /// The file's group: a dependency's import name, `std/<module>`, or the
    /// root package's name — `<dir>/<group>.bpr`.
    group: []const u8,
    module: []const u8,
};

/// META: what the file is of.
pub const Meta = struct {
    /// The file's group (`Placed.group`).
    group: []const u8,
    /// Its modules, in the order their ANALYSIS sections follow.
    modules: []const []const u8,
    /// The root package's file alone: the program's modules in the build's
    /// order, each with the file that holds it (its own included). Empty in
    /// a dependency's.
    program: []const Placed = &.{},
    /// The root package's file alone: the root package's name and the
    /// dependency packages the build's module table names.
    root: []const u8 = "",
    deps: []const []const u8 = &.{},
    /// The root package's file alone: the runtime a wasm build of the program
    /// binds to, the manifest's `"wasm": { "host": … }` (decision 334 (2)).
    wasm_host: @import("../ast.zig").WasmHost = .wasi,
};

/// One module's analysis, its source with it: a target's refusal at emit
/// renders against it (`ModuleOutput.failedModule`).
pub const Unit = struct {
    name: []const u8,
    srcPath: []const u8,
    src: []const u8,
    ok: comptimeMod.ComptimeOutput.OkData,
};

pub const WriteError = entry.EncodeError || error{ NotAnalysed, AbsolutePath };

// ── No machine's path in a set (decisions 1030 (3), 1077 (3), 1078) ─────────
//
// A by-name load's `root` is the directory its name resolves to, a property of
// the run: every string a set holds passes through the codec's `symbolize`
// on write — each load directory (`Paths.subs`) in it becomes its symbol,
// `load.rootSymbol`, wherever it stands: a literal a folded `compiler.src()`
// left, the stored build output, the comptime reply JSON, a captured `run()`
// text — and through `desymbolize` on read (`readWith`), the symbol becoming
// the directory the load resolves to now. Each string is one value of the
// STRINGS table, written with its own length: nothing is replaced in the
// file's bytes. A string already holding `bp-root:` before it is symbolized,
// and one that still holds a load directory or another path of the machine
// (`Paths.machine`) after, refuses the write (`error.AbsolutePath`,
// `Paths.found` naming the module and the field).

/// What every symbol starts with (`load.rootSymbol`), 64 hex digits after it.
pub const ROOT_MARK = @import("./load.zig").root_symbol_prefix;
const SYMBOL_LEN = ROOT_MARK.len + 64;

/// One directory and the symbol that stands for it in a set.
pub const Sub = struct { dir: []const u8, symbol: []const u8 };

/// Why a write was refused: a string of the set already held a symbol, or
/// still holds a machine's path once symbolized.
pub const Refusal = enum { symbol_in_text, absolute_path };

/// The first string that refused a set's write: the module whose analysis
/// first wrote it (`meta` for the file's META), the field holding it, the
/// string as it would be written and the directory it holds (`""` for
/// `symbol_in_text`).
pub const Found = struct { why: Refusal, module: []const u8, field: []const u8, text: []const u8, dir: []const u8 };

pub const Paths = struct {
    /// Each directory written as its symbol.
    subs: []const Sub = &.{},
    /// The directories no string may hold once `subs` are applied (the load
    /// directories among them).
    machine: []const []const u8 = &.{},
    /// Filled (in `found_arena`) when the write is refused.
    found: ?*?Found = null,
    found_arena: ?std.mem.Allocator = null,
};

fn pathChar(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '.' or c == '_' or c == '-';
}

/// The index of `dir` in `s` at or after `from`, as a whole path (what follows
/// it is no path character: `/x/lib` is not found in `/x/lib2`).
fn findPath(s: []const u8, dir: []const u8, from: usize) ?usize {
    if (dir.len == 0) return null;
    var i = from;
    while (std.mem.indexOfPos(u8, s, i, dir)) |at| {
        const end = at + dir.len;
        if (end == s.len or !pathChar(s[end])) return at;
        i = at + 1;
    }
    return null;
}

/// `s` with each `subs` directory (the longest first) written as its symbol,
/// or null when it holds none. `subs` must be sorted longest directory first.
fn substitute(gpa: std.mem.Allocator, s: []const u8, subs: []const Sub) !?[]u8 {
    var any = false;
    for (subs) |sb| if (findPath(s, sb.dir, 0) != null) {
        any = true;
        break;
    };
    if (!any) return null;
    var cur: []u8 = try gpa.dupe(u8, s);
    for (subs) |sb| {
        var out: std.ArrayListUnmanaged(u8) = .empty;
        errdefer out.deinit(gpa);
        var i: usize = 0;
        while (findPath(cur, sb.dir, i)) |at| {
            try out.appendSlice(gpa, cur[i..at]);
            try out.appendSlice(gpa, sb.symbol);
            i = at + sb.dir.len;
        }
        try out.appendSlice(gpa, cur[i..]);
        gpa.free(cur);
        cur = try out.toOwnedSlice(gpa);
    }
    return cur;
}

fn longestFirst(_: void, a: Sub, b: Sub) bool {
    return a.dir.len > b.dir.len;
}

/// The file of `outputs` (each `.ok`, all of one group), allocated with `gpa`.
pub fn write(gpa: std.mem.Allocator, stamp: Stamp, meta: Meta, outputs: []const comptimeMod.ComptimeOutput) WriteError![]u8 {
    return writeWith(gpa, stamp, meta, outputs, .{});
}

/// `write`, each `paths.subs` directory written as its symbol and a string
/// still holding a `paths.machine` directory refused (`error.AbsolutePath`).
pub fn writeWith(gpa: std.mem.Allocator, stamp: Stamp, meta: Meta, outputs: []const comptimeMod.ComptimeOutput, paths: Paths) WriteError![]u8 {
    const subs = try gpa.dupe(Sub, paths.subs);
    defer gpa.free(subs);
    std.mem.sort(Sub, subs, {}, longestFirst);
    // Each string as it is written: its symbols in place.
    var texts: std.ArrayListUnmanaged([]const u8) = .empty;
    var made: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (made.items) |m| gpa.free(m);
        made.deinit(gpa);
        texts.deinit(gpa);
    }
    var enc = entry.Encoder(&entry.default_skips).init(gpa);
    defer enc.deinit();
    var owned: std.ArrayListUnmanaged([]u8) = .empty;
    defer {
        for (owned.items) |b| gpa.free(b);
        owned.deinit(gpa);
    }
    var sections: std.ArrayListUnmanaged(entry.Section) = .empty;
    defer sections.deinit(gpa);

    // The identity table spans the sections: the reader decodes them in the
    // order they are encoded.
    try enc.encode(Meta, &meta);
    try checkNew(gpa, &enc, &texts, &made, subs, paths, "meta");
    try owned.append(gpa, try enc.takeSection());
    try sections.append(gpa, .{ .id = .meta, .bytes = owned.items[owned.items.len - 1] });
    try sections.append(gpa, .{ .id = .strings, .bytes = "" });
    for (outputs) |o| {
        const u: Unit = .{ .name = o.name, .srcPath = o.srcPath, .src = o.src, .ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => return error.NotAnalysed,
        } };
        try enc.encode(Unit, &u);
        try checkNew(gpa, &enc, &texts, &made, subs, paths, o.name);
        try owned.append(gpa, try enc.takeSection());
        try sections.append(gpa, .{ .id = .analysis, .bytes = owned.items[owned.items.len - 1] });
    }
    try owned.append(gpa, try stringsOf(gpa, texts.items));
    sections.items[1].bytes = owned.items[owned.items.len - 1];

    const packed_bytes = try entry.pack(gpa, stamp, sections.items);
    defer gpa.free(packed_bytes);
    const out = try gpa.alloc(u8, MAGIC.len + packed_bytes.len);
    @memcpy(out[0..MAGIC.len], MAGIC);
    @memcpy(out[MAGIC.len..], packed_bytes);
    return out;
}

/// The strings the last section added (`enc.strings` keeps the first-seen
/// order), each symbolized as it is written; a string already holding a
/// symbol, or still holding a machine path, refuses the write naming `module`
/// and the field (`enc.string_fields`).
fn checkNew(
    gpa: std.mem.Allocator,
    enc: anytype,
    texts: *std.ArrayListUnmanaged([]const u8),
    made: *std.ArrayListUnmanaged([]u8),
    subs: []const Sub,
    paths: Paths,
    module: []const u8,
) WriteError!void {
    const keys = enc.strings.keys();
    const start = texts.items.len;
    for (keys[start..], start..) |k, i| {
        const field = if (i < enc.string_fields.items.len) enc.string_fields.items[i] else "";
        if (std.mem.indexOf(u8, k, ROOT_MARK) != null) return refuse(paths, .symbol_in_text, module, field, k, "");
        var text: []const u8 = k;
        if (subs.len > 0) if (try substitute(gpa, k, subs)) |t| {
            try made.append(gpa, t);
            text = t;
        };
        for (paths.machine) |d| if (findPath(text, d, 0) != null) return refuse(paths, .absolute_path, module, field, text, d);
        try texts.append(gpa, text);
    }
}

fn refuse(paths: Paths, why: Refusal, module: []const u8, field: []const u8, text: []const u8, dir: []const u8) WriteError {
    if (paths.found) |f| if (paths.found_arena) |a| {
        f.* = .{ .why = why, .module = try a.dupe(u8, module), .field = try a.dupe(u8, field), .text = try a.dupe(u8, text), .dir = try a.dupe(u8, dir) };
    };
    return error.AbsolutePath;
}

/// `s` with each symbol read back as the directory `subs` maps it to — the
/// codec's `desymbolize` (decision 1078 (1)); null when a symbol is malformed
/// or `subs` does not name it.
fn desymbolize(arena: std.mem.Allocator, s: []const u8, subs: []const Sub) !?[]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var i: usize = 0;
    while (std.mem.indexOfPos(u8, s, i, ROOT_MARK)) |at| {
        if (at + SYMBOL_LEN > s.len) return null;
        const sym = s[at..][0..SYMBOL_LEN];
        for (sym[ROOT_MARK.len..]) |c| if (!std.ascii.isDigit(c) and !(c >= 'a' and c <= 'f')) return null;
        const dir = for (subs) |sb| {
            if (std.mem.eql(u8, sb.symbol, sym)) break sb.dir;
        } else return null;
        try out.appendSlice(arena, s[i..at]);
        try out.appendSlice(arena, dir);
        i = at + SYMBOL_LEN;
    }
    try out.appendSlice(arena, s[i..]);
    return out.items;
}

/// The STRINGS section of `texts`: the count, then each string's length and bytes.
fn stringsOf(gpa: std.mem.Allocator, texts: []const []const u8) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(gpa);
    try entry.writeUleb(gpa, &buf, texts.len);
    for (texts) |t| {
        try entry.writeUleb(gpa, &buf, t.len);
        try buf.appendSlice(gpa, t);
    }
    return buf.toOwnedSlice(gpa);
}

pub const ReadError = error{
    /// Not a `.bpr` at all (another magic, a short file).
    NotRuntimeFile,
    /// A `.bpr` another compiler wrote (805 (2)).
    OtherCompiler,
    /// A `.bpr` of this compiler that does not read back whole.
    Malformed,
} || std.mem.Allocator.Error;

/// What `read` gives back: the META and each module's analysed output.
pub const Decoded = struct {
    meta: Meta,
    outputs: []comptimeMod.ComptimeOutput,
};

/// Whether `bytes` opens as a `.bpr` the compiler `stamp` names wrote — its
/// two magics and its stamp, nothing decoded (decision 1006 (3): a fresh
/// `.bpr` set's root file opens with this stamp).
pub fn opensWith(bytes: []const u8, stamp: Stamp) bool {
    if (bytes.len < MAGIC.len + entry.MAGIC.len + 32 or !std.mem.eql(u8, bytes[0..MAGIC.len], MAGIC)) return false;
    const body = bytes[MAGIC.len..];
    if (!std.mem.eql(u8, body[0..entry.MAGIC.len], entry.MAGIC)) return false;
    return std.mem.eql(u8, body[entry.MAGIC.len..][0..32], &stamp);
}

/// The file `bytes`, written by the compiler `stamp` names, decoded into
/// `arena` — else why it is not.
pub fn read(arena: std.mem.Allocator, bytes: []const u8, stamp: Stamp) ReadError!Decoded {
    return readWith(arena, bytes, stamp, &.{});
}

/// `read`, each symbol of `subs` read back as its directory (decision 1077
/// (3): the directory the load resolves to now); a symbol `subs` does not
/// name is `error.Malformed` — the set needs a mapping its reader lacks.
pub fn readWith(arena: std.mem.Allocator, bytes: []const u8, stamp: Stamp, subs: []const Sub) ReadError!Decoded {
    if (bytes.len < MAGIC.len + entry.MAGIC.len + 32 or !std.mem.eql(u8, bytes[0..MAGIC.len], MAGIC)) return error.NotRuntimeFile;
    const body = bytes[MAGIC.len..];
    if (!std.mem.eql(u8, body[0..entry.MAGIC.len], entry.MAGIC)) return error.NotRuntimeFile;
    if (!std.mem.eql(u8, body[entry.MAGIC.len..][0..32], &stamp)) return error.OtherCompiler;
    const e = entry.unpack(arena, body, stamp) catch |err| switch (err) {
        error.Doubt => return error.Malformed,
        error.OutOfMemory => return error.OutOfMemory,
    };
    const strings = e.get(.strings) orelse return error.Malformed;
    var dec = entry.Decoder(&entry.default_skips).init(arena, strings) catch |err| switch (err) {
        error.Malformed => return error.Malformed,
        error.OutOfMemory => return error.OutOfMemory,
    };
    if (std.mem.indexOf(u8, strings, ROOT_MARK) != null) {
        const restored = try arena.alloc([]const u8, dec.strings.len);
        for (dec.strings, restored) |str, *r| {
            r.* = str;
            if (std.mem.indexOf(u8, str, ROOT_MARK) == null) continue;
            r.* = (try desymbolize(arena, str, subs)) orelse return error.Malformed;
        }
        dec.strings = restored;
    }
    if (e.sections.len < 2 or e.sections[0].id != .meta) return error.Malformed;
    dec.section(e.sections[0].bytes);
    const meta = dec.decode(Meta) catch |err| return mapDecode(err);
    if (!dec.done()) return error.Malformed;
    var outputs: std.ArrayListUnmanaged(comptimeMod.ComptimeOutput) = .empty;
    for (e.sections[1..]) |s| switch (s.id) {
        .strings => {},
        .analysis => {
            dec.section(s.bytes);
            const u = dec.decode(Unit) catch |err| return mapDecode(err);
            if (!dec.done()) return error.Malformed;
            try outputs.append(arena, .{ .name = u.name, .src = u.src, .srcPath = u.srcPath, .outcome = .{ .ok = u.ok } });
        },
        else => return error.Malformed,
    };
    if (outputs.items.len != meta.modules.len) return error.Malformed;
    for (meta.modules, outputs.items) |m, o| if (!std.mem.eql(u8, m, o.name)) return error.Malformed;
    return .{ .meta = meta, .outputs = outputs.items };
}

fn mapDecode(err: entry.DecodeError) ReadError {
    return switch (err) {
        error.Malformed => error.Malformed,
        error.OutOfMemory => error.OutOfMemory,
    };
}

/// The group of the module `name` of a build whose root package is `root`
/// and whose dependency packages are `deps`: an embedded std module its own
/// path, a dependency's or a loaded file's module its package (the first
/// segment), any other the root package's.
pub fn groupOf(name: []const u8, root: []const u8, deps: []const []const u8) []const u8 {
    if (std.mem.startsWith(u8, name, "std/")) return name;
    if (std.mem.indexOfScalar(u8, name, '/')) |slash| {
        const head = name[0..slash];
        if (!std.mem.eql(u8, head, root)) {
            if (@import("./load.zig").isLoadedPackage(head)) return head;
            for (deps) |d| if (std.mem.eql(u8, d, head)) return head;
        }
    }
    return root;
}

test "runtime file: a round trip keeps the modules, another stamp is refused, another file is no .bpr" {
    const gpa = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const ok: comptimeMod.ComptimeOutput.OkData = .{
        .bindings = &.{},
        .comptime_script = null,
        .transformed = .{ .decls = &.{} },
        .type_ids = std.StringHashMap(usize).init(arena),
        .dispatch_rewrites = std.AutoHashMap(@import("../ast.zig").Loc, []const u8).init(arena),
        .js_method_renames = std.AutoHashMap(@import("../ast.zig").Loc, []const u8).init(arena),
        .instance_lowerings = std.AutoHashMap(@import("../ast.zig").Loc, @import("./env.zig").InstanceLowering).init(arena),
        .custom_ast = &.{},
        .comptime_traces = &.{},
        .build_output = "built\n",
    };
    const outputs = [_]comptimeMod.ComptimeOutput{.{ .name = "main", .src = "fn main() -> void {\n}\n", .srcPath = "src/main.bp", .outcome = .{ .ok = ok } }};
    const stamp: Stamp = @splat(7);
    const bytes = try write(gpa, stamp, .{ .group = "app", .modules = &.{"main"}, .program = &.{.{ .group = "app", .module = "main" }}, .root = "app" }, &outputs);
    defer gpa.free(bytes);
    const d = try read(arena, bytes, stamp);
    try std.testing.expectEqualStrings("app", d.meta.group);
    try std.testing.expectEqual(@as(usize, 1), d.meta.program.len);
    try std.testing.expectEqualStrings("main", d.outputs[0].name);
    try std.testing.expectEqualStrings("fn main() -> void {\n}\n", d.outputs[0].src);
    try std.testing.expectEqualStrings("built\n", d.outputs[0].outcome.ok.build_output);
    try std.testing.expectError(error.OtherCompiler, read(arena, bytes, @splat(8)));
    try std.testing.expectError(error.NotRuntimeFile, read(arena, "fn main() -> void {}\n", stamp));
    const cut = try arena.dupe(u8, bytes[0 .. bytes.len - 1]);
    try std.testing.expectError(error.Malformed, read(arena, cut, stamp));
}

test "runtime file: a load's directory is written as its symbol and read back as the directory given; a machine path is refused (decision 1077 (3))" {
    const gpa = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const ok: comptimeMod.ComptimeOutput.OkData = .{
        .bindings = &.{},
        .comptime_script = null,
        .transformed = .{ .decls = &.{} },
        .type_ids = std.StringHashMap(usize).init(arena),
        .dispatch_rewrites = std.AutoHashMap(@import("../ast.zig").Loc, []const u8).init(arena),
        .js_method_renames = std.AutoHashMap(@import("../ast.zig").Loc, []const u8).init(arena),
        .instance_lowerings = std.AutoHashMap(@import("../ast.zig").Loc, @import("./env.zig").InstanceLowering).init(arena),
        .custom_ast = &.{},
        .comptime_traces = &.{},
        .build_output = "root [/w/libs/greeter] and /w/libs/greeter2\n",
    };
    const outputs = [_]comptimeMod.ComptimeOutput{.{ .name = "main", .src = "fn main() -> void {\n}\n", .srcPath = "src/main.bp", .outcome = .{ .ok = ok } }};
    const stamp: Stamp = @splat(7);
    const meta: Meta = .{ .group = "app", .modules = &.{"main"}, .program = &.{.{ .group = "app", .module = "main" }}, .root = "app" };
    const sym_arr = @import("./load.zig").rootSymbol("../libs/greeter");
    const sym: []const u8 = &sym_arr;
    const bytes = try writeWith(gpa, stamp, meta, &outputs, .{ .subs = &.{.{ .dir = "/w/libs/greeter", .symbol = sym }}, .machine = &.{"/w/ws"} });
    defer gpa.free(bytes);
    try std.testing.expect(std.mem.indexOf(u8, bytes, "/w/libs/greeter]") == null);
    // Another directory's path that only starts with it is left as it is.
    try std.testing.expect(std.mem.indexOf(u8, bytes, "/w/libs/greeter2") != null);
    const d = try readWith(arena, bytes, stamp, &.{.{ .dir = "/moved/greeter", .symbol = sym }});
    try std.testing.expectEqualStrings("root [/moved/greeter] and /w/libs/greeter2\n", d.outputs[0].outcome.ok.build_output);
    // A reader that cannot name the symbol's directory reads no program.
    try std.testing.expectError(error.Malformed, read(arena, bytes, stamp));
    // A machine path left in a string refuses the write, naming the module and the string.
    var found: ?Found = null;
    var held = ok;
    held.build_output = "cwd /w/ws/app\n";
    const refused = [_]comptimeMod.ComptimeOutput{.{ .name = "main", .src = "", .srcPath = "src/main.bp", .outcome = .{ .ok = held } }};
    try std.testing.expectError(error.AbsolutePath, writeWith(gpa, stamp, meta, &refused, .{ .machine = &.{"/w/ws"}, .found = &found, .found_arena = arena }));
    try std.testing.expectEqualStrings("main", found.?.module);
    try std.testing.expectEqualStrings("build_output", found.?.field);
    try std.testing.expectEqualStrings("cwd /w/ws/app\n", found.?.text);
    try std.testing.expectEqual(Refusal.absolute_path, found.?.why);
    // A load directory left in a string (another spelling of it no symbol stands for) refuses too.
    found = null;
    try std.testing.expectError(error.AbsolutePath, writeWith(gpa, stamp, meta, &outputs, .{ .machine = &.{"/w/libs/greeter2"}, .found = &found, .found_arena = arena }));
    // A string that already holds a symbol refuses the write before it is symbolized.
    found = null;
    var pre = ok;
    pre.build_output = try std.mem.concat(arena, u8, &.{ "root ", sym, "\n" });
    const presym = [_]comptimeMod.ComptimeOutput{.{ .name = "main", .src = "", .srcPath = "src/main.bp", .outcome = .{ .ok = pre } }};
    try std.testing.expectError(error.AbsolutePath, writeWith(gpa, stamp, meta, &presym, .{ .found = &found, .found_arena = arena }));
    try std.testing.expectEqual(Refusal.symbol_in_text, found.?.why);
}

test "runtime file: the group of a module" {
    try std.testing.expectEqualStrings("std/io", groupOf("std/io", "app", &.{"lib"}));
    try std.testing.expectEqualStrings("lib", groupOf("lib/tools", "app", &.{"lib"}));
    try std.testing.expectEqualStrings("app", groupOf("shapes/circle", "app", &.{"lib"}));
    try std.testing.expectEqualStrings("app", groupOf("main", "app", &.{"lib"}));
}
