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

pub const WriteError = entry.EncodeError || error{NotAnalysed};

/// The file of `outputs` (each `.ok`, all of one group), allocated with `gpa`.
pub fn write(gpa: std.mem.Allocator, stamp: Stamp, meta: Meta, outputs: []const comptimeMod.ComptimeOutput) WriteError![]u8 {
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
    try owned.append(gpa, try enc.takeSection());
    try sections.append(gpa, .{ .id = .meta, .bytes = owned.items[owned.items.len - 1] });
    try sections.append(gpa, .{ .id = .strings, .bytes = "" });
    for (outputs) |o| {
        const u: Unit = .{ .name = o.name, .srcPath = o.srcPath, .src = o.src, .ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => return error.NotAnalysed,
        } };
        try enc.encode(Unit, &u);
        try owned.append(gpa, try enc.takeSection());
        try sections.append(gpa, .{ .id = .analysis, .bytes = owned.items[owned.items.len - 1] });
    }
    try owned.append(gpa, try enc.stringsSection());
    sections.items[1].bytes = owned.items[owned.items.len - 1];

    const packed_bytes = try entry.pack(gpa, stamp, sections.items);
    defer gpa.free(packed_bytes);
    const out = try gpa.alloc(u8, MAGIC.len + packed_bytes.len);
    @memcpy(out[0..MAGIC.len], MAGIC);
    @memcpy(out[MAGIC.len..], packed_bytes);
    return out;
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

test "runtime file: the group of a module" {
    try std.testing.expectEqualStrings("std/io", groupOf("std/io", "app", &.{"lib"}));
    try std.testing.expectEqualStrings("lib", groupOf("lib/tools", "app", &.{"lib"}));
    try std.testing.expectEqualStrings("app", groupOf("shapes/circle", "app", &.{"lib"}));
    try std.testing.expectEqualStrings("app", groupOf("main", "app", &.{"lib"}));
}
