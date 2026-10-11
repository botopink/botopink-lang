//! BEAM instructions → `ir.Function`s.
//!
//! A BEAM function is a graph of labels; wasm has structured control only. A
//! function becomes one `loop $dispatch` over nested blocks, one per label,
//! innermost first, the innermost holding the dispatch (`pc == L` → `br $L`):
//! leaving block `$L` lands on label `L`'s code, which falls through into the
//! next label's code as BEAM code does; a jump sets `pc` and branches to
//! `$dispatch`. The whole is wrapped in `block $raise`: a call that leaves an
//! exception pending (`rt_pending`) branches there, and the function answers
//! 0 — its caller tests `rt_pending` in turn.
//!
//! The registers are locals (`x<N>`, `y<N>`); the frame and heap opcodes
//! (`allocate`, `init_yregs`, `test_heap`, `deallocate`) have nothing to do —
//! a y register is a local of the call, and the runtime's terms live on its
//! own arena. Only the measured subset converts (decision 435): anything else
//! is a `Refusal` naming it.
const std = @import("std");
const chunks = @import("chunks.zig");
const code = @import("code.zig");
const ir = @import("ir.zig");

/// A BIF of the comptime runtime: `module:name/arity` → its export.
pub const Bif = struct { module: []const u8, name: []const u8, arity: u32, rt: []const u8 };

/// The comptime runtime's term ABI a translation calls (its `rt.zig`).
pub const runtime = struct {
    pub const nil = "rt_nil";
    pub const atom = "rt_atom";
    pub const bin = "rt_bin";
    pub const int = "rt_int";
    pub const cons = "rt_cons";
    pub const is = "rt_is";
    pub const pending = "rt_pending";
    pub const function_clause = "rt_function_clause";
    /// `rt_is`'s kind of a binary (`rt.zig` `Kind.binary`).
    pub const kind_binary: i32 = 1;
};

pub const Error = error{ OutOfMemory, Refused };

pub const Lowerer = struct {
    ar: std.mem.Allocator,
    beam: chunks.Beam,
    bifs: []const Bif,
    /// What was not converted, when `error.Refused`.
    refusal: []const u8 = "",
    blocks: u32 = 0,

    fn refuse(l: *Lowerer, comptime fmt: []const u8, args: anytype) Error {
        l.refusal = std.fmt.allocPrint(l.ar, fmt, args) catch return error.OutOfMemory;
        return error.Refused;
    }

    fn label(l: *Lowerer, n: u32) Error![]const u8 {
        return std.fmt.allocPrint(l.ar, "L{d}", .{n});
    }

    fn bif(l: *Lowerer, module: []const u8, name: []const u8, arity: u32) ?[]const u8 {
        for (l.bifs) |b| {
            if (b.arity == arity and std.mem.eql(u8, b.module, module) and std.mem.eql(u8, b.name, name)) return b.rt;
        }
        return null;
    }

    /// Every function of the decoded stream.
    pub fn lowerAll(l: *Lowerer, instrs: []const code.Instr) Error![]const ir.Function {
        var out: std.ArrayListUnmanaged(ir.Function) = .empty;
        var i: usize = 0;
        while (i < instrs.len) {
            // A function starts at the `label` before its `func_info`.
            if (instrs[i].op == .int_code_end) break;
            const start = i;
            if (i + 1 >= instrs.len or instrs[i].op != .label or instrs[i + 1].op != .func_info) return l.refuse("code outside a function", .{});
            i += 2;
            while (i < instrs.len and instrs[i].op != .int_code_end) : (i += 1) {
                if (instrs[i].op == .label and i + 1 < instrs.len and instrs[i + 1].op == .func_info) break;
            }
            try out.append(l.ar, try l.function(instrs[start..i]));
        }
        return out.items;
    }

    fn function(l: *Lowerer, instrs: []const code.Instr) Error!ir.Function {
        const fi = instrs[1].args;
        const name_atom = switch (fi[1]) {
            .a => |a| a,
            else => return l.refuse("a malformed func_info", .{}),
        };
        const name = l.beam.atom(name_atom) catch return l.refuse("a malformed func_info", .{});
        const arity: u32 = switch (fi[2]) {
            .u => |u| std.math.cast(u32, u) orelse return l.refuse("a malformed func_info", .{}),
            else => return l.refuse("a malformed func_info", .{}),
        };
        const fname = try std.fmt.allocPrint(l.ar, "{s}/{d}", .{ name, arity });
        if (instrs.len < 3 or instrs[2].op != .label) return l.refuse("`{s}` has no entry label", .{fname});
        const entry: u32 = @intCast(instrs[2].args[0].u);

        // The labels in order and each one's code.
        var labels: std.ArrayListUnmanaged(u32) = .empty;
        var segments: std.ArrayListUnmanaged(std.ArrayListUnmanaged(ir.Instr)) = .empty;
        // x0 carries every result, whatever the arity.
        var regs: Regs = .{ .x = @max(arity, 1) };
        for (instrs) |ins| {
            if (ins.op == .label) {
                try labels.append(l.ar, @intCast(ins.args[0].u));
                try segments.append(l.ar, .empty);
                continue;
            }
            const seg = &segments.items[segments.items.len - 1];
            try l.instr(seg, ins, fname, &regs);
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
        try body.appendSlice(l.ar, &.{ .{ .i32_const = @intCast(entry) }, .set_pc });
        const loop_items = try l.ar.dupe(ir.Instr, &.{.{ .block = .{ .label = "dispatch", .loop = true, .body = loop_body.items } }});
        try body.append(l.ar, .{ .block = .{ .label = "raise", .body = loop_items } });
        try body.appendSlice(l.ar, &.{ .{ .i32_const = 0 }, .ret });
        return .{ .name = fname, .arity = arity, .x_regs = regs.x, .y_regs = regs.y, .body = body.items };
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

    fn jump(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), target: code.Arg) Error!void {
        const f = switch (target) {
            .f => |f| f,
            else => return l.refuse("a jump to no label", .{}),
        };
        try seg.appendSlice(l.ar, &.{ .{ .i32_const = @intCast(f) }, .set_pc, .{ .br = "dispatch" } });
    }

    /// Push the value of source operand `a`.
    fn push(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), a: code.Arg, fname: []const u8) Error!void {
        switch (a) {
            .x, .y => try seg.append(l.ar, .{ .get = reg(a).? }),
            .nil => try seg.append(l.ar, .{ .rt = runtime.nil }),
            .a => |idx| {
                const name = l.beam.atom(idx) catch return l.refuse("`{s}` names atom {d}, which the module does not have", .{ fname, idx });
                try seg.appendSlice(l.ar, &.{ .{ .bytes = name }, .{ .rt = runtime.atom } });
            },
            .i => |v| try seg.appendSlice(l.ar, &.{ .{ .i64_const = v }, .{ .rt = runtime.int } }),
            .literal => |idx| {
                if (idx >= l.beam.literals.len) return l.refuse("`{s}` names literal {d}, which the module does not have", .{ fname, idx });
                switch (l.beam.literals[idx]) {
                    .binary => |b| try seg.appendSlice(l.ar, &.{ .{ .bytes = b }, .{ .rt = runtime.bin } }),
                    .atom => |n| try seg.appendSlice(l.ar, &.{ .{ .bytes = n }, .{ .rt = runtime.atom } }),
                    .int => |v| try seg.appendSlice(l.ar, &.{ .{ .i64_const = v }, .{ .rt = runtime.int } }),
                    .nil => try seg.append(l.ar, .{ .rt = runtime.nil }),
                    .other => |tag| return l.refuse("`{s}` uses a literal of external term tag {d}", .{ fname, tag }),
                }
            },
            else => return l.refuse("`{s}` reads an operand of a kind it does not convert", .{fname}),
        }
    }

    fn set(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), dst: code.Arg, fname: []const u8) Error!void {
        const r = reg(dst) orelse return l.refuse("`{s}` writes to something not a register", .{fname});
        try seg.append(l.ar, .{ .set = r });
    }

    fn instr(l: *Lowerer, seg: *std.ArrayListUnmanaged(ir.Instr), ins: code.Instr, fname: []const u8, regs: *Regs) Error!void {
        for (ins.args) |a| regs.note(a);
        switch (ins.op) {
            .label, .int_code_end => unreachable,
            .func_info => try seg.appendSlice(l.ar, &.{ .{ .rt = runtime.function_clause }, .drop, .{ .br = "raise" } }),
            .allocate, .test_heap, .deallocate, .init_yregs => {},
            .move => {
                try l.push(seg, ins.args[0], fname);
                try l.set(seg, ins.args[1], fname);
            },
            .put_list => {
                try l.push(seg, ins.args[0], fname);
                try l.push(seg, ins.args[1], fname);
                try seg.append(l.ar, .{ .rt = runtime.cons });
                try l.set(seg, ins.args[2], fname);
            },
            .is_binary => {
                l.blocks += 1;
                const ok = try std.fmt.allocPrint(l.ar, "t{d}", .{l.blocks});
                var body: std.ArrayListUnmanaged(ir.Instr) = .empty;
                try l.push(&body, ins.args[1], fname);
                try body.appendSlice(l.ar, &.{ .{ .i32_const = runtime.kind_binary }, .{ .rt = runtime.is }, .{ .br_if = ok } });
                try l.jump(&body, ins.args[0]);
                try seg.append(l.ar, .{ .block = .{ .label = ok, .body = body.items } });
            },
            .jump => try l.jump(seg, ins.args[0]),
            .call_ext => {
                const n: u32 = @intCast(ins.args[0].u);
                const idx = switch (ins.args[1]) {
                    .u => |u| u,
                    else => return l.refuse("`{s}` makes a call_ext with no import", .{fname}),
                };
                if (idx >= l.beam.imports.len) return l.refuse("`{s}` calls import {d}, which the module does not have", .{ fname, idx });
                const imp = l.beam.imports[@intCast(idx)];
                const rt = l.bif(imp.module, imp.function, imp.arity) orelse
                    return l.refuse("`{s}:{s}/{d}`", .{ imp.module, imp.function, imp.arity });
                regs.x = @max(regs.x, n);
                for (0..n) |k| try seg.append(l.ar, .{ .get = .{ .x = @intCast(k) } });
                try seg.appendSlice(l.ar, &.{ .{ .rt = rt }, .{ .set = .{ .x = 0 } }, .{ .rt = runtime.pending }, .{ .br_if = "raise" } });
            },
            .@"return" => try seg.appendSlice(l.ar, &.{ .{ .get = .{ .x = 0 } }, .ret }),
        }
    }
};
