//! What a lowered value is, as `../wat.zig` carries it (front 164 s2, decision 544).
//!
//! The lowering recovers a value's representation by best effort (codegen is
//! untyped): a local's, a global's, a parameter's, a function's result. A
//! `Repr` names it — a scalar the wasm value type it is, or a reference and the
//! kind of value it points at — and the module's lowering mode turns it into the
//! wasm value type a declaration spells (`valType`): in `.linear` every
//! reference and every `bool` is the `i32` word (an address in linear memory, a
//! `0`/`1`); in `.gc` a reference is a GC reference to the kind's type.

const std = @import("std");
const wat = @import("wat_ast.zig");

/// How a module is lowered: every value a word in linear memory (`.linear`),
/// or every value of a GC kind a GC reference (`.gc`). `emitWat` lowers a module
/// in `.gc` and, when the lowering refuses something it has no GC form for yet,
/// lowers it again in `.linear`.
pub const Mode = enum { linear, gc };

pub const Repr = union(enum) {
    i32,
    i64,
    f64,
    /// A boolean: the `i32` `0` / `1` on the stack and in a local.
    bool,
    /// A reference to a value of `Kind`.
    ref: Kind,

    /// The value shapes a reference points at.
    pub const Kind = union(enum) {
        /// A string: its UTF-8 bytes.
        str,
        /// An array of `Elem`s.
        arr: Elem,
        tuple,
        /// A value of the named record type.
        record: []const u8,
        /// A value of the named enum type.
        enum_: []const u8,
        closure,
        /// A `@Task<T>`.
        task,
        /// A `var`'s mutable cell.
        cell,
        /// A value of any kind (`unknown`, a type parameter).
        unknown,
        /// A `Bytes` value.
        bytes,
        bigint,
        /// A `@Result<A, E>`: its tag and its payload.
        result,
        /// The frame of state machine `n` (front 164 s2 P4): its resume index
        /// and every local, typed — what a suspended task keeps.
        frame: u32,

        pub fn eql(a: Kind, b: Kind) bool {
            if (std.meta.activeTag(a) != std.meta.activeTag(b)) return false;
            return switch (a) {
                .arr => |e| e == b.arr,
                .record => |n| std.mem.eql(u8, n, b.record),
                .enum_ => |n| std.mem.eql(u8, n, b.enum_),
                .frame => |n| n == b.frame,
                else => true,
            };
        }
    };

    /// An array's element: a word, an `f64`, or a reference to anything.
    pub const Elem = enum { i32, f64, any };

    pub const string: Repr = .{ .ref = .str };

    /// The scalar class of the value: the wasm type the scalar opcodes over it
    /// are spelled with (`i32.eq`, `f64.add`). A `bool` and, in linear memory,
    /// every reference are the `i32` word.
    pub fn num(r: Repr) wat.ValType {
        return switch (r) {
            .i64 => .i64,
            .f64 => .f64,
            else => .i32,
        };
    }

    /// Whether the value is a float.
    pub fn isFloat(r: Repr) bool {
        return r == .f64;
    }

    /// Whether the value is a 64-bit integer.
    pub fn isI64(r: Repr) bool {
        return r == .i64;
    }

    /// Whether the value is the `i32` word in linear memory: an `i32`, a
    /// `bool` or a reference.
    pub fn isWord(r: Repr) bool {
        return r.num() == .i32;
    }

    pub fn isRef(r: Repr) bool {
        return r == .ref;
    }

    pub fn isStr(r: Repr) bool {
        return r == .ref and r.ref == .str;
    }

    /// Whether the value is a reference to an array.
    pub fn isArrRef(r: Repr) bool {
        return r == .ref and r.ref == .arr;
    }

    pub fn eql(a: Repr, b: Repr) bool {
        if (std.meta.activeTag(a) != std.meta.activeTag(b)) return false;
        return switch (a) {
            .ref => |k| k.eql(b.ref),
            else => true,
        };
    }

    /// The scalar repr of a wasm number type.
    pub fn ofNum(t: wat.ValType) Repr {
        return switch (t) {
            .i64 => .i64,
            .f64, .f32 => .f64,
            else => .i32,
        };
    }

    /// The value as a diagnostic names it (`i32`, `f64`, `string`, …).
    pub fn name(r: Repr) []const u8 {
        return switch (r) {
            .i32 => "i32",
            .i64 => "i64",
            .f64 => "f64",
            .bool => "bool",
            .ref => |k| switch (k) {
                .str => "string",
                .arr => "array",
                .tuple => "tuple",
                .record => |n| n,
                .enum_ => |n| n,
                .closure => "function",
                .task => "@Task",
                .cell => "var cell",
                .unknown => "unknown",
                .bytes => "Bytes",
                .bigint => "bigint",
                .result => "@Result",
                .frame => "a task's frame",
            },
        };
    }
};
