//! `math:floor`, `ceil`, `sqrt`, `pow` over terms (decision 450).
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("../root.zig");
const term = @import("../term.zig");
const erlang = @import("erlang.zig");
const lists = @import("lists.zig");
const maps = @import("maps.zig");
const string = @import("string.zig");
const binary = @import("binary.zig");
const unicode = @import("unicode.zig");
const io_lib = @import("io_lib.zig");
const json = @import("json.zig");
const etf = @import("etf.zig");
const T = term.T;

pub fn rt_math_floor(a: T) callconv(.c) term.T {
    if (!term.isNum(a)) return term.badarg();
    return term.mkFloat(@floor(term.numAsFloat(a)));
}

pub fn rt_math_ceil(a: T) callconv(.c) term.T {
    if (!term.isNum(a)) return term.badarg();
    return term.mkFloat(@ceil(term.numAsFloat(a)));
}

pub fn rt_math_sqrt(a: T) callconv(.c) term.T {
    if (!term.isNum(a) or term.numAsFloat(a) < 0) return term.badarg();
    return term.mkFloat(@sqrt(term.numAsFloat(a)));
}

pub fn rt_math_pow(a: T, b: T) callconv(.c) term.T {
    if (!term.isNum(a) or !term.isNum(b)) return term.badarg();
    return term.mkFloat(std.math.pow(f64, term.numAsFloat(a), term.numAsFloat(b)));
}
