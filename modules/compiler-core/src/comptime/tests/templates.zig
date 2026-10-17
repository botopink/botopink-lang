//! comptime: `@Expr` template capture, scope snapshot, template methods,
//! `fail`/`failAt` span mapping, and call-site expansion (expr-templates).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const snapMod = @import("../../utils/snap.zig");
const envMod = @import("../env.zig");
const inferMod = @import("../infer.zig");
const comptimeMod = @import("../../comptime.zig");
const template = @import("../template.zig");
/// Test-only: the one way a test spells a path it writes to (per process, so a
/// second `zig build test` over this checkout cannot empty it mid-test).
/// `build.zig` gives this module to the test modules alone.
const test_scratch = @import("test_scratch");
const templateEval = @import("../template_eval.zig");
const erlEmitter = @import("../../codegen/beam/erl_emitter.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;
const h = @import("helpers.zig");

/// Parse + infer `src` into `env` (builtins + stdlib preloaded). The caller
/// owns `env` (deinit) and the arena everything is allocated in.
fn inferInto(env: *Env, arena: std.mem.Allocator, src: []const u8) !void {
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const program = try p.parse(arena);
    _ = inferMod.inferProgramTyped(env, program) catch |err| {
        if (env.lastError) |te| {
            const desc = try h.renderTypeError(std.testing.allocator, src, te);
            defer std.testing.allocator.free(desc);
            std.debug.print("\nunexpected type error:\n{s}\n", .{desc});
        }
        return err;
    };
}

fn freshTestEnv(arena: std.mem.Allocator) !Env {
    var env = Env.init(arena);
    errdefer env.deinit();
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, std.testing.allocator);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));
    return env;
}

/// The single capture list recorded during inference (asserts exactly one call
/// site captured).
fn onlyCaptures(env: *Env) ![]const template.CapturedExpr {
    try std.testing.expectEqual(@as(usize, 1), env.exprCaptures.count());
    var it = env.exprCaptures.valueIterator();
    return it.next().?.*;
}

test "template: expr param capture ---- plain string arg arrives unevaluated" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn sql(expr q: string) -> string {
        \\    return q;
        \\}
        \\val stmt = sql @`SELECT 1`;
    );

    const captures = try onlyCaptures(&env);
    try std.testing.expectEqual(@as(usize, 1), captures.len);
    const cap = captures[0];
    try std.testing.expectEqualStrings("sql", cap.callee);
    try std.testing.expectEqualStrings("q", cap.paramName);
    try std.testing.expectEqual(@as(usize, 0), cap.paramIndex);
    try std.testing.expectEqualStrings("SELECT 1", cap.text.?);
    try std.testing.expect(!cap.multiline);
    // The captured node is the literal exactly as parsed — unevaluated.
    try std.testing.expect(cap.node.* == .literal);
    try std.testing.expect(cap.node.literal.kind == .stringLit);
}

test "template: expr param capture ---- a @` text keeps its raw bytes (quotes, newlines) and is multiline when it spans lines" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn conf(expr q: string) -> string {
        \\    return q;
        \\}
        \\val c = conf @`a: "x"
        \\b: 1`;
    );

    const cap = (try onlyCaptures(&env))[0];
    try std.testing.expectEqualStrings("a: \"x\"\nb: 1", cap.text.?);
    try std.testing.expect(cap.multiline);
}

test "template: expr param capture ---- a one-line @` text is not multiline" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn conf(expr q: string) -> string {
        \\    return q;
        \\}
        \\val c = conf @`say "hi"`;
    );

    const cap = (try onlyCaptures(&env))[0];
    try std.testing.expectEqualStrings("say \"hi\"", cap.text.?);
    try std.testing.expect(!cap.multiline);
}

test "template: scope snapshot lookup ---- hit and miss" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub type Button(
        \\    label: string,
        \\)
        \\pub fn html(expr template: string) -> string {
        \\    return template;
        \\}
        \\val c = html @`
        \\<Button/>
        \\`;
    );

    const captures = try onlyCaptures(&env);
    const scope = captures[0].scope.?;
    // Hits: the caller's top-level decls, with their kinds.
    try std.testing.expectEqual(template.BindingKind.struct_, scope.lookup("Button").?.kind);
    try std.testing.expectEqual(template.BindingKind.fn_, scope.lookup("html").?.kind);
    try std.testing.expectEqual(template.BindingKind.val, scope.lookup("c").?.kind);
    // Miss: typo'd component is simply absent (`lookup` surfaces @Option none).
    try std.testing.expect(scope.lookup("Buttom") == null);

    // The serializable handle for the expansion runtime (F6).
    const json = try scope.toJsonAlloc(std.testing.allocator);
    defer std.testing.allocator.free(json);
    try std.testing.expectEqualStrings(
        \\{"Button":"Record_","html":"Fn","c":"Val"}
    , json);
}

test "template: expr methods typecheck and record lowerings" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn html(expr template: string) -> string {
        \\    val sp = Span(0, 1, 1);
        \\    val t = compiler.text(template);
        \\    val where = compiler.source(template);
        \\    val ctx = compiler.context(template);
        \\    val scope = compiler.bindings(template);
        \\    val b = compiler.lookup(template, "Button");
        \\    val made = compiler.build("1 + 2");
        \\    val node = CustomNode(kind: "expr", span: sp, label: "number", ref: b, children: []);
        \\    compiler.custom(node);
        \\    val tag = compiler.tagDecl(DeclKind.Element, "div", [#("id", "x")]);
        \\    val annotated = compiler.annotate(tag, sp);
        \\    compiler.fail("bad tag", at: template, span: sp);
        \\    compiler.fail("no component", at: template);
        \\    compiler.note("a reason");
        \\    return template;
        \\}
        \\import {compiler.Span, compiler.CustomNode, compiler.DeclKind} from "std";
    );

    // Decision 576 (2) — every template op but `.value` (an `expr` is
    // opaque: its value is no `compiler` member).
    try std.testing.expectEqual(@as(usize, 12), env.templateLowerings.count());
    var counts = std.enums.EnumArray(envMod.TemplateOp, usize).initFill(0);
    var it = env.templateLowerings.valueIterator();
    while (it.next()) |op| counts.set(op.*, counts.get(op.*) + 1);
    for (std.enums.values(envMod.TemplateOp)) |op| {
        try std.testing.expectEqual(@as(usize, if (op == .value) 0 else 1), counts.get(op));
    }
}

test "template: fail span maps into the caller's template" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    const src =
        \\pub fn html(expr template: string) -> string {
        \\    return template;
        \\}
        \\val c = html @`
        \\<Buttom label="Send"/>
        \\`;
    ;
    try inferInto(&env, alloc, src);

    const captures = try onlyCaptures(&env);
    const cap = &captures[0];

    // Template text is contiguous (no holes) and keeps the leading newline.
    const text = cap.text.?;
    const start = std.mem.indexOf(u8, text, "Buttom").?;

    // `failAt` with a span pointing at `Buttom` lands on line 5 col 2 of the
    // caller's file — inside the """…""" literal, not in the template library.
    const err = template.failDiagnostic(cap, .{ .start = start, .end = start + "Buttom".len, .line = 1 }, "component `Buttom` not found in caller scope");
    try std.testing.expectEqual(@as(usize, 5), err.loc.?.line);
    try std.testing.expectEqual(@as(usize, 2), err.loc.?.col);

    // Bare `fail` (no span) points at the template literal itself.
    const errNoSpan = template.failDiagnostic(cap, null, "nope");
    try std.testing.expectEqual(cap.loc.line, errNoSpan.loc.?.line);

    const desc = try h.renderTypeError(std.testing.allocator, src, err);
    defer std.testing.allocator.free(desc);
    const trace_prev = snapMod.traceEnter(@src());
    defer snapMod.traceLeave(trace_prev);
    try snapMod.checkText(std.testing.allocator, "comptime/templates/fail_span_in_template", desc);
}

test "infer error: expr argument must be a literal string (V1)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn html(expr template: string) -> string {
        \\    return template;
        \\}
        \\val tpl = "<p></p>";
        \\val c = html(tpl);
    );
}

test "template: context exposes declaration position and scope for second-layer languages" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub type Button(
        \\    label: string,
        \\)
        \\pub fn dsl(expr template: string) -> string {
        \\    return template;
        \\}
        \\val c = dsl @`
        \\<Button/>
        \\`;
    );

    // The capture reaches the template body (`q.context()`, `q.source()`,
    // `q.bindings()`, …) as this map.
    const captures = try onlyCaptures(&env);
    var term_out: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer term_out.deinit();
    try erlEmitter.writeTerm(&term_out.writer, try templateEval.captureToTerm(alloc, &captures[0]));
    const term = term_out.written();
    const expected = [_][]const u8{
        "'__bp_capture' => <<\"template\">>",
        "source => #{file => <<\"\">>, line => 7, col => 13}",
        "text => <<\"\\n<Button/>\\n\">>, multiline => true}",
        // Decision 237: only the scope entries the text names — `dsl` and `c`
        // are in scope but not words of `<Button/>`.
        "bindings => [#{name => <<\"Button\">>, kind => 'Type', identity => <<\"main@@Button\">>, local => <<\"Button\">>}]",
        "words => [<<\"Button\">>]",
    };
    for (expected) |needle| {
        if (std.mem.indexOf(u8, term, needle) == null) {
            std.debug.print("\nmissing:\n{s}\nin:\n{s}\n", .{ needle, term });
            return error.TestExpectedContains;
        }
    }
}

test "infer: context/source/bindings/build methods typecheck against std.syntax" {
    try h.assertInfersOk(std.testing.allocator,
        \\pub fn dsl(expr template: string) -> string {
        \\    val ctx = compiler.context(template);
        \\    val file: string = ctx.source.file;
        \\    val line: i32 = ctx.source.line;
        \\    val raw: string = ctx.text;
        \\    val names = compiler.bindings(template);
        \\    return compiler.build("file + raw");
        \\}
    );
}

test "comptime: template fn with expr param compiles through the pipeline" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn html(expr template: string) -> string {
        \\    return template;
        \\}
        \\val c = html @`
        \\<p>hello</p>
        \\`;
    );
}

// ── F6: call-site expansion ───────────────────────────────────────────────────

test "template: bounded expansion is transparent to the caller (F6)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn html(expr template: string) -> string {
        \\    return template;
        \\}
        \\val c = html @`
        \\<p>hi</p>
        \\`;
    );

    // The call site types as the bound `string`, not `expr<string>` —
    // splice + re-check happened during inference.
    try std.testing.expectEqualStrings("string", env.lookup("c").?.deref().named.name);
    try std.testing.expectEqual(@as(u32, 1), env.templateExpansions.count());
}

test "template: an anyvalue answer reveals the expansion type per call (F6, decision 578)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn answer(expr q: string) -> anyvalue {
        \\    return 42;
        \\}
        \\val n = answer @`x`;
        \\val m = n + 1;
    );

    // `n` carries the expansion's own type — the `anyvalue` answer
    // revealed it, and `n + 1` typechecked against it.
    try std.testing.expectEqualStrings("i32", env.lookup("n").?.deref().named.name);
}

test "template: a value return is lifted (F6, decision 575 (4))" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn port(expr q: string) -> i32 {
        \\    return 8080;
        \\}
        \\val p = port @`x`;
    );
    try std.testing.expectEqualStrings("i32", env.lookup("p").?.deref().named.name);
}

test "infer error: splice bound violation at the call site (F6)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn bad(expr q: string) -> i32 {
        \\    return "not an int";
        \\}
        \\val d = bad @`x`;
    );
}

test "infer error: template body not expandable by the V1 driver (F6)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn hard(expr t: string) -> string {
        \\    val x = compiler.text(t);
        \\    return t;
        \\}
        \\val c = hard @`SELECT 1`;
    );
}

/// Compile `src` through the full node pipeline and require a `.ok` outcome —
/// snapshot-only assertions accept error outcomes as a SOURCE-only snapshot,
/// which silently hides template-evaluation failures.
fn assertCompilesOk(comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const io = std.testing.io;
    const build_root = h.buildRootPathFromSrc(io, loc);
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "", .source = src }},
        io,
        build_root,
        null,
    );
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[session.outputs.items.len - 1].outcome;
    if (outcome == .typeError) {
        const desc = try h.renderTypeError(std.testing.allocator, src, outcome.typeError);
        defer std.testing.allocator.free(desc);
        std.debug.print("\nunexpected type error:\n{s}\n", .{desc});
    }
    try std.testing.expect(outcome == .ok);
}

// ── F6-full: runtime-backed template bodies ───────────────────────────────────

test "comptime: runtime template body ---- a method nothing answers is refused at the call in the body" {
    // 1.0.11 front 14 step 1, the template half: a template body is typed, so
    // the checker refuses the call itself, located at the method name in the
    // body — no runtime is asked. (A decorator body is untyped; its twin is
    // `decorator invocation: a method nothing answers …`.)
    const src =
        \\pub fn shout(expr q: string) -> string {
        \\    val t = compiler.text(q);
        \\    return compiler.build(t.frobnicate());
        \\}
        \\val s = shout @`hey`;
    ;
    const io = std.testing.io;
    const build_root = h.buildRootPathFromSrc(io, @src());
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, build_root, null);
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[session.outputs.items.len - 1].outcome;
    try std.testing.expect(outcome == .typeError);
    const message = try outcome.typeError.message(std.testing.allocator);
    defer std.testing.allocator.free(message);
    const at = outcome.typeError.loc orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings("unknown-primitive-method: `string` has no method `frobnicate`", message);
    try std.testing.expectEqual([2]usize{ 3, 29 }, [2]usize{ at.line, at.col });
}

test "comptime: runtime template body ---- text() + build() end to end" {
    const src =
        \\pub fn shout(expr q: string) -> string {
        \\    val t = compiler.text(q);
        \\    return compiler.build("\"" + t + "!\"");
        \\}
        \\val s = shout @`hey`;
    ;
    try assertCompilesOk(@src(), src);
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
}

test "comptime: runtime template body ---- lookup miss drives control flow" {
    const src =
        \\pub type Button(
        \\    label: string,
        \\)
        \\pub fn need(expr t: string) -> string {
        \\    val hit = compiler.lookup(t, "Buttom");
        \\    if (hit) { b ->
        \\        return compiler.fail("should be missing", at: t);
        \\    };
        \\    return compiler.build("\"ok\"");
        \\}
        \\val r = need @`<Buttom/>`;
    ;
    try assertCompilesOk(@src(), src);
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
}

test "comptime: runtime template body ---- a computed value is lifted" {
    const src =
        \\pub fn six(expr t: string) -> i32 {
        \\    val n = 2 + 4;
        \\    return n;
        \\}
        \\val n = six @`ignored`;
    ;
    try assertCompilesOk(@src(), src);
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
}

test "template: runtime fail() maps into the caller's template" {
    const src =
        \\pub fn lint(expr q: string) -> string {
        \\    val t = compiler.text(q);
        \\    compiler.fail("template rejected: " + t, at: q);
        \\    return q;
        \\}
        \\val s = lint @`bad`;
    ;
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "", .source = src }},
        io,
        test_scratch.path(io, "comptime/runtime_fail_maps_into_template"),
        null,
    );
    defer session.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), session.outputs.items.len);
    const outcome = session.outputs.items[session.outputs.items.len - 1].outcome;
    try std.testing.expect(outcome == .typeError);
    const te = outcome.typeError;
    // The diagnostic points at the template literal in the caller's file.
    try std.testing.expectEqual(@as(usize, 6), te.loc.?.line);
    const msg = try te.message(std.testing.allocator);
    defer std.testing.allocator.free(msg);
    try std.testing.expectEqualStrings("template rejected: bad", msg);
}

// ── the term round trip, per shape (front 14 step 3) ──────────────────────────
//
// A capture reaches the body as `main/1`'s argument, an external term
// (`runtime/etf.zig`); each fixture reads the shape back in the body, answers
// it in the reply (`h.canonicalReplies`) beside the exchange snapshots
// (`comptime/runtime/`).

test "comptime: round trip ---- an @ExprCustom reference tree names a declaration of another module" {
    const shapes =
        \\pub type Item(id: i32)
    ;
    const main =
        \\import {Item} from "shapes";
        \\pub fn dsl(expr e: string) -> anyvalue {
        \\    val code = compiler.build("41");
        \\    val leaf = CustomNode(kind: "field", span: Span(7, 9, 1), label: "property", ref: compiler.lookup(e, "Item"), children: []);
        \\    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: [leaf]);
        \\    compiler.custom(root);
        \\    return code;
        \\}
        \\val rows = dsl @`select id from Item`;
        \\import {compiler.Span, compiler.CustomNode} from "std";
    ;
    const modules: []const @import("../../module.zig").Module = &.{
        .{ .path = "shapes", .source = shapes },
        .{ .path = "", .source = main },
    };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const replies = try h.canonicalReplies(std.testing.allocator, arena.allocator(), @src(), modules);
    try std.testing.expectEqual(@as(usize, 1), replies.len);
    // The leaf's `ref` is the binding `lookup` answered at the call site: the
    // declaration's own name and identity in `shapes`, and the name the call
    // site spells.
    try std.testing.expect(std.mem.indexOf(u8, replies[0], "\"identity\":\"shapes@@Item\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, replies[0], "\"kind\":\"custom\"") != null);

    const io = std.testing.io;
    var session = try comptimeMod.compile(std.testing.allocator, modules, io, h.buildRootPathFromSrc(io, @src()), null);
    defer session.deinit(std.testing.allocator);
    const out = session.outputs.items[session.outputs.items.len - 1];
    try std.testing.expect(out.outcome == .ok);
    const entries = out.outcome.ok.custom_ast;
    try std.testing.expectEqual(@as(usize, 1), entries.len);
    const root = entries[0].root;
    try std.testing.expectEqualStrings("select", root.kind);
    try std.testing.expect(root.ref == null);
    try std.testing.expectEqual(@as(usize, 1), root.children.len);
    const ref = root.children[0].ref orelse return error.TestExpectedRef;
    try std.testing.expectEqualStrings("Item", ref.name);
    // `ref.kind` is the declaration's (`Type`, decision 415 (2)), read off
    // the module that declares it.
    try std.testing.expectEqualStrings("Type", ref.kind);
    try std.testing.expectEqualStrings("shapes@@Item", ref.identity);
    try std.testing.expectEqualStrings("Item", ref.local);
    try std.testing.expectEqual(@as(usize, 7), root.children[0].span.start);

    try h.assertComptimeAst(std.testing.allocator, @src(), modules);
}

// ── decision 237: a capture carries only the bindings its text names ─────────

test "decision 237: the capture's bindings are the scope entries its text names, in text order" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub type Card(
        \\    title: string,
        \\)
        \\pub type Badge(
        \\    n: i32,
        \\)
        \\val unrelated = 1;
        \\pub fn dsl(expr template: string) -> string {
        \\    return template;
        \\}
        \\val a = dsl @`<Card title="x"><Badge/></Card> 9lives _x Badge`;
        \\val b = dsl @`cfg-0`;
    );

    var it = env.exprCaptures.iterator();
    var seen: usize = 0;
    while (it.next()) |e| {
        for (e.value_ptr.*) |*cap| {
            var term_out: std.Io.Writer.Allocating = .init(std.testing.allocator);
            defer term_out.deinit();
            try erlEmitter.writeTerm(&term_out.writer, try templateEval.captureToTerm(alloc, cap));
            const term = term_out.written();
            const text = cap.text.?;
            const expected: []const []const u8 = if (std.mem.eql(u8, text, "cfg-0")) &.{
                // `cfg-0`: one word, `cfg`, which the scope lacks — no binding.
                "bindings => []",
                "words => [<<\"cfg\">>]",
            } else &.{
                // A word is identifier-shaped: `9lives` is not one (nor is
                // `lives` inside it), `_x` is; a repeated word counts once. Not
                // `unrelated`, `dsl`, `a`, `b`: the text does not spell them.
                "bindings => [#{name => <<\"Card\">>, kind => 'Type', identity => <<\"main@@Card\">>, local => <<\"Card\">>}, #{name => <<\"Badge\">>, kind => 'Type', identity => <<\"main@@Badge\">>, local => <<\"Badge\">>}]",
                "words => [<<\"Card\">>, <<\"title\">>, <<\"x\">>, <<\"Badge\">>, <<\"_x\">>]",
            };
            for (expected) |needle| {
                if (std.mem.indexOf(u8, term, needle) == null) {
                    std.debug.print("\nmissing:\n{s}\nin:\n{s}\n", .{ needle, term });
                    return error.TestExpectedContains;
                }
            }
            seen += 1;
        }
    }
    try std.testing.expectEqual(@as(usize, 2), seen);
}

test "decision 237 ---- a text that names nothing in scope carries no binding" {
    const src =
        \\val cfg_1 = "unread";
        \\pub fn conf(expr q: string) -> i32 {
        \\    val n = compiler.bindings(q).length;
        \\    return n;
        \\}
        \\val n = conf @`cfg-0`;
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const replies = try h.canonicalReplies(std.testing.allocator, arena.allocator(), @src(), &.{.{ .path = "", .source = src }});
    try std.testing.expectEqual(@as(usize, 1), replies.len);
    try std.testing.expectEqualStrings(
        \\{"kind":"value","value":0}
    , replies[0]);
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
}

test "decision 237 ---- lookup of a word of the text finds its binding" {
    const src =
        \\pub type Card(
        \\    title: string,
        \\)
        \\pub type Badge(
        \\    n: i32,
        \\)
        \\val unrelated = 1;
        \\pub fn ui(expr q: string) -> string {
        \\    val count = compiler.bindings(q).length;
        \\    val hit = compiler.lookup(q, "Badge");
        \\    if (hit) { b ->
        \\        return compiler.build("\"" + b.name + "/" + b.module + "\"");
        \\    } else {
        \\        return compiler.fail("Badge is a word of the text and in scope", at: q);
        \\    };
        \\}
        \\val s = ui @`<Card title="x"><Badge/></Card>`;
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const replies = try h.canonicalReplies(std.testing.allocator, arena.allocator(), @src(), &.{.{ .path = "", .source = src }});
    try std.testing.expectEqual(@as(usize, 1), replies.len);
    try std.testing.expectEqualStrings(
        \\{"kind":"code","source":"\"Badge/\""}
    , replies[0]);
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
}

test "decision 237 ---- lookup of a name outside the text is a located error" {
    // `Button` is in scope but the text does not spell it: the template fails
    // at its literal on both runtimes, never `undefined`.
    const src =
        \\pub type Button(
        \\    label: string,
        \\)
        \\pub fn need(expr t: string) -> string {
        \\    val hit = compiler.lookup(t, "Button");
        \\    if (hit) { b ->
        \\        return compiler.build("\"hit\"");
        \\    } else {
        \\        return compiler.build("\"miss\"");
        \\    };
        \\}
        \\val r = need @`<Card/>`;
    ;
    const io = std.testing.io;
    {
        var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, h.buildRootPathFromSrc(io, @src()), null);
        defer session.deinit(std.testing.allocator);
        try std.testing.expectEqual(@as(usize, 1), session.outputs.items.len);
        const outcome = session.outputs.items[session.outputs.items.len - 1].outcome;
        try std.testing.expect(outcome == .typeError);
        const message = try outcome.typeError.message(std.testing.allocator);
        defer std.testing.allocator.free(message);
        try std.testing.expectEqualStrings(
            \\lookup("Button"): not a word of the template's text; a template capture carries only the bindings whose name its text spells
        , message);
        // Located at the template literal the body was handed.
        const at = outcome.typeError.loc orelse return error.TestUnexpectedResult;
        try std.testing.expectEqual([2]usize{ 12, 14 }, [2]usize{ at.line, at.col });
    }
    try h.assertComptimeCompileError(std.testing.allocator, @src(), src);
}

// ── @ExprCustom carrier (expr-custom) ─────────────────────────────────────────

test "infer: a fn returning @ExprCustom<T> is recognized as a template fn" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    // Body-only inference: the carrier return marks `dsl` as a template fn, so it
    // lands in `env.templateFns` and never reaches codegen.
    try inferInto(&env, alloc,
        \\pub fn dsl(expr e: string) -> anyvalue {
        \\    val code = compiler.build("[1, 2]");
        \\    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: []);
        \\    compiler.custom(root);
        \\    return code;
        \\}
        \\import {compiler.Span, compiler.CustomNode} from "std";
    );
    try std.testing.expect(env.templateFns.contains("dsl"));
}

test "comptime: q.custom executes `code` identically + the tree is retrievable by loc" {
    const src =
        \\pub type Item(id: i32)
        \\pub fn dsl(expr e: string) -> anyvalue {
        \\    val code = compiler.build("41");
        \\    val leaf = CustomNode(kind: "field", span: Span(5, 9, 1), label: "property", ref: compiler.lookup(e, "Item"), children: []);
        \\    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: [leaf]);
        \\    compiler.custom(root);
        \\    return code;
        \\}
        \\val rows = dsl @`select id from Item`;
        \\val answer = rows + 1;
        \\import {compiler.Span, compiler.CustomNode} from "std";
    ;
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "", .source = src }},
        io,
        test_scratch.path(io, "comptime/expr_custom_carrier"),
        null,
    );
    defer session.deinit(std.testing.allocator);

    // The program, after the `compiler` module its import brings (decision 576 (13)).
    try std.testing.expectEqual(@as(usize, 2), session.outputs.items.len);
    const outcome = session.outputs.items[session.outputs.items.len - 1].outcome;
    if (outcome == .typeError) {
        const desc = try h.renderTypeError(std.testing.allocator, src, outcome.typeError);
        defer std.testing.allocator.free(desc);
        std.debug.print("\nunexpected type error:\n{s}\n", .{desc});
    } else if (outcome != .ok) {
        std.debug.print("\nunexpected outcome: {s}\n", .{@tagName(outcome)});
    }
    try std.testing.expect(outcome == .ok);

    // `code` ran the ordinary `@Expr<T>` path: `rows[0] + 1` type-checks, so the
    // splice produced an `i32[]` exactly as returning `e.build("[10, 20]")` would.
    const entries = outcome.ok.custom_ast;
    try std.testing.expectEqual(@as(usize, 1), entries.len);
    const entry = entries[0];
    try std.testing.expectEqualStrings("dsl", entry.callee);
    // Provenance points at the template literal in the caller (line 8).
    try std.testing.expectEqual(@as(usize, 9), entry.line);

    // The canonical reference tree is the one the lib built — opaque tags intact.
    const root = entry.root;
    try std.testing.expectEqualStrings("select", root.kind);
    try std.testing.expectEqualStrings("keyword", root.label);
    try std.testing.expectEqual(@as(usize, 0), root.span.start);
    try std.testing.expectEqual(@as(usize, 6), root.span.end);
    try std.testing.expect(root.ref == null);
    try std.testing.expectEqual(@as(usize, 1), root.children.len);

    const leaf = root.children[0];
    try std.testing.expectEqualStrings("field", leaf.kind);
    try std.testing.expectEqualStrings("property", leaf.label);
    try std.testing.expectEqual(@as(usize, 5), leaf.span.start);
    // `ref` carries the resolved origin-scope declaration (a `q.lookup`
    // result, decision 415 (2)).
    try std.testing.expect(leaf.ref != null);
    try std.testing.expectEqualStrings("Item", leaf.ref.?.name);
    try std.testing.expectEqualStrings("Type", leaf.ref.?.kind);
}

test "decision 112: lookup answers the declaration's identity, never the alias" {
    // `e.lookup("surface")` for `import {area as surface}` resolves at the call
    // site and answers `area` — its own name and `<package>@<path>@@<Decl>` —
    // while `ref()` still splices the name the call site spells. The library's
    // private `double` in the built text resolves in the library (row 1 of
    // decision 112's table).
    const lib =
        \\pub fn area(w: i32, h: i32) -> i32 { return w * h; }
        \\fn double(x: i32) -> i32 { return x * 2; }
        \\pub default fn shapesdsl(expr e: string) -> anyvalue {
        \\    val code = compiler.build("double(" + compiler.text(e) + ")");
        \\    val root = CustomNode(kind: "call", span: Span(0, 7, 1), label: "keyword", ref: compiler.lookup(e, "surface"), children: []);
        \\    compiler.custom(root);
        \\    return code;
        \\}
        \\import {compiler.Span, compiler.CustomNode} from "std";
    ;
    const main =
        \\import shapesdsl, {area as surface} from "shapesdsl";
        \\val x = shapesdsl @`surface(4, 5)`;
    ;
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{
            .{ .path = "shapesdsl/root", .source = "pub default mod shapesdsl;" },
            .{ .path = "shapesdsl/shapesdsl", .source = lib },
            .{ .path = "", .source = main },
        },
        io,
        test_scratch.path(io, "comptime/dsl_hygiene_lookup"),
        null,
    );
    defer session.deinit(std.testing.allocator);

    const out = session.outputs.items[session.outputs.items.len - 1];
    if (out.outcome == .typeError) {
        const desc = try h.renderTypeError(std.testing.allocator, main, out.outcome.typeError);
        defer std.testing.allocator.free(desc);
        std.debug.print("\nunexpected type error:\n{s}\n", .{desc});
    }
    try std.testing.expect(out.outcome == .ok);
    const entries = out.outcome.ok.custom_ast;
    try std.testing.expectEqual(@as(usize, 1), entries.len);
    const ref = entries[0].root.ref orelse return error.TestExpectedRef;
    try std.testing.expectEqualStrings("area", ref.name);
    try std.testing.expectEqualStrings("shapesdsl@shapesdsl@@area", ref.identity);
    try std.testing.expectEqualStrings("surface", ref.local);
}

test "gate: the @ExprCustom carrier code names no sub-language" {
    // HARD RULE (expr-custom): the core carries a generic `CustomNode` tree and
    // never branches on a lib's opaque `kind`/`label` tags. The two
    // carrier-specific core files must stay free of any DSL keyword vocabulary —
    // example tags like "select" live only in lib and test code, never in
    // `compiler-core/src` proper. (Lib *names* are already enforced tree-wide by
    // the build's lib-agnostic `grep` gate; this test must not spell any of
    // them, or it would trip that same gate on itself.)
    const sources = [_][]const u8{
        @embedFile("../template.zig"),
        @embedFile("../template_eval.zig"),
    };
    const forbidden = [_][]const u8{ "select", "sql", "html", "markup" };
    for (sources) |src| {
        for (forbidden) |word| {
            if (std.ascii.indexOfIgnoreCase(src, word) != null) {
                std.debug.print("\nlib-agnostic gate: DSL token '{s}' leaked into carrier core code\n", .{word});
                try std.testing.expect(false);
            }
        }
    }
}

// ── anonymous record literals + the yaml model ────────────────────────────────

test "infer: anonymous record literal types structurally and fields resolve" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\val port = 8080;
        \\val server = #(port);
        \\val debug = true;
        \\val cfg = #(server, debug);
        \\val p = cfg.server.port;
        \\val d = cfg.debug;
    );
    try std.testing.expectEqualStrings("i32", env.lookup("p").?.deref().named.name);
    try std.testing.expectEqualStrings("bool", env.lookup("d").?.deref().named.name);
}

test "infer error: unknown field on an anonymous record" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val port = 8080;
        \\val cfg = #(port);
        \\val x = cfg.prot;
    );
}

test "comptime: yaml model ---- a lifted tuple reveals its element types (V1 driver)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn conf(expr q: string) -> anyvalue {
        \\    return #(8080, true);
        \\}
        \\val cfg = conf @`server:`;
        \\val p = cfg.0 + 1;
        \\val d = cfg.1;
    );
    try std.testing.expectEqualStrings("i32", env.lookup("p").?.deref().named.name);
    try std.testing.expectEqualStrings("bool", env.lookup("d").?.deref().named.name);
}

// ── net-new (v0.beta.13 · A7): expr-templates ─────────────────────────────────

// An empty template (`tpl ""`) is handled gracefully — it captures empty text
// with no holes and does not crash inference.
test "template: net-new ---- an empty template is handled gracefully" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn tpl(expr t: string) -> string {
        \\    return t;
        \\}
        \\val c = tpl @``;
    );

    const captures = try onlyCaptures(&env);
    const cap = captures[0];
    try std.testing.expect(cap.text != null);
    try std.testing.expectEqualStrings("", cap.text.?);
    try std.testing.expect(!cap.multiline);
}

// A splice whose lifted value expands to a TYPE error is reported at the splice
// site (the caller's `port @`…`` call), not at the template definition: the
// body answers a `bool`, but the template answers `i32`.
test "infer error: net-new ---- splice type error reports at the splice site" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn port(expr q: string) -> i32 {
        \\    return true;
        \\}
        \\val p = port @`x`;
    );
}

// Two separate template invocations each expand independently (the memo is keyed
// by call-site scope, so two call sites yield two expansions).
test "template: net-new ---- two template invocations expand independently" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn tpl(expr q: string) -> string {
        \\    return q;
        \\}
        \\val a = tpl @`one`;
        \\val b = tpl @`two`;
    );

    try std.testing.expectEqual(@as(u32, 2), env.templateExpansions.count());
}

// A nested template — `outer`'s built code itself calls the template fn `inner`
// with its template text. Expanding `outer` splices in `inner @`deep``, which then
// expands in turn: each template fn expands once for its own call site.
test "comptime: net-new ---- nested template call inside a template body" {
    const src =
        \\pub fn inner(expr q: string) -> string {
        \\    return q;
        \\}
        \\pub fn outer(expr q: string) -> string {
        \\    return compiler.build("inner @`deep`");
        \\}
        \\val s = outer @`x`;
    ;
    try assertCompilesOk(@src(), src);
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
}

// ── markup authoring DSL ──────────────────────────────────────────────────────
//
// A markup DSL captures `<…>` text unevaluated as `@Expr<string>`, expands it at
// compile time, and yields a plain `Element` — verified end-to-end through the
// node pipeline. Children are assembled with `fragment(Element[])`. (This is the
// pattern a React/Next-style view lib builds on top of generic primitives.)

test "template: markup DSL ---- <Component/> tags resolve to calls" {
    try assertCompilesOk(@src(),
        \\val Element = type() implement @Renderable
        \\fn fragment(items: Element[]) -> Element { return Element(); }
        \\fn Page1() -> Element { return Element(); }
        \\fn Page2() -> Element { return Element(); }
        \\pub fn html(expr q: string) -> Element {
        \\    return compiler.build("fragment([Page1(), Page2()])");
        \\}
        \\val page = html @`<Page1/><Page2/>`;
    );
}

// ── decision 331: a template module carries what its body reaches ────────────
//
// Front 118's three rows, each run on the comptime runtime, the replies read
// back (`h.canonicalReplies`).

test "decision 331: a template body calls its module's functions, a recursive one and an imported one" {
    // The template module held the template alone: every call was `the BEAM
    // runtime does not take call to undefined function wrap/1 (in shout/1)`
    // (the wat runtime the same). It carries the functions its body reaches
    // now — `helper` (private), `depth` (recursive), `wrap` imported with
    // the private `inner` it calls — expanded in the declaring module and in
    // an importer alike.
    const text =
        \\fn inner(s: string) -> string {
        \\    return "<" + s + ">";
        \\}
        \\pub fn wrap(s: string) -> string {
        \\    return inner(s);
        \\}
    ;
    const tags =
        \\import {wrap} from "text";
        \\fn helper(s: string) -> string {
        \\    return "[" + s + "]";
        \\}
        \\fn depth(n: i32) -> i32 {
        \\    return if (n <= 0) 0 else 1 + depth(n - 1);
        \\}
        \\pub fn shout(expr q: string) -> string {
        \\    return compiler.build("\"" + wrap(helper(compiler.text(q))) + depth(3).toString() + "\"");
        \\}
        \\val here = shout @`in`;
    ;
    const main =
        \\import {shout} from "tags";
        \\fn twice(s: string) -> string {
        \\    return s + s;
        \\}
        \\pub fn echo(expr q: string) -> string {
        \\    return compiler.build("\"" + twice(compiler.text(q)) + "\"");
        \\}
        \\val a = shout @`ab`;
        \\val b = echo @`xy`;
    ;
    const modules: []const @import("../../module.zig").Module = &.{
        .{ .path = "text", .source = text },
        .{ .path = "tags", .source = tags },
        .{ .path = "", .source = main },
    };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const replies = try h.canonicalReplies(std.testing.allocator, arena.allocator(), @src(), modules);
    try std.testing.expectEqual(@as(usize, 3), replies.len);
    try std.testing.expectEqualStrings(
        \\{"kind":"code","source":"\"<[in]>3\""}
    , replies[0]);
    try std.testing.expectEqualStrings(
        \\{"kind":"code","source":"\"<[ab]>3\""}
    , replies[1]);
    try std.testing.expectEqualStrings(
        \\{"kind":"code","source":"\"xyxy\""}
    , replies[2]);
}

test "decision 331: a template body reads a labelled tuple element by its label" {
    // `x.kind` lowered as a map read in the template module — `{error,
    // {badmap, {<<"ab">>, 2}}}` on both runtimes — where an ordinary function
    // reads the element by position. A label read is the position inference
    // recorded for it: a local, an array element in a loop, a helper's
    // parameter, and a template another module exports.
    const pairs =
        \\fn kindOf(x: #(kind: string, n: i32)) -> string {
        \\    return x.kind;
        \\}
        \\pub fn pairs(expr q: string) -> string {
        \\    val items: #(kind: string, n: i32)[] = [#(compiler.text(q), 1), #("z", 2)];
        \\    var out = "";
        \\    for (items) { it ->
        \\        out = out + it.kind + it.n.toString() + ";";
        \\    };
        \\    return compiler.build("\"" + out + kindOf(#("w", 7)) + "\"");
        \\}
    ;
    const main =
        \\import {pairs} from "pairs";
        \\pub fn probe(expr q: string) -> string {
        \\    val x: #(kind: string, n: i32) = #(compiler.text(q), 2);
        \\    return compiler.build("\"" + x.kind + x.n.toString() + "\"");
        \\}
        \\val a = probe @`ab`;
        \\val b = pairs @`xy`;
    ;
    const modules: []const @import("../../module.zig").Module = &.{
        .{ .path = "pairs", .source = pairs },
        .{ .path = "", .source = main },
    };
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const replies = try h.canonicalReplies(std.testing.allocator, arena.allocator(), @src(), modules);
    try std.testing.expectEqual(@as(usize, 2), replies.len);
    try std.testing.expectEqualStrings(
        \\{"kind":"code","source":"\"ab2\""}
    , replies[0]);
    try std.testing.expectEqualStrings(
        \\{"kind":"code","source":"\"xy1;z2;w\""}
    , replies[1]);
}

test "decision 331: a template body of more variables than a frame holds compiles on both runtimes" {
    // Every Erlang variable took a Y register (the BEAM) or a local (wat) of
    // its own, so a body of 1200 rebindings of one `var` overran the function's
    // stack height limit. Slots whose ranges never overlap are shared now.
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const ar = arena.allocator();
    var src: std.ArrayListUnmanaged(u8) = .empty;
    try src.appendSlice(ar,
        \\pub fn big(expr q: string) -> string {
        \\    var s = compiler.text(q);
        \\    var n = 0;
        \\
    );
    for (0..1200) |i| {
        try src.print(ar, "    s = s + \"{c}\";\n", .{@as(u8, 'a' + @as(u8, @intCast(i % 26)))});
        try src.appendSlice(ar, "    n = n + 1;\n");
    }
    try src.appendSlice(ar,
        \\    return compiler.build("\"" + s.slice(0, 6) + n.toString() + "\"");
        \\}
        \\val got = big @`q`;
    );
    const replies = try h.canonicalReplies(std.testing.allocator, ar, @src(), &.{.{ .path = "", .source = src.items }});
    try std.testing.expectEqual(@as(usize, 1), replies.len);
    try std.testing.expectEqualStrings(
        \\{"kind":"code","source":"\"qabcde1200\""}
    , replies[0]);
}

test "infer: a receiver's own method named like a template method of the scope is the type's, owing no expansion (decisions 311 (3), 415 (1))" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Greeter(who: string) {
        \\    pub fn greet(self: Self, word: string) -> string {
        \\        return word + ", " + self.who;
        \\    }
        \\}
        \\type Visitor(who: string)
        \\fn greet(expr self: Visitor, expr q: string) -> string {
        \\    return compiler.build(compiler.text(self) + ".who");
        \\}
        \\pub fn main() {
        \\    val g = Greeter(who: "Ana");
        \\    @print(g.greet("hello"));
        \\    @print(g.greet @`hello`);
        \\}
    );
}

test "infer: a behavior method the receiver's type adopts, named like a template method of the scope, is the type's (decisions 311 (3), 415 (1))" {
    try h.assertInfersOk(std.testing.allocator,
        \\behavior Waves {
        \\    fn who(self: Self) -> string;
        \\    default fn greet(self: Self, word: string) -> string {
        \\        return word + ", " + self.who();
        \\    }
        \\}
        \\type Waver(name: string) implement Waves {
        \\    fn who(self: Self) -> string {
        \\        return self.name;
        \\    }
        \\}
        \\type Visitor(who: string)
        \\fn greet(expr self: Visitor, expr q: string) -> string {
        \\    return compiler.build(compiler.text(self) + ".who");
        \\}
        \\fn wave(w: Waves) -> string {
        \\    return w.greet @`hi`;
        \\}
        \\pub fn main() {
        \\    @print(Waver(name: "Ana").greet "hello");
        \\    @print(wave(Waver(name: "Bia")));
        \\}
    );
}

test "infer: template-call-unexpanded ---- the backstop refuses a template call left without an expansion, and lets a local named like the template through (decision 425)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();
    const src =
        \\fn shout(expr q: string) -> string { return q; }
        \\fn run(shout: fn(string) -> string) -> string { return shout("x"); }
        \\pub fn main() { @print(shout @`a`); @print(run({ s -> s })); }
    ;
    var lx = Lexer.init(src);
    var p = Parser.init(try lx.scanAll(alloc));
    const program = try p.parse(alloc);
    _ = try inferMod.inferProgramTyped(&env, program);
    // The parameter's call is the parameter's: it owes no expansion.
    try std.testing.expectEqual(@as(usize, 1), env.templateExpansions.count());
    try inferMod.refuseUnexpandedTemplateCalls(&env, program);
    // A template call the compiler did not expand — no program reaches one —
    // is refused where it is written.
    env.templateExpansions.clearRetainingCapacity();
    try std.testing.expectError(error.TypeError, inferMod.refuseUnexpandedTemplateCalls(&env, program));
    const te = env.lastError.?;
    try std.testing.expectEqual(@as(usize, 3), te.loc.?.line);
    try std.testing.expectEqual(@as(usize, 24), te.loc.?.col);
    const msg = try te.message(std.testing.allocator);
    defer std.testing.allocator.free(msg);
    try std.testing.expectEqualStrings("template-call-unexpanded: `shout \"…\"` calls a template function here, where the compiler does not expand it", msg);
}

test "templates: a raise in another module's template body names the body's file" {
    // 144 B-23's proposed cell (`template_raise_names_body_file`), decision
    // 532: the refusal is located at the call that raised, in the template's
    // own file — `tpl.bp` (`@src().file` of a module the driver gave no
    // `srcPath`), line 3, column 5 —, and the call site that expanded it is
    // the `called from` line.
    const tpl =
        \\pub fn shout(expr t: string) -> string {
        \\    val s = compiler.text(t);
        \\    @panic("boom " + s);
        \\    return compiler.build("\"" + s + "\"");
        \\}
    ;
    const src =
        \\import {tpl.shout};
        \\pub fn main() {
        \\    @print(shout @`hi`);
        \\}
    ;
    const io = std.testing.io;
    const build_root = h.buildRootPathFromSrc(io, @src());
    var session = try comptimeMod.compile(std.testing.allocator, &.{
        .{ .path = "tpl", .source = tpl },
        .{ .path = "", .source = src },
    }, io, build_root, null);
    defer session.deinit(std.testing.allocator);
    const outcome = for (session.outputs.items) |o| {
        if (std.mem.eql(u8, o.name, "main")) break o.outcome;
    } else return error.TestNoMainOutput;
    try std.testing.expect(outcome == .typeError);
    const message = try outcome.typeError.message(std.testing.allocator);
    defer std.testing.allocator.free(message);
    try std.testing.expectEqualStrings("{error,{panic,<<\"boom hi\">>}}", message);
    // Decision 532: located at the call that raised, in the template's own
    // file; the call that expanded it is the `called from` line.
    const origin = outcome.typeError.origin orelse return error.TestUnexpectedResult;
    try std.testing.expectEqualStrings("tpl.bp", origin.file);
    try std.testing.expectEqual([2]usize{ 3, 5 }, [2]usize{ origin.loc.line, origin.loc.col });
    try std.testing.expectEqual(@as(usize, 1), outcome.typeError.frames.len);
    try std.testing.expectEqualStrings("main.bp", outcome.typeError.frames[0].file);
    const got = outcome.typeError.loc orelse return error.TestUnexpectedResult;
    try std.testing.expectEqual([2]usize{ 3, 12 }, [2]usize{ got.line, got.col });
}
