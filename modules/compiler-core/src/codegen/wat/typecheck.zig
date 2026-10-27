//! The operand-stack type check of a lowered module's functions (front 164 s2,
//! decision 544).
//!
//! `wat_ast.validateModule` checks what the model can name — every call, type
//! index, segment and tag; this checks what the instructions do to the operand
//! stack: each one pops what its operands are and pushes what it answers, and a
//! value is only ever consumed as its own type (or a supertype, for a GC
//! reference). It is the WasmGC lowering's guard (`../wat.zig` `emitWat`): the
//! lowering recovers a value's representation by best effort, and a module
//! whose guess was wrong somewhere — a string where a word was taken — fails
//! here, at build, and is lowered again in linear memory. It never answers a
//! module wrong; an instruction it does not type is `Unsupported`, which the
//! caller treats as a failure.

const std = @import("std");
const ast = @import("wat_ast.zig");

const ValType = ast.ValType;

pub const Error = error{
    /// An instruction consumed a value of another type, a stack held a value
    /// it should not, or a name resolves to nothing.
    Mismatch,
    /// An instruction this check does not type.
    Unsupported,
    OutOfMemory,
};

/// What failed: the function, and a short reason.
pub const Diag = struct {
    func: []const u8 = "",
    what: []const u8 = "",
    /// The name the failing instruction names (a call's callee), when it names one.
    detail: []const u8 = "",
    /// The two types a mismatch compared (`ValType` as numbers), for the debug trace.
    got: u16 = 0,
    want: u16 = 0,
};

/// Checks every function of `m` whose name `skip` does not answer true for.
pub fn checkModule(alloc: std.mem.Allocator, m: ast.Module, skip: *const fn ([]const u8) bool, diag: *Diag) Error!void {
    var arena_state = std.heap.ArenaAllocator.init(alloc);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var mod: ModCtx = .{ .types = ast.typesOf(m) };
    for (m.items) |it| switch (it) {
        .func => |f| {
            const ps = try arena.alloc(ValType, f.params.len);
            for (f.params, ps) |p, *t| t.* = p.ty;
            try mod.funcs.put(arena, f.name, .{ .params = ps, .result = f.result });
        },
        .import => |im| try mod.funcs.put(arena, im.func, im.type),
        .global => |g| try mod.globals.put(arena, g.name, g.ty),
        .tag => |t| try mod.tags.put(arena, t.name, t.params),
        else => {},
    };
    for (m.items) |it| switch (it) {
        .func => |f| {
            if (skip(f.name)) continue;
            diag.func = f.name;
            var fc: FuncCtx = .{ .mod = &mod, .arena = arena, .result = f.result, .diag = diag };
            for (f.params) |p| try fc.locals.put(arena, p.name, p.ty);
            for (f.locals) |line| for (line) |l| try fc.locals.put(arena, l.name, l.ty);
            try fc.frames.append(arena, .{ .label = null, .kind = .func, .result = f.result });
            try fc.checkSeq(f.body, f.result);
        },
        else => {},
    };
}

const ModCtx = struct {
    types: []const ast.TypeDef,
    funcs: std.StringHashMapUnmanaged(ast.FuncType) = .empty,
    globals: std.StringHashMapUnmanaged(ValType) = .empty,
    tags: std.StringHashMapUnmanaged([]const ValType) = .empty,
};

const Frame = struct {
    label: ?[]const u8,
    kind: enum { func, block, loop, @"if" },
    result: ?ValType,

    /// What a branch to the frame carries: a loop's label takes nothing (no
    /// block parameters), every other frame its result.
    fn arity(f: Frame) ?ValType {
        return if (f.kind == .loop) null else f.result;
    }
};

/// A value on the operand stack; null below a branch, a `return` or an
/// `unreachable` — the polymorphic stack, which answers any type.
const Slot = ?ValType;

const FuncCtx = struct {
    mod: *const ModCtx,
    arena: std.mem.Allocator,
    result: ?ValType,
    diag: *Diag,
    locals: std.StringHashMapUnmanaged(ValType) = .empty,
    frames: std.ArrayListUnmanaged(Frame) = .empty,

    fn fail(self: *FuncCtx, comptime what: []const u8) Error {
        self.diag.what = what;
        return error.Mismatch;
    }

    fn unsupported(self: *FuncCtx, comptime what: []const u8) Error {
        self.diag.what = what;
        return error.Unsupported;
    }

    /// One instruction sequence: a function body or a block's, starting from
    /// an empty stack and leaving `expect`.
    fn checkSeq(self: *FuncCtx, seq: ast.Seq, expect: ?ValType) Error!void {
        var st: Stack = .{ .fc = self };
        for (seq.lines) |line| self.step(&st, line.instr) catch |e| {
            // The instruction that failed, for the diagnostic.
            if (self.diag.detail.len == 0) self.diag.detail = @tagName(line.instr);
            return e;
        };
        if (expect) |want| try st.pop(want);
        if (!st.poly and st.items.items.len != 0) return self.fail("a value left on the stack");
    }

    fn frameOf(self: *FuncCtx, label: []const u8) Error!Frame {
        var i = self.frames.items.len;
        while (i > 0) {
            i -= 1;
            const f = self.frames.items[i];
            if (f.label) |l| if (std.mem.eql(u8, l, label)) return f;
        }
        return self.fail("a branch to no enclosing label");
    }

    fn step(self: *FuncCtx, st: *Stack, ins: ast.Instr) Error!void {
        switch (ins) {
            .comment => {},
            .@"const" => |c| try st.push(c.ty),
            .local_get => |n| try st.push(self.locals.get(n) orelse return self.fail("an undeclared local")),
            .local_set => |n| try st.pop(self.locals.get(n) orelse return self.fail("an undeclared local")),
            .local_tee => |n| {
                const t = self.locals.get(n) orelse return self.fail("an undeclared local");
                try st.pop(t);
                try st.push(t);
            },
            .global_get => |n| try st.push(self.mod.globals.get(n) orelse return self.fail("an undeclared global")),
            .global_set => |n| try st.pop(self.mod.globals.get(n) orelse return self.fail("an undeclared global")),
            .op => |o| try self.stepOp(st, o),
            .convert => |c| {
                const conv = convertTypes(c) orelse return self.unsupported("a conversion it does not know");
                try st.pop(conv.from);
                try st.push(conv.to);
            },
            .load => |m| {
                try st.pop(.i32);
                try st.push(m.ty);
            },
            .store => |m| {
                try st.pop(m.ty);
                try st.pop(.i32);
            },
            .call => |n| {
                const ft = self.mod.funcs.get(n) orelse {
                    self.diag.detail = n;
                    return self.fail("a call to no function");
                };
                self.diag.detail = n;
                try self.callType(st, ft);
            },
            .call_indirect => |ft| {
                try st.pop(.i32);
                try self.callType(st, ft);
            },
            .drop => try st.popAny(),
            .select => {
                try st.pop(.i32);
                const b = try st.popSlot();
                const a = try st.popSlot();
                if (a) |ta| if (b) |tb| if (ta != tb) return self.fail("a select over two types");
                if (a orelse b) |t| try st.push(t) else try st.items.append(self.arena, null);
            },
            .data_drop => {},
            .memory_copy, .memory_fill, .memory_init => {
                try st.pop(.i32);
                try st.pop(.i32);
                try st.pop(.i32);
            },
            .memory_size => try st.push(.i32),
            .memory_grow => {
                try st.pop(.i32);
                try st.push(.i32);
            },
            .@"return" => {
                if (self.result) |r| try st.pop(r);
                st.unreachable_();
            },
            .@"unreachable" => st.unreachable_(),
            .throw => |t| {
                const ps = self.mod.tags.get(t) orelse return self.fail("a throw of no tag");
                var i = ps.len;
                while (i > 0) {
                    i -= 1;
                    try st.pop(ps[i]);
                }
                st.unreachable_();
            },
            .br => |l| {
                const f = try self.frameOf(l);
                if (f.arity()) |t| try st.pop(t);
                st.unreachable_();
            },
            .br_if => |l| {
                try st.pop(.i32);
                const f = try self.frameOf(l);
                if (f.arity()) |t| {
                    try st.pop(t);
                    try st.push(t);
                }
            },
            .br_table => |bt| {
                try st.pop(.i32);
                const d = try self.frameOf(bt.default);
                for (bt.labels) |l| {
                    const f = try self.frameOf(l);
                    if (!sameOpt(f.arity(), d.arity())) return self.fail("a br_table over labels of two arities");
                }
                if (d.arity()) |t| try st.pop(t);
                st.unreachable_();
            },
            .@"if" => |i| {
                try st.pop(.i32);
                try self.frames.append(self.arena, .{ .label = i.label, .kind = .@"if", .result = i.result });
                defer _ = self.frames.pop();
                try self.checkSeq(i.then.seq, i.result);
                if (i.@"else") |e| {
                    try self.checkSeq(e.seq, i.result);
                } else if (i.result != null) return self.fail("a value `if` with no else");
                if (i.result) |r| try st.push(r);
            },
            .block => |b| {
                // A `try_table`'s catch branches to an enclosing label with
                // the tag's values (decision 518): the label takes them.
                if (b.kind == .try_table) for (b.catches) |c| {
                    const ps = self.mod.tags.get(c.tag) orelse return self.fail("a catch of no tag");
                    const want = (try self.frameOf(c.label)).arity();
                    if (ps.len > 1) return self.unsupported("a catch of several values");
                    if (ps.len == 0) {
                        if (want != null) return self.fail("a catch of no value to a label that takes one");
                    } else if (want == null or !subtype(self.mod.types, ps[0], want.?)) return self.fail("a catch whose value the label does not take");
                };
                try self.frames.append(self.arena, .{ .label = b.label, .kind = if (b.kind == .loop) .loop else .block, .result = b.result });
                defer _ = self.frames.pop();
                try self.checkSeq(b.body, b.result);
                if (b.result) |r| try st.push(r);
            },
            .struct_new => |k| {
                const fields = try self.structFields(k);
                var i = fields.len;
                while (i > 0) {
                    i -= 1;
                    try st.pop(unpacked(fields[i].ty));
                }
                try st.push(ValType.def(k));
            },
            .struct_new_default => |k| {
                _ = try self.structFields(k);
                try st.push(ValType.def(k));
            },
            .struct_get => |fr| {
                const fields = try self.structFields(fr.ty);
                if (fr.field >= fields.len) return self.fail("a struct field past its type's");
                try st.pop(ValType.def(fr.ty));
                try st.push(unpacked(fields[fr.field].ty));
            },
            .struct_set => |fr| {
                const fields = try self.structFields(fr.ty);
                if (fr.field >= fields.len) return self.fail("a struct field past its type's");
                try st.pop(unpacked(fields[fr.field].ty));
                try st.pop(ValType.def(fr.ty));
            },
            .array_new => |k| {
                const el = try self.arrayElem(k);
                try st.pop(.i32);
                try st.pop(unpacked(el.ty));
                try st.push(ValType.def(k));
            },
            .array_new_default => |k| {
                _ = try self.arrayElem(k);
                try st.pop(.i32);
                try st.push(ValType.def(k));
            },
            .array_new_fixed => |af| {
                const el = try self.arrayElem(af.ty);
                var i: u32 = 0;
                while (i < af.n) : (i += 1) try st.pop(unpacked(el.ty));
                try st.push(ValType.def(af.ty));
            },
            .array_new_data => |ad| {
                _ = try self.arrayElem(ad.ty);
                try st.pop(.i32);
                try st.pop(.i32);
                try st.push(ValType.def(ad.ty));
            },
            .array_get => |ag| {
                const el = try self.arrayElem(ag.ty);
                try st.pop(.i32);
                try st.pop(ValType.def(ag.ty));
                try st.push(unpacked(el.ty));
            },
            .array_set => |k| {
                const el = try self.arrayElem(k);
                try st.pop(unpacked(el.ty));
                try st.pop(.i32);
                try st.pop(ValType.def(k));
            },
            .array_len => {
                try st.pop(.arrayref);
                try st.push(.i32);
            },
            .array_copy => |ac| {
                const dst = try self.arrayElem(ac.dst);
                _ = try self.arrayElem(ac.src);
                if (!dst.mutable) return self.fail("an array.copy into an immutable array");
                try st.pop(.i32);
                try st.pop(.i32);
                try st.pop(ValType.def(ac.src));
                try st.pop(.i32);
                try st.pop(ValType.def(ac.dst));
            },
            .array_fill => |k| {
                const el = try self.arrayElem(k);
                try st.pop(.i32);
                try st.pop(unpacked(el.ty));
                try st.pop(.i32);
                try st.pop(ValType.def(k));
            },
            .ref_null => |t| try st.push(t),
            .ref_is_null => {
                try st.popRef();
                try st.push(.i32);
            },
            .ref_eq => {
                try st.pop(.eqref);
                try st.pop(.eqref);
                try st.push(.i32);
            },
            .ref_as_non_null => {
                const t = try st.popSlot();
                if (t) |x| if (!x.isRef()) return self.fail("ref.as_non_null of a number");
                try st.items.append(self.arena, t);
            },
            .ref_test => {
                try st.popRef();
                try st.push(.i32);
            },
            .ref_cast => |t| {
                try st.popRef();
                try st.push(t);
            },
            .ref_i31 => {
                try st.pop(.i32);
                try st.push(.i31ref);
            },
            .i31_get => {
                try st.pop(.i31ref);
                try st.push(.i32);
            },
        }
    }

    fn callType(self: *FuncCtx, st: *Stack, ft: ast.FuncType) Error!void {
        _ = self;
        var i = ft.params.len;
        while (i > 0) {
            i -= 1;
            try st.pop(ft.params[i]);
        }
        if (ft.result) |r| try st.push(r);
    }

    fn stepOp(self: *FuncCtx, st: *Stack, o: ast.Instr.Op) Error!void {
        const t = o.ty;
        switch (opShape(o.name)) {
            .binary => {
                try st.pop(t);
                try st.pop(t);
                try st.push(t);
            },
            .compare => {
                try st.pop(t);
                try st.pop(t);
                try st.push(.i32);
            },
            .test_ => {
                try st.pop(t);
                try st.push(.i32);
            },
            .unary => {
                try st.pop(t);
                try st.push(t);
            },
            .unknown => return self.unsupported("an operator it does not know"),
        }
    }

    fn structFields(self: *FuncCtx, k: u16) Error![]const ast.Field {
        if (k >= self.mod.types.len) return self.fail("a type index past the group");
        return switch (self.mod.types[k].kind) {
            .@"struct" => |fs| fs,
            .array => self.fail("a struct instruction on an array type"),
        };
    }

    fn arrayElem(self: *FuncCtx, k: u16) Error!ast.Field {
        if (k >= self.mod.types.len) return self.fail("a type index past the group");
        return switch (self.mod.types[k].kind) {
            .array => |f| f,
            .@"struct" => self.fail("an array instruction on a struct type"),
        };
    }
};

const Stack = struct {
    fc: *FuncCtx,
    items: std.ArrayListUnmanaged(Slot) = .empty,
    /// Below a branch: an empty stack answers any pop.
    poly: bool = false,

    fn push(st: *Stack, t: ValType) Error!void {
        try st.items.append(st.fc.arena, t);
    }

    fn popSlot(st: *Stack) Error!Slot {
        if (st.items.items.len == 0) {
            if (st.poly) return null;
            return st.fc.fail("a pop of an empty stack");
        }
        return st.items.pop().?;
    }

    fn pop(st: *Stack, want: ValType) Error!void {
        const got = try st.popSlot() orelse return;
        if (!subtype(st.fc.mod.types, got, want)) {
            st.fc.diag.got = @intFromEnum(got);
            st.fc.diag.want = @intFromEnum(want);
            return st.fc.fail("a value of another type");
        }
    }

    fn popAny(st: *Stack) Error!void {
        _ = try st.popSlot();
    }

    fn popRef(st: *Stack) Error!void {
        const got = try st.popSlot() orelse return;
        if (!got.isRef()) return st.fc.fail("a number where a reference was taken");
    }

    fn unreachable_(st: *Stack) void {
        st.items.clearRetainingCapacity();
        st.poly = true;
    }
};

fn sameOpt(a: ?ValType, b: ?ValType) bool {
    if (a == null or b == null) return a == null and b == null;
    return a.? == b.?;
}

/// The value a packed field or element reads as: an `i32`.
fn unpacked(t: ValType) ValType {
    return if (t.isPacked()) .i32 else t;
}

/// Whether a value of `a` is one of `b`. Nullability is not tracked: every
/// reference this backend declares is nullable.
pub fn subtype(types: []const ast.TypeDef, a: ValType, b: ValType) bool {
    if (a == b) return true;
    if (!a.isRef() or !b.isRef()) return false;
    // A declared subtype (`$box_bool` of `$box_i32`): up its supertypes.
    if (a.defIndex()) |k0| if (b.defIndex()) |kb| {
        var k = k0;
        while (k < types.len) {
            if (k == kb) return true;
            k = types[k].super orelse break;
        }
        return false;
    };
    const kind: ?ast.TypeDef.Kind = if (a.defIndex()) |k| (if (k < types.len) types[k].kind else null) else null;
    return switch (b) {
        .anyref => a != .funcref and a != .externref,
        .eqref => a == .i31ref or a == .structref or a == .arrayref or kind != null,
        .structref => kind != null and kind.? == .@"struct",
        .arrayref => kind != null and kind.? == .array,
        else => false,
    };
}

const OpShape = enum { binary, compare, test_, unary, unknown };

fn opShape(name: []const u8) OpShape {
    const binary = [_][]const u8{ "add", "sub", "mul", "div", "div_s", "div_u", "rem_s", "rem_u", "and", "or", "xor", "shl", "shr_s", "shr_u", "rotl", "rotr", "min", "max", "copysign" };
    const compare = [_][]const u8{ "eq", "ne", "lt", "lt_s", "lt_u", "gt", "gt_s", "gt_u", "le", "le_s", "le_u", "ge", "ge_s", "ge_u" };
    const unary = [_][]const u8{ "clz", "ctz", "popcnt", "neg", "abs", "sqrt", "ceil", "floor", "trunc", "nearest", "extend8_s", "extend16_s", "extend32_s" };
    for (binary) |n| if (std.mem.eql(u8, n, name)) return .binary;
    for (compare) |n| if (std.mem.eql(u8, n, name)) return .compare;
    for (unary) |n| if (std.mem.eql(u8, n, name)) return .unary;
    if (std.mem.eql(u8, name, "eqz")) return .test_;
    return .unknown;
}

/// The operand and result types of a fully-spelled conversion opcode
/// (`f64.convert_i32_s`: an `i32` into an `f64`).
fn convertTypes(opcode: []const u8) ?struct { from: ValType, to: ValType } {
    const dot = std.mem.indexOfScalar(u8, opcode, '.') orelse return null;
    const to = numType(opcode[0..dot]) orelse return null;
    const rest = opcode[dot + 1 ..];
    var i: usize = 0;
    while (i + 3 <= rest.len) : (i += 1) {
        if (i > 0 and rest[i - 1] != '_') continue;
        if (numType(rest[i .. i + 3])) |from| return .{ .from = from, .to = to };
    }
    return null;
}

fn numType(s: []const u8) ?ValType {
    if (std.mem.eql(u8, s, "i32")) return .i32;
    if (std.mem.eql(u8, s, "i64")) return .i64;
    if (std.mem.eql(u8, s, "f32")) return .f32;
    if (std.mem.eql(u8, s, "f64")) return .f64;
    return null;
}

test "typecheck: the conversion opcodes name their operand" {
    const c = convertTypes("f64.convert_i32_s").?;
    try std.testing.expectEqual(ValType.i32, c.from);
    try std.testing.expectEqual(ValType.f64, c.to);
    try std.testing.expectEqual(ValType.i64, convertTypes("i32.wrap_i64").?.from);
    try std.testing.expectEqual(ValType.f64, convertTypes("i64.trunc_sat_f64_s").?.from);
    try std.testing.expectEqual(ValType.f32, convertTypes("f64.promote_f32").?.from);
}

fn noSkip(_: []const u8) bool {
    return false;
}

test "typecheck: a string taken as a word fails, the same body over its own type passes" {
    const str: ValType = .def(0);
    const types = [_]ast.TypeDef{.{ .name = "str", .kind = .{ .array = .{ .ty = .i8, .mutable = true } } }};
    const good = [_]ast.Line{ .{ .instr = .{ .local_get = "s" } }, .{ .instr = .array_len } };
    const bad = [_]ast.Line{ .{ .instr = .{ .local_get = "s" } }, .{ .instr = .{ .@"const" = .{ .ty = .i32, .text = "1" } } }, .{ .instr = .{ .op = .{ .ty = .i32, .name = "add" } } } };
    const params = [_]ast.Param{.{ .name = "s", .ty = str }};
    var diag: Diag = .{};
    const ok_items = [_]ast.Item{ .{ .types = &types }, .{ .func = .{ .name = "f", .params = &params, .result = .i32, .body = .{ .lines = &good, .stack = .{ .value = .i32 } } } } };
    try checkModule(std.testing.allocator, .{ .items = &ok_items }, noSkip, &diag);
    const bad_items = [_]ast.Item{ .{ .types = &types }, .{ .func = .{ .name = "f", .params = &params, .result = .i32, .body = .{ .lines = &bad, .stack = .{ .value = .i32 } } } } };
    try std.testing.expectError(error.Mismatch, checkModule(std.testing.allocator, .{ .items = &bad_items }, noSkip, &diag));
}
