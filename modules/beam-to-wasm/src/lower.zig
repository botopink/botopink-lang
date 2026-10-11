//! BEAM instructions → `ir.Function`s.
//!
//! A BEAM function is a graph of labels; wasm has structured control only. A
//! function becomes one `loop $dispatch` over nested blocks, one per label,
//! innermost first, the innermost holding the dispatch (`pc == L` → `br $L`):
//! leaving block `$L` lands on label `L`'s code, which falls through into the
//! next label's code as BEAM code does; a jump (and a failed test) sets `pc`
//! and branches to `$dispatch`. The whole is wrapped in `block $raise`: a
//! call that leaves an exception pending (`rt_pending`) branches there, and
//! the function answers 0 — its caller tests `rt_pending` in turn.
//!
//! The registers are locals (`x<N>`, `y<N>`); the frame and heap opcodes
//! (`allocate*`, `init_yregs`, `test_heap`, `deallocate`) and `line` have
//! nothing to do — a y register is a local of the call, and the runtime's
//! terms live on its own arena. A call reaches a function of this module
//! (`call`, `call_last`, `call_only`: by its entry label), a function another
//! module of the set exports (`call_ext*` naming it), an operator
//! (`runtime.operators`) or an OTP function std-wasm serves (`Bif`); a tail
//! call is a call and a return. Anything else — an opcode, a call none of
//! those serves, an operand or a literal of another kind — refuses the
//! function that holds it, named (decision 438); the rest of the module
//! translates.
const std = @import("std");
const stdWasm = @import("std_wasm");
const chunks = @import("chunks.zig");
const code = @import("code.zig");
const ir = @import("ir.zig");

/// A BIF or OTP function std-wasm answers: `module:name/arity` → its export
/// (`std_wasm.otp.table`, decision 450 (2)).
pub const Bif = stdWasm.otp.Bif;

/// The term ABI a translation calls: std-wasm's runtime exports over its
/// Erlang terms (`modules/std-wasm/src/term.zig`, decision 450).
pub const runtime = struct {
    pub const nil = "rt_nil";
    pub const atom = "rt_atom";
    pub const bin = "rt_bin";
    pub const int = "rt_int";
    pub const cons = "rt_cons";
    pub const hd = "rt_hd";
    pub const tl = "rt_tl";
    pub const tuple = "rt_tuple";
    pub const tset = "rt_tset";
    pub const elem = "rt_elem";
    pub const tuple_arity = "rt_tuple_arity";
    pub const is = "rt_is";
    pub const eq = "rt_eq";
    pub const eqx = "rt_eqx";
    pub const cmp = "rt_cmp";
    pub const bb_new = "rt_bb_new";
    pub const bb_bin = "rt_bb_bin";
    pub const bb_int = "rt_bb_int";
    pub const bb_utf8 = "rt_bb_utf8";
    pub const bb_end = "rt_bb_end";
    pub const pending = "rt_pending";
    /// Clears the pending exception (no result): a failed guard BIF jumps.
    pub const clear = "rt_clear";
    pub const function_clause = "rt_function_clause";
    pub const badmatch = "rt_badmatch";
    pub const case_clause = "rt_case_clause";
    pub const if_clause = "rt_if_clause";

    /// `rt_is`'s kinds (std-wasm's `term.Kind`, held to it below).
    pub const Kind = enum(i32) {
        atom = 0,
        binary = 1,
        integer = 2,
        float = 3,
        number = 4,
        list = 5,
        tuple = 6,
        map = 7,
        function = 8,
        boolean = 9,
        nil = 11,
        cons = 12,
    };
    pub const kind_binary: i32 = @intFromEnum(Kind.binary);

    /// The `erlang` operators a `gc_bif` / `bif` names, each a runtime
    /// export of the same arity.
    pub const operators = [_]Bif{
        .{ .module = "erlang", .name = "+", .arity = 2, .rt = "rt_add" },
        .{ .module = "erlang", .name = "-", .arity = 2, .rt = "rt_sub" },
        .{ .module = "erlang", .name = "*", .arity = 2, .rt = "rt_mul" },
        .{ .module = "erlang", .name = "/", .arity = 2, .rt = "rt_fdiv" },
        .{ .module = "erlang", .name = "div", .arity = 2, .rt = "rt_idiv" },
        .{ .module = "erlang", .name = "rem", .arity = 2, .rt = "rt_rem" },
        .{ .module = "erlang", .name = "band", .arity = 2, .rt = "rt_band" },
        .{ .module = "erlang", .name = "bor", .arity = 2, .rt = "rt_bor" },
        .{ .module = "erlang", .name = "bxor", .arity = 2, .rt = "rt_bxor" },
        .{ .module = "erlang", .name = "bsl", .arity = 2, .rt = "rt_bsl" },
        .{ .module = "erlang", .name = "bsr", .arity = 2, .rt = "rt_bsr" },
        .{ .module = "erlang", .name = "-", .arity = 1, .rt = "rt_neg" },
        .{ .module = "erlang", .name = "bnot", .arity = 1, .rt = "rt_bnot" },
        .{ .module = "erlang", .name = "not", .arity = 1, .rt = "rt_not" },
        .{ .module = "erlang", .name = "and", .arity = 2, .rt = "rt_and" },
        .{ .module = "erlang", .name = "or", .arity = 2, .rt = "rt_or" },
        .{ .module = "erlang", .name = "xor", .arity = 2, .rt = "rt_xor" },
    };
};

comptime {
    // This view of the term ABI is std-wasm's: every name an export of its
    // term library, every kind its number there.
    @setEvalBranchQuota(100_000);
    for (@typeInfo(runtime).@"struct".decls) |d| {
        const v = @field(runtime, d.name);
        if (@typeInfo(@TypeOf(v)) != .pointer) continue;
        if (!stdWasm.otp.isRuntimeExport(v)) @compileError("beam-to-wasm calls " ++ v ++ ", which std-wasm does not export");
    }
    for (runtime.operators) |o| if (!stdWasm.otp.isRuntimeExport(o.rt)) @compileError("beam-to-wasm calls " ++ o.rt ++ ", which std-wasm does not export");
    for (@typeInfo(runtime.Kind).@"enum".fields) |f| {
        if (@intFromEnum(@field(stdWasm.term.Kind, f.name)) != f.value) @compileError("rt_is kind " ++ f.name ++ " differs from std-wasm's");
    }
}

pub const Error = error{ OutOfMemory, Refused };

/// What a call names: a runtime export, or a function of a translated
/// module.
const Target = union(enum) { rt: []const u8, call: ir.Call };

/// One function of the stream: its name, arity, entry label and
/// instructions.
const Span = struct { name: []const u8, arity: u32, entry: u32, instrs: []const code.Instr };

pub const Lowerer = struct {
    ar: std.mem.Allocator,
    beam: chunks.Beam,
    /// Every module of the set, this one included: a call to one of them
    /// reaches the function it exports.
    modules: []const chunks.Beam,
    /// What was not converted, when `error.Refused`.
    refusal: []const u8 = "",
    blocks: u32 = 0,
    /// Entry label → `name/arity` of this module's functions.
    entries: std.AutoHashMapUnmanaged(u32, []const u8) = .empty,

    fn refuse(l: *Lowerer, comptime fmt: []const u8, args: anytype) Error {
        l.refusal = std.fmt.allocPrint(l.ar, fmt, args) catch return error.OutOfMemory;
        return error.Refused;
    }

    fn label(l: *Lowerer, n: u32) Error![]const u8 {
        return std.fmt.allocPrint(l.ar, "L{d}", .{n});
    }

    fn fresh(l: *Lowerer, comptime prefix: []const u8) Error![]const u8 {
        l.blocks += 1;
        return std.fmt.allocPrint(l.ar, prefix ++ "{d}", .{l.blocks});
    }

    fn findBif(table: []const Bif, imp: chunks.Import) ?[]const u8 {
        for (table) |b| {
            if (b.arity == imp.arity and std.mem.eql(u8, b.module, imp.module) and std.mem.eql(u8, b.name, imp.function)) return b.rt;
        }
        return null;
    }

    /// What import `imp` reaches, or null when nothing serves it: a module of
    /// the set (only what it exports), an operator, an OTP function of
    /// std-wasm's table.
    fn target(l: *Lowerer, imp: chunks.Import) Error!?Target {
        for (l.modules) |m| {
            if (!std.mem.eql(u8, m.moduleName(), imp.module)) continue;
            for (m.exports) |e| {
                if (e.arity == imp.arity and std.mem.eql(u8, e.function, imp.function))
                    return .{ .call = .{ .module = imp.module, .function = try std.fmt.allocPrint(l.ar, "{s}/{d}", .{ imp.function, imp.arity }), .arity = imp.arity } };
            }
            return null;
        }
        if (findBif(&runtime.operators, imp)) |rt| return .{ .rt = rt };
        if (findBif(&stdWasm.otp.table, imp)) |rt| return .{ .rt = rt };
        return null;
    }

    fn import(l: *Lowerer, a: code.Arg) Error!chunks.Import {
        const idx = switch (a) {
            .u => |u| u,
            else => return l.refuse("a call that names no import", .{}),
        };
        if (idx >= l.beam.imports.len) return l.refuse("a call to import {d}, which the module does not have", .{idx});
        return l.beam.imports[@intCast(idx)];
    }

    /// The import operand of `ins`, when it calls one.
    fn importOf(ins: code.Instr) ?code.Arg {
        return switch (ins.op) {
            .call_ext, .call_ext_last, .call_ext_only => ins.args[1],
            .bif0 => ins.args[0],
            .bif1, .bif2 => ins.args[1],
            .gc_bif1, .gc_bif2, .gc_bif3 => ins.args[2],
            else => null,
        };
    }

    /// Every function of the decoded stream, each translated or refused.
    pub fn lowerAll(l: *Lowerer, instrs: []const code.Instr) Error![]const ir.Function {
        // The functions first: a local call names its callee by entry label.
        var spans: std.ArrayListUnmanaged(Span) = .empty;
        var i: usize = 0;
        while (i < instrs.len) {
            if (instrs[i].op == .int_code_end) break;
            const start = i;
            // A function starts at the `label` before its `func_info` (a
            // `line` may sit between them).
            var fi = i + 1;
            while (fi < instrs.len and instrs[fi].op == .line) fi += 1;
            if (instrs[i].op != .label or fi >= instrs.len or instrs[fi].op != .func_info) return l.refuse("code outside a function", .{});
            i = fi + 1;
            while (i < instrs.len and instrs[i].op != .int_code_end) : (i += 1) {
                if (instrs[i].op == .label and startsFunction(instrs, i)) break;
            }
            const span = instrs[start..i];
            const args = instrs[fi].args;
            const name = switch (args[1]) {
                .a => |a| l.beam.atom(a) catch return l.refuse("a malformed func_info", .{}),
                else => return l.refuse("a malformed func_info", .{}),
            };
            const arity: u32 = switch (args[2]) {
                .u => |u| std.math.cast(u32, u) orelse return l.refuse("a malformed func_info", .{}),
                else => return l.refuse("a malformed func_info", .{}),
            };
            const entry_at = fi + 1 - start;
            if (entry_at >= span.len or span[entry_at].op != .label) return l.refuse("`{s}/{d}` has no entry label", .{ name, arity });
            const entry: u32 = std.math.cast(u32, span[entry_at].args[0].u) orelse return l.refuse("a malformed label", .{});
            const fname = try std.fmt.allocPrint(l.ar, "{s}/{d}", .{ name, arity });
            try l.entries.put(l.ar, entry, fname);
            try spans.append(l.ar, .{ .name = fname, .arity = arity, .entry = entry, .instrs = span });
        }
        const out = try l.ar.alloc(ir.Function, spans.items.len);
        for (spans.items, out) |s, *f| {
            l.blocks = 0;
            f.* = l.function(s) catch |err| switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
                error.Refused => .{ .name = s.name, .arity = s.arity, .x_regs = 0, .y_regs = 0, .body = &.{}, .refused = l.refusal },
            };
        }
        return out;
    }

    fn startsFunction(instrs: []const code.Instr, at: usize) bool {
        var j = at + 1;
        while (j < instrs.len and instrs[j].op == .line) j += 1;
        return j < instrs.len and instrs[j].op == .func_info;
    }

    fn function(l: *Lowerer, s: Span) Error!ir.Function {
        // A call nothing serves is named first: what the code calls is what a
        // reader can act on.
        for (s.instrs) |ins| {
            const a = importOf(ins) orelse continue;
            const imp = try l.import(a);
            if (try l.target(imp) == null) return l.refuse("`{s}:{s}/{d}`", .{ imp.module, imp.function, imp.arity });
        }
        for (s.instrs) |ins| if (!converted(ins.op))
            return l.refuse("opcode {d} ({s})", .{ @intFromEnum(ins.op), code.opName(@intFromEnum(ins.op)) });

        // The labels in order and each one's code.
        var labels: std.ArrayListUnmanaged(u32) = .empty;
        var segments: std.ArrayListUnmanaged(std.ArrayListUnmanaged(ir.Instr)) = .empty;
        // x0 carries every result, whatever the arity.
        var regs: Regs = .{ .x = @max(s.arity, 1) };
        for (s.instrs) |ins| {
            if (ins.op == .label) {
                try labels.append(l.ar, std.math.cast(u32, ins.args[0].u) orelse return l.refuse("a malformed label", .{}));
                try segments.append(l.ar, .empty);
                continue;
            }
            // The `line` before the first label.
            if (segments.items.len == 0) continue;
            const seg = &segments.items[segments.items.len - 1];
            try l.instr(seg, ins, &regs);
        }

        // Innermost: the dispatch.
        var dispatch: std.ArrayListUnmanaged(ir.Instr) = .empty;
        for (labels.items) |lb| {
            try dispatch.appendSlice(l.ar, &.{ .get_pc, .{ .i32_const = @intCast(lb) }, .i32_eq, .{ .br_if = try l.label(lb) } });
        }
        try dispatch.append(l.ar, .trap);
        var inner: ir.Instr = .{ .block = .{ .label = try l.label(labels.items[0]), .body = dispatch.items } };
        for (labels.items[1..], 1..) |lb, k| {
            var body: std.ArrayListUnmanaged(ir.Instr) = .empty;
            try body.append(l.ar, inner);
            try body.appendSlice(l.ar, segments.items[k - 1].items);
            inner = .{ .block = .{ .label = try l.label(lb), .body = body.items } };
        }
        var loop_body: std.ArrayListUnmanaged(ir.Instr) = .empty;
        try loop_body.append(l.ar, inner);
        try loop_body.appendSlice(l.ar, segments.items[segments.items.len - 1].items);
        try loop_body.append(l.ar, .trap);

        var body: std.ArrayListUnmanaged(ir.Instr) = .empty;
        try body.appendSlice(l.ar, &.{ .{ .i32_const = @intCast(s.entry) }, .set_pc });
        const loop_items = try l.ar.dupe(ir.Instr, &.{.{ .block = .{ .label = "dispatch", .loop = true, .body = loop_body.items } }});
        try body.append(l.ar, .{ .block = .{ .label = "raise", .body = loop_items } });
        try body.appendSlice(l.ar, &.{ .{ .i32_const = 0 }, .ret });
        return .{ .name = s.name, .arity = s.arity, .x_regs = regs.x, .y_regs = regs.y, .body = body.items };
    }

    /// Whether the lowering converts `op`.
    fn converted(op: code.Op) bool {
        return switch (op) {
            .label, .func_info, .int_code_end, .call, .call_last, .call_only, .call_ext, .call_ext_last, .call_ext_only, .bif0, .bif1, .bif2, .gc_bif1, .gc_bif2, .gc_bif3, .allocate, .allocate_heap, .allocate_zero, .allocate_heap_zero, .test_heap, .init, .deallocate, .@"return", .is_lt, .is_ge, .is_eq, .is_ne, .is_eq_exact, .is_ne_exact, .is_integer, .is_float, .is_number, .is_atom, .is_nil, .is_binary, .is_list, .is_nonempty_list, .is_tuple, .is_map, .is_function, .is_boolean, .test_arity, .is_tagged_tuple, .select_val, .select_tuple_arity, .jump, .move, .swap, .get_list, .get_hd, .get_tl, .get_tuple_element, .put_list, .put_tuple2, .badmatch, .if_end, .case_end, .line, .executable_line, .init_yregs, .bs_create_bin => true,
            _ => false,
        };
    }

    const Regs = struct {
        x: u32,
        y: u32 = 0,

        fn note(r: *Regs, a: code.Arg) void {
            switch (a) {
                .x => |n| r.x = @max(r.x, n + 1),
                .y => |n| r.y = @max(r.y, n + 1),
                .list => |items| for (items) |it| r.note(it),
                else => {},
            }
        }
    };

    fn reg(a: code.Arg) ?ir.Reg {
        return switch (a) {
            .x => |n| .{ .x = n },
            .y => |n| .{ .y = n },
            else => null,
        };
    }

    fn labelOf(l: *Lowerer, a: code.Arg) Error!u32 {
        return switch (a) {
            .f => |f| f,
            else => l.refuse("a jump to no label", .{}),
        };
    }

    fn jumpTo(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), f: u32) Error!void {
        try seg.appendSlice(l.ar, &.{ .{ .i32_const = @intCast(f) }, .set_pc, .{ .br = "dispatch" } });
    }

    fn jump(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), target_label: code.Arg) Error!void {
        try l.jumpTo(seg, try l.labelOf(target_label));
    }

    /// After a call that can raise: with no fail label (`{f,0}`) the
    /// exception propagates (`$raise`); with one — a guard BIF — it is
    /// cleared and control goes to the label.
    fn failCheck(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), fail: code.Arg) Error!void {
        const f = try l.labelOf(fail);
        if (f == 0) return seg.appendSlice(l.ar, &.{ .{ .rt = runtime.pending }, .{ .br_if = "raise" } });
        const ok = try l.fresh("ok");
        var body: std.ArrayListUnmanaged(ir.Instr) = .empty;
        try body.appendSlice(l.ar, &.{ .{ .rt = runtime.pending }, .i32_eqz, .{ .br_if = ok }, .{ .rt = runtime.clear } });
        try l.jumpTo(&body, f);
        try seg.append(l.ar, .{ .block = .{ .label = ok, .body = body.items } });
    }

    /// A test: `cond` pushes an i32, non-zero when it holds; else control
    /// goes to `fail`.
    fn testThen(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), fail: code.Arg, cond: []const ir.Instr) Error!void {
        const ok = try l.fresh("t");
        var body: std.ArrayListUnmanaged(ir.Instr) = .empty;
        try body.appendSlice(l.ar, cond);
        try body.append(l.ar, .{ .br_if = ok });
        try l.jump(&body, fail);
        try seg.append(l.ar, .{ .block = .{ .label = ok, .body = body.items } });
    }

    /// Push the value of source operand `a`.
    fn push(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), a: code.Arg) Error!void {
        switch (a) {
            .x, .y => try seg.append(l.ar, .{ .get = reg(a).? }),
            .nil => try seg.append(l.ar, .{ .rt = runtime.nil }),
            .a => |idx| {
                const name = l.beam.atom(idx) catch return l.refuse("atom {d}, which the module does not have", .{idx});
                try seg.appendSlice(l.ar, &.{ .{ .bytes = name }, .{ .rt = runtime.atom } });
            },
            .i => |v| try seg.appendSlice(l.ar, &.{ .{ .i64_const = v }, .{ .rt = runtime.int } }),
            .literal => |idx| {
                if (idx >= l.beam.literals.len) return l.refuse("literal {d}, which the module does not have", .{idx});
                switch (l.beam.literals[idx]) {
                    .binary => |b| try seg.appendSlice(l.ar, &.{ .{ .bytes = b }, .{ .rt = runtime.bin } }),
                    .atom => |n| try seg.appendSlice(l.ar, &.{ .{ .bytes = n }, .{ .rt = runtime.atom } }),
                    .int => |v| try seg.appendSlice(l.ar, &.{ .{ .i64_const = v }, .{ .rt = runtime.int } }),
                    .nil => try seg.append(l.ar, .{ .rt = runtime.nil }),
                    .other => |tag| return l.refuse("a literal of external term tag {d}", .{tag}),
                }
            },
            .fr => return l.refuse("a float register", .{}),
            else => return l.refuse("an operand of a kind it does not convert", .{}),
        }
    }

    fn set(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), dst: code.Arg) Error!void {
        const r = reg(dst) orelse return l.refuse("a write to something not a register", .{});
        try seg.append(l.ar, .{ .set = r });
    }

    fn count(l: *Lowerer, a: code.Arg) Error!u32 {
        return switch (a) {
            .u => |u| std.math.cast(u32, u) orelse l.refuse("a count out of range", .{}),
            .i => |i| std.math.cast(u32, i) orelse l.refuse("a count out of range", .{}),
            else => l.refuse("a count that is not an integer", .{}),
        };
    }

    /// A call of `t` with its `n` arguments in x0…x<n-1>, its answer in x0.
    fn callTarget(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), t: Target, n: u32, regs: *Regs) Error!void {
        regs.x = @max(regs.x, n);
        for (0..n) |k| try seg.append(l.ar, .{ .get = .{ .x = @intCast(k) } });
        try seg.append(l.ar, switch (t) {
            .rt => |rt| .{ .rt = rt },
            .call => |c| .{ .call = c },
        });
        try seg.appendSlice(l.ar, &.{ .{ .set = .{ .x = 0 } }, .{ .rt = runtime.pending }, .{ .br_if = "raise" } });
    }

    fn ret(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr)) Error!void {
        try seg.appendSlice(l.ar, &.{ .{ .get = .{ .x = 0 } }, .ret });
    }

    fn local(l: *Lowerer, a: code.Arg) Error!Target {
        const f = try l.labelOf(a);
        const name = l.entries.get(f) orelse return l.refuse("a call to label {d}, which starts no function", .{f});
        const slash = std.mem.lastIndexOfScalar(u8, name, '/').?;
        return .{ .call = .{ .module = l.beam.moduleName(), .function = name, .arity = std.fmt.parseInt(u32, name[slash + 1 ..], 10) catch unreachable } };
    }

    /// A `bif*` / `gc_bif*`: `args` pushed, the answer in `dst`, a failure
    /// to `fail`.
    fn bif(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), fail: code.Arg, import_arg: code.Arg, args: []const code.Arg, dst: code.Arg) Error!void {
        const imp = try l.import(import_arg);
        const rt = switch ((try l.target(imp)).?) {
            .rt => |rt| rt,
            .call => return l.refuse("`{s}:{s}/{d}` called as a BIF", .{ imp.module, imp.function, imp.arity }),
        };
        for (args) |a| try l.push(seg, a);
        try seg.append(l.ar, .{ .rt = rt });
        try l.set(seg, dst);
        try l.failCheck(seg, fail);
    }

    fn typeTest(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), ins: code.Instr, kind: runtime.Kind) Error!void {
        var cond: std.ArrayListUnmanaged(ir.Instr) = .empty;
        try l.push(&cond, ins.args[1]);
        try cond.appendSlice(l.ar, &.{ .{ .i32_const = @intFromEnum(kind) }, .{ .rt = runtime.is } });
        try l.testThen(seg, ins.args[0], cond.items);
    }

    fn compare(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), ins: code.Instr, rt: []const u8, tail: []const ir.Instr) Error!void {
        var cond: std.ArrayListUnmanaged(ir.Instr) = .empty;
        const operands = switch (ins.args[1]) {
            .list => |items| items,
            else => ins.args[1..3],
        };
        if (operands.len != 2) return l.refuse("a comparison of {d} operands", .{operands.len});
        try l.push(&cond, operands[0]);
        try l.push(&cond, operands[1]);
        try cond.append(l.ar, .{ .rt = rt });
        try cond.appendSlice(l.ar, tail);
        try l.testThen(seg, ins.args[0], cond.items);
    }

    /// `bs_create_bin`: the segments appended to a binary builder, in order.
    /// A `string` (bytes of `StrT`), a `binary` of size `all`, an `integer`
    /// of a whole number of bytes, big-endian, and a `utf8` code point
    /// convert; any other segment is refused, named.
    fn createBin(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), ins: code.Instr) Error!void {
        const fail = ins.args[0];
        const segs = switch (ins.args[5]) {
            .list => |items| items,
            else => return l.refuse("a bs_create_bin with no segment list", .{}),
        };
        if (segs.len % 6 != 0) return l.refuse("a bs_create_bin segment list of {d} terms", .{segs.len});
        try seg.append(l.ar, .{ .rt = runtime.bb_new });
        var k: usize = 0;
        while (k < segs.len) : (k += 6) {
            const kind = switch (segs[k]) {
                .a => |a| l.beam.atom(a) catch return l.refuse("a bs_create_bin segment of no type", .{}),
                else => return l.refuse("a bs_create_bin segment of no type", .{}),
            };
            const unit = try l.count(segs[k + 2]);
            const flags_plain = segs[k + 3] == .nil;
            const src = segs[k + 4];
            const size = segs[k + 5];
            if (std.mem.eql(u8, kind, "string")) {
                const off = try l.count(src);
                const len = try l.count(size);
                if (@as(usize, off) + len > l.beam.strings.len) return l.refuse("a string segment outside StrT", .{});
                try seg.appendSlice(l.ar, &.{ .{ .bytes = l.beam.strings[off..][0..len] }, .{ .rt = runtime.bin }, .{ .rt = runtime.bb_bin } });
            } else if (std.mem.eql(u8, kind, "binary")) {
                const all = switch (size) {
                    .a => |a| std.mem.eql(u8, l.beam.atom(a) catch "", "all"),
                    else => false,
                };
                if (!all) return l.refuse("a binary segment of a fixed size", .{});
                try l.push(seg, src);
                try seg.append(l.ar, .{ .rt = runtime.bb_bin });
            } else if (std.mem.eql(u8, kind, "integer")) {
                const bits = (try l.count(size)) * unit;
                if (!flags_plain or bits == 0 or bits % 8 != 0 or bits > 64) return l.refuse("an integer segment of {d} bits or with flags", .{bits});
                try l.push(seg, src);
                try seg.appendSlice(l.ar, &.{ .{ .i32_const = @intCast(bits) }, .{ .rt = runtime.bb_int } });
            } else if (std.mem.eql(u8, kind, "utf8")) {
                try l.push(seg, src);
                try seg.append(l.ar, .{ .rt = runtime.bb_utf8 });
            } else return l.refuse("a bs_create_bin segment `{s}`", .{kind});
            try l.failCheck(seg, fail);
        }
        try seg.append(l.ar, .{ .rt = runtime.bb_end });
        try l.set(seg, ins.args[4]);
    }

    fn instr(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), ins: code.Instr, regs: *Regs) Error!void {
        for (ins.args) |a| regs.note(a);
        switch (ins.op) {
            .func_info => try seg.appendSlice(l.ar, &.{ .{ .rt = runtime.function_clause }, .drop, .{ .br = "raise" } }),
            .allocate, .allocate_heap, .allocate_zero, .allocate_heap_zero, .test_heap, .deallocate, .init_yregs, .line, .executable_line => {},
            .init => {
                try seg.append(l.ar, .{ .rt = runtime.nil });
                try l.set(seg, ins.args[0]);
            },
            .move => {
                try l.push(seg, ins.args[0]);
                try l.set(seg, ins.args[1]);
            },
            .swap => {
                try l.push(seg, ins.args[0]);
                try l.push(seg, ins.args[1]);
                try l.set(seg, ins.args[0]);
                try l.set(seg, ins.args[1]);
            },
            .put_list => {
                try l.push(seg, ins.args[0]);
                try l.push(seg, ins.args[1]);
                try seg.append(l.ar, .{ .rt = runtime.cons });
                try l.set(seg, ins.args[2]);
            },
            .put_tuple2 => {
                const items = switch (ins.args[1]) {
                    .list => |items| items,
                    else => return l.refuse("a put_tuple2 with no element list", .{}),
                };
                try seg.appendSlice(l.ar, &.{ .{ .i32_const = @intCast(items.len) }, .{ .rt = runtime.tuple } });
                for (items, 0..) |it, k| {
                    try seg.append(l.ar, .{ .i32_const = @intCast(k) });
                    try l.push(seg, it);
                    try seg.append(l.ar, .{ .rt = runtime.tset });
                }
                try l.set(seg, ins.args[0]);
            },
            .get_list => {
                // Both read before either is written: the head may go to the
                // source register.
                try l.push(seg, ins.args[0]);
                try seg.append(l.ar, .{ .rt = runtime.hd });
                try l.push(seg, ins.args[0]);
                try seg.append(l.ar, .{ .rt = runtime.tl });
                try l.set(seg, ins.args[2]);
                try l.set(seg, ins.args[1]);
            },
            .get_hd, .get_tl => {
                try l.push(seg, ins.args[0]);
                try seg.append(l.ar, .{ .rt = if (ins.op == .get_hd) runtime.hd else runtime.tl });
                try l.set(seg, ins.args[1]);
            },
            .get_tuple_element => {
                try l.push(seg, ins.args[0]);
                try seg.appendSlice(l.ar, &.{ .{ .i32_const = @intCast(try l.count(ins.args[1])) }, .{ .rt = runtime.elem } });
                try l.set(seg, ins.args[2]);
            },
            .is_integer => try l.typeTest(seg, ins, .integer),
            .is_float => try l.typeTest(seg, ins, .float),
            .is_number => try l.typeTest(seg, ins, .number),
            .is_atom => try l.typeTest(seg, ins, .atom),
            .is_nil => try l.typeTest(seg, ins, .nil),
            .is_binary => try l.typeTest(seg, ins, .binary),
            .is_list => try l.typeTest(seg, ins, .list),
            .is_nonempty_list => try l.typeTest(seg, ins, .cons),
            .is_tuple => try l.typeTest(seg, ins, .tuple),
            .is_map => try l.typeTest(seg, ins, .map),
            .is_function => try l.typeTest(seg, ins, .function),
            .is_boolean => try l.typeTest(seg, ins, .boolean),
            .is_eq_exact => try l.compare(seg, ins, runtime.eqx, &.{}),
            .is_ne_exact => try l.compare(seg, ins, runtime.eqx, &.{.i32_eqz}),
            .is_eq => try l.compare(seg, ins, runtime.eq, &.{}),
            .is_ne => try l.compare(seg, ins, runtime.eq, &.{.i32_eqz}),
            .is_lt => try l.compare(seg, ins, runtime.cmp, &.{ .{ .i32_const = 0 }, .i32_lt_s }),
            .is_ge => try l.compare(seg, ins, runtime.cmp, &.{ .{ .i32_const = 0 }, .i32_ge_s }),
            .test_arity => {
                var cond: std.ArrayListUnmanaged(ir.Instr) = .empty;
                try l.push(&cond, ins.args[1]);
                try cond.appendSlice(l.ar, &.{ .{ .rt = runtime.tuple_arity }, .{ .i32_const = @intCast(try l.count(ins.args[2])) }, .i32_eq });
                try l.testThen(seg, ins.args[0], cond.items);
            },
            .is_tagged_tuple => {
                // A tuple of the arity whose first element is the atom.
                const no = try l.fresh("n");
                var cond: std.ArrayListUnmanaged(ir.Instr) = .empty;
                try l.push(&cond, ins.args[1]);
                try cond.appendSlice(l.ar, &.{ .{ .rt = runtime.tuple_arity }, .{ .i32_const = @intCast(try l.count(ins.args[2])) }, .i32_ne, .{ .br_if = no } });
                try l.push(&cond, ins.args[1]);
                try cond.appendSlice(l.ar, &.{ .{ .i32_const = 0 }, .{ .rt = runtime.elem } });
                try l.push(&cond, ins.args[3]);
                try cond.append(l.ar, .{ .rt = runtime.eqx });
                const ok = try l.fresh("t");
                try cond.append(l.ar, .{ .br_if = ok });
                var outer: std.ArrayListUnmanaged(ir.Instr) = .empty;
                try outer.append(l.ar, .{ .block = .{ .label = no, .body = cond.items } });
                try l.jump(&outer, ins.args[0]);
                try seg.append(l.ar, .{ .block = .{ .label = ok, .body = outer.items } });
            },
            .select_val, .select_tuple_arity => {
                const pairs = switch (ins.args[2]) {
                    .list => |items| items,
                    else => return l.refuse("a select with no value list", .{}),
                };
                if (pairs.len % 2 != 0) return l.refuse("a select list of {d} terms", .{pairs.len});
                var k: usize = 0;
                while (k < pairs.len) : (k += 2) {
                    const next = try l.fresh("s");
                    var body: std.ArrayListUnmanaged(ir.Instr) = .empty;
                    try l.push(&body, ins.args[0]);
                    if (ins.op == .select_val) {
                        try l.push(&body, pairs[k]);
                        try body.appendSlice(l.ar, &.{ .{ .rt = runtime.eqx }, .i32_eqz, .{ .br_if = next } });
                    } else {
                        try body.appendSlice(l.ar, &.{ .{ .rt = runtime.tuple_arity }, .{ .i32_const = @intCast(try l.count(pairs[k])) }, .i32_ne, .{ .br_if = next } });
                    }
                    try l.jump(&body, pairs[k + 1]);
                    try seg.append(l.ar, .{ .block = .{ .label = next, .body = body.items } });
                }
                try l.jump(seg, ins.args[1]);
            },
            .jump => try l.jump(seg, ins.args[0]),
            .call, .call_last, .call_only => {
                try l.callTarget(seg, try l.local(ins.args[1]), try l.count(ins.args[0]), regs);
                if (ins.op != .call) try l.ret(seg);
            },
            .call_ext, .call_ext_last, .call_ext_only => {
                const imp = try l.import(ins.args[1]);
                try l.callTarget(seg, (try l.target(imp)).?, try l.count(ins.args[0]), regs);
                if (ins.op != .call_ext) try l.ret(seg);
            },
            .bif0 => try l.bif(seg, .{ .f = 0 }, ins.args[0], &.{}, ins.args[1]),
            .bif1 => try l.bif(seg, ins.args[0], ins.args[1], ins.args[2..3], ins.args[3]),
            .bif2 => try l.bif(seg, ins.args[0], ins.args[1], ins.args[2..4], ins.args[4]),
            .gc_bif1 => try l.bif(seg, ins.args[0], ins.args[2], ins.args[3..4], ins.args[4]),
            .gc_bif2 => try l.bif(seg, ins.args[0], ins.args[2], ins.args[3..5], ins.args[5]),
            .gc_bif3 => try l.bif(seg, ins.args[0], ins.args[2], ins.args[3..6], ins.args[6]),
            .badmatch, .case_end => {
                try l.push(seg, ins.args[0]);
                try seg.appendSlice(l.ar, &.{ .{ .rt = if (ins.op == .badmatch) runtime.badmatch else runtime.case_clause }, .drop, .{ .br = "raise" } });
            },
            .if_end => try seg.appendSlice(l.ar, &.{ .{ .rt = runtime.if_clause }, .drop, .{ .br = "raise" } }),
            .bs_create_bin => try l.createBin(seg, ins),
            .@"return" => try l.ret(seg),
            .label, .int_code_end => unreachable,
            _ => unreachable, // `converted` refused it
        }
    }
};
