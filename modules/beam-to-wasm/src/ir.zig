//! What a translation answers: wasm functions as a small structured
//! instruction tree over the comptime runtime's term ABI (every value an
//! `i32` term; a raise recorded by the runtime and answered by returning 0,
//! the caller testing `rt_pending`). The host (compiler-core's wat comptime
//! runtime) maps each node onto its own wasm model and links the functions
//! into the program that calls them.
const std = @import("std");

/// A BEAM register as a wasm local of the function: `x<N>` (the first
/// `arity` are the parameters) and `y<N>`.
pub const Reg = union(enum) {
    x: u32,
    y: u32,

    pub fn format(r: Reg, w: *std.Io.Writer) std.Io.Writer.Error!void {
        switch (r) {
            .x => |n| try w.print("x{d}", .{n}),
            .y => |n| try w.print("y{d}", .{n}),
        }
    }
};

pub const Instr = union(enum) {
    get: Reg,
    set: Reg,
    /// The dispatch local `pc`: the BEAM label control goes to next.
    get_pc,
    set_pc,
    i32_const: i32,
    i64_const: i64,
    /// Push the address and the length of these literal bytes (an atom's
    /// name, a binary): the host lays them out in the module's data.
    bytes: []const u8,
    /// Call a runtime export by name. Its parameters are `i32` terms — but
    /// `rt_int`'s, an `i64` — and its result an `i32`.
    rt: []const u8,
    /// Call a function of a translated module — this one's or another of the
    /// set it was translated with: its `arity` arguments pushed, an `i32`
    /// term answered (0 with an exception pending).
    call: Call,
    block: Block,
    br: []const u8,
    br_if: []const u8,
    i32_eq,
    i32_ne,
    i32_lt_s,
    i32_ge_s,
    i32_eqz,
    drop,
    ret,
    trap,
};

pub const Call = struct {
    /// The BEAM module's name.
    module: []const u8,
    /// `<name>/<arity>`, as `Function.name`.
    function: []const u8,
    arity: u32,
};

/// `block` (or `loop`, when `loop`) labelled `label` over `body`.
pub const Block = struct {
    label: []const u8,
    loop: bool = false,
    body: []const Instr,
};

pub const Function = struct {
    /// `<name>/<arity>`, as the module names it.
    name: []const u8,
    arity: u32,
    /// Locals `x0…x<x_regs - 1>` (the first `arity` the parameters) and
    /// `y0…y<y_regs - 1>`, plus `pc`.
    x_regs: u32,
    y_regs: u32,
    body: []const Instr,
    /// What is not converted in this function — an opcode
    /// (`opcode 4 (call)`), a call (`` `re:run/3` ``), an operand — when it
    /// is not; `body` is then empty. A function is refused where a caller
    /// reaches it (`root.refusalReaching`), never for being in the module.
    refused: ?[]const u8 = null,
};

pub const Module = struct {
    /// The BEAM module's name (atom 1).
    name: []const u8,
    /// Every function of the module, in the order of its `Code` chunk.
    functions: []const Function,

    /// Function `<name>/<arity>`, when the module has it.
    pub fn find(m: Module, function: []const u8) ?*const Function {
        for (m.functions) |*f| if (std.mem.eql(u8, f.name, function)) return f;
        return null;
    }
};
