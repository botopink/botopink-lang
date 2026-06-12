/// WebAssembly Text (`.wat`) codegen backend.
///
/// Emits a `(module ...)` form that `wasmtime` can execute directly.
///
/// Covers: numeric fn decls, arithmetic, comparisons, if/else, return,
/// top-level val as globals, fn main/0 wrapper, linear memory with bump
/// allocator, length-prefixed strings (`.len`/`.slice`/concat/compare),
/// @print via WASI fd_write, case via if-chain, loops via block/loop/br_if,
/// tuples/arrays in memory, lambdas as i32 indices.
const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");
const crossModule = @import("./crossModule.zig");

const CrossModule = crossModule.CrossModule;

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;

// ── helpers ──────────────────────────────────────────────────────────────────

fn fnArityNoSelf(f: ast.FnDecl) usize {
    var n: usize = 0;
    for (f.params) |p| {
        if (!std.mem.eql(u8, p.name, "self")) n += 1;
    }
    return n;
}

fn isMain0(f: ast.FnDecl) bool {
    return std.mem.eql(u8, f.name, "main") and fnArityNoSelf(f) == 0;
}

fn isSyntheticEntrypointVal(v: ast.ValDecl) bool {
    return std.mem.startsWith(u8, v.name, "_");
}

fn watType(t: ast.TypeRef) []const u8 {
    switch (t) {
        .named => |n| {
            if (std.mem.eql(u8, n, "i32")) return "i32";
            if (std.mem.eql(u8, n, "i64")) return "i64";
            if (std.mem.eql(u8, n, "f32")) return "f32";
            if (std.mem.eql(u8, n, "f64")) return "f64";
            if (std.mem.eql(u8, n, "bool")) return "i32";
        },
        else => {},
    }
    return "i32";
}

fn watTypeOpt(t: ?ast.TypeRef) []const u8 {
    if (t) |x| return watType(x);
    return "i32";
}

// ── public entry ─────────────────────────────────────────────────────────────

pub fn codegenEmit(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    _ = config;
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    // Built only to detect (and flag) cross-module imports — wasm stays
    // single-module today, so it links nothing; the index lets `emitWat`
    // record the explicit limitation instead of silently emitting a `call`
    // to a function that lives in another module.
    var cross = try crossModule.build(alloc, outputs);
    defer cross.deinit();

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError => continue,
            .typeError => continue,
            .validationError => |verr| {
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = try alloc.dupe(u8, ""),
                        .comptime_script = null,
                        .comptime_err = verr,
                    },
                });
            },
            .ok => |*ok| {
                const code = try emitWat(alloc, ct.name, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, &cross);
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = code,
                        .comptime_script = if (ok.comptime_script) |s| try alloc.dupe(u8, s) else null,
                        .comptime_err = null,
                    },
                });
            },
        }
    }

    return results;
}

// ── top-level emitter ────────────────────────────────────────────────────────

const DataSeg = struct { offset: u32, len: u32, content: []const u8 };

fn emitWat(
    alloc: std.mem.Allocator,
    module_name: []const u8,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    cross: ?*const CrossModule,
) ![]u8 {
    _ = module_name;

    var fn_buf: std.Io.Writer.Allocating = .init(alloc);
    defer fn_buf.deinit();

    var em = Emitter.init(alloc, &fn_buf.writer, comptime_vals, rewrites);
    defer em.deinit();
    try em.registerTypes(program);
    try em.collectExtensions(program);

    var has_main_0 = false;
    var main_returns_value = false;
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| if (isMain0(f)) {
            has_main_0 = true;
            main_returns_value = f.returnType != null;
        },
        else => {},
    };

    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| try em.emitFn(f),
        .val => |v| {
            if (!has_main_0 and !isSyntheticEntrypointVal(v)) {
                try em.emitGlobalVal(v);
            }
        },
        .comment => |c| try fn_buf.writer.print("  ;; {s}\n", .{c.text}),
        // Extension methods lower to linear-memory functions named
        // `$<target>_<method>` so activated/qualified dispatch can `call` them.
        .implement => |im| try em.emitExtensionMethods(im.target, im.methods),
        .extend => |ex| try em.emitExtensionMethods(ex.target, ex.methods),
        // KNOWN GAP: wasm is single-module. A `from "<pkg>"` import that
        // resolves to a concrete emitted symbol in another module can't be
        // linked here (no wasm module-linking story yet) — flag it explicitly
        // so the broken `call $sym` below isn't silently mistaken for working
        // code. erlang/beam handle this via remote calls (see crossModule.zig).
        .use => |u| if (cross) |xc| {
            for (u.imports) |imp| {
                if (xc.exports.get(imp.name())) |info| {
                    try fn_buf.writer.print(
                        "  ;; cross-module import not linked (wasm single-module): {s} from {s}\n",
                        .{ imp.name(), info.module },
                    );
                }
            }
        },
        .record, .@"struct", .@"enum", .interface, .delegate, .mod, .@"test" => {},
    };

    if (has_main_0) try em.emitEntrypointWrapper(main_returns_value);

    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();

    try aw.writer.writeAll("(module\n");

    const has_print = em.uses_print;
    if (has_print) {
        try aw.writer.writeAll("  (import \"wasi_snapshot_preview1\" \"fd_write\" (func $fd_write (param i32 i32 i32 i32) (result i32)))\n");
    }

    try aw.writer.writeAll("  (memory (export \"memory\") 1)\n");

    for (em.data_segments.items) |seg| {
        try aw.writer.writeAll("  (data (i32.const ");
        try aw.writer.print("{d}", .{seg.offset});
        try aw.writer.writeAll(") \"");
        // 4-byte little-endian length prefix, then the raw bytes.
        const lenbytes = [4]u8{
            @truncate(seg.len),
            @truncate(seg.len >> 8),
            @truncate(seg.len >> 16),
            @truncate(seg.len >> 24),
        };
        for (lenbytes) |lc| try aw.writer.print("\\{x:0>2}", .{lc});
        for (seg.content) |c| switch (c) {
            '\n' => try aw.writer.writeAll("\\n"),
            '"' => try aw.writer.writeAll("\\\""),
            '\\' => try aw.writer.writeAll("\\\\"),
            '\t' => try aw.writer.writeAll("\\t"),
            '\r' => try aw.writer.writeAll("\\r"),
            else => if (c < 0x20)
                try aw.writer.print("\\{x:0>2}", .{c})
            else
                try aw.writer.writeByte(c),
        };
        try aw.writer.writeAll("\")\n");
    }

    const heap_start = em.next_data_offset;
    try aw.writer.print("  (global $__heap_ptr (mut i32) (i32.const {d}))\n", .{heap_start});

    try aw.writer.writeAll(fn_buf.written());

    if (has_print) {
        try aw.writer.writeAll(
            \\  (func $__print_i32 (param $n i32)
            \\    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
            \\    (local $i i32) (local $j i32) (local $tmp i32)
            \\    i32.const 100
            \\    local.set $buf
            \\    local.get $n
            \\    i32.const 0
            \\    i32.lt_s
            \\    (if
            \\      (then
            \\        i32.const 1
            \\        local.set $neg
            \\        i32.const 0
            \\        local.get $n
            \\        i32.sub
            \\        local.set $n
            \\      )
            \\    )
            \\    (block $done
            \\      (loop $digits
            \\        local.get $n
            \\        i32.const 10
            \\        i32.rem_u
            \\        i32.const 48
            \\        i32.add
            \\        local.set $d
            \\        local.get $buf
            \\        local.get $len
            \\        i32.add
            \\        local.get $d
            \\        i32.store8
            \\        local.get $len
            \\        i32.const 1
            \\        i32.add
            \\        local.set $len
            \\        local.get $n
            \\        i32.const 10
            \\        i32.div_u
            \\        local.set $n
            \\        local.get $n
            \\        i32.const 0
            \\        i32.gt_u
            \\        br_if $digits
            \\      )
            \\    )
            \\    ;; reverse
            \\    i32.const 0
            \\    local.set $i
            \\    local.get $len
            \\    i32.const 1
            \\    i32.sub
            \\    local.set $j
            \\    (block $rdone
            \\      (loop $rev
            \\        local.get $i
            \\        local.get $j
            \\        i32.ge_u
            \\        br_if $rdone
            \\        local.get $buf
            \\        local.get $i
            \\        i32.add
            \\        i32.load8_u
            \\        local.set $tmp
            \\        local.get $buf
            \\        local.get $i
            \\        i32.add
            \\        local.get $buf
            \\        local.get $j
            \\        i32.add
            \\        i32.load8_u
            \\        i32.store8
            \\        local.get $buf
            \\        local.get $j
            \\        i32.add
            \\        local.get $tmp
            \\        i32.store8
            \\        local.get $i
            \\        i32.const 1
            \\        i32.add
            \\        local.set $i
            \\        local.get $j
            \\        i32.const 1
            \\        i32.sub
            \\        local.set $j
            \\        br $rev
            \\      )
            \\    )
            \\    ;; add neg sign + newline
            \\    local.get $neg
            \\    (if
            \\      (then
            \\        local.get $buf
            \\        local.get $len
            \\        i32.add
            \\        local.get $buf
            \\        local.get $len
            \\        call $__memmove
            \\        local.get $buf
            \\        i32.const 45
            \\        i32.store8
            \\        local.get $len
            \\        i32.const 1
            \\        i32.add
            \\        local.set $len
            \\      )
            \\    )
            \\    local.get $buf
            \\    local.get $len
            \\    i32.add
            \\    i32.const 10
            \\    i32.store8
            \\    local.get $len
            \\    i32.const 1
            \\    i32.add
            \\    local.set $len
            \\    ;; fd_write
            \\    i32.const 0
            \\    local.get $buf
            \\    i32.store
            \\    i32.const 4
            \\    local.get $len
            \\    i32.store
            \\    i32.const 1
            \\    i32.const 0
            \\    i32.const 1
            \\    i32.const 8
            \\    call $fd_write
            \\    drop
            \\  )
            \\  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
            \\    (local $i i32)
            \\    local.get $len
            \\    i32.const 1
            \\    i32.sub
            \\    local.set $i
            \\    (block $done
            \\      (loop $loop
            \\        local.get $i
            \\        i32.const 0
            \\        i32.lt_s
            \\        br_if $done
            \\        local.get $dst
            \\        local.get $i
            \\        i32.add
            \\        local.get $src
            \\        local.get $i
            \\        i32.add
            \\        i32.load8_u
            \\        i32.store8
            \\        local.get $i
            \\        i32.const 1
            \\        i32.sub
            \\        local.set $i
            \\        br $loop
            \\      )
            \\    )
            \\  )
            \\
        );
    }

    if (em.uses_str_concat) {
        try aw.writer.writeAll(
            \\  (func $__str_concat (param $a i32) (param $alen i32) (param $b i32) (param $blen i32) (result i32)
            \\    (local $base i32)
            \\    global.get $__heap_ptr
            \\    local.set $base
            \\    ;; bump heap by 4 (length prefix) + alen + blen
            \\    global.get $__heap_ptr
            \\    i32.const 4
            \\    local.get $alen
            \\    i32.add
            \\    local.get $blen
            \\    i32.add
            \\    i32.add
            \\    global.set $__heap_ptr
            \\    ;; store combined length prefix
            \\    local.get $base
            \\    local.get $alen
            \\    local.get $blen
            \\    i32.add
            \\    i32.store
            \\    ;; copy a's bytes: base+4 <- a+4
            \\    local.get $base
            \\    i32.const 4
            \\    i32.add
            \\    local.get $a
            \\    i32.const 4
            \\    i32.add
            \\    local.get $alen
            \\    memory.copy
            \\    ;; copy b's bytes: base+4+alen <- b+4
            \\    local.get $base
            \\    i32.const 4
            \\    i32.add
            \\    local.get $alen
            \\    i32.add
            \\    local.get $b
            \\    i32.const 4
            \\    i32.add
            \\    local.get $blen
            \\    memory.copy
            \\    local.get $base
            \\  )
            \\
        );
    }

    if (em.uses_str_eq) {
        try aw.writer.writeAll(
            \\  (func $__str_eq (param $a i32) (param $alen i32) (param $b i32) (param $blen i32) (result i32)
            \\    (local $i i32)
            \\    local.get $alen
            \\    local.get $blen
            \\    i32.ne
            \\    (if
            \\      (then i32.const 0 return)
            \\    )
            \\    (block $done
            \\      (loop $cmp
            \\        local.get $i
            \\        local.get $alen
            \\        i32.ge_u
            \\        br_if $done
            \\        local.get $a
            \\        local.get $i
            \\        i32.add
            \\        i32.load8_u offset=4
            \\        local.get $b
            \\        local.get $i
            \\        i32.add
            \\        i32.load8_u offset=4
            \\        i32.ne
            \\        (if
            \\          (then i32.const 0 return)
            \\        )
            \\        local.get $i
            \\        i32.const 1
            \\        i32.add
            \\        local.set $i
            \\        br $cmp
            \\      )
            \\    )
            \\    i32.const 1
            \\  )
            \\
        );
    }

    if (em.uses_str_slice) {
        try aw.writer.writeAll(
            \\  (func $__str_slice (param $src i32) (param $start i32) (param $end i32) (result i32)
            \\    (local $newlen i32) (local $dst i32)
            \\    local.get $end
            \\    local.get $start
            \\    i32.sub
            \\    local.set $newlen
            \\    global.get $__heap_ptr
            \\    local.set $dst
            \\    ;; bump heap by 4 (length prefix) + newlen
            \\    global.get $__heap_ptr
            \\    i32.const 4
            \\    local.get $newlen
            \\    i32.add
            \\    i32.add
            \\    global.set $__heap_ptr
            \\    ;; store length prefix
            \\    local.get $dst
            \\    local.get $newlen
            \\    i32.store
            \\    ;; copy bytes: dst+4 <- src+4+start
            \\    local.get $dst
            \\    i32.const 4
            \\    i32.add
            \\    local.get $src
            \\    i32.const 4
            \\    i32.add
            \\    local.get $start
            \\    i32.add
            \\    local.get $newlen
            \\    memory.copy
            \\    local.get $dst
            \\  )
            \\
        );
    }

    try aw.writer.writeAll(")\n");

    return aw.toOwnedSlice();
}

// ── Emitter ──────────────────────────────────────────────────────────────────

const Emitter = struct {
    alloc: std.mem.Allocator,
    out: *std.Io.Writer,
    cv: std.StringHashMap([]const u8),

    cur_result: []const u8 = "i32",
    locals: std.StringHashMap([]const u8),
    case_depth: u32 = 0,
    try_seq: u32 = 0,
    /// Sequence counter for the `$_res{n}` scratch pointers a Result/Option
    /// method op uses to hold its receiver (and, for `map`, the rewrapped
    /// result) while the tag/payload are read out.
    res_seq: u32 = 0,
    /// Sequence counter for the `$__mem{n}` scratch pointers used when building
    /// or destructuring aggregates (tuples, arrays, records, enum payloads).
    mem_seq: u32 = 0,

    // ── type registry (codegen is untyped, so we recover record/enum layout
    //    from the declarations to lower construction/access by memory offset) ──
    /// record/struct name → ordered field names (slots are 4 bytes each).
    records: std.StringHashMap([]const []const u8),
    /// enum name → variants (tag = declaration index; payload fields follow).
    enums: std.StringHashMap([]const ast.EnumVariant),
    /// Arena backing the slices stored in `records` (field-name strings alias
    /// the AST and are not copied).
    reg_arena: std.heap.ArenaAllocator,

    data_segments: std.ArrayListUnmanaged(DataSeg) = .empty,
    next_data_offset: u32 = 256,
    uses_print: bool = false,
    uses_str_concat: bool = false,
    uses_str_eq: bool = false,
    uses_str_slice: bool = false,

    /// Static extension dispatch (F6): call-site loc → activated extension symbol.
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    /// Extension block name → target type + methods (for resolving the mangled
    /// `$<target>_<method>` callee at activated and qualified dispatch sites).
    ext_by_name: std.StringHashMap(ExtInfo),

    const ExtInfo = struct { target: []const u8, methods: []const ast.ImplementMethod };

    fn init(alloc: std.mem.Allocator, out: *std.Io.Writer, cv: std.StringHashMap([]const u8), rewrites: std.AutoHashMap(ast.Loc, []const u8)) Emitter {
        return .{
            .alloc = alloc,
            .out = out,
            .cv = cv,
            .locals = std.StringHashMap([]const u8).init(alloc),
            .records = std.StringHashMap([]const []const u8).init(alloc),
            .enums = std.StringHashMap([]const ast.EnumVariant).init(alloc),
            .reg_arena = std.heap.ArenaAllocator.init(alloc),
            .rewrites = rewrites,
            .ext_by_name = std.StringHashMap(ExtInfo).init(alloc),
        };
    }

    fn deinit(self: *Emitter) void {
        self.locals.deinit();
        self.records.deinit();
        self.enums.deinit();
        self.reg_arena.deinit();
        self.data_segments.deinit(self.alloc);
        self.ext_by_name.deinit();
    }

    fn collectExtensions(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .implement => |im| try self.ext_by_name.put(im.name, .{ .target = im.target, .methods = im.methods }),
            .extend => |ex| try self.ext_by_name.put(ex.name, .{ .target = ex.target, .methods = ex.methods }),
            else => {},
        };
    }

    /// Mangled `$<target>_<method>` name for a dispatch site (without the `$`),
    /// written into `buf`. `sym` is the extension block name; the qualifier
    /// defaults to the target type (matching `emitExtensionMethods`).
    fn extMangledName(self: *Emitter, buf: []u8, sym: []const u8, method: []const u8) ?[]const u8 {
        const info = self.ext_by_name.get(sym) orelse return null;
        var qualifier = info.target;
        for (info.methods) |m| {
            if (std.mem.eql(u8, m.name, method)) {
                qualifier = m.qualifier orelse info.target;
                break;
            }
        }
        return std.fmt.bufPrint(buf, "{s}_{s}", .{ qualifier, method }) catch null;
    }

    /// Populate `records`/`enums` from the program's type declarations so that
    /// construction calls can be distinguished from ordinary function calls.
    fn registerTypes(self: *Emitter, program: ast.Program) !void {
        const ra = self.reg_arena.allocator();
        for (program.decls) |decl| switch (decl) {
            .record => |r| {
                const names = try ra.alloc([]const u8, r.fields.len);
                for (r.fields, 0..) |f, i| names[i] = f.name;
                try self.records.put(r.name, names);
            },
            .@"struct" => |s| {
                var count: usize = 0;
                for (s.members) |m| switch (m) {
                    .field => count += 1,
                    else => {},
                };
                const names = try ra.alloc([]const u8, count);
                var i: usize = 0;
                for (s.members) |m| switch (m) {
                    .field => |f| {
                        names[i] = f.name;
                        i += 1;
                    },
                    else => {},
                };
                try self.records.put(s.name, names);
            },
            .@"enum" => |e| try self.enums.put(e.name, e.variants),
            else => {},
        };
    }

    fn w(self: *Emitter, s: []const u8) !void {
        try self.out.writeAll(s);
    }

    fn fmt(self: *Emitter, comptime f: []const u8, args: anytype) !void {
        try self.out.print(f, args);
    }

    fn resetFnState(self: *Emitter, result_type: []const u8) void {
        self.locals.clearRetainingCapacity();
        self.cur_result = result_type;
        self.case_depth = 0;
        self.try_seq = 0;
        self.mem_seq = 0;
        self.res_seq = 0;
    }

    fn internString(self: *Emitter, s: []const u8) !DataSeg {
        for (self.data_segments.items) |seg| {
            if (seg.len == s.len and std.mem.eql(u8, seg.content, s)) return seg;
        }
        // Strings are length-prefixed: the value is a pointer to a 4-byte i32
        // length word, immediately followed by the raw bytes (at `offset + 4`).
        // This lets `.len`/`.slice` and concat operate on runtime strings without
        // carrying the length in a separate register.
        const seg = DataSeg{
            .offset = self.next_data_offset,
            .len = @intCast(s.len),
            .content = s,
        };
        self.next_data_offset += 4 + @as(u32, @intCast(s.len));
        if (self.next_data_offset % 4 != 0)
            self.next_data_offset += 4 - (self.next_data_offset % 4);
        try self.data_segments.append(self.alloc, seg);
        return seg;
    }

    // ── fn ───────────────────────────────────────────────────────────────────

    fn emitFn(self: *Emitter, f: ast.FnDecl) !void {
        const result_type = watTypeOpt(f.returnType);
        self.resetFnState(result_type);

        // An effect fn is async/generator — except `#[@result]` (checked-Result
        // effect), which is a plain function. WASM is single-threaded and eager
        // here: `@Future<T>` resolves to `T` (`await` is identity); full
        // generator state-machine lowering is not yet implemented.
        if (f.effect != null and f.effect.? != .result) {
            try self.w("  ;; *fn (async/generator) — eager lowering\n");
        }
        try self.w("  (func $");
        try self.w(f.name);
        if (f.isPub) {
            try self.fmt(" (export \"{s}\")", .{f.name});
        }
        for (f.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            const t = watType(p.typeRef);
            try self.locals.put(p.name, t);
            try self.fmt(" (param ${s} {s})", .{ p.name, t });
        }
        if (f.returnType != null) {
            try self.fmt(" (result {s})", .{result_type});
        }
        try self.w("\n");
        const try_count = countTrys(f.body);
        for (0..try_count) |i| {
            try self.fmt("    (local $_try{d} i32)\n", .{i});
        }
        const mem_count = self.countMems(f.body);
        for (0..mem_count) |i| {
            try self.fmt("    (local $__mem{d} i32)\n", .{i});
        }
        try self.emitLocalDecls(f.body);
        try self.emitBody(f.body, result_type);
        try self.w("  )\n");
    }

    /// Emit each `implement`/`extend` method as a linear-memory function
    /// `$<target>_<method>`. Unlike `emitFn`, the receiver `self` is kept as a
    /// real `i32` param (records/structs are heap pointers) so an activated
    /// `recv.m(args)` dispatch can pass it. Codegen is untyped and method
    /// bodies carry no return type, so params/result default to `i32`; a method
    /// whose body yields no value is emitted without a result.
    fn emitExtensionMethods(self: *Emitter, target: []const u8, methods: []const ast.ImplementMethod) !void {
        for (methods) |m| {
            const has_result = bodyYieldsValue(m.body);
            self.resetFnState("i32");
            const qualifier = m.qualifier orelse target;
            try self.fmt("  (func ${s}_{s}", .{ qualifier, m.name });
            for (m.params) |p| {
                try self.locals.put(p.name, "i32");
                try self.fmt(" (param ${s} i32)", .{p.name});
            }
            if (has_result) try self.w(" (result i32)");
            try self.w("\n");
            const try_count = countTrys(m.body);
            for (0..try_count) |i| {
                try self.fmt("    (local $_try{d} i32)\n", .{i});
            }
            const mem_count = self.countMems(m.body);
            for (0..mem_count) |i| {
                try self.fmt("    (local $__mem{d} i32)\n", .{i});
            }
            try self.emitLocalDecls(m.body);
            try self.emitBody(m.body, "i32");
            try self.w("  )\n");
        }
    }

    /// True when a method body's final statement produces a value (so the WAT
    /// function needs a `(result i32)`). Void-tailed bodies (a bare `@print`,
    /// a valueless `return`, or an empty body) yield nothing.
    fn bodyYieldsValue(body: []const ast.Stmt) bool {
        if (body.len == 0) return false;
        const last = body[body.len - 1].expr;
        return switch (last) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| r != null,
                .yield => |y| y.value != null,
                .await_ => true,
                else => false,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| !(cc.is_builtin and
                    (std.mem.eql(u8, cc.callee, "print") or
                        std.mem.eql(u8, cc.callee, "todo") or
                        std.mem.eql(u8, cc.callee, "panic"))),
                .pipeline => true,
            },
            .binding => false,
            else => true,
        };
    }

    /// Count `try`/`try…catch` nodes so a scratch pointer local can be declared
    /// for each (WAT locals must be declared up-front, before the body).
    fn countTrys(body: []const ast.Stmt) u32 {
        var n: u32 = 0;
        for (body) |stmt| n += countTrysExpr(stmt.expr);
        return n;
    }

    fn countTrysExpr(e: ast.Expr) u32 {
        return switch (e) {
            .jump => |j| switch (j.kind) {
                .try_ => |t| 1 + (if (t) |i| countTrysExpr(i.*) else 0),
                .@"return", .throw_, .@"break" => |v| if (v) |i| countTrysExpr(i.*) else 0,
                .yield => |y| if (y.value) |i| countTrysExpr(i.*) else 0,
                .await_ => |a| countTrysExpr(a.*),
                else => 0,
            },
            .branch => |b| switch (b.kind) {
                .tryCatch => |tc| 1 + countTrysExpr(tc.expr.*) + countTrysExpr(tc.handler.*),
                .if_ => |i| blk: {
                    var n = countTrysExpr(i.cond.*) + countTrys(i.then_);
                    if (i.else_) |els| n += countTrys(els);
                    break :blk n;
                },
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| countTrysExpr(lb.value.*),
                .localBindDestruct => |lb| countTrysExpr(lb.value.*),
                .assign => |a| countTrysExpr(a.value.*),
            },
            else => 0,
        };
    }

    /// What a `.call` lowers to. Construction calls need a `$__mem` scratch
    /// pointer; plain calls and builtins do not. Used identically by
    /// `countMems` (to size the scratch pool) and `lowerExpr` (to consume it),
    /// so the count and usage stay in lock-step.
    const CallKind = enum { builtin, record_ctor, enum_ctor, plain };

    fn callKind(self: *Emitter, cc: anytype) CallKind {
        if (cc.is_builtin) return .builtin;
        if (self.records.contains(cc.callee)) return .record_ctor;
        if (receiverName(cc)) |rcv| {
            if (self.enums.contains(rcv)) return .enum_ctor;
        } else if (cc.callee.len > 0 and std.ascii.isUpper(cc.callee[0])) {
            // `Variant(...)` with no receiver: an enum payload constructor when
            // the (capitalised) name uniquely names a payload-bearing variant.
            if (self.findVariant(cc.callee)) |fv| {
                if (fv.variant.fields.len > 0) return .enum_ctor;
            }
        }
        return .plain;
    }

    /// The receiver of a qualified call, when it is a plain identifier
    /// (`Color.Rgb(…)` → `"Color"`). The call `receiver` is an expression
    /// pointer, so anything more complex yields null.
    fn receiverName(cc: anytype) ?[]const u8 {
        const recv = cc.receiver orelse return null;
        return switch (recv.*) {
            .identifier => |rid| switch (rid.kind) {
                .ident => |n| n,
                else => null,
            },
            else => null,
        };
    }

    const FoundVariant = struct { variants: []const ast.EnumVariant, tag: u32, variant: ast.EnumVariant };

    /// Search every enum for a variant named `name`. First match wins.
    fn findVariant(self: *Emitter, name: []const u8) ?FoundVariant {
        var it = self.enums.iterator();
        while (it.next()) |entry| {
            for (entry.value_ptr.*, 0..) |v, i| {
                if (std.mem.eql(u8, v.name, name))
                    return .{ .variants = entry.value_ptr.*, .tag = @intCast(i), .variant = v };
            }
        }
        return null;
    }

    /// Count the `$__mem` scratch pointers a function body needs: one per
    /// aggregate construction (tuple/array/record/enum-payload) and one per
    /// destructuring binding.
    fn countMems(self: *Emitter, body: []const ast.Stmt) u32 {
        var n: u32 = 0;
        for (body) |stmt| {
            switch (stmt.expr) {
                .binding => |b| switch (b.kind) {
                    .localBind => |lb| n += self.countMemsExpr(lb.value.*),
                    .assign => |a| n += self.countMemsExpr(a.value.*),
                    .localBindDestruct => |lb| n += 1 + self.countMemsExpr(lb.value.*),
                },
                else => n += self.countMemsExpr(stmt.expr),
            }
        }
        return n;
    }

    fn countMemsExpr(self: *Emitter, e: ast.Expr) u32 {
        return switch (e) {
            .identifier => |id| switch (id.kind) {
                .identAccess => |ia| self.countMemsExpr(ia.receiver.*),
                else => 0,
            },
            .binaryOp => |bin| self.countMemsExpr(bin.lhs.*) + self.countMemsExpr(bin.rhs.*),
            .unaryOp => |un| self.countMemsExpr(un.expr.*),
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    var n: u32 = switch (self.callKind(cc)) {
                        .record_ctor, .enum_ctor => 1,
                        else => 0,
                    };
                    for (cc.args) |arg| n += self.countMemsExpr(arg.value.*);
                    for (cc.trailing) |t| n += self.countMems(t.body);
                    break :blk n;
                },
                .pipeline => |pl| self.countMemsExpr(pl.lhs.*) + self.countMemsExpr(pl.rhs.*),
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| blk: {
                    var n = self.countMemsExpr(i.cond.*) + self.countMems(i.then_);
                    if (i.else_) |els| n += self.countMems(els);
                    break :blk n;
                },
                .tryCatch => |tc| self.countMemsExpr(tc.expr.*) + self.countMemsExpr(tc.handler.*),
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| self.countMemsExpr(inner.*),
                .case => |c| blk: {
                    var n: u32 = 0;
                    for (c.subjects) |s| n += self.countMemsExpr(s);
                    for (c.arms) |arm| n += self.countMemsExpr(arm.body);
                    break :blk n;
                },
                .tupleLit => |tl| blk: {
                    var n: u32 = 1;
                    for (tl.elems) |el| n += self.countMemsExpr(el);
                    break :blk n;
                },
                .arrayLit => |al| blk: {
                    var n: u32 = 1;
                    for (al.elems) |el| n += self.countMemsExpr(el);
                    break :blk n;
                },
                .range => |r| blk: {
                    var n = self.countMemsExpr(r.start.*);
                    if (r.end) |end| n += self.countMemsExpr(end.*);
                    break :blk n;
                },
                .recordLit => |rl| blk: {
                    var n: u32 = 0;
                    for (rl.fields) |f| n += self.countMemsExpr(f.value.*);
                    break :blk n;
                },
            },
            .jump => |j| switch (j.kind) {
                .@"return", .throw_, .@"break" => |v| if (v) |i| self.countMemsExpr(i.*) else 0,
                .try_ => |v| if (v) |i| self.countMemsExpr(i.*) else 0,
                .yield => |y| if (y.value) |i| self.countMemsExpr(i.*) else 0,
                .await_ => |a| self.countMemsExpr(a.*),
                else => 0,
            },
            .loop => |lp| self.countMemsExpr(lp.iter.*) + self.countMems(lp.body),
            else => 0,
        };
    }

    fn emitLocalDecls(self: *Emitter, body: []const ast.Stmt) anyerror!void {
        for (body) |stmt| {
            switch (stmt.expr) {
                .binding => |b| switch (b.kind) {
                    .localBind => |lb| {
                        const t = self.inferExprType(lb.value.*);
                        try self.locals.put(lb.name, t);
                        try self.fmt("    (local ${s} {s})\n", .{ lb.name, t });
                    },
                    .localBindDestruct => |lb| switch (lb.pattern) {
                        .names => |n| {
                            for (n.fields) |fld| {
                                try self.locals.put(fld.bind_name, "i32");
                                try self.fmt("    (local ${s} i32)\n", .{fld.bind_name});
                            }
                        },
                        .tuple_ => |bindings| {
                            for (bindings) |name| {
                                try self.locals.put(name, "i32");
                                try self.fmt("    (local ${s} i32)\n", .{name});
                            }
                        },
                        else => {},
                    },
                    else => {},
                },
                .branch => |br| switch (br.kind) {
                    .if_ => |i| {
                        try self.emitLocalDecls(i.then_);
                        if (i.else_) |els| try self.emitLocalDecls(els);
                    },
                    else => {},
                },
                else => {},
            }
        }
    }

    fn inferExprType(self: *Emitter, e: ast.Expr) []const u8 {
        _ = self;
        return exprNumType(e);
    }

    fn emitGlobalVal(self: *Emitter, v: ast.ValDecl) !void {
        const t = watTypeOpt(v.typeAnnotation);
        switch (v.value.*) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| {
                    if (v.isPub) {
                        try self.fmt("  (global ${s} (export \"{s}\") {s} ({s}.const {s}))\n", .{ v.name, v.name, t, t, n });
                    } else {
                        try self.fmt("  (global ${s} {s} ({s}.const {s}))\n", .{ v.name, t, t, n });
                    }
                    return;
                },
                .stringLit => |s| {
                    const seg = try self.internString(s);
                    try self.fmt("  (global ${s} (mut i32) (i32.const {d}))\n", .{ v.name, seg.offset });
                    return;
                },
                else => {},
            },
            else => {},
        }
        try self.fmt("  (global ${s} (mut i32) (i32.const 0))\n", .{v.name});
    }

    fn emitEntrypointWrapper(self: *Emitter, main_returns_value: bool) !void {
        try self.w("  (func $_botopink_main (export \"_botopink_main\") (export \"_start\")\n");
        try self.w("    (call $main)\n");
        // The wrapper itself returns nothing, so a value-returning `main` would
        // leave its result on the stack — invalid wasm. Discard it.
        if (main_returns_value) try self.w("    drop\n");
        try self.w("  )\n");
    }

    // ── body ─────────────────────────────────────────────────────────────────

    fn emitBody(self: *Emitter, body: []const ast.Stmt, result_type: []const u8) anyerror!void {
        _ = result_type;
        for (body, 0..) |stmt, idx| {
            const is_last = idx == body.len - 1;
            try self.emitStmt(stmt, is_last);
        }
    }

    fn emitStmt(self: *Emitter, stmt: ast.Stmt, is_last: bool) anyerror!void {
        switch (stmt.expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| try self.lowerExpr(val.*);
                    try self.w("    return\n");
                },
                .throw_ => |val| {
                    if (val) |v| try self.lowerExpr(v.*);
                    try self.w("    unreachable\n");
                },
                .try_ => |val| {
                    if (val) |v| try self.lowerTryPropagate(v.*);
                },
                .await_ => |av| try self.lowerExpr(av.*),
                .@"break" => |val| {
                    if (val) |v| try self.lowerExpr(v.*);
                },
                .yield => |y| {
                    if (y.value) |v| try self.lowerExpr(v.*);
                },
                .@"continue" => {},
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    try self.lowerExpr(lb.value.*);
                    try self.fmt("    local.set ${s}\n", .{lb.name});
                },
                .assign => |a| switch (a.target) {
                    .name => |name| switch (a.op) {
                        .assign => {
                            try self.lowerExpr(a.value.*);
                            if (self.locals.contains(name))
                                try self.fmt("    local.set ${s}\n", .{name})
                            else
                                try self.fmt("    global.set ${s}\n", .{name});
                        },
                        .plusAssign => {
                            if (self.locals.contains(name))
                                try self.fmt("    local.get ${s}\n", .{name})
                            else
                                try self.fmt("    global.get ${s}\n", .{name});
                            try self.lowerExpr(a.value.*);
                            const t = self.locals.get(name) orelse "i32";
                            try self.fmt("    {s}.add\n", .{t});
                            if (self.locals.contains(name))
                                try self.fmt("    local.set ${s}\n", .{name})
                            else
                                try self.fmt("    global.set ${s}\n", .{name});
                        },
                    },
                    .fieldAccess => try self.w("    ;; field assign (needs linear memory)\n"),
                },
                .localBindDestruct => |lb| {
                    // The value is a pointer to a contiguous run of 4-byte slots
                    // (tuple or record). Load each slot at its offset, in the
                    // order the names appear in the pattern.
                    const k = self.nextMem();
                    try self.lowerExpr(lb.value.*);
                    try self.fmt("    local.set $__mem{d}\n", .{k});
                    switch (lb.pattern) {
                        .names => |n| {
                            for (n.fields, 0..) |fld, i| {
                                try self.fmt("    local.get $__mem{d}\n", .{k});
                                try self.emitLoadOffset(@intCast(i * 4));
                                try self.fmt("    local.set ${s}\n", .{fld.bind_name});
                            }
                        },
                        .tuple_ => |bindings| {
                            for (bindings, 0..) |name, i| {
                                try self.fmt("    local.get $__mem{d}\n", .{k});
                                try self.emitLoadOffset(@intCast(i * 4));
                                try self.fmt("    local.set ${s}\n", .{name});
                            }
                        },
                        else => try self.w("    ;; unsupported destructure pattern\n"),
                    }
                },
            },
            else => {
                if (is_last) {
                    try self.lowerExpr(stmt.expr);
                } else {
                    try self.lowerExpr(stmt.expr);
                    try self.w("    drop\n");
                }
            },
        }
    }

    // ── expressions ──────────────────────────────────────────────────────────

    fn lowerExpr(self: *Emitter, e: ast.Expr) anyerror!void {
        switch (e) {
            // `use` is a transparent prefix: lower the wrapped hook call. The
            // enclosing `val` stores the result into its local slot.
            .useHook => |uh| try self.lowerExpr(uh.kind.inner.*),
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| {
                    const t = numLitType(n);
                    try self.fmt("    {s}.const {s}\n", .{ t, n });
                },
                .null_ => try self.w("    i32.const 0\n"),
                .stringLit => |s| {
                    const seg = try self.internString(s);
                    try self.fmt("    i32.const {d}\n", .{seg.offset});
                },
                // Desugared to a `+` chain by the transform pass; never reaches codegen.
                .stringTemplate => unreachable,
                .comment => {},
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    // `true`/`false` are bound as identifiers (bool builtins),
                    // not literals. wasm has no boolean type — they lower to
                    // the same `i32` 0/1 a comparison yields. Without this they
                    // would emit `global.get $true`, referencing a global that
                    // is never defined.
                    if (std.mem.eql(u8, n, "true")) {
                        try self.w("    i32.const 1\n");
                    } else if (std.mem.eql(u8, n, "false")) {
                        try self.w("    i32.const 0\n");
                    } else if (self.locals.contains(n)) {
                        try self.fmt("    local.get ${s}\n", .{n});
                    } else {
                        try self.fmt("    global.get ${s}\n", .{n});
                    }
                },
                .dotIdent => |name| {
                    // `.Variant` — type inferred from context. Emit the variant
                    // tag if the name uniquely identifies a unit variant.
                    if (self.findVariant(name)) |fv| {
                        try self.fmt("    i32.const {d} ;; .{s}\n", .{ fv.tag, name });
                    } else {
                        try self.fmt("    i32.const 0 ;; .{s}\n", .{name});
                    }
                },
                .identAccess => |ia| try self.lowerIdentAccess(ia),
            },
            .binaryOp => |bin| try self.lowerBinOp(bin.op, bin.lhs.*, bin.rhs.*),
            .unaryOp => |un| switch (un.op) {
                .neg => try self.lowerNeg(un.expr.*),
                .not => {
                    try self.lowerExpr(un.expr.*);
                    try self.w("    i32.eqz\n");
                },
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    // Static extension dispatch (F6) — resolve to the mangled
                    // linear-memory function `$<target>_<method>` before the
                    // ordinary call-kind handling.
                    if (try self.lowerDispatchCall(cc, c.loc)) return;
                    // String slice method (`s.slice(a, b)`) — handled before the
                    // ctor/plain classification (codegen is untyped).
                    if (isStrSlice(cc)) {
                        try self.lowerStrSlice(cc);
                        return;
                    }
                    switch (self.callKind(cc)) {
                        .builtin => try self.lowerBuiltin(cc),
                        .record_ctor => try self.lowerRecordCtor(cc, self.records.get(cc.callee).?),
                        .enum_ctor => {
                            if (receiverName(cc)) |rcv| {
                                const variants = self.enums.get(rcv).?;
                                for (variants, 0..) |v, i| {
                                    if (std.mem.eql(u8, v.name, cc.callee)) {
                                        try self.lowerEnumCtor(cc, @intCast(i), v);
                                        return;
                                    }
                                }
                                try self.w("    i32.const 0 ;; unknown variant\n");
                            } else if (self.findVariant(cc.callee)) |fv| {
                                try self.lowerEnumCtor(cc, fv.tag, fv.variant);
                            }
                        },
                        .plain => {
                            for (cc.args) |arg| try self.lowerExpr(arg.value.*);
                            try self.fmt("    call ${s}\n", .{cc.callee});
                        },
                    }
                },
                .pipeline => |pl| {
                    try self.lowerExpr(pl.lhs.*);
                    switch (pl.rhs.*) {
                        .identifier => |pid| switch (pid.kind) {
                            .ident => |name| try self.fmt("    call ${s}\n", .{name}),
                            else => try self.w("    ;; unsupported pipeline rhs\n"),
                        },
                        else => {
                            try self.w("    drop\n");
                            try self.lowerExpr(pl.rhs.*);
                        },
                    }
                },
            },
            .branch => |b| switch (b.kind) {
                .if_ => |i| try self.lowerIfExpr(i),
                .tryCatch => |tc| try self.lowerTryCatch(tc),
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| try self.lowerExpr(inner.*),
                .case => |c| try self.lowerCase(c),
                .tupleLit => |tl| try self.lowerTupleLit(tl),
                .arrayLit => |al| try self.lowerArrayLit(al),
                // Anonymous record literals are a deferred WAT gap (named
                // records lower via linear memory; same treatment applies).
                .recordLit => try self.w("    i32.const 0 ;; unsupported: record literal\n"),
                .range => try self.w("    i32.const 0 ;; range\n"),
            },
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |val| try self.lowerExpr(val.*);
                    try self.w("    return\n");
                },
                .throw_ => |val| {
                    if (val) |v| try self.lowerExpr(v.*);
                    try self.w("    unreachable\n");
                },
                .try_ => |val| {
                    if (val) |v| try self.lowerTryPropagate(v.*);
                },
                .await_ => |av| try self.lowerExpr(av.*),
                .@"break" => |val| {
                    if (val) |v| try self.lowerExpr(v.*);
                },
                .yield => |y| {
                    if (y.value) |v| try self.lowerExpr(v.*);
                },
                else => try self.fmt("    ;; unsupported jump: {s}\n", .{@tagName(j.kind)}),
            },
            .comptime_ => try self.w("    i32.const 0\n"),
            .function => try self.w("    i32.const 0 ;; lambda\n"),
            .loop => |lp| try self.lowerLoop(lp),
            else => try self.fmt("    ;; unsupported expr: {s}\n", .{@tagName(e)}),
        }
    }

    // A `@Result` lives in linear memory as a pointer: the tag is the `i32` at
    // `[ptr]` (0 = Ok, non-zero = Error) and the payload is the `i32` at `[ptr+4]`.
    // `try`/`catch` branch on that tag with `if`/`else` — never host exceptions.

    /// `try expr catch handler` → load the tag; Ok yields `[ptr+4]`, Error runs
    /// the handler. Leaves the resulting value on the stack.
    fn lowerTryCatch(self: *Emitter, tc: anytype) anyerror!void {
        const n = self.try_seq;
        self.try_seq += 1;
        try self.lowerExpr(tc.expr.*);
        try self.fmt("    local.set $_try{d}\n", .{n});
        try self.fmt("    local.get $_try{d}\n", .{n});
        try self.w("    i32.load ;; Result tag (0 = Ok, non-zero = Error)\n");
        try self.fmt("    (if (result {s})\n", .{self.cur_result});
        try self.w("      (then\n");
        try self.lowerExpr(tc.handler.*);
        try self.w("      )\n");
        try self.w("      (else\n");
        try self.fmt("    local.get $_try{d}\n", .{n});
        try self.w("    i32.load offset=4 ;; Ok payload\n");
        try self.w("      )\n");
        try self.w("    )\n");
    }

    /// `try expr` (no catch) → unwrap the Ok payload, or `return` the Result
    /// pointer unchanged to propagate the Error variant up. Leaves the unwrapped
    /// Ok payload on the stack.
    fn lowerTryPropagate(self: *Emitter, inner: ast.Expr) anyerror!void {
        const n = self.try_seq;
        self.try_seq += 1;
        try self.lowerExpr(inner);
        try self.fmt("    local.set $_try{d}\n", .{n});
        try self.fmt("    local.get $_try{d}\n", .{n});
        try self.w("    i32.load ;; Result tag (0 = Ok, non-zero = Error)\n");
        try self.w("    (if\n");
        try self.w("      (then\n");
        try self.fmt("    local.get $_try{d}\n", .{n});
        try self.w("    return ;; propagate Error\n");
        try self.w("      )\n");
        try self.w("    )\n");
        try self.fmt("    local.get $_try{d}\n", .{n});
        try self.w("    i32.load offset=4 ;; Ok payload\n");
    }

    fn lowerBuiltin(self: *Emitter, cc: anytype) anyerror!void {
        if (std.mem.eql(u8, cc.callee, "todo") or std.mem.eql(u8, cc.callee, "panic")) {
            try self.w("    unreachable\n");
            return;
        }
        if (std.mem.eql(u8, cc.callee, "block")) {
            if (cc.trailing.len > 0) {
                const body = cc.trailing[0];
                for (body.body, 0..) |stmt, idx| {
                    const is_last = idx == body.body.len - 1;
                    try self.emitStmt(stmt, is_last);
                }
            }
            return;
        }
        if (std.mem.eql(u8, cc.callee, "print")) {
            self.uses_print = true;
            if (cc.args.len > 0) {
                const arg = cc.args[0].value.*;
                switch (arg) {
                    .literal => |lit| switch (lit.kind) {
                        .stringLit => |s| {
                            // Strings are length-prefixed; the printable bytes
                            // begin at `offset + 4` (past the i32 length word).
                            const nl = try self.internString(s);
                            try self.emitFdWriteString(nl.offset + 4, nl.len);
                            const newline = try self.internString("\n");
                            try self.emitFdWriteString(newline.offset + 4, newline.len);
                            return;
                        },
                        else => {},
                    },
                    else => {},
                }
                try self.lowerExpr(cc.args[0].value.*);
                try self.w("    call $__print_i32\n");
            }
            return;
        }
        if (std.mem.startsWith(u8, cc.callee, "__bp_")) {
            try self.lowerResultOptionOp(cc.callee, cc.args);
            return;
        }
        try self.w("    ;; builtin stub\n");
    }

    /// Reserve and declare the next `$_res{n}` scratch pointer local. Declared
    /// inline (like the `$__case` locals) since the count isn't known up front.
    fn declRes(self: *Emitter) !u32 {
        const k = self.res_seq;
        self.res_seq += 1;
        try self.fmt("    (local $_res{d} i32)\n", .{k});
        return k;
    }

    /// True when `arg` is a literal lambda (`{ x -> ... }`), the only fn form a
    /// higher-order Result/Option op can inline on WASM (there is no first-class
    /// closure value in this backend — `.function` otherwise lowers to `0`).
    fn lambdaArg(arg: ?*ast.Expr) ?*ast.Expr {
        const a = arg orelse return null;
        if (a.* != .function) return null;
        if (a.function.kind.syntax != .lambda) return null;
        return a;
    }

    /// Bind a single-param lambda's parameter to a value held in `src` (a local
    /// name), declaring the parameter local on first use. A zero-param lambda
    /// ignores the value.
    fn bindLambdaParam(self: *Emitter, lam: anytype, src: []const u8) !void {
        if (lam.params.len == 0) return;
        const p = lam.params[0];
        if (!self.locals.contains(p)) {
            try self.locals.put(p, "i32");
            try self.fmt("    (local ${s} i32)\n", .{p});
        }
        try self.fmt("    local.get ${s}\n", .{src});
        try self.fmt("    local.set ${s}\n", .{p});
    }

    /// Inline a lambda body, leaving its tail value on the stack. An explicit
    /// `return` tail is unwrapped to its value (a bare `return` opcode would
    /// exit the *enclosing* function, not the inlined closure).
    fn inlineLambdaBody(self: *Emitter, body: []const ast.Stmt) anyerror!void {
        if (body.len == 0) {
            try self.w("    i32.const 0\n");
            return;
        }
        for (body[0 .. body.len - 1]) |s| try self.emitStmt(s, false);
        const last = body[body.len - 1];
        switch (last.expr) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |v| try self.lowerExpr(v.*) else try self.w("    i32.const 0\n");
                    return;
                },
                else => {},
            },
            else => {},
        }
        try self.emitStmt(last, true);
    }

    /// Lower a `__bp_<domain>_<op>(receiver, arg?)` Result/Option method op.
    /// A `@Result` is a pointer to two `i32` slots — `[ptr]` is the tag (0 = Ok,
    /// non-zero = Error), `[ptr+4]` the payload — matching `try`/`catch`. A
    /// `@Option` is the bare value, with `0` standing for absence. `map`/`flatMap`
    /// inline the closure body (there are no first-class funs here); the other
    /// ops are pure tag tests / payload loads.
    fn lowerResultOptionOp(self: *Emitter, callee: []const u8, args: anytype) anyerror!void {
        const recv = args[0].value;
        const arg1: ?*ast.Expr = if (args.len > 1) args[1].value else null;

        if (std.mem.eql(u8, callee, "__bp_ok") or std.mem.eql(u8, callee, "__bp_error")) {
            // Result constructor (`return v` / `throw e` in a `-> @Result<…>`
            // fn): allocate a fresh `{ tag, payload }` pair (tag 0 = Ok, 1 = Error).
            const tag: u8 = if (std.mem.eql(u8, callee, "__bp_ok")) 0 else 1;
            const b = try self.declRes();
            try self.w("    global.get $__heap_ptr\n");
            try self.fmt("    local.set $_res{d}\n", .{b});
            try self.w("    global.get $__heap_ptr\n");
            try self.w("    i32.const 8\n");
            try self.w("    i32.add\n");
            try self.w("    global.set $__heap_ptr\n");
            try self.fmt("    local.get $_res{d}\n", .{b});
            try self.fmt("    i32.const {d}\n", .{tag});
            try self.fmt("    i32.store ;; Result tag ({s})\n", .{if (tag == 0) "Ok" else "Error"});
            try self.fmt("    local.get $_res{d}\n", .{b});
            try self.lowerExpr(recv.*);
            try self.w("    i32.store offset=4 ;; payload\n");
            try self.fmt("    local.get $_res{d}\n", .{b});
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_map") or std.mem.eql(u8, callee, "__bp_result_flatMap")) {
            const is_map = std.mem.eql(u8, callee, "__bp_result_map");
            const le = lambdaArg(arg1) orelse {
                try self.w("    ;; map/flatMap needs a literal closure on WASM — receiver passed through\n");
                try self.lowerExpr(recv.*);
                return;
            };
            const lam = le.function.kind;
            const a = try self.declRes();
            var pbuf: [24]u8 = undefined;
            const aname = try std.fmt.bufPrint(&pbuf, "_res{d}", .{a});
            try self.lowerExpr(recv.*);
            try self.fmt("    local.set $_res{d}\n", .{a});
            try self.fmt("    local.get $_res{d}\n", .{a});
            try self.w("    i32.load ;; Result tag (0 = Ok, non-zero = Error)\n");
            try self.w("    (if (result i32)\n");
            try self.w("      (then\n");
            try self.fmt("    local.get $_res{d} ;; Error — propagate unchanged\n", .{a});
            try self.w("      )\n");
            try self.w("      (else\n");
            // Ok: bind the closure param to the payload, then apply it.
            try self.fmt("    local.get $_res{d}\n", .{a});
            try self.w("    i32.load offset=4 ;; Ok payload\n");
            try self.fmt("    local.set $_res{d}\n", .{a});
            try self.bindLambdaParam(lam, aname);
            if (is_map) {
                // Rewrap the mapped value as a fresh `{ tag: 0, payload }` Result.
                const b = try self.declRes();
                try self.w("    global.get $__heap_ptr\n");
                try self.fmt("    local.set $_res{d}\n", .{b});
                try self.w("    global.get $__heap_ptr\n");
                try self.w("    i32.const 8\n");
                try self.w("    i32.add\n");
                try self.w("    global.set $__heap_ptr\n");
                try self.fmt("    local.get $_res{d}\n", .{b});
                try self.w("    i32.const 0\n");
                try self.w("    i32.store ;; Ok tag\n");
                try self.fmt("    local.get $_res{d}\n", .{b});
                try self.inlineLambdaBody(lam.body);
                try self.w("    i32.store offset=4 ;; mapped payload\n");
                try self.fmt("    local.get $_res{d}\n", .{b});
            } else {
                // flatMap: the closure already yields a `@Result` pointer.
                try self.inlineLambdaBody(lam.body);
            }
            try self.w("      )\n");
            try self.w("    )\n");
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_unwrapOr")) {
            const a = try self.declRes();
            try self.lowerExpr(recv.*);
            try self.fmt("    local.set $_res{d}\n", .{a});
            try self.fmt("    local.get $_res{d}\n", .{a});
            try self.w("    i32.load ;; Result tag (0 = Ok, non-zero = Error)\n");
            try self.w("    (if (result i32)\n");
            try self.w("      (then\n");
            if (arg1) |d| try self.lowerExpr(d.*) else try self.w("    i32.const 0\n");
            try self.w("      )\n");
            try self.w("      (else\n");
            try self.fmt("    local.get $_res{d}\n", .{a});
            try self.w("    i32.load offset=4 ;; Ok payload\n");
            try self.w("      )\n");
            try self.w("    )\n");
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_isOk")) {
            try self.lowerExpr(recv.*);
            try self.w("    i32.load ;; Result tag\n");
            try self.w("    i32.eqz ;; isOk = (tag == 0)\n");
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_result_isError")) {
            try self.lowerExpr(recv.*);
            try self.w("    i32.load ;; Result tag\n");
            try self.w("    i32.const 0\n");
            try self.w("    i32.ne ;; isError = (tag != 0)\n");
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_option_map") or std.mem.eql(u8, callee, "__bp_option_flatMap")) {
            const le = lambdaArg(arg1) orelse {
                try self.w("    ;; map/flatMap needs a literal closure on WASM — receiver passed through\n");
                try self.lowerExpr(recv.*);
                return;
            };
            const lam = le.function.kind;
            const a = try self.declRes();
            var pbuf: [24]u8 = undefined;
            const aname = try std.fmt.bufPrint(&pbuf, "_res{d}", .{a});
            try self.lowerExpr(recv.*);
            try self.fmt("    local.set $_res{d}\n", .{a});
            try self.fmt("    local.get $_res{d} ;; Option (0 = None, else Some payload)\n", .{a});
            try self.w("    (if (result i32)\n");
            try self.w("      (then\n");
            // Some: apply the closure to the present value.
            try self.bindLambdaParam(lam, aname);
            try self.inlineLambdaBody(lam.body);
            try self.w("      )\n");
            try self.w("      (else\n");
            try self.w("    i32.const 0 ;; None — propagate absence\n");
            try self.w("      )\n");
            try self.w("    )\n");
            return;
        }

        if (std.mem.eql(u8, callee, "__bp_option_unwrapOr")) {
            const a = try self.declRes();
            try self.lowerExpr(recv.*);
            try self.fmt("    local.set $_res{d}\n", .{a});
            try self.fmt("    local.get $_res{d} ;; Option (0 = None, else Some payload)\n", .{a});
            try self.w("    (if (result i32)\n");
            try self.w("      (then\n");
            try self.fmt("    local.get $_res{d} ;; Some — present value\n", .{a});
            try self.w("      )\n");
            try self.w("      (else\n");
            if (arg1) |d| try self.lowerExpr(d.*) else try self.w("    i32.const 0\n");
            try self.w("      )\n");
            try self.w("    )\n");
            return;
        }

        try self.fmt("    ;; unsupported Result/Option op: {s}\n", .{callee});
    }

    fn emitFdWriteString(self: *Emitter, offset: u32, len: u32) !void {
        try self.w("    i32.const 0\n");
        try self.fmt("    i32.const {d}\n", .{offset});
        try self.w("    i32.store\n");
        try self.w("    i32.const 4\n");
        try self.fmt("    i32.const {d}\n", .{len});
        try self.w("    i32.store\n");
        try self.w("    i32.const 1\n");
        try self.w("    i32.const 0\n");
        try self.w("    i32.const 1\n");
        try self.w("    i32.const 8\n");
        try self.w("    call $fd_write\n");
        try self.w("    drop\n");
    }

    fn lowerCase(self: *Emitter, c: anytype) anyerror!void {
        if (c.subjects.len == 0 or c.arms.len == 0) {
            try self.w("    i32.const 0\n");
            return;
        }
        try self.lowerExpr(c.subjects[0]);
        const subj_local = try std.fmt.allocPrint(self.alloc, "__case_{d}", .{self.case_depth});
        defer self.alloc.free(subj_local);
        self.case_depth += 1;
        try self.locals.put(subj_local, "i32");
        try self.fmt("    (local ${s} i32)\n", .{subj_local});
        try self.fmt("    local.set ${s}\n", .{subj_local});

        try self.emitCaseArms(c.arms, subj_local, 0);
    }

    fn emitCaseArms(self: *Emitter, arms: anytype, subj: []const u8, idx: usize) anyerror!void {
        if (idx >= arms.len) {
            try self.w("    i32.const 0\n");
            return;
        }
        const arm = arms[idx];
        switch (arm.pattern) {
            .wildcard, .ident => {
                try self.lowerExpr(arm.body);
            },
            .numberLit => |n| {
                try self.fmt("    local.get ${s}\n", .{subj});
                const t = numLitType(n);
                try self.fmt("    {s}.const {s}\n", .{ t, n });
                try self.fmt("    {s}.eq\n", .{t});
                try self.fmt("    (if (result {s})\n", .{self.cur_result});
                try self.w("      (then\n");
                try self.lowerExpr(arm.body);
                try self.w("      )\n");
                try self.w("      (else\n");
                try self.emitCaseArms(arms, subj, idx + 1);
                try self.w("      )\n");
                try self.w("    )\n");
            },
            .stringLit => |s| {
                _ = s;
                try self.fmt("    local.get ${s}\n", .{subj});
                try self.w("    drop\n");
                try self.lowerExpr(arm.body);
            },
            .@"or" => |pats| {
                try self.w("    i32.const 0\n");
                for (pats) |p| {
                    switch (p) {
                        .numberLit => |n| {
                            try self.fmt("    local.get ${s}\n", .{subj});
                            const t = numLitType(n);
                            try self.fmt("    {s}.const {s}\n", .{ t, n });
                            try self.fmt("    {s}.eq\n", .{t});
                            try self.w("    i32.or\n");
                        },
                        else => {},
                    }
                }
                try self.fmt("    (if (result {s})\n", .{self.cur_result});
                try self.w("      (then\n");
                try self.lowerExpr(arm.body);
                try self.w("      )\n");
                try self.w("      (else\n");
                try self.emitCaseArms(arms, subj, idx + 1);
                try self.w("      )\n");
                try self.w("    )\n");
            },
            else => {
                try self.lowerExpr(arm.body);
            },
        }
    }

    // ── aggregates in linear memory ───────────────────────────────────────────
    //
    // Tuples, arrays, records and enum payloads are laid out as a contiguous run
    // of 4-byte slots in the bump-allocated heap. Construction leaves a pointer
    // to the first slot on the stack; element/field access loads from a fixed
    // offset. `$__mem{n}` scratch locals hold the base pointer while the slots
    // are filled (WAT has no `dup`, so the base must be reloaded per slot).

    /// Reserve the next `$__mem` scratch index without emitting anything.
    fn nextMem(self: *Emitter) u32 {
        const k = self.mem_seq;
        self.mem_seq += 1;
        return k;
    }

    /// Bump the heap by `nbytes`, stash the base pointer in a fresh `$__mem{k}`
    /// scratch local, and return `k`.
    fn allocSlots(self: *Emitter, nbytes: u32) !u32 {
        const k = self.nextMem();
        try self.w("    global.get $__heap_ptr\n");
        try self.fmt("    local.set $__mem{d}\n", .{k});
        if (nbytes > 0) {
            try self.w("    global.get $__heap_ptr\n");
            try self.fmt("    i32.const {d}\n", .{nbytes});
            try self.w("    i32.add\n");
            try self.w("    global.set $__heap_ptr\n");
        }
        return k;
    }

    fn storeSlotExpr(self: *Emitter, k: u32, offset: u32, value: ast.Expr) !void {
        try self.fmt("    local.get $__mem{d}\n", .{k});
        try self.lowerExpr(value);
        if (offset == 0)
            try self.w("    i32.store\n")
        else
            try self.fmt("    i32.store offset={d}\n", .{offset});
    }

    fn storeSlotConst(self: *Emitter, k: u32, offset: u32, value: i64) !void {
        try self.fmt("    local.get $__mem{d}\n", .{k});
        try self.fmt("    i32.const {d}\n", .{value});
        if (offset == 0)
            try self.w("    i32.store\n")
        else
            try self.fmt("    i32.store offset={d}\n", .{offset});
    }

    fn loadBase(self: *Emitter, k: u32) !void {
        try self.fmt("    local.get $__mem{d}\n", .{k});
    }

    /// Emit `i32.load` (offset 0) or `i32.load offset=N`. Expects the base
    /// pointer on the stack.
    fn emitLoadOffset(self: *Emitter, offset: u32) !void {
        if (offset == 0)
            try self.w("    i32.load\n")
        else
            try self.fmt("    i32.load offset={d}\n", .{offset});
    }

    fn lowerTupleLit(self: *Emitter, tl: anytype) anyerror!void {
        const k = try self.allocSlots(@intCast(tl.elems.len * 4));
        for (tl.elems, 0..) |el, i| try self.storeSlotExpr(k, @intCast(i * 4), el);
        try self.loadBase(k);
    }

    fn lowerArrayLit(self: *Emitter, al: anytype) anyerror!void {
        if (al.spread != null) try self.w("    ;; note: array spread not lowered\n");
        const k = try self.allocSlots(@intCast(al.elems.len * 4));
        for (al.elems, 0..) |el, i| try self.storeSlotExpr(k, @intCast(i * 4), el);
        try self.loadBase(k);
    }

    /// `Rec(a: 1, b: 2)` → contiguous slots in declaration order. Named args are
    /// matched to fields by label; otherwise positional order is used.
    /// Static extension dispatch (F6). Returns true when `cc` is an activated
    /// or qualified extension call and was lowered to `call $<target>_<method>`.
    fn lowerDispatchCall(self: *Emitter, cc: anytype, loc: ast.Loc) anyerror!bool {
        var nbuf: [256]u8 = undefined;
        // Activated: `recv.m(args)` carries a rewrite entry → push the receiver
        // as the first argument, then the explicit args.
        if (self.rewrites.get(loc)) |sym| {
            const mangled = self.extMangledName(&nbuf, sym, cc.callee) orelse return false;
            if (cc.receiver) |recv| try self.lowerExpr(recv.*);
            for (cc.args) |arg| try self.lowerExpr(arg.value.*);
            try self.fmt("    call ${s}\n", .{mangled});
            return true;
        }
        // Qualified: `Sym.m(obj, args)` where `Sym` names an extension block —
        // the object is already arg 0, so only the args are pushed.
        if (receiverName(cc)) |rn| {
            if (self.ext_by_name.contains(rn)) {
                const mangled = self.extMangledName(&nbuf, rn, cc.callee) orelse return false;
                for (cc.args) |arg| try self.lowerExpr(arg.value.*);
                try self.fmt("    call ${s}\n", .{mangled});
                return true;
            }
        }
        return false;
    }

    fn lowerRecordCtor(self: *Emitter, cc: anytype, fields: []const []const u8) anyerror!void {
        const k = try self.allocSlots(@intCast(fields.len * 4));
        for (fields, 0..) |fname, i| {
            const off: u32 = @intCast(i * 4);
            if (self.argForField(cc.args, fname, i)) |arg| {
                try self.storeSlotExpr(k, off, arg.value.*);
            } else {
                try self.storeSlotConst(k, off, 0);
            }
        }
        try self.loadBase(k);
    }

    /// Pick the call argument that fills field `fname` (declaration index `idx`):
    /// the labelled arg whose label matches, else the positional arg at `idx`.
    fn argForField(self: *Emitter, args: anytype, fname: []const u8, idx: usize) ?@TypeOf(args[0]) {
        _ = self;
        for (args) |arg| {
            if (arg.label) |lbl| {
                if (std.mem.eql(u8, lbl, fname)) return arg;
            }
        }
        // No matching label — fall back to positional (skipping `..spread`).
        if (idx < args.len and args[idx].label == null) return args[idx];
        return null;
    }

    /// `Color.Rgb(r: 1, g: 2, b: 3)` → `[tag, r, g, b]`. The tag (variant index)
    /// lives at offset 0; payload fields follow at 4, 8, ...
    fn lowerEnumCtor(self: *Emitter, cc: anytype, tag: u32, variant: ast.EnumVariant) anyerror!void {
        const nslots = 1 + variant.fields.len;
        const k = try self.allocSlots(@intCast(nslots * 4));
        try self.storeSlotConst(k, 0, tag);
        for (variant.fields, 0..) |vf, i| {
            const off: u32 = @intCast((i + 1) * 4);
            if (self.argForField(cc.args, vf.name, i)) |arg| {
                try self.storeSlotExpr(k, off, arg.value.*);
            } else {
                try self.storeSlotConst(k, off, 0);
            }
        }
        try self.loadBase(k);
    }

    /// `recv.member` — tuple element (`t._0`), qualified enum unit variant
    /// (`Color.Red`), or an as-yet-unsupported record field access.
    fn lowerIdentAccess(self: *Emitter, ia: anytype) anyerror!void {
        // `.len` on a string → load the length prefix. Strings are
        // length-prefixed buffers, so the value points at the i32 length word.
        // Codegen is untyped; `.len` is assumed to mean string length here.
        if (std.mem.eql(u8, ia.member, "len")) {
            try self.lowerExpr(ia.receiver.*);
            try self.w("    i32.load ;; string length\n");
            return;
        }
        // Tuple element access: `_0`, `_1`, ... → load at `index * 4`.
        if (tupleIndex(ia.member)) |idx| {
            try self.lowerExpr(ia.receiver.*);
            try self.emitLoadOffset(idx * 4);
            return;
        }
        // Qualified enum unit variant: `Color.Red` → variant tag.
        switch (ia.receiver.*) {
            .identifier => |rid| switch (rid.kind) {
                .ident => |ename| {
                    if (self.enums.get(ename)) |variants| {
                        for (variants, 0..) |v, i| {
                            if (std.mem.eql(u8, v.name, ia.member)) {
                                try self.fmt("    i32.const {d} ;; {s}.{s}\n", .{ i, ename, ia.member });
                                return;
                            }
                        }
                    }
                },
                else => {},
            },
            else => {},
        }
        // Named record-field access is a pre-existing WAT gap (fields aren't laid
        // out by name in linear memory yet), so optional chaining (`recv?.member`)
        // can't be realized here either — both short-circuit to `0`. Recorded as a
        // genuine backend limit rather than faked; beam/erlang/commonJS guard `?.`.
        if (ia.optional) {
            try self.fmt("    i32.const 0 ;; optional field access .{s} (unsupported on wasm)\n", .{ia.member});
            return;
        }
        try self.fmt("    i32.const 0 ;; field access .{s}\n", .{ia.member});
    }

    /// Returns N for a tuple-accessor member of the form `_N` (e.g. `_0`).
    fn tupleIndex(member: []const u8) ?u32 {
        if (member.len < 2 or member[0] != '_') return null;
        var n: u32 = 0;
        for (member[1..]) |c| {
            if (!std.ascii.isDigit(c)) return null;
            n = n * 10 + (c - '0');
        }
        return n;
    }

    // ── strings in linear memory ──────────────────────────────────────────────
    //
    // Strings are length-prefixed buffers: a value is a pointer to a 4-byte i32
    // length word immediately followed by the raw bytes. Literals are interned in
    // the data section with this layout; `.len` loads the prefix and `.slice`
    // copies a sub-range into a fresh prefixed buffer, so length travels with the
    // string at runtime (it no longer has to be a compile-time constant).
    // Concatenation and comparison of literals lower to helper calls (offsets +
    // compile-time lengths), demonstrating `memory.copy` and a byte-compare loop;
    // the concat result is itself a valid prefixed string, so `.len`/`.slice`
    // compose on it. Concat/compare of non-literal operands is not detected here
    // (codegen is untyped, so `a + b` on string variables lowers as numeric add).

    fn isStrLit(e: ast.Expr) ?[]const u8 {
        return switch (e) {
            .literal => |lit| switch (lit.kind) {
                .stringLit => |s| s,
                else => null,
            },
            else => null,
        };
    }

    fn lowerStrConcat(self: *Emitter, a: []const u8, b: []const u8) anyerror!void {
        self.uses_str_concat = true;
        const sa = try self.internString(a);
        const sb = try self.internString(b);
        try self.fmt("    i32.const {d} ;; \"{s}\" ptr\n", .{ sa.offset, a });
        try self.fmt("    i32.const {d} ;; \"{s}\" len\n", .{ sa.len, a });
        try self.fmt("    i32.const {d} ;; \"{s}\" ptr\n", .{ sb.offset, b });
        try self.fmt("    i32.const {d} ;; \"{s}\" len\n", .{ sb.len, b });
        try self.w("    call $__str_concat\n");
    }

    /// A `recv.slice(...)` method call. Codegen is untyped, so a `slice` with a
    /// receiver (and not a builtin) is treated as a string slice.
    fn isStrSlice(cc: anytype) bool {
        return cc.receiver != null and !cc.is_builtin and std.mem.eql(u8, cc.callee, "slice");
    }

    /// `s.slice(start, end)` → a fresh length-prefixed buffer holding the bytes
    /// `[start, end)` of the receiver. A missing `end` slices to the source's
    /// length. Leaves a pointer to the new string on the stack.
    fn lowerStrSlice(self: *Emitter, cc: anytype) anyerror!void {
        self.uses_str_slice = true;
        try self.lowerExpr(cc.receiver.?.*);
        if (cc.args.len > 0)
            try self.lowerExpr(cc.args[0].value.*)
        else
            try self.w("    i32.const 0\n");
        if (cc.args.len > 1) {
            try self.lowerExpr(cc.args[1].value.*);
        } else {
            // No end argument: slice to the end (load the source length prefix).
            try self.lowerExpr(cc.receiver.?.*);
            try self.w("    i32.load ;; source length\n");
        }
        try self.w("    call $__str_slice\n");
    }

    fn lowerStrEq(self: *Emitter, a: []const u8, b: []const u8, negate: bool) anyerror!void {
        self.uses_str_eq = true;
        const sa = try self.internString(a);
        const sb = try self.internString(b);
        try self.fmt("    i32.const {d}\n", .{sa.offset});
        try self.fmt("    i32.const {d}\n", .{sa.len});
        try self.fmt("    i32.const {d}\n", .{sb.offset});
        try self.fmt("    i32.const {d}\n", .{sb.len});
        try self.w("    call $__str_eq\n");
        if (negate) try self.w("    i32.eqz\n");
    }

    fn lowerLoop(self: *Emitter, lp: anytype) anyerror!void {
        switch (lp.iter.*) {
            .collection => |col| switch (col.kind) {
                .range => |r| {
                    try self.lowerRangeLoop(lp.params, lp.body, r);
                    return;
                },
                else => {},
            },
            else => {},
        }
        try self.w("    i32.const 0 ;; loop over non-range\n");
    }

    fn lowerRangeLoop(self: *Emitter, params: []const []const u8, body: []const ast.Stmt, r: anytype) anyerror!void {
        const param = if (params.len > 0) params[0] else "__i";
        if (!self.locals.contains(param)) {
            try self.locals.put(param, "i32");
            try self.fmt("    (local ${s} i32)\n", .{param});
        }

        try self.lowerExpr(r.start.*);
        try self.fmt("    local.set ${s}\n", .{param});

        try self.w("    (block $__break\n");
        try self.w("      (loop $__continue\n");

        if (r.end) |end| {
            try self.fmt("        local.get ${s}\n", .{param});
            try self.lowerExpr(end.*);
            try self.w("        i32.ge_s\n");
            try self.w("        br_if $__break\n");
        }

        for (body) |stmt| {
            try self.emitStmt(stmt, false);
        }

        try self.fmt("        local.get ${s}\n", .{param});
        try self.w("        i32.const 1\n");
        try self.w("        i32.add\n");
        try self.fmt("        local.set ${s}\n", .{param});
        try self.w("        br $__continue\n");
        try self.w("      )\n");
        try self.w("    )\n");
        try self.w("    i32.const 0\n");
    }

    fn lowerBinOp(self: *Emitter, op: anytype, lhs: ast.Expr, rhs: ast.Expr) !void {
        const Op = @TypeOf(op);
        // String literal operands: concatenation and comparison run through
        // linear-memory helpers rather than the numeric ALU.
        if (isStrLit(lhs)) |a| if (isStrLit(rhs)) |b| switch (op) {
            Op.add => return self.lowerStrConcat(a, b),
            Op.eq => return self.lowerStrEq(a, b, false),
            Op.ne => return self.lowerStrEq(a, b, true),
            else => {},
        };
        try self.lowerExpr(lhs);
        try self.lowerExpr(rhs);
        const t = exprNumType(lhs);
        const opname: ?[]const u8 = switch (op) {
            Op.add => "add",
            Op.sub => "sub",
            Op.mul => "mul",
            Op.div => if (t[0] == 'f') "div" else "div_s",
            Op.mod => if (t[0] == 'f') null else "rem_s",
            Op.lt => if (t[0] == 'f') "lt" else "lt_s",
            Op.gt => if (t[0] == 'f') "gt" else "gt_s",
            Op.lte => if (t[0] == 'f') "le" else "le_s",
            Op.gte => if (t[0] == 'f') "ge" else "ge_s",
            Op.eq => "eq",
            Op.ne => "ne",
            Op.@"and" => "and",
            Op.@"or" => "or",
        };
        if (opname) |on| {
            try self.fmt("    {s}.{s}\n", .{ t, on });
        } else {
            try self.fmt("    ;; unsupported binary op for {s}\n", .{t});
        }
    }

    fn lowerNeg(self: *Emitter, inner: ast.Expr) !void {
        const t = exprNumType(inner);
        if (t[0] == 'f') {
            try self.lowerExpr(inner);
            try self.fmt("    {s}.neg\n", .{t});
        } else {
            try self.fmt("    {s}.const 0\n", .{t});
            try self.lowerExpr(inner);
            try self.fmt("    {s}.sub\n", .{t});
        }
    }

    fn lowerIfExpr(self: *Emitter, i: anytype) !void {
        try self.lowerExpr(i.cond.*);
        try self.fmt("    (if (result {s})\n", .{self.cur_result});
        try self.w("      (then\n");
        try self.emitBranchBody(i.then_);
        try self.w("      )\n");
        try self.w("      (else\n");
        if (i.else_) |els| {
            try self.emitBranchBody(els);
        } else {
            try self.fmt("        {s}.const 0\n", .{self.cur_result});
        }
        try self.w("      )\n");
        try self.w("    )\n");
    }

    fn emitBranchBody(self: *Emitter, body: []const ast.Stmt) anyerror!void {
        if (body.len == 0) {
            try self.fmt("        {s}.const 0\n", .{self.cur_result});
            return;
        }
        for (body, 0..) |stmt, idx| {
            const is_last = idx == body.len - 1;
            try self.emitStmt(stmt, is_last);
        }
    }
};

// ── small helpers ────────────────────────────────────────────────────────────

fn numLitType(n: []const u8) []const u8 {
    for (n) |c| if (c == '.' or c == 'e' or c == 'E') return "f32";
    return "i32";
}

fn exprNumType(e: ast.Expr) []const u8 {
    return switch (e) {
        .literal => |lit| switch (lit.kind) {
            .numberLit => |n| numLitType(n),
            else => "i32",
        },
        .unaryOp => |un| switch (un.op) {
            .neg => exprNumType(un.expr.*),
            else => "i32",
        },
        .binaryOp => |bin| exprNumType(bin.lhs.*),
        .collection => |col| switch (col.kind) {
            .grouped => |inner| exprNumType(inner.*),
            else => "i32",
        },
        else => "i32",
    };
}
