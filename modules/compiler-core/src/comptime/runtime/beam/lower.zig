//! Erlang (a generated comptime module, as `../wat/erl_parse.zig` reads it) →
//! BEAM instructions in `codegen/beam/beam_file.zig`'s model.
//!
//! Front 14 step 3 / front 18 step 1b: a comptime body reaches the resident
//! node as `.beam` bytes this file's output assembles to, not as `.erl` source
//! `compile:file` compiles. The input is **the program the other two paths
//! run** — the Erlang `codegen/erlang.zig`'s untyped mode lowered the botopink
//! body to, which the wat runtime lowers too — so what a comptime body means is
//! still decided in one place, and the three answers can differ only where a
//! construct is implemented three times.
//!
//! The code shape is deliberately simple, not optimised — the body runs in
//! well under a millisecond, and what is being removed is the Erlang
//! compiler's time:
//!
//!   * every variable and every intermediate value lives in a **Y register**
//!     of the function's frame; an expression's value is an operand that is a
//!     Y register or a literal, never an X register. So a call — which kills
//!     every X register — never has to save anything, and a heap allocation
//!     (`test_heap Need, 0`) never has a live X register to keep;
//!   * X registers carry only a call's arguments, a test's operands and the
//!     result the next instruction moves into a Y register;
//!   * the frame is `allocate N` + `init_yregs` of all N at entry, so the
//!     garbage collector never sees an uninitialised slot;
//!   * a list comprehension is an in-line loop (cons onto an accumulator,
//!     `lists:reverse/1` at the end); a `fun` is lifted to a function whose
//!     extra parameters are its captured variables (`make_fun3`); a named
//!     `fun` calls itself directly, so a recursive loop is a tail call;
//!   * a call in tail position is `call_last`/`call_ext_last`.
//!
//! Errors are the BEAM's own: a failed match is `badmatch`, a `case` with no
//! clause `case_end`, a function with no clause jumps to its `func_info`, an
//! operator is `erlang:'+'/2` and friends through `call_ext`, a guard BIF is a
//! `bif`/`gc_bif` with the guard's fail label. `main/1` catches `Class:Reason`
//! and renders it without a stack, so the replies are the `.erl` path's.
//!
//! Decision 86: only opcodes stable since OTP 24. The one construct that has
//! no such opcode is building a binary from computed segments (`bs_create_bin`
//! is OTP 25; the older `bs_init2` family is obsolete in OTP 28), so a
//! computed binary is built by `erlang:iolist_to_binary/1` over its checked
//! segments — each segment tested as the segment type would test it, a
//! mismatch raising `badarg` as the segment would.
//!
//! What it cannot lower it **refuses** by name (`error.Unsupported`,
//! `Failure.message`): the evaluator then runs that declaration from Erlang
//! source — the counted, visible fallback of decision 67 — instead of loading
//! code that might mean something else.
const std = @import("std");
const ep = @import("../wat/erl_parse.zig");
const bf = @import("../../../codegen/beam/beam_file.zig");
const Term = @import("../../../codegen/beam/term.zig").Term;

pub const Error = error{ OutOfMemory, Unsupported };

pub const Failure = struct {
    message: []const u8 = "",
};

const Arg = bf.Arg;
const Instr = bf.Instr;
const Op = bf.Op;

// ── slot encoding ────────────────────────────────────────────────────────────
//
// While a function is compiled its Y registers are numbered in three spaces —
// variables, temporaries, `try` tags — and renumbered when its frame size is
// known (`Fn.finish`). The frame size itself is a placeholder operand until
// then.

const temp_space: u32 = 1 << 29;
const tag_space: u32 = 1 << 30;
const frame_placeholder: u64 = std.math.maxInt(u64) - 7;

fn frameArg() Arg {
    return .{ .u = frame_placeholder };
}

// ── the BIF tables ───────────────────────────────────────────────────────────

/// Erlang's auto-imported functions (`erl_internal:bif/2`): a bare call to one
/// of these that the module does not define is `erlang:<name>`.
const auto_imported = std.StaticStringMap(void).initComptime(.{
    .{"abs/1"},                      .{"alias/0"},                    .{"alias/1"},                  .{"apply/2"},              .{"apply/3"},
    .{"atom_to_binary/1"},           .{"atom_to_binary/2"},           .{"atom_to_list/1"},           .{"binary_part/2"},        .{"binary_part/3"},
    .{"binary_to_atom/1"},           .{"binary_to_atom/2"},           .{"binary_to_existing_atom/1"}, .{"binary_to_existing_atom/2"}, .{"binary_to_float/1"},
    .{"binary_to_integer/1"},        .{"binary_to_integer/2"},        .{"binary_to_list/1"},         .{"binary_to_list/3"},     .{"binary_to_term/1"},
    .{"binary_to_term/2"},           .{"bit_size/1"},                 .{"bitstring_to_list/1"},      .{"byte_size/1"},          .{"ceil/1"},
    .{"date/0"},                     .{"element/2"},                  .{"erase/0"},                  .{"erase/1"},              .{"error/1"},
    .{"error/2"},                    .{"error/3"},                    .{"exit/1"},                   .{"exit/2"},               .{"float/1"},
    .{"float_to_binary/1"},          .{"float_to_binary/2"},          .{"float_to_list/1"},          .{"float_to_list/2"},      .{"floor/1"},
    .{"get/0"},                      .{"get/1"},                      .{"get_keys/0"},               .{"get_keys/1"},           .{"group_leader/0"},
    .{"hd/1"},                       .{"integer_to_binary/1"},        .{"integer_to_binary/2"},      .{"integer_to_list/1"},    .{"integer_to_list/2"},
    .{"iolist_size/1"},              .{"iolist_to_binary/1"},         .{"is_atom/1"},                .{"is_binary/1"},          .{"is_bitstring/1"},
    .{"is_boolean/1"},               .{"is_float/1"},                 .{"is_function/1"},            .{"is_function/2"},        .{"is_integer/1"},
    .{"is_list/1"},                  .{"is_map/1"},                   .{"is_map_key/2"},             .{"is_number/1"},          .{"is_pid/1"},
    .{"is_port/1"},                  .{"is_reference/1"},             .{"is_tuple/1"},               .{"length/1"},             .{"list_to_atom/1"},
    .{"list_to_binary/1"},           .{"list_to_bitstring/1"},        .{"list_to_existing_atom/1"},  .{"list_to_float/1"},      .{"list_to_integer/1"},
    .{"list_to_integer/2"},          .{"list_to_tuple/1"},            .{"make_ref/0"},               .{"map_get/2"},            .{"map_size/1"},
    .{"max/2"},                      .{"min/2"},                      .{"node/0"},                   .{"node/1"},               .{"put/2"},
    .{"round/1"},                    .{"self/0"},                     .{"setelement/3"},             .{"size/1"},               .{"split_binary/2"},
    .{"term_to_binary/1"},           .{"term_to_binary/2"},           .{"throw/1"},                  .{"time/0"},               .{"tl/1"},
    .{"trunc/1"},                    .{"tuple_size/1"},               .{"tuple_to_list/1"},          .{"spawn/1"},              .{"spawn/3"},
    .{"process_flag/2"},             .{"whereis/1"},                  .{"is_process_alive/1"},       .{"statistics/1"},         .{"nodes/0"},
});

/// Guard BIFs (`erl_internal:guard_bif/2`), each marked with whether it can
/// allocate (a `gc_bif`) or not (a `bif`) — the split `beam_ssa_codegen`
/// makes: type tests, `element`, `hd`, `tl`, `self`, `node`, `tuple_size`,
/// `map_get`, `is_map_key` do not collect.
const GuardBif = struct { gc: bool };
const guard_bifs = std.StaticStringMap(GuardBif).initComptime(.{
    .{ "abs/1", GuardBif{ .gc = true } },           .{ "binary_part/2", GuardBif{ .gc = true } }, .{ "binary_part/3", GuardBif{ .gc = true } },
    .{ "bit_size/1", GuardBif{ .gc = true } },      .{ "byte_size/1", GuardBif{ .gc = true } },   .{ "ceil/1", GuardBif{ .gc = true } },
    .{ "element/2", GuardBif{ .gc = false } },      .{ "float/1", GuardBif{ .gc = true } },       .{ "floor/1", GuardBif{ .gc = true } },
    .{ "hd/1", GuardBif{ .gc = false } },           .{ "length/1", GuardBif{ .gc = true } },      .{ "map_get/2", GuardBif{ .gc = false } },
    .{ "is_map_key/2", GuardBif{ .gc = false } },   .{ "map_size/1", GuardBif{ .gc = true } },    .{ "max/2", GuardBif{ .gc = true } },
    .{ "min/2", GuardBif{ .gc = true } },           .{ "node/0", GuardBif{ .gc = false } },       .{ "node/1", GuardBif{ .gc = false } },
    .{ "round/1", GuardBif{ .gc = true } },         .{ "self/0", GuardBif{ .gc = false } },       .{ "size/1", GuardBif{ .gc = true } },
    .{ "tl/1", GuardBif{ .gc = false } },           .{ "trunc/1", GuardBif{ .gc = true } },       .{ "tuple_size/1", GuardBif{ .gc = false } },
    // the operators a guard may apply
    .{ "+/2", GuardBif{ .gc = true } },             .{ "-/2", GuardBif{ .gc = true } },           .{ "*/2", GuardBif{ .gc = true } },
    .{ "//2", GuardBif{ .gc = true } },             .{ "div/2", GuardBif{ .gc = true } },         .{ "rem/2", GuardBif{ .gc = true } },
    .{ "band/2", GuardBif{ .gc = true } },          .{ "bor/2", GuardBif{ .gc = true } },         .{ "bxor/2", GuardBif{ .gc = true } },
    .{ "bsl/2", GuardBif{ .gc = true } },           .{ "bsr/2", GuardBif{ .gc = true } },         .{ "-/1", GuardBif{ .gc = true } },
    .{ "+/1", GuardBif{ .gc = true } },             .{ "bnot/1", GuardBif{ .gc = true } },
    .{ "not/1", GuardBif{ .gc = false } },          .{ "and/2", GuardBif{ .gc = false } },        .{ "or/2", GuardBif{ .gc = false } },
    .{ "xor/2", GuardBif{ .gc = false } },          .{ "==/2", GuardBif{ .gc = false } },         .{ "/=/2", GuardBif{ .gc = false } },
    .{ "=</2", GuardBif{ .gc = false } },           .{ "</2", GuardBif{ .gc = false } },          .{ ">=/2", GuardBif{ .gc = false } },
    .{ ">/2", GuardBif{ .gc = false } },            .{ "=:=/2", GuardBif{ .gc = false } },        .{ "=/=/2", GuardBif{ .gc = false } },
    .{ "is_atom/1", GuardBif{ .gc = false } },      .{ "is_binary/1", GuardBif{ .gc = false } },  .{ "is_bitstring/1", GuardBif{ .gc = false } },
    .{ "is_boolean/1", GuardBif{ .gc = false } },   .{ "is_float/1", GuardBif{ .gc = false } },   .{ "is_function/1", GuardBif{ .gc = false } },
    .{ "is_function/2", GuardBif{ .gc = false } },  .{ "is_integer/1", GuardBif{ .gc = false } }, .{ "is_list/1", GuardBif{ .gc = false } },
    .{ "is_map/1", GuardBif{ .gc = false } },       .{ "is_number/1", GuardBif{ .gc = false } },  .{ "is_pid/1", GuardBif{ .gc = false } },
    .{ "is_port/1", GuardBif{ .gc = false } },      .{ "is_reference/1", GuardBif{ .gc = false } }, .{ "is_tuple/1", GuardBif{ .gc = false } },
});

/// A type test and the test instruction that performs it.
const type_tests = std.StaticStringMap(Op).initComptime(.{
    .{ "is_atom", .is_atom },         .{ "is_binary", .is_binary }, .{ "is_bitstring", .is_bitstr },   .{ "is_boolean", .is_boolean },
    .{ "is_float", .is_float },       .{ "is_function", .is_function }, .{ "is_integer", .is_integer }, .{ "is_list", .is_list },
    .{ "is_map", .is_map },           .{ "is_number", .is_number }, .{ "is_pid", .is_pid },             .{ "is_port", .is_port },
    .{ "is_reference", .is_reference }, .{ "is_tuple", .is_tuple },
});

const Comparison = struct { op: Op, swap: bool };
const comparisons = std.StaticStringMap(Comparison).initComptime(.{
    .{ "<", Comparison{ .op = .is_lt, .swap = false } },
    .{ ">", Comparison{ .op = .is_lt, .swap = true } },
    .{ ">=", Comparison{ .op = .is_ge, .swap = false } },
    .{ "=<", Comparison{ .op = .is_ge, .swap = true } },
    .{ "==", Comparison{ .op = .is_eq, .swap = false } },
    .{ "/=", Comparison{ .op = .is_ne, .swap = false } },
    .{ "=:=", Comparison{ .op = .is_eq_exact, .swap = false } },
    .{ "=/=", Comparison{ .op = .is_ne_exact, .swap = false } },
});

/// The binary operators a body applies through `call_ext erlang:<op>/2`.
const body_binops = std.StaticStringMap(void).initComptime(.{
    .{"+"},  .{"-"},  .{"*"},   .{"/"},   .{"div"}, .{"rem"}, .{"band"}, .{"bor"}, .{"bxor"}, .{"bsl"}, .{"bsr"},
    .{"and"}, .{"or"}, .{"xor"}, .{"=="}, .{"/="},  .{"=<"},  .{"<"},    .{">="},  .{">"},    .{"=:="}, .{"=/="},
    .{"++"}, .{"--"},
});

// ── the lowerer ──────────────────────────────────────────────────────────────

pub const Output = struct {
    module: bf.Module,
};

const FnKey = struct { name: []const u8, arity: usize };

const Local = struct {
    entry: u32,
    info: u32,
};

const Lowerer = struct {
    ar: std.mem.Allocator,
    mod: ep.Module,
    name: []const u8,
    failure: *Failure,
    next_label: u32 = 1,
    functions: std.ArrayListUnmanaged(bf.Function) = .empty,
    locals: std.StringHashMapUnmanaged(Local) = .empty,
    imports: std.StringHashMapUnmanaged([]const u8) = .empty,
    lambda_count: usize = 0,
    key_buf: [300]u8 = undefined,
    /// Where a refusal happened, for its message.
    where: []const u8 = "",

    fn refuse(l: *Lowerer, comptime fmt: []const u8, args: anytype) Error {
        const what = try std.fmt.allocPrint(l.ar, fmt, args);
        l.failure.message = try std.fmt.allocPrint(l.ar, "{s} (in {s})", .{ what, l.where });
        return error.Unsupported;
    }

    fn label(l: *Lowerer) u32 {
        const n = l.next_label;
        l.next_label += 1;
        return n;
    }

    /// `name/arity` in a scratch buffer — for a lookup only; a key that is
    /// stored is `ownedKey`.
    fn key(l: *Lowerer, name: []const u8, arity: usize) Error![]const u8 {
        return std.fmt.bufPrint(&l.key_buf, "{s}/{d}", .{ name, arity }) catch l.ownedKey(name, arity);
    }

    fn ownedKey(l: *Lowerer, name: []const u8, arity: usize) Error![]const u8 {
        return std.fmt.allocPrint(l.ar, "{s}/{d}", .{ name, arity });
    }
};

const Change = struct { name: []const u8, added: bool };

const CatchStack = struct { slot: Arg, vars: []const ?[]const u8 };

/// The named `fun` a lifted function is, so a call of the name is a direct
/// (tail) call of the function rather than a `call_fun` through the value.
const SelfFun = struct {
    name: []const u8,
    arity: usize,
    entry: u32,
    free: []const []const u8,
};

const Fn = struct {
    l: *Lowerer,
    code: std.ArrayListUnmanaged(Instr) = .empty,
    /// Variable name → its slot in the variable space.
    vars: std.StringHashMapUnmanaged(u32) = .empty,
    /// A function-head variable is its argument's slot, not a copy of it
    /// (the argument slots are never reused). Per clause.
    aliases: std.StringHashMapUnmanaged(Arg) = .empty,
    /// The variables bound at this point of the code, and the trail of every
    /// change to it — a branch point saves the trail's length and undoes back
    /// to it, instead of copying the set (a large body has hundreds of
    /// variables and hundreds of clauses).
    bound: std.StringHashMapUnmanaged(void) = .empty,
    trail: std.ArrayListUnmanaged(Change) = .empty,
    n_vars: u32 = 0,
    temp_top: u32 = 0,
    temp_max: u32 = 0,
    tag_depth: u32 = 0,
    tag_max: u32 = 0,
    /// Set by `headClauses` for the one `clausesValue` that matches a
    /// function's arguments.
    head: bool = false,
    arity: u32,
    self_fun: ?SelfFun = null,
    /// Set for the one `clausesValue` that matches a `try`'s catch clauses:
    /// the raw stack's slot and, per clause, the variable its `:Stack` binds.
    catch_stack: ?CatchStack = null,

    fn ar(f: *Fn) std.mem.Allocator {
        return f.l.ar;
    }

    fn emit(f: *Fn, op: Op, args: []const Arg) Error!void {
        try f.code.append(f.ar(), .{ .op = op, .args = try f.ar().dupe(Arg, args) });
    }

    fn label(f: *Fn, n: u32) Error!void {
        try f.emit(.label, &.{Arg.uint(n)});
    }

    fn jump(f: *Fn, n: u32) Error!void {
        try f.emit(.jump, &.{Arg.lbl(n)});
    }

    fn move(f: *Fn, src: Arg, dst: Arg) Error!void {
        if (std.meta.eql(src, dst)) return;
        try f.emit(.move, &.{ src, dst });
    }

    /// Reset the temporaries to `mark` and move x0 into a fresh one: the value
    /// of an operation whose operands (temporaries at or above `mark`) are
    /// already consumed.
    fn resultOf(f: *Fn, mark: u32) Error!Arg {
        f.temp_top = mark;
        const r = f.temp();
        try f.move(Arg.xr(0), r);
        return r;
    }

    /// An operand that stays valid across the code that follows. An
    /// expression's value already is (a literal or a Y register); this only
    /// guards against an X register reaching a caller that keeps it.
    fn stable(f: *Fn, v: Arg) Error!Arg {
        if (v != .x) return v;
        const t = f.temp();
        try f.move(v, t);
        return t;
    }

    fn temp(f: *Fn) Arg {
        const n = f.temp_top;
        f.temp_top += 1;
        f.temp_max = @max(f.temp_max, f.temp_top);
        return Arg.yr(temp_space + n);
    }

    fn varSlot(f: *Fn, name: []const u8) Error!Arg {
        if (f.aliases.get(name)) |a| return a;
        const gop = try f.vars.getOrPut(f.ar(), name);
        if (!gop.found_existing) {
            gop.value_ptr.* = f.n_vars;
            f.n_vars += 1;
        }
        return Arg.yr(gop.value_ptr.*);
    }

    /// A fresh slot for `name` — a shadowing binding (a generator pattern).
    fn freshVar(f: *Fn, name: []const u8) Error!void {
        try f.vars.put(f.ar(), name, f.n_vars);
        f.n_vars += 1;
        try f.unsetBound(name);
        _ = f.aliases.remove(name);
    }

    fn isBound(f: *Fn, name: []const u8) bool {
        return f.bound.contains(name);
    }

    fn bind(f: *Fn, name: []const u8) Error!Arg {
        try f.setBound(name);
        return f.varSlot(name);
    }

    fn setBound(f: *Fn, name: []const u8) Error!void {
        const gop = try f.bound.getOrPut(f.ar(), name);
        if (!gop.found_existing) try f.trail.append(f.ar(), .{ .name = name, .added = true });
    }

    fn unsetBound(f: *Fn, name: []const u8) Error!void {
        if (f.bound.remove(name)) try f.trail.append(f.ar(), .{ .name = name, .added = false });
    }

    /// Undo every change to `bound` made since the trail was `mark` long.
    fn restoreBound(f: *Fn, mark: usize) Error!void {
        while (f.trail.items.len > mark) {
            const c = f.trail.pop().?;
            if (c.added) {
                _ = f.bound.remove(c.name);
            } else {
                try f.bound.put(f.ar(), c.name, {});
            }
        }
    }

    /// Raise `erlang:error(Reason)` where `Reason` is `{Tag, Value}`.
    fn raiseTagged(f: *Fn, tag: []const u8, value: Arg) Error!void {
        try f.emit(.test_heap, &.{ Arg.uint(3), Arg.uint(0) });
        try f.emit(.put_tuple2, &.{ Arg.xr(0), Arg.listOf(try f.ar().dupe(Arg, &.{ Arg.atomOf(tag), value })) });
        try f.emit(.call_ext, &.{ Arg.uint(1), Arg.extFn("erlang", "error", 1) });
    }

    fn raiseAtom(f: *Fn, reason: []const u8) Error!void {
        try f.move(Arg.atomOf(reason), Arg.xr(0));
        try f.emit(.call_ext, &.{ Arg.uint(1), Arg.extFn("erlang", "error", 1) });
    }

    /// A call in tail position; the value is the callee's return.
    fn lastCall(f: *Fn, op: Op, args: []const Arg) Error!Arg {
        try f.emit(op, args);
        return Arg.nil;
    }

    /// `move Result → x0; deallocate; return`.
    fn ret(f: *Fn, v: Arg) Error!void {
        try f.move(v, Arg.xr(0));
        try f.emit(.deallocate, &.{frameArg()});
        try f.emit(.@"return", &.{});
    }

    /// Renumber the three slot spaces into one frame, and wrap the body in the
    /// function's `label`/`func_info`/`label`/`allocate` prologue.
    fn finish(f: *Fn, name: []const u8, info: u32, entry: u32, exported: bool) Error!bf.Function {
        const ar_ = f.ar();
        const frame: u32 = f.n_vars + f.temp_max + f.tag_max;
        var out: std.ArrayListUnmanaged(Instr) = .empty;
        try out.append(ar_, Instr.of(.label, try ar_.dupe(Arg, &.{Arg.uint(info)})));
        try out.append(ar_, Instr.of(.func_info, try ar_.dupe(Arg, &.{ Arg.atomOf(f.l.name), Arg.atomOf(name), Arg.uint(f.arity) })));
        try out.append(ar_, Instr.of(.label, try ar_.dupe(Arg, &.{Arg.uint(entry)})));
        try out.append(ar_, Instr.of(.allocate, try ar_.dupe(Arg, &.{ Arg.uint(frame), Arg.uint(f.arity) })));
        if (frame > 0) {
            const regs = try ar_.alloc(Arg, frame);
            for (regs, 0..) |*r, i| r.* = Arg.yr(i);
            try out.append(ar_, Instr.of(.init_yregs, try ar_.dupe(Arg, &.{Arg.listOf(regs)})));
        }
        var body_code: std.ArrayListUnmanaged(Instr) = .empty;
        for (f.code.items) |ins| {
            const args = try ar_.dupe(Arg, ins.args);
            for (args) |*a| a.* = try f.renumber(a.*, frame);
            try body_code.append(ar_, .{ .op = ins.op, .args = args });
        }
        try out.appendSlice(ar_, try prune(ar_, body_code.items));
        return .{ .name = name, .arity = f.arity, .entry = entry, .exported = exported, .code = out.items };
    }

    fn renumber(f: *Fn, a: Arg, frame: u32) Error!Arg {
        return switch (a) {
            // A nested `try` takes a lower slot than the one it is inside:
            // catch tags must nest downwards on the stack (`beam_validator`'s
            // `bad_try_catch_nesting`; the emulator's catch search assumes it).
            .y => |n| Arg.yr(if (n >= tag_space)
                f.n_vars + f.temp_max + (f.tag_max - 1 - (n - tag_space))
            else if (n >= temp_space)
                f.n_vars + (n - temp_space)
            else
                n),
            .u => |n| if (n == frame_placeholder) Arg.uint(frame) else a,
            .list => |items| blk: {
                const out = try f.ar().alloc(Arg, items.len);
                for (items, 0..) |it, i| out[i] = try f.renumber(it, frame);
                break :blk Arg.listOf(out);
            },
            else => a,
        };
    }
};

// ── dead code ────────────────────────────────────────────────────────────────

/// Whether control never falls through `ins` to the next instruction.
fn isTerminal(ins: Instr) bool {
    return switch (ins.op) {
        .@"return", .jump, .call_last, .call_ext_last, .call_only, .call_ext_only, .raw_raise, .case_end, .badmatch, .if_end, .try_case_end => true,
        .call_ext => blk: {
            const e = ins.args[1].ext;
            if (!std.mem.eql(u8, e.module, "erlang")) break :blk false;
            break :blk std.mem.eql(u8, e.function, "error") or std.mem.eql(u8, e.function, "throw") or std.mem.eql(u8, e.function, "exit");
        },
        else => false,
    };
}

fn collectRefs(ar: std.mem.Allocator, a: Arg, refs: *std.AutoHashMapUnmanaged(u32, void)) Error!void {
    switch (a) {
        .f => |n| if (n != 0) try refs.put(ar, n, {}),
        .list => |items| for (items) |it| try collectRefs(ar, it, refs),
        else => {},
    }
}

/// Drop the code no path reaches (after a terminal instruction, up to the next
/// label something jumps to) and the labels nothing names, until neither
/// changes — the shape `erlc` hands the loader, which refuses some dead
/// sequences a validator would merely skip.
fn prune(ar: std.mem.Allocator, code: []const Instr) Error![]const Instr {
    var cur = code;
    while (true) {
        var refs: std.AutoHashMapUnmanaged(u32, void) = .empty;
        for (cur) |ins| {
            if (ins.op == .label) continue;
            for (ins.args) |a| try collectRefs(ar, a, &refs);
        }
        var out: std.ArrayListUnmanaged(Instr) = .empty;
        var live = true;
        for (cur) |ins| {
            if (ins.op == .label) {
                if (!refs.contains(@intCast(ins.args[0].u))) continue;
                live = true;
                try out.append(ar, ins);
                continue;
            }
            if (!live) continue;
            try out.append(ar, ins);
            if (isTerminal(ins)) live = false;
        }
        if (out.items.len == cur.len) return out.items;
        cur = out.items;
    }
}

// ── constants ────────────────────────────────────────────────────────────────

/// Whether `e` is a constant — `constTerm` without building the term, so a
/// large non-constant tree is not rebuilt at every level it is visited from.
fn isConst(e: ep.Expr) bool {
    return switch (e) {
        .atom, .int, .float, .string => true,
        .binary => |segs| for (segs) |sg| {
            if (sg.size != null or sg.types.len > 1) break false;
            switch (sg.value) {
                .string, .int => {},
                else => break false,
            }
        } else true,
        .tuple => |items| for (items) |it| {
            if (!isConst(it)) break false;
        } else true,
        .list => |l| l.tail == null and for (l.items) |it| {
            if (!isConst(it)) break false;
        } else true,
        .map => |m| m.base == null and for (m.fields) |fl| {
            if (fl.exact or !isConst(fl.key) or !isConst(fl.value)) break false;
        } else true,
        else => false,
    };
}

/// The term `e` denotes when it is a constant, or null.
fn constTerm(ar: std.mem.Allocator, e: ep.Expr) Error!?Term {
    if (!isConst(e)) return null;
    return switch (e) {
        .atom => |a| Term.atomOf(a),
        .int => |n| Term.int(n),
        .float => |x| Term{ .float = x },
        .string => |cps| blk: {
            if (cps.len == 0) break :blk Term.nil;
            const items = try ar.alloc(Term, cps.len);
            for (cps, 0..) |cp, i| items[i] = Term.int(cp);
            break :blk Term.listOf(items);
        },
        .binary => |segs| if (try literalBinary(ar, segs)) |bytes| Term.str(bytes) else null,
        .tuple => |items| blk: {
            const out = try ar.alloc(Term, items.len);
            for (items, 0..) |it, i| out[i] = (try constTerm(ar, it)) orelse break :blk null;
            break :blk Term.tupleOf(out);
        },
        .list => |l| blk: {
            if (l.tail != null) break :blk null;
            if (l.items.len == 0) break :blk Term.nil;
            const out = try ar.alloc(Term, l.items.len);
            for (l.items, 0..) |it, i| out[i] = (try constTerm(ar, it)) orelse break :blk null;
            break :blk Term.listOf(out);
        },
        .map => |m| blk: {
            if (m.base != null) break :blk null;
            const out = try ar.alloc(Term.MapEntry, m.fields.len);
            for (m.fields, 0..) |fl, i| {
                if (fl.exact) break :blk null;
                const k = (try constTerm(ar, fl.key)) orelse break :blk null;
                const v = (try constTerm(ar, fl.value)) orelse break :blk null;
                // A repeated key: the later value wins, as in a construction.
                for (out[0..i]) |*prev| if (termEql(prev.key, k)) break :blk null;
                out[i] = .{ .key = k, .value = v };
            }
            break :blk Term.mapOf(out);
        },
        else => null,
    };
}

fn termEql(a: Term, b: Term) bool {
    if (std.meta.activeTag(a) != std.meta.activeTag(b)) return false;
    return switch (a) {
        .atom => |x| std.mem.eql(u8, x, b.atom),
        .binary => |x| std.mem.eql(u8, x, b.binary),
        .integer => |x| x == b.integer,
        .float => |x| x == b.float,
        .boolean => |x| x == b.boolean,
        .nil => true,
        else => false,
    };
}

/// The bytes of a binary whose every segment is a literal, or null.
fn literalBinary(ar: std.mem.Allocator, segs: []const ep.Segment) Error!?[]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (segs) |s| {
        if (s.size != null) return null;
        const ty: []const u8 = if (s.types.len == 0) "" else if (s.types.len == 1) s.types[0] else return null;
        switch (s.value) {
            .string => |cps| {
                if (std.mem.eql(u8, ty, "utf8")) {
                    for (cps) |cp| {
                        var buf: [4]u8 = undefined;
                        const n = std.unicode.utf8Encode(cp, &buf) catch return null;
                        try out.appendSlice(ar, buf[0..n]);
                    }
                } else if (ty.len == 0 or std.mem.eql(u8, ty, "binary")) {
                    for (cps) |cp| try out.append(ar, @truncate(cp));
                } else return null;
            },
            .int => |n| {
                if (std.mem.eql(u8, ty, "utf8")) {
                    if (n < 0 or n > 0x10FFFF) return null;
                    var buf: [4]u8 = undefined;
                    const k = std.unicode.utf8Encode(@intCast(n), &buf) catch return null;
                    try out.appendSlice(ar, buf[0..k]);
                } else if (ty.len == 0 or std.mem.eql(u8, ty, "integer")) {
                    try out.append(ar, @truncate(@as(u64, @bitCast(n))));
                } else return null;
            },
            else => return null,
        }
    }
    return out.items;
}

// ── expressions ──────────────────────────────────────────────────────────────

/// Compile `e`; its value is a literal or a Y register.
fn expr(f: *Fn, e: ep.Expr) Error!Arg {
    if (try constTerm(f.ar(), e)) |t| return Arg.lit(t);
    const l = f.l;
    switch (e) {
        .variable => |v| {
            if (std.mem.eql(u8, v, "_")) return l.refuse("`_` used as a value", .{});
            if (!f.isBound(v)) return l.refuse("variable `{s}` used before it is bound", .{v});
            return f.varSlot(v);
        },
        .atom, .int, .float, .string => unreachable,
        .binary => |segs| return binary(f, segs),
        .tuple => |items| {
            const mark = f.temp_top;
            const vals = try f.ar().alloc(Arg, items.len);
            for (items, 0..) |it, i| vals[i] = try expr(f, it);
            try f.emit(.test_heap, &.{ Arg.uint(items.len + 1), Arg.uint(0) });
            try f.emit(.put_tuple2, &.{ Arg.xr(0), Arg.listOf(vals) });
            return f.resultOf(mark);
        },
        .list => |lst| {
            const mark = f.temp_top;
            const vals = try f.ar().alloc(Arg, lst.items.len);
            for (lst.items, 0..) |it, i| vals[i] = try expr(f, it);
            const tail = if (lst.tail) |t| try expr(f, t.*) else Arg.nil;
            if (vals.len == 0) {
                f.temp_top = mark;
                return tail;
            }
            try f.emit(.test_heap, &.{ Arg.uint(2 * vals.len), Arg.uint(0) });
            var acc = tail;
            var i = vals.len;
            while (i > 0) {
                i -= 1;
                try f.emit(.put_list, &.{ vals[i], acc, Arg.xr(0) });
                acc = Arg.xr(0);
            }
            return f.resultOf(mark);
        },
        .map => |m| return mapExpr(f, m),
        .call => |c| return call(f, c, false),
        .fun_ref => |r| return funRef(f, r),
        .fun => |fun| return lambda(f, fun),
        .binop => |b| return binop(f, b),
        .unop => |u| {
            const mark = f.temp_top;
            const v = try expr(f, u.operand.*);
            const name: []const u8 = if (std.mem.eql(u8, u.op, "-")) "-" else if (std.mem.eql(u8, u.op, "not")) "not" else if (std.mem.eql(u8, u.op, "bnot")) "bnot" else return l.refuse("unary `{s}`", .{u.op});
            try f.move(v, Arg.xr(0));
            try f.emit(.call_ext, &.{ Arg.uint(1), Arg.extFn("erlang", name, 1) });
            return f.resultOf(mark);
        },
        .match => |m| {
            const v = try expr(f, m.value.*);
            const subject = try f.stable(v);
            const fail = l.label();
            const ok = l.label();
            try pattern(f, m.pattern.*, subject, fail);
            try f.jump(ok);
            try f.label(fail);
            try f.move(subject, Arg.xr(0));
            try f.emit(.badmatch, &.{Arg.xr(0)});
            try f.label(ok);
            return subject;
        },
        .case_ => |c| return caseExpr(f, c, false),
        .if_ => |cls| return ifExpr(f, cls, false),
        .try_ => |t| return tryExpr(f, t),
        .block => |b| return body(f, b, false),
        .list_comp => |lc| return listComp(f, lc),
    }
}

/// The sequence `body`: every expression but the last for its effect; the
/// last's value, or — in tail position — a return of it.
fn body(f: *Fn, exprs: []const ep.Expr, tail: bool) Error!Arg {
    if (exprs.len == 0) return f.l.refuse("an empty body", .{});
    for (exprs[0 .. exprs.len - 1]) |e| {
        const mark = f.temp_top;
        _ = try expr(f, e);
        f.temp_top = mark;
    }
    const last = exprs[exprs.len - 1];
    if (tail) {
        try tailExpr(f, last);
        return Arg.nil;
    }
    return expr(f, last);
}

/// `e` in tail position: the code returns its value (or tail-calls).
fn tailExpr(f: *Fn, e: ep.Expr) Error!void {
    switch (e) {
        .call => |c| {
            _ = try call(f, c, true);
            return;
        },
        .case_ => |c| {
            _ = try caseExpr(f, c, true);
            return;
        },
        .if_ => |cls| {
            _ = try ifExpr(f, cls, true);
            return;
        },
        .block => |b| {
            _ = try body(f, b, true);
            return;
        },
        else => {
            const v = try expr(f, e);
            try f.ret(v);
        },
    }
}

// ── binaries ─────────────────────────────────────────────────────────────────

fn binary(f: *Fn, segs: []const ep.Segment) Error!Arg {
    const l = f.l;
    const mark = f.temp_top;
    const parts = try f.ar().alloc(Arg, segs.len);
    const bad = l.label();
    const built = l.label();
    for (segs, 0..) |s, i| {
        if (try literalBinary(f.ar(), &.{s})) |bytes| {
            parts[i] = Arg.lit(Term.str(bytes));
            continue;
        }
        const ty: []const u8 = if (s.types.len == 0) "integer" else s.types[0];
        for (s.types[@min(1, s.types.len)..]) |extra| {
            if (!(std.mem.eql(u8, extra, "unsigned") or std.mem.eql(u8, extra, "big"))) return l.refuse("binary segment type `{s}-{s}`", .{ ty, extra });
        }
        const v = try f.stable(try expr(f, s.value));
        if (std.mem.eql(u8, ty, "binary") or std.mem.eql(u8, ty, "bytes")) {
            if (s.size != null) return l.refuse("a sized /binary segment", .{});
            try f.move(v, Arg.xr(0));
            try f.emit(.is_binary, &.{ Arg.lbl(bad), Arg.xr(0) });
            parts[i] = v;
        } else if (std.mem.eql(u8, ty, "integer")) {
            if (s.size) |sz| switch (sz) {
                .int => |n| if (n != 8) return l.refuse("an integer segment of {d} bits", .{n}),
                else => return l.refuse("a binary segment with a computed size", .{}),
            };
            try f.move(v, Arg.xr(0));
            try f.emit(.is_integer, &.{ Arg.lbl(bad), Arg.xr(0) });
            try f.move(Arg.int(255), Arg.xr(1));
            try f.emit(.call_ext, &.{ Arg.uint(2), Arg.extFn("erlang", "band", 2) });
            const r = f.temp();
            try f.move(Arg.xr(0), r);
            parts[i] = r;
        } else if (std.mem.eql(u8, ty, "utf8")) {
            if (s.size != null) return l.refuse("a sized /utf8 segment", .{});
            try f.move(v, Arg.xr(0));
            try f.emit(.is_integer, &.{ Arg.lbl(bad), Arg.xr(0) });
            try f.emit(.test_heap, &.{ Arg.uint(2), Arg.uint(0) });
            try f.emit(.put_list, &.{ v, Arg.nil, Arg.xr(0) });
            try f.emit(.call_ext, &.{ Arg.uint(1), Arg.extFn("unicode", "characters_to_binary", 1) });
            try f.emit(.is_binary, &.{ Arg.lbl(bad), Arg.xr(0) });
            const r = f.temp();
            try f.move(Arg.xr(0), r);
            parts[i] = r;
        } else return l.refuse("binary segment type `{s}`", .{ty});
    }
    try f.emit(.test_heap, &.{ Arg.uint(2 * parts.len), Arg.uint(0) });
    var acc: Arg = Arg.nil;
    var i = parts.len;
    while (i > 0) {
        i -= 1;
        try f.emit(.put_list, &.{ parts[i], acc, Arg.xr(0) });
        acc = Arg.xr(0);
    }
    try f.emit(.call_ext, &.{ Arg.uint(1), Arg.extFn("erlang", "iolist_to_binary", 1) });
    try f.jump(built);
    // A segment of the wrong type: the `badarg` the construction raises.
    try f.label(bad);
    try f.raiseAtom("badarg");
    try f.label(built);
    return f.resultOf(mark);
}

// ── maps ─────────────────────────────────────────────────────────────────────

fn mapExpr(f: *Fn, m: ep.Expr.MapExpr) Error!Arg {
    const mark = f.temp_top;
    var assoc: std.ArrayListUnmanaged(Arg) = .empty;
    var exact: std.ArrayListUnmanaged(Arg) = .empty;
    const base = if (m.base) |b| try f.stable(try expr(f, b.*)) else Arg.lit(Term.mapOf(&.{}));
    for (m.fields) |fl| {
        if (fl.exact and m.base == null) return f.l.refuse("`:=` in a map construction", .{});
        const k = try f.stable(try expr(f, fl.key));
        const v = try f.stable(try expr(f, fl.value));
        const list = if (fl.exact) &exact else &assoc;
        try list.appendSlice(f.ar(), &.{ k, v });
    }
    try f.move(base, Arg.xr(0));
    if (assoc.items.len > 0) try f.emit(.put_map_assoc, &.{ Arg.lbl(0), Arg.xr(0), Arg.xr(0), Arg.uint(1), Arg.listOf(assoc.items) });
    if (exact.items.len > 0) try f.emit(.put_map_exact, &.{ Arg.lbl(0), Arg.xr(0), Arg.xr(0), Arg.uint(1), Arg.listOf(exact.items) });
    return f.resultOf(mark);
}

// ── operators ────────────────────────────────────────────────────────────────

fn binop(f: *Fn, b: ep.Expr.BinOp) Error!Arg {
    const l = f.l;
    if (std.mem.eql(u8, b.op, "andalso") or std.mem.eql(u8, b.op, "orelse")) return shortCircuit(f, b);
    if (!body_binops.has(b.op)) return l.refuse("operator `{s}`", .{b.op});
    const mark = f.temp_top;
    const lhs = try f.stable(try expr(f, b.lhs.*));
    const rhs = try expr(f, b.rhs.*);
    try f.move(lhs, Arg.xr(0));
    try f.move(rhs, Arg.xr(1));
    try f.emit(.call_ext, &.{ Arg.uint(2), Arg.extFn("erlang", b.op, 2) });
    return f.resultOf(mark);
}

/// `A andalso B` / `A orelse B`: `B` only when `A` does not decide; an `A`
/// that is not a boolean is `{badarg, A}`, and `B` is not checked.
fn shortCircuit(f: *Fn, b: ep.Expr.BinOp) Error!Arg {
    const l = f.l;
    const is_and = std.mem.eql(u8, b.op, "andalso");
    const r = f.temp();
    const mark = f.temp_top;
    const a = try f.stable(try expr(f, b.lhs.*));
    const not_first = l.label();
    const bad = l.label();
    const done = l.label();
    // `andalso` continues on `true`, `orelse` on `false`.
    try f.move(a, Arg.xr(0));
    try f.emit(.is_eq_exact, &.{ Arg.lbl(not_first), Arg.xr(0), Arg.atomOf(if (is_and) "true" else "false") });
    const v = try expr(f, b.rhs.*);
    try f.move(v, r);
    try f.jump(done);
    try f.label(not_first);
    try f.move(a, Arg.xr(0));
    try f.emit(.is_eq_exact, &.{ Arg.lbl(bad), Arg.xr(0), Arg.atomOf(if (is_and) "false" else "true") });
    try f.move(Arg.atomOf(if (is_and) "false" else "true"), r);
    try f.jump(done);
    try f.label(bad);
    try f.raiseTagged("badarg", a);
    try f.label(done);
    f.temp_top = mark;
    return r;
}

// ── calls ────────────────────────────────────────────────────────────────────

const Callee = union(enum) {
    local: Local,
    ext: bf.ExtFunc,
    self: SelfFun,
    value: ep.Expr,
};

fn resolve(f: *Fn, c: ep.Expr.Call) Error!Callee {
    const l = f.l;
    const n = c.args.len;
    if (c.module) |m| {
        const mod = switch (m.*) {
            .atom => |a| a,
            else => return l.refuse("a call through a computed module", .{}),
        };
        const name = switch (c.fun.*) {
            .atom => |a| a,
            else => return l.refuse("a call to a computed function name", .{}),
        };
        if (std.mem.eql(u8, mod, l.mod.name)) {
            if (l.locals.get(try l.key(name, n))) |loc| return .{ .local = loc };
        }
        return .{ .ext = .{ .module = mod, .function = name, .arity = @intCast(n) } };
    }
    switch (c.fun.*) {
        .atom => |name| {
            const k = try l.key(name, n);
            if (l.locals.get(k)) |loc| return .{ .local = loc };
            if (l.imports.get(k)) |mod| return .{ .ext = .{ .module = mod, .function = name, .arity = @intCast(n) } };
            if (auto_imported.has(k)) return .{ .ext = .{ .module = "erlang", .function = name, .arity = @intCast(n) } };
            return l.refuse("call to undefined function {s}/{d}", .{ name, n });
        },
        .variable => |v| if (f.self_fun) |s| {
            if (std.mem.eql(u8, v, s.name) and n == s.arity) return .{ .self = s };
        },
        else => {},
    }
    return .{ .value = c.fun.* };
}

fn call(f: *Fn, c: ep.Expr.Call, tail: bool) Error!Arg {
    const callee = try resolve(f, c);
    const mark = f.temp_top;
    var fun_val: Arg = Arg.nil;
    if (callee == .value) fun_val = try f.stable(try expr(f, callee.value));
    const args = try f.ar().alloc(Arg, c.args.len);
    for (c.args, 0..) |a, i| args[i] = try f.stable(try expr(f, a));
    for (args, 0..) |a, i| try f.move(a, Arg.xr(i));
    const n = args.len;
    switch (callee) {
        .local => |loc| {
            if (tail) return f.lastCall(.call_last, &.{ Arg.uint(n), Arg.lbl(loc.entry), frameArg() });
            try f.emit(.call, &.{ Arg.uint(n), Arg.lbl(loc.entry) });
        },
        .ext => |x| {
            if (tail) return f.lastCall(.call_ext_last, &.{ Arg.uint(n), .{ .ext = x }, frameArg() });
            try f.emit(.call_ext, &.{ Arg.uint(n), .{ .ext = x } });
        },
        .self => |s| {
            // The captured variables ride after the arguments, as the fun's
            // environment does.
            for (s.free, 0..) |name, i| try f.move(try f.varSlot(name), Arg.xr(n + i));
            const total = n + s.free.len;
            if (tail) return f.lastCall(.call_last, &.{ Arg.uint(total), Arg.lbl(s.entry), frameArg() });
            try f.emit(.call, &.{ Arg.uint(total), Arg.lbl(s.entry) });
        },
        .value => {
            try f.move(fun_val, Arg.xr(n));
            try f.emit(.call_fun, &.{Arg.uint(n)});
            if (tail) {
                try f.emit(.deallocate, &.{frameArg()});
                try f.emit(.@"return", &.{});
                return Arg.nil;
            }
        },
    }
    return f.resultOf(mark);
}

// ── funs ─────────────────────────────────────────────────────────────────────

/// `fun name/Arity` — a fun of a local function; `fun M:F/A` — `erlang:make_fun/3`.
fn funRef(f: *Fn, r: ep.Expr.FunRef) Error!Arg {
    const l = f.l;
    const mark = f.temp_top;
    const module = r.module orelse blk: {
        if (l.locals.get(try l.key(r.name, r.arity))) |loc| {
            try f.emit(.test_heap, &.{ .{ .alloc = .{ .funs = 1 } }, Arg.uint(0) });
            try f.emit(.make_fun3, &.{ Arg.lbl(loc.entry), Arg.xr(0), Arg.listOf(&.{}) });
            return f.resultOf(mark);
        }
        const k = try l.key(r.name, r.arity);
        if (l.imports.get(k)) |m| break :blk m;
        if (auto_imported.has(k)) break :blk "erlang";
        return l.refuse("fun {s}/{d}: no such function", .{ r.name, r.arity });
    };
    try f.move(Arg.atomOf(module), Arg.xr(0));
    try f.move(Arg.atomOf(r.name), Arg.xr(1));
    try f.move(Arg.int(r.arity), Arg.xr(2));
    try f.emit(.call_ext, &.{ Arg.uint(3), Arg.extFn("erlang", "make_fun", 3) });
    return f.resultOf(mark);
}

/// A `fun … end`: lifted to a function `(Args…, Captured…)`, made here with
/// its captured variables as the environment.
fn lambda(f: *Fn, fun: ep.Expr.Fun) Error!Arg {
    const l = f.l;
    if (fun.clauses.len == 0) return l.refuse("a fun with no clause", .{});
    const arity = fun.clauses[0].patterns.len;
    var free: std.ArrayListUnmanaged([]const u8) = .empty;
    try freeVars(f, fun, &free);

    const info = l.label();
    const entry = l.label();
    l.lambda_count += 1;
    const name = try std.fmt.allocPrint(l.ar, "-{s}-fun-{d}-", .{ l.where, l.lambda_count - 1 });
    const saved_where = l.where;
    try compileLambda(l, name, info, entry, fun, arity, free.items);
    l.where = saved_where;

    const mark = f.temp_top;
    const env = try f.ar().alloc(Arg, free.items.len);
    for (free.items, 0..) |v, i| env[i] = try f.varSlot(v);
    try f.emit(.test_heap, &.{ .{ .alloc = .{ .words = @intCast(env.len), .funs = 1 } }, Arg.uint(0) });
    try f.emit(.make_fun3, &.{ Arg.lbl(entry), Arg.xr(0), Arg.listOf(env) });
    return f.resultOf(mark);
}

fn compileLambda(l: *Lowerer, name: []const u8, info: u32, entry: u32, fun: ep.Expr.Fun, arity: usize, free: []const []const u8) Error!void {
    l.where = name;
    var g: Fn = .{ .l = l, .arity = @intCast(arity + free.len) };
    const subjects = try l.ar.alloc(Arg, arity);
    for (subjects, 0..) |*s, i| {
        s.* = g.temp();
        try g.move(Arg.xr(i), s.*);
    }
    for (free, 0..) |v, i| try g.move(Arg.xr(arity + i), try g.bind(v));
    if (fun.name) |self_name| {
        g.self_fun = .{ .name = self_name, .arity = arity, .entry = entry, .free = free };
        // The name is also a value inside the body: the same fun, remade.
        const env = try l.ar.alloc(Arg, free.len);
        for (free, 0..) |v, i| env[i] = try g.varSlot(v);
        try g.emit(.test_heap, &.{ .{ .alloc = .{ .words = @intCast(env.len), .funs = 1 } }, Arg.uint(0) });
        try g.emit(.make_fun3, &.{ Arg.lbl(entry), Arg.xr(0), Arg.listOf(env) });
        try g.move(Arg.xr(0), try g.bind(self_name));
    }
    const restore = try l.ar.alloc(Arg, arity + free.len);
    @memcpy(restore[0..arity], subjects);
    for (free, 0..) |v, i| restore[arity + i] = try g.varSlot(v);
    try headClauses(&g, fun.clauses, subjects, .{ .function_clause = .{ .info = info, .restore = restore } }, true);
    try l.functions.append(l.ar, try g.finish(name, info, entry, false));
}

/// Variables a fun reads that are bound where it is made, in first-use order.
fn freeVars(f: *Fn, fun: ep.Expr.Fun, out: *std.ArrayListUnmanaged([]const u8)) Error!void {
    var shadow: std.StringHashMapUnmanaged(void) = .empty;
    if (fun.name) |n| try shadow.put(f.ar(), n, {});
    for (fun.clauses) |cl| {
        var local = try shadow.clone(f.ar());
        for (cl.patterns) |p| try collectPatternVars(f.ar(), p, &local);
        for (cl.guards) |alt| for (alt) |g| try collectUses(f, g, &local, out);
        for (cl.body) |b| try collectUses(f, b, &local, out);
    }
}

fn collectPatternVars(ar: std.mem.Allocator, p: ep.Expr, into: *std.StringHashMapUnmanaged(void)) Error!void {
    switch (p) {
        .variable => |v| if (!std.mem.eql(u8, v, "_")) try into.put(ar, v, {}),
        .tuple => |items| for (items) |it| try collectPatternVars(ar, it, into),
        .list => |l| {
            for (l.items) |it| try collectPatternVars(ar, it, into);
            if (l.tail) |t| try collectPatternVars(ar, t.*, into);
        },
        .map => |m| for (m.fields) |fl| try collectPatternVars(ar, fl.value, into),
        .match => |m| {
            try collectPatternVars(ar, m.pattern.*, into);
            try collectPatternVars(ar, m.value.*, into);
        },
        .binary => |segs| for (segs) |s| try collectPatternVars(ar, s.value, into),
        .binop => |b| {
            try collectPatternVars(ar, b.lhs.*, into);
            try collectPatternVars(ar, b.rhs.*, into);
        },
        else => {},
    }
}

/// Every variable `e` reads that is bound in `f` and not shadowed.
fn collectUses(f: *Fn, e: ep.Expr, shadow: *std.StringHashMapUnmanaged(void), out: *std.ArrayListUnmanaged([]const u8)) Error!void {
    const ar = f.ar();
    switch (e) {
        .variable => |v| {
            if (shadow.contains(v) or !f.isBound(v)) return;
            for (out.items) |o| if (std.mem.eql(u8, o, v)) return;
            try out.append(ar, v);
        },
        .atom, .int, .float, .string, .fun_ref => {},
        .binary => |segs| for (segs) |s| {
            try collectUses(f, s.value, shadow, out);
            if (s.size) |sz| try collectUses(f, sz, shadow, out);
        },
        .tuple => |items| for (items) |it| try collectUses(f, it, shadow, out),
        .list => |l| {
            for (l.items) |it| try collectUses(f, it, shadow, out);
            if (l.tail) |t| try collectUses(f, t.*, shadow, out);
        },
        .map => |m| {
            if (m.base) |b| try collectUses(f, b.*, shadow, out);
            for (m.fields) |fl| {
                try collectUses(f, fl.key, shadow, out);
                try collectUses(f, fl.value, shadow, out);
            }
        },
        .call => |c| {
            if (c.module) |m| try collectUses(f, m.*, shadow, out);
            try collectUses(f, c.fun.*, shadow, out);
            for (c.args) |a| try collectUses(f, a, shadow, out);
        },
        .fun => |fun| {
            var inner = try shadow.clone(ar);
            if (fun.name) |n| try inner.put(ar, n, {});
            for (fun.clauses) |cl| {
                var cs = try inner.clone(ar);
                for (cl.patterns) |p| try collectPatternVars(ar, p, &cs);
                for (cl.guards) |alt| for (alt) |g| try collectUses(f, g, &cs, out);
                for (cl.body) |b| try collectUses(f, b, &cs, out);
            }
        },
        .binop => |b| {
            try collectUses(f, b.lhs.*, shadow, out);
            try collectUses(f, b.rhs.*, shadow, out);
        },
        .unop => |u| try collectUses(f, u.operand.*, shadow, out),
        .match => |m| {
            try collectUses(f, m.pattern.*, shadow, out);
            try collectUses(f, m.value.*, shadow, out);
        },
        .case_ => |c| {
            try collectUses(f, c.subject.*, shadow, out);
            for (c.clauses) |cl| try collectClauseUses(f, cl, shadow, out);
        },
        .if_ => |cls| for (cls) |cl| try collectClauseUses(f, cl, shadow, out),
        .try_ => |t| {
            for (t.body) |b| try collectUses(f, b, shadow, out);
            for (t.of) |cl| try collectClauseUses(f, cl, shadow, out);
            for (t.catches) |cl| try collectClauseUses(f, cl, shadow, out);
            for (t.after) |b| try collectUses(f, b, shadow, out);
        },
        .block => |b| for (b) |it| try collectUses(f, it, shadow, out),
        .list_comp => |lc| {
            var inner = try shadow.clone(ar);
            for (lc.qualifiers) |q| switch (q) {
                .generator => |g| {
                    try collectUses(f, g.list, &inner, out);
                    try collectPatternVars(ar, g.pattern, &inner);
                },
                .bin_generator => |g| {
                    try collectUses(f, g.bin, &inner, out);
                    try collectPatternVars(ar, g.pattern, &inner);
                },
                .filter => |fl| try collectUses(f, fl, &inner, out),
            };
            try collectUses(f, lc.element.*, &inner, out);
        },
    }
}

fn collectClauseUses(f: *Fn, cl: ep.Clause, shadow: *std.StringHashMapUnmanaged(void), out: *std.ArrayListUnmanaged([]const u8)) Error!void {
    for (cl.patterns) |p| try collectUses(f, p, shadow, out);
    for (cl.guards) |alt| for (alt) |g| try collectUses(f, g, shadow, out);
    for (cl.body) |b| try collectUses(f, b, shadow, out);
}

// ── patterns ─────────────────────────────────────────────────────────────────

/// Match the value in `subject` (a Y register or a literal) against `p`,
/// binding its unbound variables; jump to `fail` when it does not match.
fn pattern(f: *Fn, p: ep.Expr, subject: Arg, fail: u32) Error!void {
    const l = f.l;
    if (p == .variable) {
        const name = p.variable;
        if (std.mem.eql(u8, name, "_")) return;
        if (f.isBound(name)) {
            try f.move(subject, Arg.xr(0));
            try f.move(try f.varSlot(name), Arg.xr(1));
            try f.emit(.is_eq_exact, &.{ Arg.lbl(fail), Arg.xr(0), Arg.xr(1) });
        } else {
            try f.move(subject, try f.bind(name));
        }
        return;
    }
    if (try constTerm(f.ar(), p)) |t| {
        try f.move(subject, Arg.xr(0));
        try f.emit(.is_eq_exact, &.{ Arg.lbl(fail), Arg.xr(0), Arg.lit(t) });
        return;
    }
    switch (p) {
        .tuple => |items| {
            try f.move(subject, Arg.xr(0));
            try f.emit(.is_tuple, &.{ Arg.lbl(fail), Arg.xr(0) });
            try f.emit(.test_arity, &.{ Arg.lbl(fail), Arg.xr(0), Arg.uint(items.len) });
            const elems = try f.ar().alloc(?Arg, items.len);
            for (items, 0..) |it, i| {
                if (it == .variable and std.mem.eql(u8, it.variable, "_")) {
                    elems[i] = null;
                    continue;
                }
                const t = f.temp();
                try f.emit(.get_tuple_element, &.{ Arg.xr(0), Arg.uint(i), t });
                elems[i] = t;
            }
            for (items, elems) |it, e| if (e) |t| try pattern(f, it, t, fail);
        },
        .list => |lst| {
            var cur = subject;
            for (lst.items) |it| {
                try f.move(cur, Arg.xr(0));
                try f.emit(.is_nonempty_list, &.{ Arg.lbl(fail), Arg.xr(0) });
                const h = f.temp();
                const t = f.temp();
                try f.emit(.get_list, &.{ Arg.xr(0), h, t });
                try pattern(f, it, h, fail);
                cur = t;
            }
            if (lst.tail) |tl| {
                try pattern(f, tl.*, cur, fail);
            } else {
                try f.move(cur, Arg.xr(0));
                try f.emit(.is_nil, &.{ Arg.lbl(fail), Arg.xr(0) });
            }
        },
        .map => |m| {
            if (m.base != null) return l.refuse("a map update in a pattern", .{});
            try f.move(subject, Arg.xr(0));
            try f.emit(.is_map, &.{ Arg.lbl(fail), Arg.xr(0) });
            const vals = try f.ar().alloc(Arg, m.fields.len);
            for (m.fields, 0..) |fl, i| {
                const k: Arg = if (try constTerm(f.ar(), fl.key)) |t| Arg.lit(t) else switch (fl.key) {
                    .variable => |v| if (f.isBound(v)) try f.varSlot(v) else return l.refuse("an unbound map pattern key", .{}),
                    else => return l.refuse("a computed map pattern key", .{}),
                };
                vals[i] = f.temp();
                try f.move(subject, Arg.xr(0));
                try f.emit(.get_map_elements, &.{ Arg.lbl(fail), Arg.xr(0), Arg.listOf(try f.ar().dupe(Arg, &.{ k, vals[i] })) });
            }
            for (m.fields, vals) |fl, v| try pattern(f, fl.value, v, fail);
        },
        .match => |m| {
            try pattern(f, m.pattern.*, subject, fail);
            try pattern(f, m.value.*, subject, fail);
        },
        .binary => |segs| try binaryPattern(f, segs, subject, fail),
        .binop => |b| {
            if (!std.mem.eql(u8, b.op, "++")) return l.refuse("operator `{s}` in a pattern", .{b.op});
            // `"prefix" ++ Rest`
            const prefix = switch (b.lhs.*) {
                .string => |cps| cps,
                else => return l.refuse("`++` in a pattern with a non-literal prefix", .{}),
            };
            var cur = subject;
            for (prefix) |cp| {
                try f.move(cur, Arg.xr(0));
                try f.emit(.is_nonempty_list, &.{ Arg.lbl(fail), Arg.xr(0) });
                const h = f.temp();
                const t = f.temp();
                try f.emit(.get_list, &.{ Arg.xr(0), h, t });
                try f.move(h, Arg.xr(0));
                try f.emit(.is_eq_exact, &.{ Arg.lbl(fail), Arg.xr(0), Arg.int(cp) });
                cur = t;
            }
            try pattern(f, b.rhs.*, cur, fail);
        },
        else => return l.refuse("this pattern shape ({s})", .{@tagName(p)}),
    }
}

/// `<<Lit…, Rest/binary>>` (literal bytes, then an optional `/binary` tail),
/// matched with guard BIFs: the size, the prefix by `binary_part/3`, the rest.
fn binaryPattern(f: *Fn, segs: []const ep.Segment, subject: Arg, fail: u32) Error!void {
    const l = f.l;
    const last = segs[segs.len - 1];
    const rest_ok = last.types.len == 1 and std.mem.eql(u8, last.types[0], "binary") and last.size == null and last.value == .variable;
    if (!rest_ok) return l.refuse("a binary pattern other than literal bytes and a `/binary` tail", .{});
    const prefix = (try literalBinary(f.ar(), segs[0 .. segs.len - 1])) orelse
        return l.refuse("a binary pattern other than literal bytes and a `/binary` tail", .{});
    try f.move(subject, Arg.xr(0));
    try f.emit(.is_binary, &.{ Arg.lbl(fail), Arg.xr(0) });
    const size = f.temp();
    try f.emit(.gc_bif1, &.{ Arg.lbl(fail), Arg.uint(1), Arg.extFn("erlang", "byte_size", 1), Arg.xr(0), size });
    try f.move(size, Arg.xr(0));
    try f.emit(.is_ge, &.{ Arg.lbl(fail), Arg.xr(0), Arg.int(prefix.len) });
    if (prefix.len > 0) {
        try f.move(subject, Arg.xr(0));
        try f.move(Arg.int(0), Arg.xr(1));
        try f.move(Arg.int(prefix.len), Arg.xr(2));
        try f.emit(.call_ext, &.{ Arg.uint(3), Arg.extFn("erlang", "binary_part", 3) });
        try f.emit(.is_eq_exact, &.{ Arg.lbl(fail), Arg.xr(0), Arg.lit(Term.str(prefix)) });
    }
    const rest_len = f.temp();
    try f.move(size, Arg.xr(0));
    try f.move(Arg.int(prefix.len), Arg.xr(1));
    try f.emit(.call_ext, &.{ Arg.uint(2), Arg.extFn("erlang", "-", 2) });
    try f.move(Arg.xr(0), rest_len);
    try f.move(subject, Arg.xr(0));
    try f.move(Arg.int(prefix.len), Arg.xr(1));
    try f.move(rest_len, Arg.xr(2));
    try f.emit(.call_ext, &.{ Arg.uint(3), Arg.extFn("erlang", "binary_part", 3) });
    const rest = f.temp();
    try f.move(Arg.xr(0), rest);
    try pattern(f, last.value, rest, fail);
}

// ── clauses and guards ───────────────────────────────────────────────────────

const NoMatch = union(enum) {
    /// Jump to the function's `func_info` with its arguments — and, for a
    /// lifted `fun`, its captured variables — restored to x0….
    function_clause: struct { info: u32, restore: []const Arg },
    if_clause,
    case_clause: Arg,
    /// None of a `try`'s catch clauses: re-raise class/reason/stack.
    reraise: [3]Arg,
};

/// Clauses tried in order against `subjects`; the chosen body's value, or —
/// in tail position — its return. `fresh_heads`: head variables shadow any
/// binding of the name (a `fun` head) instead of testing against it.
/// A function's own clauses (`head`): a head variable aliases its argument.
fn headClauses(f: *Fn, cls: []const ep.Clause, subjects: []const Arg, no_match: NoMatch, fresh_heads: bool) Error!void {
    f.head = true;
    _ = try clausesValue(f, cls, subjects, no_match, true, fresh_heads, null);
}

fn clausesValue(f: *Fn, cls: []const ep.Clause, subjects: []const Arg, no_match: NoMatch, tail: bool, fresh_heads: bool, result: ?Arg) Error!Arg {
    const l = f.l;
    const done = l.label();
    const before = f.trail.items.len;
    const catch_stack = f.catch_stack;
    f.catch_stack = null;
    const head = f.head;
    f.head = false;
    var after: std.ArrayListUnmanaged([]const u8) = .empty;
    for (cls, 0..) |cl, ci| {
        if (cl.patterns.len != subjects.len) return l.refuse("a clause of {d} patterns for {d} values", .{ cl.patterns.len, subjects.len });
        try f.restoreBound(before);
        if (fresh_heads) for (cl.patterns) |p| try unbindPatternVars(f, p);
        const next = l.label();
        const mark = f.temp_top;
        if (head) f.aliases.clearRetainingCapacity();
        for (cl.patterns, subjects) |p, s| {
            if (head and p == .variable and !std.mem.eql(u8, p.variable, "_") and !f.isBound(p.variable)) {
                try f.aliases.put(f.ar(), p.variable, s);
                try f.setBound(p.variable);
                continue;
            }
            try pattern(f, p, s, next);
        }
        try guards(f, cl.guards, next);
        if (catch_stack) |cs| if (cs.vars[ci]) |sv| {
            // `Class:Reason:Stack`: the stack is built on demand, as `erlc`
            // builds it — `build_stacktrace` turns the raw stack in x0 into
            // the list the variable binds.
            try f.move(cs.slot, Arg.xr(0));
            try f.emit(.build_stacktrace, &.{});
            try f.move(Arg.xr(0), try f.bind(sv));
        };
        if (tail) {
            _ = try body(f, cl.body, true);
        } else {
            const v = try body(f, cl.body, false);
            try f.move(v, result.?);
            try f.jump(done);
        }
        f.temp_top = mark;
        try f.label(next);
        for (f.trail.items[before..]) |c| if (c.added) try after.append(f.ar(), c.name);
    }
    switch (no_match) {
        .function_clause => |fc| {
            for (fc.restore, 0..) |s, i| try f.move(s, Arg.xr(i));
            try f.emit(.deallocate, &.{frameArg()});
            try f.jump(fc.info);
        },
        .if_clause => try f.emit(.if_end, &.{}),
        .case_clause => |v| {
            try f.move(v, Arg.xr(0));
            try f.emit(.case_end, &.{Arg.xr(0)});
        },
        .reraise => |cr| {
            try f.move(cr[0], Arg.xr(0));
            try f.move(cr[1], Arg.xr(1));
            try f.move(cr[2], Arg.xr(2));
            try f.emit(.raw_raise, &.{});
        },
    }
    try f.label(done);
    // What the clauses bound survives them (erlc refuses a use of a variable
    // some clause leaves unbound, so the union is exact for accepted code).
    try f.restoreBound(before);
    for (after.items) |name| try f.setBound(name);
    return result orelse Arg.nil;
}

fn unbindPatternVars(f: *Fn, p: ep.Expr) Error!void {
    var names: std.StringHashMapUnmanaged(void) = .empty;
    try collectPatternVars(f.ar(), p, &names);
    var it = names.keyIterator();
    while (it.next()) |k| try f.unsetBound(k.*);
}

fn caseExpr(f: *Fn, c: ep.Expr.Case, tail: bool) Error!Arg {
    const subject = try f.stable(try expr(f, c.subject.*));
    const result: ?Arg = if (tail) null else f.temp();
    return clausesValue(f, c.clauses, &.{subject}, .{ .case_clause = subject }, tail, false, result);
}

fn ifExpr(f: *Fn, cls: []const ep.Clause, tail: bool) Error!Arg {
    const result: ?Arg = if (tail) null else f.temp();
    return clausesValue(f, cls, &.{}, .if_clause, tail, false, result);
}

/// A guard sequence: alternatives joined by `;`, each a conjunction. An
/// exception inside an alternative fails that alternative.
fn guards(f: *Fn, alts: []const []const ep.Expr, fail: u32) Error!void {
    if (alts.len == 0) return;
    const l = f.l;
    const ok = l.label();
    for (alts, 0..) |tests, i| {
        const next = if (i + 1 == alts.len) fail else l.label();
        for (tests) |t| try guardTest(f, t, next, next);
        try f.jump(ok);
        if (i + 1 != alts.len) try f.label(next);
    }
    try f.label(ok);
}

/// Continue when `e` is `true`; jump to `false_lbl` when it is anything else,
/// to `exc_lbl` when evaluating it raises.
fn guardTest(f: *Fn, e: ep.Expr, false_lbl: u32, exc_lbl: u32) Error!void {
    const l = f.l;
    const mark = f.temp_top;
    defer f.temp_top = mark;
    switch (e) {
        .atom => |a| {
            if (std.mem.eql(u8, a, "true")) return;
            try f.jump(false_lbl);
            return;
        },
        .binop => |b| {
            if (std.mem.eql(u8, b.op, "andalso")) {
                try guardTest(f, b.lhs.*, false_lbl, exc_lbl);
                try guardTest(f, b.rhs.*, false_lbl, exc_lbl);
                return;
            }
            if (std.mem.eql(u8, b.op, "orelse")) {
                const second = l.label();
                const ok = l.label();
                try guardTest(f, b.lhs.*, second, exc_lbl);
                try f.jump(ok);
                try f.label(second);
                try guardTest(f, b.rhs.*, false_lbl, exc_lbl);
                try f.label(ok);
                return;
            }
            if (comparisons.get(b.op)) |cmp| {
                const lhs = try f.stable(try guardValue(f, b.lhs.*, exc_lbl));
                const rhs = try guardValue(f, b.rhs.*, exc_lbl);
                const first = if (cmp.swap) rhs else lhs;
                const second = if (cmp.swap) lhs else rhs;
                try f.move(first, Arg.xr(0));
                try f.move(second, Arg.xr(1));
                try f.emit(cmp.op, &.{ Arg.lbl(false_lbl), Arg.xr(0), Arg.xr(1) });
                return;
            }
        },
        .call => |c| if (guardCallName(c)) |name| {
            if (c.args.len == 1) if (type_tests.get(name)) |op| {
                const v = try guardValue(f, c.args[0], exc_lbl);
                try f.move(v, Arg.xr(0));
                try f.emit(op, &.{ Arg.lbl(false_lbl), Arg.xr(0) });
                return;
            };
            if (c.args.len == 2 and std.mem.eql(u8, name, "is_function")) {
                const fun = try f.stable(try guardValue(f, c.args[0], exc_lbl));
                const ar_ = try guardValue(f, c.args[1], exc_lbl);
                // `is_function2` takes a literal arity; anything else is the bif.
                if (ar_ == .literal and ar_.literal == .integer) {
                    try f.move(fun, Arg.xr(0));
                    try f.emit(.is_function2, &.{ Arg.lbl(false_lbl), Arg.xr(0), Arg.uint(ar_.literal.integer) });
                    return;
                }
            }
        },
        else => {},
    }
    const v = try guardValue(f, e, exc_lbl);
    try f.move(v, Arg.xr(0));
    try f.emit(.is_eq_exact, &.{ Arg.lbl(false_lbl), Arg.xr(0), Arg.atomOf("true") });
}

fn guardCallName(c: ep.Expr.Call) ?[]const u8 {
    if (c.module) |m| {
        if (m.* != .atom or !std.mem.eql(u8, m.atom, "erlang")) return null;
    }
    return switch (c.fun.*) {
        .atom => |a| a,
        else => null,
    };
}

/// The value of guard expression `e` (a literal or a Y register); a BIF that
/// raises jumps to `exc_lbl`.
fn guardValue(f: *Fn, e: ep.Expr, exc_lbl: u32) Error!Arg {
    const l = f.l;
    if (try constTerm(f.ar(), e)) |t| return Arg.lit(t);
    switch (e) {
        .variable => |v| {
            if (!f.isBound(v)) return l.refuse("variable `{s}` unbound in a guard", .{v});
            return f.varSlot(v);
        },
        .binop => |b| {
            if (std.mem.eql(u8, b.op, "andalso") or std.mem.eql(u8, b.op, "orelse")) {
                // As a value: `true`/`false` by the test.
                const r = f.temp();
                const no = l.label();
                const done = l.label();
                try guardTest(f, e, no, exc_lbl);
                try f.move(Arg.atomOf("true"), r);
                try f.jump(done);
                try f.label(no);
                try f.move(Arg.atomOf("false"), r);
                try f.label(done);
                return r;
            }
            return guardBif(f, b.op, &.{ b.lhs.*, b.rhs.* }, exc_lbl);
        },
        .unop => |u| return guardBif(f, u.op, &.{u.operand.*}, exc_lbl),
        .call => |c| {
            const name = guardCallName(c) orelse return l.refuse("a call in a guard", .{});
            return guardBif(f, name, c.args, exc_lbl);
        },
        else => return l.refuse("guard expression ({s})", .{@tagName(e)}),
    }
}

fn guardBif(f: *Fn, name: []const u8, args: []const ep.Expr, exc_lbl: u32) Error!Arg {
    const l = f.l;
    const k = try l.ownedKey(name, args.len);
    const gb = guard_bifs.get(k) orelse return l.refuse("{s} in a guard", .{k});
    const r = f.temp();
    const mark = f.temp_top;
    const vals = try f.ar().alloc(Arg, args.len);
    for (args, 0..) |a, i| vals[i] = try f.stable(try guardValue(f, a, exc_lbl));
    for (vals, 0..) |v, i| try f.move(v, Arg.xr(i));
    const regs = try f.ar().alloc(Arg, args.len);
    for (regs, 0..) |*reg, i| reg.* = Arg.xr(i);
    const ext = Arg.extFn("erlang", name, args.len);
    if (gb.gc) {
        const op: Op = switch (args.len) {
            1 => .gc_bif1,
            2 => .gc_bif2,
            3 => .gc_bif3,
            else => return l.refuse("{s} in a guard", .{k}),
        };
        var list: std.ArrayListUnmanaged(Arg) = .empty;
        try list.appendSlice(f.ar(), &.{ Arg.lbl(exc_lbl), Arg.uint(args.len), ext });
        try list.appendSlice(f.ar(), regs);
        try list.append(f.ar(), Arg.xr(0));
        try f.emit(op, list.items);
    } else {
        switch (args.len) {
            0 => try f.emit(.bif0, &.{ ext, Arg.xr(0) }),
            1, 2 => {
                var list: std.ArrayListUnmanaged(Arg) = .empty;
                try list.appendSlice(f.ar(), &.{ Arg.lbl(exc_lbl), ext });
                try list.appendSlice(f.ar(), regs);
                try list.append(f.ar(), Arg.xr(0));
                try f.emit(if (args.len == 1) .bif1 else .bif2, list.items);
            },
            else => return l.refuse("{s} in a guard", .{k}),
        }
    }
    f.temp_top = mark;
    try f.move(Arg.xr(0), r);
    return r;
}

// ── try ──────────────────────────────────────────────────────────────────────

fn tryExpr(f: *Fn, t: ep.Expr.Try) Error!Arg {
    const l = f.l;
    if (t.after.len > 0) return l.refuse("`try … after`", .{});
    if (t.of.len > 0) return l.refuse("`try … of`", .{});
    const tag = Arg.yr(tag_space + f.tag_depth);
    f.tag_depth += 1;
    f.tag_max = @max(f.tag_max, f.tag_depth);
    const result = f.temp();
    const handler = l.label();
    const done = l.label();
    const before = f.trail.items.len;

    try f.emit(.@"try", &.{ tag, Arg.lbl(handler) });
    const mark = f.temp_top;
    const v = try body(f, t.body, false);
    try f.move(v, result);
    f.temp_top = mark;
    try f.emit(.try_end, &.{tag});
    try f.jump(done);
    f.tag_depth -= 1;

    // The handler: x0 = class, x1 = reason, x2 = the raw stack.
    try f.label(handler);
    try f.emit(.try_case, &.{tag});
    try f.restoreBound(before);
    const class = f.temp();
    const reason = f.temp();
    const stack = f.temp();
    try f.move(Arg.xr(0), class);
    try f.move(Arg.xr(1), reason);
    try f.move(Arg.xr(2), stack);
    var cls: std.ArrayListUnmanaged(ep.Clause) = .empty;
    var stack_vars: std.ArrayListUnmanaged(?[]const u8) = .empty;
    for (t.catches) |cl| {
        const pat = cl.patterns[0];
        var class_pat: ep.Expr = .{ .atom = "throw" };
        var reason_pat: ep.Expr = pat;
        var stack_var: ?[]const u8 = null;
        if (pat == .binop and std.mem.eql(u8, pat.binop.op, ":")) {
            var lhs = pat.binop.lhs.*;
            reason_pat = pat.binop.rhs.*;
            // `Class:Reason:Stack` parses as `(Class:Reason):Stack`
            if (lhs == .binop and std.mem.eql(u8, lhs.binop.op, ":")) {
                const stack_pat = reason_pat;
                reason_pat = lhs.binop.rhs.*;
                lhs = lhs.binop.lhs.*;
                if (stack_pat != .variable) return l.refuse("a stack pattern other than a variable", .{});
                if (!std.mem.eql(u8, stack_pat.variable, "_")) stack_var = stack_pat.variable;
            }
            class_pat = lhs;
        }
        try stack_vars.append(f.ar(), stack_var);
        try cls.append(f.ar(), .{ .patterns = try f.ar().dupe(ep.Expr, &.{ class_pat, reason_pat }), .guards = cl.guards, .body = cl.body });
    }
    f.catch_stack = .{ .slot = stack, .vars = stack_vars.items };
    _ = try clausesValue(f, cls.items, &.{ class, reason }, .{ .reraise = .{ class, reason, stack } }, false, false, result);
    try f.label(done);
    return result;
}

// ── list comprehensions ──────────────────────────────────────────────────────

/// `[E || Q…]` as an in-line loop per generator: cons each `E` onto an
/// accumulator, `lists:reverse/1` it at the end. A generator's pattern
/// variables are fresh (they shadow), and none of them outlives the
/// comprehension.
fn listComp(f: *Fn, lc: ep.Expr.ListComp) Error!Arg {
    const acc = f.temp();
    try f.move(Arg.nil, acc);
    const saved_vars = try f.vars.clone(f.ar());
    const saved_aliases = try f.aliases.clone(f.ar());
    const saved_bound = f.trail.items.len;
    const end = f.l.label();
    try qualifiers(f, lc, 0, acc, end);
    try f.label(end);
    f.vars = saved_vars;
    f.aliases = saved_aliases;
    try f.restoreBound(saved_bound);
    const mark = f.temp_top;
    try f.move(acc, Arg.xr(0));
    try f.emit(.call_ext, &.{ Arg.uint(1), Arg.extFn("lists", "reverse", 1) });
    return f.resultOf(mark);
}

/// Qualifier `i` onwards; `next` is where the enclosing generator takes its
/// next element (or, outermost, the comprehension's end).
fn qualifiers(f: *Fn, lc: ep.Expr.ListComp, i: usize, acc: Arg, next: u32) Error!void {
    const l = f.l;
    if (i == lc.qualifiers.len) {
        const mark = f.temp_top;
        const v = try expr(f, lc.element.*);
        try f.emit(.test_heap, &.{ Arg.uint(2), Arg.uint(0) });
        try f.emit(.put_list, &.{ v, acc, Arg.xr(0) });
        try f.move(Arg.xr(0), acc);
        f.temp_top = mark;
        try f.jump(next);
        return;
    }
    switch (lc.qualifiers[i]) {
        .filter => |flt| {
            const mark = f.temp_top;
            if (isGuardExpr(f, flt)) {
                // A guard filter: false, anything not `true`, or an exception
                // skips the element.
                try guardTest(f, flt, next, next);
            } else {
                const v = try expr(f, flt);
                const not_true = l.label();
                const bad = l.label();
                const go = l.label();
                try f.move(v, Arg.xr(0));
                try f.emit(.is_eq_exact, &.{ Arg.lbl(not_true), Arg.xr(0), Arg.atomOf("true") });
                try f.jump(go);
                try f.label(not_true);
                try f.move(v, Arg.xr(0));
                try f.emit(.is_eq_exact, &.{ Arg.lbl(bad), Arg.xr(0), Arg.atomOf("false") });
                try f.jump(next);
                try f.label(bad);
                const sv = try f.stable(v);
                try f.raiseTagged("bad_filter", sv);
                try f.label(go);
            }
            f.temp_top = mark;
            try qualifiers(f, lc, i + 1, acc, next);
        },
        .generator => |g| {
            const mark = f.temp_top;
            const cur = f.temp();
            const src = try expr(f, g.list);
            try f.move(src, cur);
            try generatorLoop(f, lc, i, acc, next, cur, g.pattern);
            f.temp_top = mark;
        },
        .bin_generator => |g| {
            // `<<C/utf8>> <= Bin` walks Bin's code points; `<<B>> <= Bin` its
            // bytes. Both are a list generator over the decoded prefix: the
            // generator ends where the rest stops matching, which is where
            // `unicode:characters_to_list/1` stops decoding.
            const segs = switch (g.pattern) {
                .binary => |s| s,
                else => return l.refuse("a binary generator whose pattern is not a binary", .{}),
            };
            if (segs.len != 1 or segs[0].size != null) return l.refuse("a binary generator pattern of more than one segment", .{});
            const ty: []const u8 = if (segs[0].types.len == 0) "integer" else segs[0].types[0];
            const mark = f.temp_top;
            const cur = f.temp();
            const src = try expr(f, g.bin);
            try f.move(src, Arg.xr(0));
            if (std.mem.eql(u8, ty, "utf8")) {
                try f.emit(.call_ext, &.{ Arg.uint(1), Arg.extFn("unicode", "characters_to_list", 1) });
                const decoded = l.label();
                try f.emit(.is_list, &.{ Arg.lbl(decoded), Arg.xr(0) });
                const have = l.label();
                const bad = l.label();
                try f.jump(have);
                // `{error, Prefix, Rest}` / `{incomplete, Prefix, Rest}`
                try f.label(decoded);
                try f.emit(.is_tuple, &.{ Arg.lbl(bad), Arg.xr(0) });
                try f.emit(.test_arity, &.{ Arg.lbl(bad), Arg.xr(0), Arg.uint(3) });
                try f.emit(.get_tuple_element, &.{ Arg.xr(0), Arg.uint(1), Arg.xr(0) });
                try f.jump(have);
                try f.label(bad);
                try f.raiseTagged("bad_generator", try f.stable(src));
                try f.label(have);
            } else if (std.mem.eql(u8, ty, "integer")) {
                try f.emit(.call_ext, &.{ Arg.uint(1), Arg.extFn("erlang", "binary_to_list", 1) });
            } else return l.refuse("a binary generator of `/{s}` segments", .{ty});
            try f.move(Arg.xr(0), cur);
            try generatorLoop(f, lc, i, acc, next, cur, segs[0].value);
            f.temp_top = mark;
        },
    }
}

fn generatorLoop(f: *Fn, lc: ep.Expr.ListComp, i: usize, acc: Arg, next: u32, cur: Arg, pat: ep.Expr) Error!void {
    const l = f.l;
    const loop = l.label();
    const not_cons = l.label();
    const bad = l.label();
    try f.label(loop);
    try f.move(cur, Arg.xr(0));
    try f.emit(.is_nonempty_list, &.{ Arg.lbl(not_cons), Arg.xr(0) });
    const h = f.temp();
    try f.emit(.get_list, &.{ Arg.xr(0), h, cur });
    // Fresh variables for the pattern.
    var names: std.StringHashMapUnmanaged(void) = .empty;
    try collectPatternVars(f.ar(), pat, &names);
    var it = names.keyIterator();
    while (it.next()) |k| try f.freshVar(k.*);
    try pattern(f, pat, h, loop);
    try qualifiers(f, lc, i + 1, acc, loop);
    try f.label(not_cons);
    try f.move(cur, Arg.xr(0));
    try f.emit(.is_nil, &.{ Arg.lbl(bad), Arg.xr(0) });
    try f.jump(next);
    try f.label(bad);
    try f.raiseTagged("bad_generator", cur);
}

/// Whether filter `e` is a guard expression (so it is evaluated as one:
/// an exception or a non-boolean skips the element instead of raising).
fn isGuardExpr(f: *Fn, e: ep.Expr) bool {
    return switch (e) {
        .variable => |v| f.isBound(v),
        .atom, .int, .float, .string => true,
        .binop => |b| (std.mem.eql(u8, b.op, "andalso") or std.mem.eql(u8, b.op, "orelse") or
            guard_bifs.has(keyOf(f, b.op, 2))) and isGuardExpr(f, b.lhs.*) and isGuardExpr(f, b.rhs.*),
        .unop => |u| guard_bifs.has(keyOf(f, u.op, 1)) and isGuardExpr(f, u.operand.*),
        .call => |c| blk: {
            const name = guardCallName(c) orelse break :blk false;
            const k = keyOf(f, name, c.args.len);
            if (!guard_bifs.has(k)) break :blk false;
            // A module-local function of the same name is not the BIF.
            if (c.module == null and f.l.locals.contains(k)) break :blk false;
            for (c.args) |a| if (!isGuardExpr(f, a)) break :blk false;
            break :blk true;
        },
        else => false,
    };
}

/// `name/arity`, or "" when out of memory (which then matches nothing).
fn keyOf(f: *Fn, name: []const u8, n: usize) []const u8 {
    return f.l.key(name, n) catch "";
}

// ── functions and the module ─────────────────────────────────────────────────

fn function(l: *Lowerer, func: ep.Function, exported: bool) Error!void {
    const loc = l.locals.get(try l.key(func.name, func.arity)).?;
    l.where = try std.fmt.allocPrint(l.ar, "{s}/{d}", .{ func.name, func.arity });
    var f: Fn = .{ .l = l, .arity = @intCast(func.arity) };
    const subjects = try l.ar.alloc(Arg, func.arity);
    for (subjects, 0..) |*s, i| {
        s.* = f.temp();
        try f.move(Arg.xr(i), s.*);
    }
    try headClauses(&f, func.clauses, subjects, .{ .function_clause = .{ .info = loc.info, .restore = subjects } }, false);
    try l.functions.append(l.ar, try f.finish(func.name, loc.info, loc.entry, exported));
}

/// Lower `mod` into a `beam_file.Module` named `name` (the module's own
/// `-module` atom is not read: the caller decides what the code is loaded as,
/// and the listing and the loaded bytes differ only there).
pub fn lowerModule(ar: std.mem.Allocator, mod: ep.Module, name: []const u8, failure: *Failure) Error!Output {
    var l: Lowerer = .{ .ar = ar, .mod = mod, .name = name, .failure = failure };
    for (mod.imports) |im| try l.imports.put(ar, try l.ownedKey(im.name, im.arity), im.module);
    for (mod.functions) |func| {
        const k = try l.ownedKey(func.name, func.arity);
        if (l.locals.contains(k)) return l.refuse("function {s} defined twice", .{k});
        const info = l.label();
        const entry = l.label();
        try l.locals.put(ar, k, .{ .info = info, .entry = entry });
    }
    for (mod.functions) |func| {
        var exported = false;
        for (mod.exports) |e| {
            if (e.arity == func.arity and std.mem.eql(u8, e.name, func.name)) exported = true;
        }
        try function(&l, func, exported);
    }
    return .{ .module = .{ .name = name, .functions = l.functions.items } };
}
