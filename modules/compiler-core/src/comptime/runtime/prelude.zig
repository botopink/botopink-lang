//! The comptime evaluators' resident prelude.
//!
//! A template or a decorator body is lowered into a generated Erlang module,
//! which the wasm comptime runtime parses and lowers before it runs
//! (`wat/program.zig`). Until 1.0.5-beta every one of
//! those modules also carried the host glue — the capture API, the reply
//! encoder, the failure throws and the untyped helpers of
//! `codegen/erlang.zig`'s `comptime_helper_forms` — and those forms are
//! **byte-identical in every module the compiler has ever produced**: 54 of the
//! 295 lines of the smallest realistic module, and the part of it the Erlang
//! front end actually works for (guards, list comprehensions, multi-clause
//! heads). The data literal that does differ per call site is a term, which is
//! cheap to compile.
//!
//! So they move here. Two modules, rendered from `erl_ast` forms and parsed
//! once per process by the wat runtime (`wat/program.zig`), which lowers what
//! a generated module reaches of them into the same wasm program; a generated
//! module reaches them by `-import`, which leaves the lowered body's own text
//! unchanged:
//!
//!   bp_comptime_template    the capture API (`text/1`, `source/1`,
//!                           `context/1`, `bindings/1`, `lookup/2`, `ref/1`),
//!                           the result constructors (`build/2`, `ast/2`, `custom/3`,
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
/// `{'__bp_ast', Node}` — what `ast/2` returns (decision 625 (2)).
pub const ast_tag = "__bp_ast";
/// Decision 637 — the resident function a template call in a body that runs
/// at build is lowered to the argument of (`infer.zig`
/// `lowerBuildTemplateCalls`): `'__bp_captureOf'(Text, Holes)`.
pub const capture_of_fn = "__bp_captureOf";
/// The parameter name of the capture `capture_of_fn` builds: no template's.
pub const nested_capture_param = "__bp_nested";
/// Decision 237 — the message `lookup/2` fails the template with when its name
/// is not a word of the captured text: head ++ Name ++ tail. ASCII only: the
/// prelude's binary literals carry bytes, not code points.
pub const lookup_not_a_word_head = "lookup(\"";
/// Decision 415 (3), 372's pattern — the meta of a looked-up declaration of
/// the module whose `.hooks` reader has not run yet: `{'__bp_pending', Name}`
/// in place of the list, refused at its read.
pub const meta_pending_tag = "__bp_pending";
/// Decision 426 — `q.build(src, i)` records `i`, the build the body answers
/// (`template_eval.numberBuilds`), and `q.note(m)` a reason for an error at
/// the call; `main/1` resets both before the body and `'__bp_extras'/1` adds
/// them to the reply (`build`, `notes`, latest first).
pub const build_key = "__bp_build";
pub const notes_key = "__bp_notes";
pub const extras_fn = "__bp_extras";
pub const extras_reset_fn = "__bp_extrasReset";
pub const meta_pending_head = "typeinfo-meta-hooks-pending: `";
pub const meta_pending_tail = "` carries a decorator that reads `.hooks`, which records its meta after this read";
pub const lookup_not_a_word_tail = "\"): not a word of the template's text; a template capture carries only the bindings whose name its text spells";
/// The process-dictionary key `emit/1` accumulates under.
pub const emitted_key = "__bp_emitted";

pub const Error = Ast.Builder.Error;

/// Decision 364 (3) — the function a decorator body's `x.fail(m)` becomes
/// (`comptime/syntax_param.zig`): `'__bp_failArg'(Index, Message)`.
pub const fail_arg_fn = "__bp_failArg";

/// Decision 576 (2) — the function a decorator body's `compiler.text(x)`
/// becomes (`comptime/syntax_param.zig`): `'__bp_argText'(Index)`, the
/// argument as the annotation wrote it, read from `arg_texts_key`, which
/// `main/1` sets (`decorator_eval.zig`).
pub const arg_text_fn = "__bp_argText";
pub const arg_texts_key = "__bp_arg_texts";

/// Decision 643 — the function a decorator body's `compiler.name(x)` becomes
/// (`comptime/syntax_param.zig`): `'__bp_argName'(Index)`, the name the
/// argument is written as, or `undefined` (`null`) when it is a lambda, a
/// literal, a call or an operator expression. Each `arg_texts_key` entry is
/// `{Text, Name}`, `Name` a binary or `undefined` (`decorator_eval.zig`
/// `argNameTerm`).
pub const arg_name_fn = "__bp_argName";

/// Decision 298 — the function `decl.setMeta(v)` / `decl.addMeta(v)` becomes
/// in a decorator body (`typed_meta.typed_meta_fn`).
pub const typed_meta_fn = "__bp_typedMeta";

/// Question s29-b — the functions `m.meta(T)` / `m.metaAll(T)` on a
/// `decl.methods` entry become in a decorator body (`syntax_param.eraseForRun`).
pub const method_meta_fn = "__bp_methodMeta";
pub const method_meta_all_fn = "__bp_methodMetaAll";

/// Decision 302 — what `q.annotate(decl, at)` throws when the call has no
/// answer yet: `{'__bp_template_need', Request, Span}`, caught by the template's
/// `main/1`, which replies `{"kind":"need", …}`; the compiler runs the
/// annotation and evaluates the body again with the answer
/// (`template_eval.zig` § tag annotations).
pub const template_need_tag = "__bp_template_need";
/// The capture key the answers ride under, in call order.
pub const annotations_key = "__bp_annotations";
/// The process-dictionary key counting a run's `annotate` calls.
const annotate_count_key = "__bp_annotate_n";
/// An answered handle's index among the answers (`Request.answer`).
pub const answer_key = "__bp_answer";

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
        .{ "text", "Text" },       .{ "source", "Source" },
        .{ "context", "Context" }, .{ "bindings", "Bindings" },
        .{ "name", "Name" },
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
        try b.function("build", &.{ V("_Capture"), V("Source") }, &.{}, &.{
            try b.tuple(&.{ code, try b.call("__bp_text", &.{V("Source")}) }),
        }),
        try b.function("build", &.{ V("_Capture"), V("Source"), V("At") }, &.{}, &.{
            try b.remote("erlang", "put", &.{ A(build_key), V("At") }),
            try b.tuple(&.{ code, try b.call("__bp_text", &.{V("Source")}) }),
        }),
        // Decision 625 (2) — `q.ast(node)`: the tree, encoded whole by the
        // reply; `ast/3` records the index as `build/3` does.
        try b.function("ast", &.{ V("_Capture"), V("Node") }, &.{}, &.{
            try b.tuple(&.{ A(ast_tag), V("Node") }),
        }),
        try b.function("ast", &.{ V("_Capture"), V("Node"), V("At") }, &.{}, &.{
            try b.remote("erlang", "put", &.{ A(build_key), V("At") }),
            try b.tuple(&.{ A(ast_tag), V("Node") }),
        }),
        // Decision 637 — `compiler.holes(t)`: the holes a capture carries
        // (the caller's hole expressions, or the values a body that runs at
        // build handed a template, `'__bp_captureOf'/2`).
        try b.functionClauses("holes", &.{
            try b.clause(&.{try b.map(&.{Ast.exactField("holes", V("Holes"))})}, &.{}, &.{V("Holes")}),
            try b.clause(&.{V("_Capture")}, &.{}, &.{try b.list(&.{})}),
        }),
        // Decision 637 — `compiler.isSyntax(v)`: a `syntax` value is a
        // capture.
        try b.functionClauses("isSyntax", &.{
            try b.clause(&.{ V("_Capture"), try b.map(&.{.{ .key = A("__bp_capture"), .value = V("_"), .exact = true }}) }, &.{}, &.{A("true")}),
            try b.clause(&.{ V("_Capture"), V("_") }, &.{}, &.{A("false")}),
        }),
        // Decision 637 — a template called in a body that runs at build
        // (`` code @`…` ``) receives its text as a capture whose holes are the
        // values the body computed for them.
        try b.function(capture_of_fn, &.{ V("Text"), V("Holes") }, &.{}, &.{
            try b.map(&.{
                .{ .key = A("__bp_capture"), .value = Ast.str(nested_capture_param) },
                Ast.field("text", V("Text")),
                Ast.field("holes", V("Holes")),
                Ast.field("source", try b.map(&.{ Ast.field("file", Ast.str("")), Ast.field("line", Ast.Expr.r("0")), Ast.field("col", Ast.Expr.r("0")) })),
                Ast.field("context", try b.map(&.{})),
                Ast.field("bindings", try b.list(&.{})),
                Ast.field("words", try b.list(&.{})),
                Ast.field("name", A("undefined")),
            }),
        }),
        try b.function("note", &.{ V("_Capture"), V("Message") }, &.{}, &.{
            try b.remote("erlang", "put", &.{ A(notes_key), try b.cons(&.{try b.call("__bp_text", &.{V("Message")})}, try b.call("__bp_notes", &.{})) }),
            A("ok"),
        }),
        try b.function("__bp_notes", &.{}, &.{}, &.{
            try b.caseOf(try b.remote("erlang", "get", &.{A(notes_key)}), &.{
                try b.clause(&.{A("undefined")}, &.{}, &.{try b.list(&.{})}),
                try b.clause(&.{V("Notes")}, &.{}, &.{V("Notes")}),
            }),
        }),
        try b.function(extras_reset_fn, &.{}, &.{}, &.{
            try b.remote("erlang", "erase", &.{A(build_key)}),
            try b.remote("erlang", "erase", &.{A(notes_key)}),
        }),
        try b.function(extras_fn, &.{V("Reply")}, &.{}, &.{
            try b.match(V("WithBuild"), try b.caseOf(try b.remote("erlang", "get", &.{A(build_key)}), &.{
                try b.clause(&.{A("undefined")}, &.{}, &.{V("Reply")}),
                try b.clause(&.{V("At")}, &.{}, &.{try b.remote("maps", "put", &.{ A("build"), V("At"), V("Reply") })}),
            })),
            try b.caseOf(try b.call("__bp_notes", &.{}), &.{
                try b.clause(&.{try b.list(&.{})}, &.{}, &.{V("WithBuild")}),
                try b.clause(&.{V("Notes")}, &.{}, &.{try b.remote("maps", "put", &.{ A("notes"), V("Notes"), V("WithBuild") })}),
            }),
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
        // Decision 302 — tagDecl(_Capture, Kind, Name, Attrs): a tag's handle,
        // the keys of a declaration's (`decorator_eval.handleToTerm`) with the
        // tag's `attrs` and an empty `meta`.
        try b.function("tagDecl", &.{ V("_Capture"), V("Kind"), V("Name"), V("Attrs") }, &.{}, &.{
            try b.map(&.{
                Ast.field("kind", V("Kind")),
                Ast.field("name", V("Name")),
                Ast.field("fields", try b.list(&.{})),
                Ast.field("variants", try b.list(&.{})),
                Ast.field("methods", try b.list(&.{})),
                Ast.field("returnType", Ast.str("")),
                Ast.field("annotations", try b.list(&.{})),
                Ast.field("hooks", try b.list(&.{})),
                Ast.field("params", try b.list(&.{})),
                Ast.field("component", A("undefined")),
                Ast.field("module", Ast.str("")),
                Ast.field("owner", A("undefined")),
                Ast.field("attrs", V("Attrs")),
                Ast.field("meta", try b.list(&.{})),
            }),
        }),
        // annotate(Capture, Decl, Span): the run's N-th call answers the N-th
        // answer the capture carries; past them it throws the request — the
        // tag (its kind, name, attributes, and the answer it is, -1 for a
        // fresh one) and the span of the annotation in the text.
        try b.function("annotate", &.{ V("Capture"), V("Decl"), V("Span") }, &.{}, &.{
            try b.match(V("N"), try b.caseOf(try b.remote("erlang", "get", &.{A(annotate_count_key)}), &.{
                try b.clause(&.{A("undefined")}, &.{}, &.{Ast.Expr.r("0")}),
                try b.clause(&.{V("Seen")}, &.{}, &.{V("Seen")}),
            })),
            try b.remote("erlang", "put", &.{ A(annotate_count_key), try b.binop("+", V("N"), Ast.Expr.r("1")) }),
            try b.match(V("Answers"), try b.remote("maps", "get", &.{ A(annotations_key), V("Capture"), try b.list(&.{}) })),
            try b.caseOf(try b.binop("<", V("N"), try b.call("length", &.{V("Answers")})), &.{
                try b.clause(&.{A("true")}, &.{}, &.{try b.remote("lists", "nth", &.{ try b.binop("+", V("N"), Ast.Expr.r("1")), V("Answers") })}),
                try b.clause(&.{A("false")}, &.{}, &.{
                    try throw(b, &.{
                        A(template_need_tag),
                        try b.map(&.{
                            Ast.field("kind", try b.remote("maps", "get", &.{ A("kind"), V("Decl") })),
                            Ast.field("name", try b.remote("maps", "get", &.{ A("name"), V("Decl") })),
                            Ast.field("attrs", try b.remote("maps", "get", &.{ A("attrs"), V("Decl"), try b.list(&.{}) })),
                            Ast.field("answer", try b.remote("maps", "get", &.{ A(answer_key), V("Decl"), Ast.Expr.r("-1") })),
                        }),
                        V("Span"),
                    }),
                }),
            }),
        }),
        try b.function("__bp_annotateReset", &.{}, &.{}, &.{try b.remote("erlang", "erase", &.{A(annotate_count_key)})}),
        try b.functionClauses("__bp_reply", &.{
            try b.clause(&.{try b.tuple(&.{ code, V("Source") })}, &.{}, &.{
                try b.map(&.{ Ast.field("kind", Ast.str("code")), Ast.field("source", V("Source")) }),
            }),
            try b.clause(&.{try b.tuple(&.{ A(ast_tag), V("Node") })}, &.{}, &.{
                try b.map(&.{ Ast.field("kind", Ast.str("ast")), Ast.field("node", try b.call("__bp_json", &.{V("Node")})) }),
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
    try forms.appendSlice(b.arena, try tagForms(b));
    try forms.appendSlice(b.arena, &erlang.comptime_helper_forms);
    return forms.items;
}

/// Decision 302 — the handle's reads a tag adds, in both preludes: `attr/2`
/// (`decl.attr(name)`, `undefined` on a declaration, whose handle has no
/// `attrs`) and the typed meta reads `d.meta(T)` / `d.metaAll(T)` become
/// (`'__bp_methodMeta'/2`, a method entry's shape: `meta =>
/// [#{type, value}]`).
fn tagForms(b: Ast.Builder) Error![]const Ast.Form {
    const V = Ast.Expr.v;
    const A = Ast.Expr.a;
    return b.arena.dupe(Ast.Form, &.{
        try b.functionClauses("attr", &.{
            try b.clause(&.{ try b.map(&.{Ast.exactField("attrs", V("Attrs"))}), V("Name") }, &.{}, &.{
                try b.caseOf(try b.remote("lists", "keyfind", &.{ V("Name"), Ast.Expr.r("1"), V("Attrs") }), &.{
                    try b.clause(&.{try b.tuple(&.{ V("_"), V("Value") })}, &.{}, &.{V("Value")}),
                    try b.clause(&.{A("false")}, &.{}, &.{A("undefined")}),
                }),
            }),
            try b.clause(&.{ V("_Decl"), V("_Name") }, &.{}, &.{A("undefined")}),
        }),
        try b.functionClauses(method_meta_all_fn, &.{
            try b.clause(&.{ try b.map(&.{Ast.exactField("meta", try b.tuple(&.{ A(meta_pending_tag), V("Name") }))}), V("_Type") }, &.{}, &.{
                try b.remote("erlang", "throw", &.{try b.tuple(&.{
                    A(template_fail_tag),
                    try b.remote("erlang", "iolist_to_binary", &.{try b.list(&.{ Ast.str(meta_pending_head), V("Name"), Ast.str(meta_pending_tail) })}),
                    A("null"),
                    A("null"),
                })}),
            }),
            try b.clause(&.{ try b.map(&.{Ast.exactField("meta", V("Metas"))}), V("Type") }, &.{}, &.{
                .{ .list_comp = .{
                    .element = try b.ptr(V("Value")),
                    .qualifiers = try b.arena.dupe(Ast.ListComp.Qualifier, &.{
                        .{ .generator = .{ .pattern = try b.map(&.{ Ast.exactField("type", V("T")), Ast.exactField("value", V("Value")) }), .list = V("Metas") } },
                        .{ .filter = .{ .binop = .{ .op = "=:=", .lhs = try b.ptr(V("T")), .rhs = try b.ptr(V("Type")), .parens = false } } },
                    }),
                } },
            }),
        }),
        try b.function(method_meta_fn, &.{ V("Method"), V("Type") }, &.{}, &.{
            try b.caseOf(try b.call(method_meta_all_fn, &.{ V("Method"), V("Type") }), &.{
                try b.clause(&.{try b.cons(&.{V("First")}, V("_"))}, &.{}, &.{V("First")}),
                try b.clause(&.{try b.list(&.{})}, &.{}, &.{A("undefined")}),
            }),
        }),
    });
}

/// Decision 311 — the capture API a template annotation's body reads its
/// literal through (`text/1`, `source/1`, `context/1`,
/// `bindings/1`, `lookup/2`, `ref/1`) and the result constructors its
/// `return` builds (`build/2`, `custom/3`, `expr/1`, `code/1`): the template
/// prelude's forms of those names. A template annotation runs on the
/// decorator prelude (its handle's `fail`, `setMeta`, …), so these are
/// rendered into its module instead of imported — a second resident would
/// clash with the decorator's `fail/2` / `failAt/3` / `compilerError/1`, which
/// are not carried (the handle's report at the annotation).
pub fn captureForms(b: Ast.Builder) Error![]const Ast.Form {
    const names = [_][]const u8{ "text", "name", "source", "context", "bindings", "lookup", "ref", "build", "ast", "holes", "isSyntax", capture_of_fn, "custom", "expr", "code" };
    var out: std.ArrayListUnmanaged(Ast.Form) = .empty;
    for (try templateForms(b)) |form| switch (form) {
        .function => |f| for (names) |n| {
            if (std.mem.eql(u8, f.name, n)) {
                try out.append(b.arena, form);
                break;
            }
        },
        else => {},
    };
    return out.items;
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
        try b.function(arg_text_fn, &.{V("Index")}, &.{}, &.{
            try b.remote("erlang", "element", &.{ Ast.Expr.r("1"), try b.remote("lists", "nth", &.{ try b.binop("+", V("Index"), Ast.Expr.r("1")), try b.remote("erlang", "get", &.{A(arg_texts_key)}) }) }),
        }),
        try b.function("emit", &.{V("Source")}, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("emit")), Ast.field("source", V("Source")) })}),
        }),
        try b.function("addMember", &.{ V("_Decl"), V("Source") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("member")), Ast.field("source", V("Source")) })}),
        }),
        // Decision 370 (2) — `decl.addMember(name, fn…)`: the function is the
        // program's code, so the body hands its index (`syntax_param.eraseFn`,
        // `member_fn.collect`'s order) and the name it gets.
        try b.function("addMember", &.{ V("_Decl"), V("Name"), V("Index") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("memberFn")), Ast.field("name", V("Name")), Ast.field("index", V("Index")) })}),
        }),
        // Decision 575 (4), the tree rule — the body's locals the member
        // reads, their values in `member_fn.capturedLocals`'s order; the
        // compiler spells each as a literal in the member.
        try b.function("addMember", &.{ V("_Decl"), V("Name"), V("Index"), V("Captured") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("memberFn")), Ast.field("name", V("Name")), Ast.field("index", V("Index")), Ast.field("data", try b.call(meta_json_fn, &.{V("Captured")})) })}),
        }),
        // Decision 575 (3) — `decl.compile(f)`: the executor is the
        // program's code, so the body hands its index (`syntax_param.eraseFn`,
        // `member_fn.collectExecutors`'s order) and, by the tree rule, the
        // values of the body's locals it reads.
        try b.function("compile", &.{ V("_Decl"), V("Index") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("compile")), Ast.field("index", V("Index")) })}),
        }),
        try b.function("compile", &.{ V("_Decl"), V("Index"), V("Captured") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("compile")), Ast.field("index", V("Index")), Ast.field("data", try b.call(meta_json_fn, &.{V("Captured")})) })}),
        }),
        try b.function("setMeta", &.{ V("_Decl"), V("Key"), V("Value") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("meta")), Ast.field("key", V("Key")), Ast.field("value", V("Value")) })}),
        }),
        try b.function("addType", &.{ V("_Decl"), V("Name"), V("Source") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("assoc")), Ast.field("name", V("Name")), Ast.field("source", V("Source")) })}),
        }),
        // Decision 575 (6) — `compiler.implement(source)`: the
        // `Implementation` the body built, as JSON (`implementations.ofJson`).
        try b.function("implement", &.{ V("_Decl"), V("Value") }, &.{}, &.{
            try b.call("__bp_contribute", &.{try b.map(&.{ Ast.field("kind", Ast.str("implement")), Ast.field("data", try b.call(meta_json_fn, &.{V("Value")})) })}),
        }),
        // Decision 298 — `decl.setMeta(v)` / `decl.addMeta(v)`: the body hands
        // the call's index (`syntax_param.eraseFn`, `typed_meta.collect`'s
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
            // A tuple field (144 B-19): `{"tuple": [...]}`, its items walked.
            try b.clause(&.{V("V")}, &.{try b.call("is_tuple", &.{V("V")})}, &.{
                try b.map(&.{Ast.field("tuple", .{ .list_comp = .{
                    .element = try b.ptr(try b.call(meta_json_fn, &.{V("X")})),
                    .qualifiers = try b.arena.dupe(Ast.ListComp.Qualifier, &.{
                        .{ .generator = .{ .pattern = V("X"), .list = try b.call("tuple_to_list", &.{V("V")}) } },
                    }),
                } })}),
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
        // (`comptime/syntax_param.zig`): the span names the parameter's index
        // after the `@Decl` one, and the checker reports at its argument.
        try b.function(fail_arg_fn, &.{ V("Index"), V("Message") }, &.{}, &.{
            try b.remote("erlang", "throw", &.{try b.tuple(&.{ fail_tag, V("Message"), try b.map(&.{Ast.field("arg", V("Index"))}) })}),
        }),
        try b.function(arg_name_fn, &.{V("Index")}, &.{}, &.{
            try b.remote("erlang", "element", &.{ Ast.Expr.r("2"), try b.remote("lists", "nth", &.{ try b.binop("+", V("Index"), Ast.Expr.r("1")), try b.remote("erlang", "get", &.{A(arg_texts_key)}) }) }),
        }),
    });
    // Question s29-b — `m.meta(T)` / `m.metaAll(T)` on a `decl.methods`
    // entry (`comptime/syntax_param.zig` `eraseForRun`): the values of record
    // type `T` the method's decorators recorded, `undefined` / `[]` when
    // none; and decision 302's `decl.attr(name)`.
    try forms.appendSlice(b.arena, try tagForms(b));
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

/// Both prelude modules, built into `arena`; the wat runtime parses them.
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
        "lookup/2",
        "build/2",
        "build/3",
        "note/2",
        "'__bp_extras'/1",
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
    // `'__bp_json'/1` has five clauses and `'__bp_add'/2` two; six refs, the
    // two frame helpers (`'__bp_push'/4`, `'__bp_frames'/1`, decision 532)
    // among them.
    try std.testing.expectEqual(@as(usize, 6), refs.len);
    try std.testing.expectEqualStrings("__bp_add", refs[0].name);
    try std.testing.expectEqual(@as(usize, 2), refs[0].arity);
    try std.testing.expectEqualStrings("__bp_push", refs[3].name);
    try std.testing.expectEqual(@as(usize, 4), refs[3].arity);
    try std.testing.expectEqualStrings("__bp_frames", refs[4].name);
    try std.testing.expectEqual(@as(usize, 1), refs[4].arity);
    try std.testing.expectEqualStrings("__bp_json", refs[5].name);
    try std.testing.expectEqual(@as(usize, 1), refs[5].arity);
}
