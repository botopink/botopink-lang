//! What a translation answers: wasm functions as a small structured
//! instruction tree over std-wasm's term ABI (every value an `i32` term; a
//! raise recorded by the runtime and answered by returning 0, the caller
//! testing `rt_pending`). The host maps each node onto its own wasm model and
//! links the functions into the program that calls them.
//!
//! **Memory** (decision 449 (3)). Terms live on the current process's heap
//! (std-wasm's `heap.zig`): the host binds the term library's
//! `env.bp_term_alloc` to `heap.alloc` and `env.bp_term_static` (an atom) to
//! `heap.static`, and calls `heap.termRoots` once the process's heap is
//! current. A collection runs only at a `collect` node — `test_heap` and
//! `allocate_heap*`, BEAM's own collection points — whose roots are the live
//! x registers it names and the process's root stack: every y register of
//! every frame lives there (`frame_push` … `frame_pop`), never in a wasm
//! local, so a term a caller keeps across a call that collects is moved
//! with it. An x register is live across no call (BEAM's convention), so a
//! callee's collection moves none the caller still reads.
const std = @import("std");

/// A BEAM register: `x<N>` a wasm local of the function (the first `arity`
/// are the parameters); `y<N>` word `N` of the function's frame on the
/// process's root stack (`frame_push`), which a collection reads and
/// rewrites.
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
    /// The function's entry, in a function that pushes a frame: the root
    /// stack's depth kept for `frame_restore`.
    frame_save,
    /// A raise leaving the function: the root stack back to the depth
    /// `frame_save` kept — the frames this call pushed popped.
    frame_restore,
    /// `allocate*`: a frame of `n` y registers pushed on the process's root
    /// stack, zeroed (a collection reads every word of it).
    frame_push: u32,
    /// `deallocate`, and a tail call's: the frame of `n` y registers popped.
    frame_pop: u32,
    /// A collection point (`test_heap`, `allocate_heap*`): `heap.reserve`
    /// of `need` bytes, its roots x0…x<live - 1> (the host stores them in
    /// a root area beside the root stack and loads them back after) and the
    /// whole root stack.
    collect: Collect,
};

/// A collection point's operands.
pub const Collect = struct {
    /// Bytes the instructions up to the next collection point may allocate
    /// (BEAM's need by kind, `lower.needBytes`): a collection runs first when
    /// the nursery has less room — `alloc` itself never collects, it takes
    /// another chunk.
    need: u32,
    /// The x registers live across it.
    live: u32,
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
    /// `pc`; `y_regs` the most y registers a frame of it holds.
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
