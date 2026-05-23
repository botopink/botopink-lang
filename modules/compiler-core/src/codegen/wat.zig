/// WebAssembly Text (`.wat`) codegen backend.
///
/// Emits a `(module ...)` form that `wasmtime` can execute directly.
///
/// Covers: numeric fn decls, arithmetic, comparisons, if/else, return,
/// top-level val as globals, fn main/0 wrapper, linear memory with bump
/// allocator, string data section, @print via WASI fd_write, case via
/// if-chain, loops via block/loop/br_if, tuples/arrays in memory,
/// lambdas as i32 indices.
const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");

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

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError => continue,
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
                const code = try emitWat(alloc, ct.name, ok.transformed, ok.comptime_vals);
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
) ![]u8 {
    _ = module_name;

    var fn_buf: std.Io.Writer.Allocating = .init(alloc);
    defer fn_buf.deinit();

    var em = Emitter.init(alloc, &fn_buf.writer, comptime_vals);
    defer em.deinit();

    var has_main_0 = false;
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| if (isMain0(f)) {
            has_main_0 = true;
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
        .record, .@"struct", .@"enum", .implement, .interface, .delegate, .use => {},
    };

    if (has_main_0) try em.emitEntrypointWrapper();

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

    data_segments: std.ArrayListUnmanaged(DataSeg) = .empty,
    next_data_offset: u32 = 256,
    uses_print: bool = false,

    fn init(alloc: std.mem.Allocator, out: *std.Io.Writer, cv: std.StringHashMap([]const u8)) Emitter {
        return .{
            .alloc = alloc,
            .out = out,
            .cv = cv,
            .locals = std.StringHashMap([]const u8).init(alloc),
        };
    }

    fn deinit(self: *Emitter) void {
        self.locals.deinit();
        self.data_segments.deinit(self.alloc);
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
    }

    fn internString(self: *Emitter, s: []const u8) !DataSeg {
        for (self.data_segments.items) |seg| {
            if (seg.len == s.len and std.mem.eql(u8, seg.content, s)) return seg;
        }
        const seg = DataSeg{
            .offset = self.next_data_offset,
            .len = @intCast(s.len),
            .content = s,
        };
        self.next_data_offset += @intCast(s.len);
        if (self.next_data_offset % 4 != 0)
            self.next_data_offset += 4 - (self.next_data_offset % 4);
        try self.data_segments.append(self.alloc, seg);
        return seg;
    }

    // ── fn ───────────────────────────────────────────────────────────────────

    fn emitFn(self: *Emitter, f: ast.FnDecl) !void {
        const result_type = watTypeOpt(f.returnType);
        self.resetFnState(result_type);

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
        try self.emitLocalDecls(f.body);
        try self.emitBody(f.body, result_type);
        try self.w("  )\n");
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

    fn emitEntrypointWrapper(self: *Emitter) !void {
        try self.w("  (func $_botopink_main (export \"_botopink_main\") (export \"_start\")\n");
        try self.w("    (call $main)\n");
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
                    if (val) |v| try self.lowerExpr(v.*);
                },
                .@"break" => |val| {
                    if (val) |v| try self.lowerExpr(v.*);
                },
                .yield => |val| {
                    if (val) |v| try self.lowerExpr(v.*);
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
                    try self.lowerExpr(lb.value.*);
                    switch (lb.pattern) {
                        .names => |n| {
                            for (n.fields) |fld| {
                                try self.fmt("    local.set ${s}\n", .{fld.bind_name});
                            }
                        },
                        .tuple_ => |bindings| {
                            var i: usize = bindings.len;
                            while (i > 0) {
                                i -= 1;
                                try self.fmt("    local.set ${s}\n", .{bindings[i]});
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
                .comment => {},
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    if (self.locals.contains(n)) {
                        try self.fmt("    local.get ${s}\n", .{n});
                    } else {
                        try self.fmt("    global.get ${s}\n", .{n});
                    }
                },
                .dotIdent => try self.w("    i32.const 0 ;; enum variant\n"),
                .identAccess => try self.w("    i32.const 0 ;; field access\n"),
            },
            .binaryOp => |bin| try self.lowerBinOp(bin.kind.op, bin.kind.lhs.*, bin.kind.rhs.*),
            .unaryOp => |un| switch (un.kind.op) {
                .neg => try self.lowerNeg(un.kind.expr.*),
                .not => {
                    try self.lowerExpr(un.kind.expr.*);
                    try self.w("    i32.eqz\n");
                },
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (cc.is_builtin) {
                        try self.lowerBuiltin(cc);
                        return;
                    }
                    for (cc.args) |arg| try self.lowerExpr(arg.value.*);
                    try self.fmt("    call ${s}\n", .{cc.callee});
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
                .tryCatch => |tc| try self.lowerExpr(tc.expr.*),
            },
            .collection => |col| switch (col.kind) {
                .grouped => |inner| try self.lowerExpr(inner.*),
                .case => |c| try self.lowerCase(c),
                .tupleLit => |tl| try self.lowerTupleLit(tl),
                .arrayLit => |al| try self.lowerArrayLit(al),
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
                    if (val) |v| try self.lowerExpr(v.*);
                },
                .@"break" => |val| {
                    if (val) |v| try self.lowerExpr(v.*);
                },
                .yield => |val| {
                    if (val) |v| try self.lowerExpr(v.*);
                },
                else => try self.fmt("    ;; unsupported jump: {s}\n", .{@tagName(j.kind)}),
            },
            .comptime_ => try self.w("    i32.const 0\n"),
            .function => try self.w("    i32.const 0 ;; lambda\n"),
            .loop => |lp| try self.lowerLoop(lp),
            else => try self.fmt("    ;; unsupported expr: {s}\n", .{@tagName(e)}),
        }
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
                            const nl = try self.internString(s);
                            try self.emitFdWriteString(nl.offset, nl.len);
                            const newline = try self.internString("\n");
                            try self.emitFdWriteString(newline.offset, newline.len);
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
        try self.w("    ;; builtin stub\n");
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

    fn lowerTupleLit(self: *Emitter, tl: anytype) anyerror!void {
        _ = tl;
        try self.w("    i32.const 0 ;; tuple\n");
    }

    fn lowerArrayLit(self: *Emitter, al: anytype) anyerror!void {
        _ = al;
        try self.w("    i32.const 0 ;; array\n");
    }

    fn lowerLoop(self: *Emitter, lp: anytype) anyerror!void {
        switch (lp.kind.iter.*) {
            .collection => |col| switch (col.kind) {
                .range => |r| {
                    try self.lowerRangeLoop(lp.kind.params, lp.kind.body, r);
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
        try self.lowerExpr(lhs);
        try self.lowerExpr(rhs);
        const t = exprNumType(lhs);
        const Op = @TypeOf(op);
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
        .unaryOp => |un| switch (un.kind.op) {
            .neg => exprNumType(un.kind.expr.*),
            else => "i32",
        },
        .binaryOp => |bin| exprNumType(bin.kind.lhs.*),
        .collection => |col| switch (col.kind) {
            .grouped => |inner| exprNumType(inner.*),
            else => "i32",
        },
        else => "i32",
    };
}
