//! The comptime evaluators' resident prelude.
//!
//! A template or a decorator body is lowered into a generated Erlang module and
//! compiled by the persistent node before it runs. Until 1.0.5-beta every one of
//! those modules also carried the host glue — the capture API, the reply
//! encoder, the failure throws and the untyped helpers of
//! `codegen/erlang.zig`'s `comptime_helper_forms` — and those forms are
//! **byte-identical in every module the compiler has ever produced**: 54 of the
//! 295 lines of the smallest realistic module, and the part of it the Erlang
//! front end actually works for (guards, list comprehensions, multi-clause
//! heads). The data literal that does differ per call site is a term, which is
//! cheap to compile.
//!
//! So they move here. Two modules are compiled by `erlc` at `zig build` time
//! and embedded (decision 83, `render_resident.zig`), loaded into the node at
//! spawn beside `botopink_comptime_server` (`persistent_beam.zig`), and a
//! generated module reaches them by `-import`, which leaves the lowered body's
//! own text unchanged — the BEAM lowering turns each imported call into a
//! `call_ext` into the prelude:
//!
//!   bp_comptime_template    the capture API (`text/1`, `parts/1`, `source/1`,
//!                           `context/1`, `bindings/1`, `lookup/2`, `ref/1`),
//!                           the result constructors (`build/2`, `custom/3`,
//!                           `expr/1`, `code/1`), the failure throws
//!                           (`fail/2`, `failAt/3`, `compilerError/1`), the
//!                           reply encoder (`'__bp_reply'/1`) and the untyped
//!                           helpers
//!   bp_comptime_decorator   `fail/2`, `failAt/3`, `compilerError/1`, `emit/1`,
//!                           `'__bp_emitted'/0` and the untyped helpers
//!
//! The two cannot be one module: a template's `fail/2` throws
//! `'__bp_template_fail'` with the capture's parameter name, a decorator's
//! throws `'__bp_decorator_fail'` without it. Each carries its own copy of the
//! four untyped helpers rather than calling a third module, so neither prelude
//! has a cross-module call of its own.
//!
//! What stays in the generated module: the lowered body, the `'__bp_prim_…'`
//! shims its own method calls reached, and `main/0` — the only host form whose
//! text depends on the call site.
const std = @import("std");
const Ast = @import("../../codegen/beam/erl_ast.zig");
const erlEmitter = @import("../../codegen/beam/erl_emitter.zig");
const erlang = @import("../../codegen/erlang.zig");

/// The prelude a template module imports.
pub const template_module = "bp_comptime_template";
/// The prelude a decorator module imports.
pub const decorator_module = "bp_comptime_decorator";

/// `'__bp_template_fail'` — the tag `fail`/`failAt`/`compilerError` throw and
/// `main/0` catches. Shared with `template_eval.zig`, which builds the catch.
pub const template_fail_tag = "__bp_template_fail";
/// `'__bp_decorator_fail'` — the decorator twin.
pub const decorator_fail_tag = "__bp_decorator_fail";

/// `{'__bp_code', Source}` — what `build`/`code`/`ref` return and `'__bp_reply'`
/// matches.
pub const code_tag = "__bp_code";
/// Decision 237 — the message `lookup/2` fails the template with when its name
/// is not a word of the captured text: head ++ Name ++ tail. ASCII only: the
/// prelude's binary literals carry bytes, not code points.
pub const lookup_not_a_word_head = "lookup(\"";
pub const lookup_not_a_word_tail = "\"): not a word of the template's text; a template capture carries only the bindings whose name its text spells";
/// The process-dictionary key `emit/1` accumulates under.
pub const emitted_key = "__bp_emitted";

pub const Error = Ast.Builder.Error;

/// Decision 364 (3) — the function a decorator body's `x.fail(m)` becomes
/// (`comptime/expr_param.zig`): `'__bp_failArg'(Index, Message)`.
pub const fail_arg_fn = "__bp_failArg";

/// Decision 298 — the function `decl.setMeta(v)` / `decl.addMeta(v)` becomes
/// in a decorator body (`typed_meta.typed_meta_fn`).
pub const typed_meta_fn = "__bp_typedMeta";

/// The prelude's walk of a typed meta value before it is encoded
/// (`'__bp_metaJson'/1`): `undefined` (a comptime `null`) becomes `null`.
const meta_json_fn = "__bp_metaJson";

/// One prelude module: its atom and the Erlang source built for it.
pub const Module = struct {
    name: []const u8,
    source: []const u8,
};

// ── the forms ─────────────────────────────────────────────────────────────────

/// The host functions of `bp_comptime_template`, in the order they are rendered.
/// A capture is a map tagged with `'__bp_capture'` (its parameter name);
/// `build`/`custom`/`expr`/`code` wrap the body's result in a tagged tuple
/// `'__bp_reply'` dispatches on.
pub fn templateForms(b: Ast.Builder) Error![]const Ast.Form {
    const V = Ast.Expr.v;
    const A = Ast.Expr.a;
    const fail_tag = A(template_fail_tag);
    const code = A(code_tag);

    const throw = struct {
        fn call(bb: Ast.Builder, items: []const Ast.Expr) Ast.Builder.Error!Ast.Expr {
            return bb.remote("erlang", "throw", &.{try bb.tuple(items)});
        }
    }.call;

    // Capture accessors: `text(#{text := Text}) -> Text.` …
    const accessors = [_][2][]const u8{
        .{ "text", "Text" },       .{ "parts", "Parts" },       .{ "source", "Source" },
        .{ "context", "Context" }, .{ "bindings", "Bindings" },
    };
    var forms: std.ArrayListUnmanaged(Ast.Form) = .empty;
    for (accessors) |acc| {
        try forms.append(b.arena, try b.function(acc[0], &.{try b.map(&.{Ast.exactField(acc[0], V(acc[1]))})}, &.{}, &.{V(acc[1])}));
    }

    const capture_param = try b.map(&.{.{ .key = A("__bp_capture"), .value = V("Param"), .exact = true }});
    try forms.appendSlice(b.arena, &.{
        // lookup(#{'__bp_capture' := Param, bindings := Bindings, words := Words}, Name) ->
        //     case [B || B = #{local := N} <- Bindings, N =:= Name] of
        //         [Hit | _] -> Hit;
        //         [] -> case [W || W <- Words, W =:= Name] of
        //                   [_ | _] -> undefined;
        //                   [] -> erlang:throw({'__bp_template_fail', <message naming Name>, Param, null})
        //               end
        //     end.
        // Matched on the name the call site spells (`local`); the hit carries
        // the declaration's own `name` and `identity` (decision 112). Decision
        // 237: the capture carries only the bindings its text names, so a
        // word of the text the scope lacks is `undefined`, and a name that is
        // not a word of the text fails the template at its literal — never a
        // silent miss.
        try b.function("lookup", &.{
            try b.map(&.{
                .{ .key = A("__bp_capture"), .value = V("Param"), .exact = true },
                Ast.exactField("bindings", V("Bindings")),
                Ast.exactField("words", V("Words")),
            }),
            V("Name"),
        }, &.{}, &.{
            try b.caseOf(.{ .list_comp = .{
                .element = try b.ptr(V("B")),
                .qualifiers = try b.arena.dupe(Ast.ListComp.Qualifier, &.{
                    .{ .generator = .{
                        .pattern = try b.match(V("B"), try b.map(&.{Ast.exactField("local", V("N"))})),
                        .list = V("Bindings"),
                    } },
                    .{ .filter = .{ .binop = .{ .op = "=:=", .lhs = try b.ptr(V("N")), .rhs = try b.ptr(V("Name")), .parens = false } } },
                }),
            } }, &.{
                try b.clause(&.{try b.cons(&.{V("Hit")}, V("_"))}, &.{}, &.{V("Hit")}),
                try b.clause(&.{try b.list(&.{})}, &.{}, &.{
                    try b.caseOf(.{ .list_comp = .{
                        .element = try b.ptr(V("W")),
                        .qualifiers = try b.arena.dupe(Ast.ListComp.Qualifier, &.{
                            .{ .generator = .{ .pattern = V("W"), .list = V("Words") } },
                            .{ .filter = .{ .binop = .{ .op = "=:=", .lhs = try b.ptr(V("W")), .rhs = try b.ptr(V("Name")), .parens = false } } },
                        }),
                    } }, &.{
                        try b.clause(&.{try b.cons(&.{V("_")}, V("_"))}, &.{}, &.{A("undefined")}),
                        try b.clause(&.{try b.list(&.{})}, &.{}, &.{
                            try throw(b, &.{
                                fail_tag,
                                try b.remote("erlang", "iolist_to_binary", &.{try b.list(&.{
                                    Ast.str(lookup_not_a_word_head),
                                    try b.call("__bp_text", &.{V("Name")}),
                                    Ast.str(lookup_not_a_word_tail),
                                })}),
                                V("Param"),
                                A("null"),
                            }),
                        }),
                    }),
                }),
            }),
        }),
        // ref(#{local := Name}) -> {'__bp_code', __bp_text(Name)}.
        // `Binding.ref()` splices the caller-scope binding back into the
        // expansion as a bare reference, so `return b.ref();` for a hit on
        // `greeting` expands to the identifier `greeting`, not to its value.
        try b.function("ref", &.{try b.map(&.{Ast.exactField("local", V("Name"))})}, &.{}, &.{
            try b.tuple(&.{ code, try b.call("__bp_text", &.{V("Name")}) }),
        }),
        try b.function("build", &.{ V("_Capture"), V("Source") }, &.{}, &.{
            try b.tuple(&.{ code, try b.call("__bp_text", &.{V("Source")}) }),
        }),
        try b.function("custom", &.{ V("_Capture"), V("Tree"), try b.tuple(&.{ code, V("Source") }) }, &.{}, &.{
            try b.tuple(&.{ A("__bp_custom"), V("Tree"), V("Source") }),
        }),
        try b.function("fail", &.{ capture_param, V("Message") }, &.{}, &.{
            try throw(b, &.{ fail_tag, V("Message"), V("Param"), A("null") }),
        }),
        try b.function("failAt", &.{ capture_param, V("Span"), V("Message") }, &.{}, &.{
            try throw(b, &.{ fail_tag, V("Message"), V("Param"), V("Span") }),
        }),
        try b.function("compilerError", &.{V("Message")}, &.{}, &.{
            try throw(b, &.{ fail_tag, V("Message"), A("null"), A("null") }),
        }),
        try b.function("expr", &.{V("Value")}, &.{}, &.{try b.tuple(&.{ A("__bp_value"), V("Value") })}),
        try b.function("code", &.{V("Source")}, &.{}, &.{
            try b.tuple(&.{ code, try b.call("__bp_text", &.{V("Source")}) }),
        }),
        try b.functionClauses("__bp_reply", &.{
            try b.clause(&.{try b.tuple(&.{ code, V("Source") })}, &.{}, &.{
                try b.map(&.{ Ast.field("kind", Ast.str("code")), Ast.field("source", V("Source")) }),
            }),
            try b.clause(&.{try b.tuple(&.{ A("__bp_value"), V("Value") })}, &.{}, &.{
                try b.map(&.{ Ast.field("kind", Ast.str("value")), Ast.field("value", try b.call("__bp_json", &.{V("Value")})) }),
            }),
            try b.clause(&.{try b.tuple(&.{ A("__bp_custom"), V("Tree"), V("Source") })}, &.{}, &.{
                try b.map(&.{
                    Ast.field("kind", Ast.str("custom")),
                    Ast.field("source", V("Source")),
                    Ast.field("ast", try b.call("__bp_json", &.{V("Tree")})),
                }),
            }),
            try b.clause(&.{capture_param}, &.{}, &.{
                try b.map(&.{ Ast.field("kind", Ast.str("capture")), Ast.field("param", V("Param")) }),
            }),
            try b.clause(&.{V("Other")}, &.{}, &.{
                try b.map(&.{
                    Ast.field("kind", Ast.str("error")),
                    Ast.field("message", try b.call("__bp_text", &.{try b.tuple(&.{ A("unsupported_template_result"), V("Other") })})),
                }),
            }),
        }),
    });
    try forms.appendSlice(b.arena, &erlang.comptime_helper_forms);
    return forms.items;
}

/// The host functions of `bp_comptime_decorator`. `fail`/`failAt`/
/// `compilerError` throw a tagged rejection `main/0` catches; `emit` accumulates
/// sources in the process dictionary, newest first, and `'__bp_emitted'/0` reads
/// them back.
pub fn decoratorForms(b: Ast.Builder) Error![]const Ast.Form {
    const V = Ast.Expr.v;
    const A = Ast.Expr.a;
    const fail_tag = A(decorator_fail_tag);
    const key = A(emitted_key);

    var forms: std.ArrayListUnmanaged(Ast.Form) = .empty;
    try forms.appendSlice(b.arena, &.{
        try b.function("fail", &.{ V("_Decl"), V("Message") }, &.{}, &.{
            try b.remote("erlang", "throw", &.{try b.tuple(&.{ fail_tag, V("Message"), A("null") })}),
        }),
        try b.function("failAt", &.{ V("_Decl"), V("Span"), V("Message") }, &.{}, &.{
            try b.remote("erlang", "throw", &.{try b.tuple(&.{ fail_tag, V("Message"), V("Span") })}),
        }),
        try b.function("compilerError", &.{V("Message")}, &.{}, &.{
            try b.remote("erlang", "throw", &.{try b.tuple(&.{ fail_tag, V("Message"), A("null") })}),
        }),
        // Every output of a decorator body is one tagged map on the same list
        // (decision 216): `emit` (a loose top-level declaration), `addMember`
        // (a member of the annotated type), `setMeta` (a comptime key/value)
        // and `addType` (a type associated with the annotated one). The
        // compiler reads the list back in call order (`decorator_eval.Reply`).
        try b.function("emit", &.{V("Source")}, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("emit")), Ast.field("source", V("Source")) })}),
        }),
        try b.function("addMember", &.{ V("_Decl"), V("Source") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("member")), Ast.field("source", V("Source")) })}),
        }),
        // Decision 370 (2) — `decl.addMember(name, fn…)`: the function is the
        // program's code, so the body hands its index (`expr_param.eraseFn`,
        // `member_fn.collect`'s order) and the name it gets.
        try b.function("addMember", &.{ V("_Decl"), V("Name"), V("Index") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("memberFn")), Ast.field("name", V("Name")), Ast.field("index", V("Index")) })}),
        }),
        try b.function("setMeta", &.{ V("_Decl"), V("Key"), V("Value") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("meta")), Ast.field("key", V("Key")), Ast.field("value", V("Value")) })}),
        }),
        try b.function("addType", &.{ V("_Decl"), V("Name"), V("Source") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("assoc")), Ast.field("name", V("Name")), Ast.field("source", V("Source")) })}),
        }),
        // Decision 298 — `decl.setMeta(v)` / `decl.addMeta(v)`: the body hands
        // the call's index (`expr_param.eraseFn`, `typed_meta.collect`'s
        // order) and the record it built, which the compiler writes back as
        // the constructor's arguments (`typed_meta.render`).
        try b.function(typed_meta_fn, &.{ V("Index"), V("Value") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("typedMeta")), Ast.field("index", V("Index")), Ast.field("data", try b.call(meta_json_fn, &.{V("Value")})) })}),
        }),
        // A comptime `null` is the atom `undefined`, which `json:encode`
        // writes as the string "undefined" — the same text as that string:
        // the value is walked first, `undefined` becoming `null`.
        try b.functionClauses(meta_json_fn, &.{
            try b.clause(&.{A("undefined")}, &.{}, &.{A("null")}),
            try b.clause(&.{V("V")}, &.{try b.call("is_map", &.{V("V")})}, &.{
                try b.remote("maps", "from_list", &.{.{ .list_comp = .{
                    .element = try b.ptr(try b.tuple(&.{ V("K"), try b.call(meta_json_fn, &.{V("X")}) })),
                    .qualifiers = try b.arena.dupe(Ast.ListComp.Qualifier, &.{
                        .{ .generator = .{ .pattern = try b.tuple(&.{ V("K"), V("X") }), .list = try b.remote("maps", "to_list", &.{V("V")}) } },
                    }),
                } }}),
            }),
            try b.clause(&.{V("V")}, &.{try b.call("is_list", &.{V("V")})}, &.{
                .{ .list_comp = .{
                    .element = try b.ptr(try b.call(meta_json_fn, &.{V("X")})),
                    .qualifiers = try b.arena.dupe(Ast.ListComp.Qualifier, &.{
                        .{ .generator = .{ .pattern = V("X"), .list = V("V") } },
                    }),
                } },
            }),
            try b.clause(&.{V("V")}, &.{}, &.{V("V")}),
        }),
        try b.function("__bp_contribute", &.{V("Item")}, &.{}, &.{
            try b.remote("erlang", "put", &.{ key, try b.cons(&.{V("Item")}, try b.call("__bp_emitted", &.{})) }),
            A("ok"),
        }),
        try b.function("__bp_emitted", &.{}, &.{}, &.{
            try b.caseOf(try b.remote("erlang", "get", &.{key}), &.{
                try b.clause(&.{A("undefined")}, &.{}, &.{try b.list(&.{})}),
                try b.clause(&.{V("Sources")}, &.{}, &.{V("Sources")}),
            }),
        }),
        // Decision 364 (3) — `x.fail(m)` on a decorator parameter
        // (`comptime/expr_param.zig`): the span names the parameter's index
        // after the `@Decl` one, and the checker reports at its argument.
        try b.function(fail_arg_fn, &.{ V("Index"), V("Message") }, &.{}, &.{
            try b.remote("erlang", "throw", &.{try b.tuple(&.{ fail_tag, V("Message"), try b.map(&.{Ast.field("arg", V("Index"))}) })}),
        }),
    });
    try forms.appendSlice(b.arena, &erlang.comptime_helper_forms);
    return forms.items;
}

// ── rendering ─────────────────────────────────────────────────────────────────

/// `name/arity` of every function form, in order and de-duplicated — the
/// prelude's `-export` list and, on the other side, the generated module's
/// `-import` list. Both are derived from the same forms, so a function cannot
/// be imported that the prelude does not export.
pub fn exportRefs(arena: std.mem.Allocator, forms: []const Ast.Form) Error![]const Ast.FnRef {
    var refs: std.ArrayListUnmanaged(Ast.FnRef) = .empty;
    for (forms) |form| switch (form) {
        .function => |f| {
            if (f.clauses.len == 0) continue;
            const ref: Ast.FnRef = .{ .name = f.name, .arity = f.clauses[0].patterns.len };
            for (refs.items) |seen| {
                if (seen.arity == ref.arity and std.mem.eql(u8, seen.name, ref.name)) break;
            } else try refs.append(arena, ref);
        },
        else => {},
    };
    return refs.items;
}

/// One prelude module as Erlang source: the header, an `-export` naming every
/// function, then the forms.
pub fn render(arena: std.mem.Allocator, name: []const u8, forms: []const Ast.Form) ![]u8 {
    var out: std.ArrayListUnmanaged(Ast.Form) = .empty;
    try out.appendSlice(arena, &.{
        .{ .comment = .{ .level = .module, .text = "Resident comptime host glue — built once at server warmup." } },
        .{ .module = name },
        .{ .exports = try exportRefs(arena, forms) },
    });
    for (forms) |form| try out.appendSlice(arena, &.{ .blank, form });

    var aw: std.Io.Writer.Allocating = .init(arena);
    try erlEmitter.writeForms(&aw.writer, out.items);
    return aw.toOwnedSlice();
}

/// Both prelude modules, built into `arena`. `render_resident.zig` writes them
/// for `erlc` at `zig build` time; the wat runtime parses them.
pub fn modules(arena: std.mem.Allocator) ![]const Module {
    const b: Ast.Builder = .{ .arena = arena };
    const out = try arena.alloc(Module, 2);
    out[0] = .{ .name = template_module, .source = try render(arena, template_module, try templateForms(b)) };
    out[1] = .{ .name = decorator_module, .source = try render(arena, decorator_module, try decoratorForms(b)) };
    return out;
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "prelude: both modules render, export every function and define no main" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const mods = try modules(arena);
    try std.testing.expectEqual(@as(usize, 2), mods.len);

    const tpl = mods[0].source;
    try std.testing.expect(std.mem.startsWith(u8, tpl, "%%% Resident comptime host glue"));
    for ([_][]const u8{
        "-module(bp_comptime_template).",
        "text/1",
        "parts/1",
        "lookup/2",
        "ref/1",
        "build/2",
        "custom/3",
        "fail/2",
        "failAt/3",
        "compilerError/1",
        "expr/1",
        "code/1",
        "'__bp_reply'/1",
        "'__bp_add'/2",
        "'__bp_len'/2",
        "'__bp_text'/1",
        "'__bp_json'/1",
    }) |needle| {
        if (std.mem.indexOf(u8, tpl, needle) == null) {
            std.debug.print("\nmissing {s} in:\n{s}\n", .{ needle, tpl });
            return error.TestExpectedContains;
        }
    }

    const dec = mods[1].source;
    try std.testing.expect(std.mem.indexOf(u8, dec, "-module(bp_comptime_decorator).") != null);
    try std.testing.expect(std.mem.indexOf(u8, dec, "'__bp_emitted'/0") != null);
    // The capture API is the template's alone; a decorator body has no capture.
    try std.testing.expect(std.mem.indexOf(u8, dec, "lookup/2") == null);

    // `main/0` is the one host form whose text depends on the call site, so it
    // stays in the generated module and never reaches a prelude.
    for (mods) |m| try std.testing.expect(std.mem.indexOf(u8, m.source, "main/0") == null);
}

test "prelude: exportRefs de-duplicates a multi-clause function" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const refs = try exportRefs(arena, &erlang.comptime_helper_forms);
    // `'__bp_json'/1` has five clauses and `'__bp_add'/2` two; four refs.
    try std.testing.expectEqual(@as(usize, 4), refs.len);
    try std.testing.expectEqualStrings("__bp_add", refs[0].name);
    try std.testing.expectEqual(@as(usize, 2), refs[0].arity);
    try std.testing.expectEqualStrings("__bp_json", refs[3].name);
    try std.testing.expectEqual(@as(usize, 1), refs[3].arity);
}
