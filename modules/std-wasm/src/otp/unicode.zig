//! `unicode:characters_to_list` / `characters_to_binary` (decision 450).
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("../root.zig");
const term = @import("../term.zig");
const erlang = @import("erlang.zig");
const lists = @import("lists.zig");
const maps = @import("maps.zig");
const string = @import("string.zig");
const binary = @import("binary.zig");
const math = @import("math.zig");
const io_lib = @import("io_lib.zig");
const json = @import("json.zig");
const etf = @import("etf.zig");
const T = term.T;

pub fn rt_unicode_characters_to_list(t: T) callconv(.c) term.T {
    const s = string.chardata(t) orelse return term.badarg();
    return erlang.utf8Chars(s);
}

pub fn rt_unicode_characters_to_list2(t: T, _: T) callconv(.c) term.T {
    return rt_unicode_characters_to_list(t);
}

pub fn rt_unicode_characters_to_binary(t: T) callconv(.c) term.T {
    const s = string.chardata(t) orelse return term.badarg();
    return term.binOf(s);
}

pub fn rt_unicode_characters_to_binary2(t: T, _: T) callconv(.c) term.T {
    return rt_unicode_characters_to_binary(t);
}
