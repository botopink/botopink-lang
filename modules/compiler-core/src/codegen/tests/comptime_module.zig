//! `erlang.emitComptimeModule` — the standalone Erlang module a decorator or
//! template body is lowered to for evaluation in the persistent `erl`. Bodies
//! are untyped, so the runtime-dispatched lowerings (`'__bp_add'`,
//! `'__bp_len'`) and host enums are what these tests pin.

const std = @import("std");
const erlang = @import("../erlang.zig");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");

/// Parse `src` and lower it with `module`; returns the Erlang source.
fn lower(arena: std.mem.Allocator, src: []const u8, module: erlang.ComptimeModule) ![]const u8 {
    var lx = lexerMod.Lexer.init(src);
    const tokens = try lx.scanAll(arena);
    var p = parserMod.Parser.init(tokens);
    const program = try p.parse(arena);
    return erlang.emitComptimeModule(arena, "decorator_test", program, module);
}

fn expectContains(haystack: []const u8, needle: []const u8) !void {
    if (std.mem.indexOf(u8, haystack, needle) == null) {
        std.debug.print("\nexpected to find:\n{s}\nin:\n{s}\n", .{ needle, haystack });
        return error.TestExpectedContains;
    }
}

test "comptime module: host enum member lowers to an atom, method call to a host fn" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Record) { decl.fail("must annotate a record"); }
        \\}
    , .{
        .host_enums = &.{"DeclKind"},
        .exports = &.{"main/0"},
        .forms = &.{.{ .function = .{ .name = "main", .clauses = &.{.{
            .patterns = &.{},
            .body = .{ .stmts = &.{.{ .expr = .{ .call = .{ .name = "service", .args = &.{.{ .map = &.{
                .{ .key = .{ .atom = "kind" }, .value = .{ .atom = "Record" } },
            } }} } } }} },
            .layout = .inline_,
        }} } }},
    });
    try expectContains(out, "-module(decorator_test).");
    try expectContains(out, "-export([main/0]).");
    try expectContains(out, "(maps:get(kind, Decl) =/= 'Record')");
    try expectContains(out, "fail(Decl, <<\"must annotate a record\">>)");
    try expectContains(out, "main() -> service(#{kind => 'Record'}).");
}

test "comptime module: `+` and `.len` dispatch at runtime, rebinding versions the variable" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\fn check(comptime decl: @Decl) {
        \\    var msg = "invalid name: ";
        \\    msg = msg + decl.name;
        \\    if (decl.fields.len > 5) { decl.fail(msg); }
        \\}
    , .{ .host_enums = &.{"DeclKind"} });
    try expectContains(out, "Msg = <<\"invalid name: \">>,");
    try expectContains(out, "Msg@1 = '__bp_add'(Msg, maps:get(name, Decl))");
    try expectContains(out, "('__bp_len'(maps:get(fields, Decl), len) > 5)");
    try expectContains(out, "fail(Decl, Msg@1)");
    try expectContains(out, "'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;");
    try expectContains(out, "'__bp_len'(X, Field) -> maps:get(Field, X).");
    try expectContains(out, "'__bp_json'(undefined) -> null;");
    try expectContains(out, "'__bp_text'(Value) when is_binary(Value) -> Value;");
}

test "comptime module: forEach with a mutated var fuses into a fold" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\fn mock(comptime decl: @Decl) {
        \\    var methods = "";
        \\    decl.methods.forEach({ m ->
        \\        methods = methods + "fn " + m.name;
        \\    });
        \\    @emit("record Mock" + decl.name + " {" + methods + "}");
        \\}
    , .{ .host_enums = &.{"DeclKind"} });
    try expectContains(out, "lists:foldl(fun(M, Methods) ->");
    try expectContains(out, "'__bp_add'('__bp_add'(Methods, <<\"fn \">>), maps:get(name, M))");
    try expectContains(out, "emit('__bp_add'(");
}
