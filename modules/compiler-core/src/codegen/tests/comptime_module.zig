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
        .exports = &.{.{ .name = "main", .arity = 0 }},
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

test "comptime module: a two-parameter loop folds over lists:enumerate" {
    // A query template's `loop (xs) { x, i -> }` reassigning outer vars. It used
    // to hand a 2-arity fun to `lists:foreach/2` and lose every reassignment.
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\fn pick(comptime decl: @Decl) {
        \\    var first = "";
        \\    loop (decl.fields) { f, idx ->
        \\        if (idx == 0) { first = f.name; };
        \\    };
        \\    @emit(first);
        \\}
    , .{ .host_enums = &.{"DeclKind"} });
    try expectContains(out, "First@4 = lists:foldl(fun({Idx, F}, First@1) ->");
    try expectContains(out, "end, First, lists:enumerate(0, maps:get(fields, Decl))),");
    try expectContains(out, "emit(First@4)");
    if (std.mem.indexOf(u8, out, "lists:foreach") != null) return error.TestUnexpectedForeach;
}

test "comptime module: a closure reassigning outer vars takes and answers them" {
    // An erlang fun cannot rebind what it captured: the reassigned variables go
    // in as the last argument and come back as the value.
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\fn tags(comptime decl: @Decl) {
        \\    var toks = [];
        \\    val emit = { t -> toks = toks.append([t]); };
        \\    emit("first");
        \\    decl.fields.forEach({ f -> emit(f.name); });
        \\    @emit(toks.join(","));
        \\}
    , .{ .host_enums = &.{"DeclKind"} });
    try expectContains(out, "Emit = fun(T, Toks@1) ->");
    try expectContains(out, "Toks@3 = Emit(<<\"first\">>, Toks),");
    try expectContains(out, "Toks@6 = lists:foldl(fun(F, Toks@4) ->");
    try expectContains(out, "Toks@5 = Emit(maps:get(name, F), Toks@4),");
    try expectContains(out, "emit('__bp_prim_join'(Toks@6, <<\",\">>))");
}

test "comptime module: a while loop threads the variables its body reassigns" {
    // `while (cond) { … }` is not in scope for checked code; the prelude's
    // bodied interface defaults (`Array.chunked`/`sliding`) write it, and they
    // are lowered without inference — like a comptime body.
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\fn count(comptime decl: @Decl) {
        \\    var i = 0;
        \\    var names = "";
        \\    while (i < 3) {
        \\        names = names + decl.name;
        \\        i = i + 1;
        \\    };
        \\    @emit(names);
        \\}
    , .{ .host_enums = &.{"DeclKind"} });
    try expectContains(out, "{Names@3, I@3} = (fun __Loop({Names@1, I@1}) ->");
    try expectContains(out, "case (I@1 < 3) of");
    try expectContains(out, "__Loop({Names@2, I@2});");
    try expectContains(out, "_ -> {Names@1, I@1}");
    try expectContains(out, "end)({Names, I}),");
    try expectContains(out, "emit(Names@3)");
}

test "comptime module: push through a local threads out of a multi-statement closure" {
    // A dependency-injection constructor shape: a 2-statement closure whose inner
    // `forEach` mutates by assignment and whose `push` mutates the receiver.
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\fn component(comptime decl: @Decl) {
        \\    var args: Array<string> = [];
        \\    args.push("first");
        \\    decl.fields.forEach({ f ->
        \\        var valKey = "";
        \\        f.annotations.forEach({ a -> if (a.name == "value") { valKey = a.args.join(""); } });
        \\        args.push(f.name + ": " + valKey);
        \\    });
        \\    @emit(args.join(", "));
        \\}
    , .{ .host_enums = &.{"DeclKind"} });
    // Straight-line position rebinds the local.
    try expectContains(out, "Args@1 = '__bp_prim_push'(Args, <<\"first\">>),");
    // The closure's push is threaded out through the fold.
    try expectContains(out, "Args@4 = lists:foldl(fun(F, Args@2) ->");
    try expectContains(out, "Args@3 = '__bp_prim_push'(Args@2, '__bp_add'('__bp_add'(maps:get(name, F), <<\": \">>), ValKey)),");
    try expectContains(out, "end, Args@1, maps:get(fields, Decl)),");
    try expectContains(out, "emit('__bp_prim_join'(Args@4, <<\", \">>))");

    // A parameter is not rebound: the push keeps its plain lowering.
    const param = try lower(arena_state.allocator(),
        \\fn tag(comptime decl: @Decl, names: Array<string>) {
        \\    names.push(decl.name);
        \\    @emit(names.join(", "));
        \\}
    , .{ .host_enums = &.{"DeclKind"} });
    try expectContains(param, "    '__bp_prim_push'(Names, maps:get(name, Decl)),");
    try expectContains(param, "emit('__bp_prim_join'(Names, <<\", \">>))");
}

// ── primitive methods in a comptime body ──────────────────────────────────────
//
// A body has no inferred types, so `recv.m(args)` lowers to the runtime-dispatch
// shim `'__bp_prim_m'(Recv, Args…)`; the shim carries one clause per primitive
// kind that answers `m`, each the typed path's own lowering.

/// The host forms both evaluators append, reduced to what the lowering reads:
/// a defined `name/arity` keeps a method call a bare local call.
fn hostFn(comptime name: []const u8, comptime arity: usize) @import("../beam/erl_ast.zig").Form {
    const Ast = @import("../beam/erl_ast.zig");
    return comptime .{ .function = .{ .name = name, .clauses = &.{.{
        .patterns = &([_]Ast.Expr{Ast.Expr.v("_")} ** arity),
        .body = Ast.Body.of(&.{.{ .expr = Ast.Expr.a("ok") }}),
    }} } };
}

test "comptime module: template body primitive methods dispatch through shims" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
        \\    val t = q.text().trim();
        \\    val lines = t.split("\n").map({ l -> l.toUpper() });
        \\    val head = t.slice(0, t.indexOf(">"));
        \\    val tail = t.slice(1);
        \\    val all = lines.append(["x"]).reverse();
        \\    val open = head.startsWith("<");
        \\    val hasP = t.contains("p");
        \\    val first = all.at(0);
        \\    return q.build(all.join(",") + tail);
        \\}
    , .{ .forms = &.{ hostFn("text", 1), hostFn("build", 2) } });
    // Host API calls stay bare local calls.
    try expectContains(out, "text(Q)");
    try expectContains(out, "build(Q, ");
    // Call sites.
    try expectContains(out, "'__bp_prim_trim'(text(Q))");
    try expectContains(out, "'__bp_prim_map'('__bp_prim_split'(T, <<\"\\n\">>), fun(L) ->");
    try expectContains(out, "'__bp_prim_toUpper'(L)");
    try expectContains(out, "'__bp_prim_slice'(T, 0, '__bp_prim_indexOf'(T, <<\">\">>))");
    try expectContains(out, "'__bp_prim_slice'(T, 1)");
    try expectContains(out, "'__bp_prim_reverse'('__bp_prim_append'(Lines, [<<\"x\">>]))");
    try expectContains(out, "'__bp_prim_startsWith'(Head, <<\"<\">>)");
    try expectContains(out, "'__bp_prim_contains'(T, <<\"p\">>)");
    try expectContains(out, "'__bp_prim_at'(All, 0)");
    try expectContains(out, "'__bp_prim_join'(All, <<\",\">>)");
    // Shims: one guarded clause per answering kind, from the typed table.
    try expectContains(out, "'__bp_prim_split'(Recv, Arg0) when is_binary(Recv) ->\n    string:split(Recv, Arg0, all);");
    try expectContains(out, "'__bp_prim_trim'(Recv) when is_binary(Recv) ->\n    string:trim(Recv);");
    try expectContains(out, "'__bp_prim_toUpper'(Recv) when is_binary(Recv) ->\n    string:uppercase(Recv);");
    try expectContains(out, "'__bp_prim_map'(Recv, Arg0) when is_list(Recv) ->\n    lists:map(Arg0, Recv);");
    try expectContains(out, "'__bp_prim_reverse'(Recv) when is_list(Recv) ->\n    lists:reverse(Recv);");
    try expectContains(out, "'__bp_prim_append'(Recv, Arg0) when is_list(Recv) ->\n    (Recv ++ Arg0);");
    try expectContains(out, "'__bp_prim_startsWith'(Recv, Arg0) when is_binary(Recv) ->\n    (string:prefix(Recv, Arg0) =/= nomatch);");
    // `indexOf` / `contains` exist on both strings and arrays.
    try expectContains(out, "'__bp_prim_indexOf'(Recv, Arg0) when is_list(Recv) ->");
    try expectContains(out, "'__bp_prim_indexOf'(Recv, Arg0) when is_binary(Recv) ->\n    (fun(__S, __X) -> case __X of <<>> -> 0; _ -> case binary:match(__S, __X) of nomatch -> -1; {__P, _} -> __P end end end)(Recv, Arg0);");
    try expectContains(out, "'__bp_prim_contains'(Recv, Arg0) when is_list(Recv) ->\n    lists:member(Arg0, Recv);");
    try expectContains(out, "'__bp_prim_contains'(Recv, Arg0) when is_binary(Recv) ->\n    (string:find(Recv, Arg0) =/= nomatch);");
    try expectContains(out, "'__bp_prim_at'(Recv, Arg0) when is_list(Recv) ->\n    (fun(__L, __I) ->");
    // A kind nothing answers ends in a raise naming the method.
    try expectContains(out, "'__bp_prim_split'(Recv, _) ->\n    erlang:error({bp_unsupported_method, <<\"split\">>, 1, Recv}).");
    // `slice` is a bodied `default fn` (no host annotation): the shim reaches the
    // prelude's body, filling the omitted `end` from its declared default.
    try expectContains(out, "'__bp_prim_slice'(Recv, Arg0, Arg1) when is_binary(Recv) ->\n    string_slice(Recv, Arg0, Arg1);");
    try expectContains(out, "'__bp_prim_slice'(Recv, Arg0) when is_list(Recv) ->\n    array_slice(Recv, Arg0, undefined);");
    try expectContains(out, "'__bp_prim_slice'(Recv, Arg0) when is_binary(Recv) ->\n    string_slice(Recv, Arg0, undefined);");
    try expectContains(out, "string_slice(Self, Start, End) ->");
    try expectContains(out, "string:slice(Self, Start, ((End) - (Start)))");
    try expectContains(out, "array_slice(Self, Start, End) ->");
}

test "comptime module: decorator body primitive methods dispatch through shims" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\fn mock(comptime decl: @Decl) {
        \\    val names = decl.fields.map({ f -> f.name });
        \\    if (decl.name.startsWith("_")) { decl.fail("private: " + names.join(", ")); }
        \\}
    , .{ .host_enums = &.{"DeclKind"}, .forms = &.{hostFn("fail", 2)} });
    try expectContains(out, "Names = '__bp_prim_map'(maps:get(fields, Decl), fun(F) ->");
    try expectContains(out, "'__bp_prim_startsWith'(maps:get(name, Decl), <<\"_\">>)");
    try expectContains(out, "fail(Decl, '__bp_add'(<<\"private: \">>, '__bp_prim_join'(Names, <<\", \">>)))");
    try expectContains(out, "'__bp_prim_join'(Recv, Arg0) when is_list(Recv) ->\n    iolist_to_binary(lists:join(Arg0,");
}

test "comptime module: a method named like an auto-imported BIF dispatches on the receiver" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\fn sizes(comptime decl: @Decl) {
        \\    val a = decl.name.length();
        \\    val b = decl.fields.length();
        \\    val c = decl.fields.size;
        \\    val d = a.abs() + b.round() + c.floor() + a.ceil();
        \\}
    , .{ .host_enums = &.{"DeclKind"} });
    try expectContains(out, "A = '__bp_prim_length'(maps:get(name, Decl))");
    try expectContains(out, "B = '__bp_prim_length'(maps:get(fields, Decl))");
    try expectContains(out, "C = '__bp_len'(maps:get(fields, Decl), size)");
    try expectContains(out, "'__bp_prim_abs'(A)");
    try expectContains(out, "'__bp_prim_round'(B)");
    try expectContains(out, "'__bp_prim_floor'(C)");
    try expectContains(out, "'__bp_prim_ceil'(A)");
    try expectContains(out, "'__bp_prim_length'(Recv) when is_list(Recv) ->\n    length(Recv);");
    try expectContains(out, "'__bp_prim_length'(Recv) when is_binary(Recv) ->\n    string:length(Recv);");
    // `abs` is declared on `Signed` and `Float`; an int receiver's controller
    // interface is `Integer` (as on the typed path), so only floats answer it.
    try expectContains(out, "'__bp_prim_abs'(Recv) when is_float(Recv) ->");
    // No bare BIF call survives in the body.
    try std.testing.expect(std.mem.indexOf(u8, out, " = length(") == null);
}

test "comptime module: a method nothing answers is a located error, not an undefined function" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    var unsupported: erlang.UnsupportedMethod = .{};
    const result = lower(arena_state.allocator(),
        \\fn check(comptime decl: @Decl) {
        \\    val n = decl.name;
        \\    val x = n.frobnicate(1, 2);
        \\}
    , .{ .host_enums = &.{"DeclKind"}, .unsupported_method = &unsupported });
    try std.testing.expectError(error.UnsupportedComptimeMethod, result);
    try std.testing.expectEqualStrings("frobnicate", unsupported.callee);
    try std.testing.expectEqual(@as(usize, 2), unsupported.argc);
    try std.testing.expectEqual(@as(usize, 3), unsupported.loc.line);

    // A host form of that name/arity answers it: the bare local call stays.
    const hosted = try lower(arena_state.allocator(),
        \\fn check(comptime decl: @Decl) {
        \\    decl.frobnicate(1, 2);
        \\}
    , .{ .host_enums = &.{"DeclKind"}, .forms = &.{hostFn("frobnicate", 3)}, .unsupported_method = &unsupported });
    try expectContains(hosted, "frobnicate(Decl, 1, 2)");
}

test "comptime module: a listing shows the shim calls but not the shims" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const out = try lower(arena_state.allocator(),
        \\fn names(comptime decl: @Decl) {
        \\    @emit(decl.fields.map({ f -> f.name }).join(", "));
        \\}
    , .{ .listing = true });
    try expectContains(out, "'__bp_prim_join'('__bp_prim_map'(maps:get(fields, Decl), fun(F) ->");
    try std.testing.expect(std.mem.indexOf(u8, out, "'__bp_prim_join'(Recv") == null);
    try std.testing.expect(std.mem.indexOf(u8, out, "'__bp_add'(A, B)") == null);
}

test "comptime module: the primitive dispatch table is populated from the prelude" {
    // `collectPrimErlangDispatch` swallows a `primitives.bp` parse failure; an
    // empty table would turn every primitive method call into a raise.
    const n = try erlang.primErlangDispatchCount(std.testing.allocator);
    try std.testing.expect(n > 40);
}
