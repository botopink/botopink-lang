//! .d.ts emitter: the types the compiler names without any module declaring
//! them (`Bytes`, `Children`, `Asset`, a std `Context` reached through an
//! inferred type) are spelled with their JavaScript shape or imported, never
//! left as a name `tsc` cannot find (`Cannot find name 'Bytes'`).

const std = @import("std");
const codegen = @import("../../codegen.zig");
const helpers = @import("./helpers.zig");

fn typedefOf(alloc: std.mem.Allocator, src: []const u8) ![]u8 {
    var outputs = try codegen.generate(alloc, &.{.{ .path = "", .source = src }}, std.testing.io, helpers.configs[0]);
    defer {
        for (outputs.items) |*o| o.result.deinit(alloc);
        outputs.deinit(alloc);
    }
    try std.testing.expect(outputs.items.len >= 1);
    return alloc.dupe(u8, outputs.items[outputs.items.len - 1].result.typedef orelse return error.MissingTypedef);
}

fn expectDts(src: []const u8, present: []const []const u8, absent: []const []const u8) !void {
    const dts = try typedefOf(std.testing.allocator, src);
    defer std.testing.allocator.free(dts);
    for (present) |needle| if (std.mem.indexOf(u8, dts, needle) == null) {
        std.debug.print("\nmissing `{s}` in .d.ts:\n{s}\n", .{ needle, dts });
        return error.NeedleNotFound;
    };
    for (absent) |needle| if (std.mem.indexOf(u8, dts, needle) != null) {
        std.debug.print("\nunexpected `{s}` in .d.ts:\n{s}\n", .{ needle, dts });
        return error.UnexpectedNeedle;
    };
}

test ".d.ts: bytes is a Uint8Array" {
    try expectDts(
        \\pub fn size(b: bytes) -> bytes { return b; }
    , &.{"size(b: Uint8Array): Uint8Array"}, &.{": bytes"});
}

test ".d.ts: Children is an array" {
    try expectDts(
        \\pub type El(tag: string, children: Children)
    , &.{"readonly children: any[]"}, &.{"Children"});
}

test ".d.ts: a std Context named by an inferred type is imported" {
    try expectDts(
        \\import {context.createContext} from "std";
        \\pub val themeContext = comptime createContext("");
    , &.{ "import { Context } from \"./std/context\"", "themeContext: Context<string>" }, &.{});
}

test ".d.ts: a payload-less variant of a generic enum names no class type parameter" {
    try expectDts(
        \\pub type Maybe<T> { None, Some(value: T) }
    , &.{"static readonly None: Maybe<any>"}, &.{"static readonly None: Maybe<T>"});
}

test ".d.ts: a compiler-spliced record named by a signature is declared private" {
    try expectDts(
        \\pub fn show(all: Declared<unknown>[]) -> void { }
    , &.{ "declare class Declared<T>", "declare class DeclaredMeta", "export {};" }, &.{"export declare class Declared"});
}
