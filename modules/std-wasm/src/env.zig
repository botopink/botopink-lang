//! What std-wasm imports from its caller (`env`), declared once for both
//! value representations. A program binds them in
//! `compiler-core/src/codegen/wat/std_wasm_link.zig`; the comptime runtime in
//! `compiler-core/src/comptime/runtime/wat/runtime_module.zig`. Only a wasm
//! build references them: every use is behind `builtin.cpu.arch.isWasm()`
//! or in `wasm.zig`.

const T = @import("term.zig").T;

/// `n` fresh bytes for a program face's value (`wasm.zig`): a program's bump
/// allocator (`$__alloc`, 4-aligned) — allocation is the caller's (decision
/// 450 (5)).
pub extern "env" fn bp_alloc(n: u32) u32;

/// A term's `n` bytes of `layout` (a `heap.zig` layout: the words a
/// collection follows): the comptime's arena, which ignores the layout, or
/// in translated code the current process's heap (`heap.alloc`, decision 449
/// (3)).
pub extern "env" fn bp_term_alloc(n: u32, layout: u32) u32;

/// `n` bytes outside every process's heap, never moved or freed — an atom:
/// the comptime's arena, or in translated code `heap.static`.
pub extern "env" fn bp_term_static(n: u32) u32;

/// The host's entropy (decision 451 (2)): a uniform `f64` in `[0.0, 1.0)`,
/// the program's `$__wasi_random_f64` — what an unseeded draw answers.
pub extern "env" fn bp_random_f64() f64;

/// A term fun called through the caller's function table: `index` the fun's
/// slot, the fun itself first, then its arguments (`term.applyFun`).
pub extern "env" fn bp_call0(index: u32, f: T) T;
pub extern "env" fn bp_call1(index: u32, f: T, a: T) T;
pub extern "env" fn bp_call2(index: u32, f: T, a: T, b: T) T;
pub extern "env" fn bp_call3(index: u32, f: T, a: T, b: T, c: T) T;
pub extern "env" fn bp_call4(index: u32, f: T, a: T, b: T, c: T, d: T) T;
