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
        \\pub fn sql(comptime q: @Expr<string>) -> @Expr<string> {
        \\    return q;
        \\}
        \\val stmt = sql "SELECT 1";
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

test "template: expr param capture ---- multiline template with hole keeps parts" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val c = html """
        \\<p>${1 + 2}</p>
        \\""";
    );

    const captures = try onlyCaptures(&env);
    const cap = captures[0];
    try std.testing.expectEqualStrings("template", cap.paramName);
    try std.testing.expect(cap.multiline);
    // Holes present: no contiguous text — the parts live on the node.
    try std.testing.expect(cap.text == null);
    try std.testing.expect(cap.node.* == .literal);
    const parts = cap.node.literal.kind.stringTemplate.parts;
    try std.testing.expectEqual(@as(usize, 3), parts.len); // text, hole, text
    try std.testing.expect(parts[1] == .expr);
}

test "template: scope snapshot lookup ---- hit and miss" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub struct Button {
        \\    label: string,
        \\}
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val c = html """
        \\<Button/>
        \\""";
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
        \\{"Button":"Struct","html":"Fn","c":"Val"}
    , json);
}

test "template: expr methods typecheck and record lowerings" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn html(comptime template: @Expr<string>, sp: Span) -> @Expr<string> {
        \\    val v = template.value();
        \\    val t = template.text();
        \\    val ps = template.parts();
        \\    val where = template.source();
        \\    val ctx = template.context();
        \\    val scope = template.bindings();
        \\    val b = template.lookup("Button");
        \\    val made = template.build("1 + 2");
        \\    val node = CustomNode(kind: "expr", span: sp, label: "number", ref: b, children: []);
        \\    val cu = template.custom(node, made);
        \\    template.failAt(sp, "bad tag");
        \\    template.fail("no component");
        \\    return template;
        \\}
        \\pub fn mk<T>(b: Binding) -> @Expr<T> {
        \\    return b.ref();
        \\}
    );

    try std.testing.expectEqual(@as(usize, 12), env.templateLowerings.count());
    var counts = std.enums.EnumArray(envMod.TemplateOp, usize).initFill(0);
    var it = env.templateLowerings.valueIterator();
    while (it.next()) |op| counts.set(op.*, counts.get(op.*) + 1);
    for (std.enums.values(envMod.TemplateOp)) |op| {
        try std.testing.expectEqual(@as(usize, 1), counts.get(op));
    }
}

test "template: fail span maps into the caller's template" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    const src =
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val c = html """
        \\<Buttom label="Send"/>
        \\""";
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
    try snapMod.checkText(std.testing.allocator, "comptime/templates/fail_span_in_template", desc);
}

test "infer error: expr argument must be a literal string (V1)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val tpl = "<p></p>";
        \\val c = html(tpl);
    );
}

test "infer error: expr argument is typed in the caller against inner T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn check(comptime cond: @Expr<bool>) -> @Expr<bool> {
        \\    return cond;
        \\}
        \\val c = check("not a bool");
    );
}

test "template: context exposes declaration position and scope for second-layer languages" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub struct Button {
        \\    label: string,
        \\}
        \\pub fn dsl(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val c = dsl """
        \\<Button/>
        \\""";
    );

    const captures = try onlyCaptures(&env);
    const json = try template.contextJsonAlloc(&captures[0], std.testing.allocator);
    defer std.testing.allocator.free(json);
    try std.testing.expectEqualStrings(
        \\{"file":"","line":7,"col":13,"multiline":true,"text":"\n<Button/>\n","scope":{"Button":"Struct","dsl":"Fn","c":"Val"}}
    , json);
}

test "infer: context/source/bindings/build methods typecheck against std.syntax" {
    try h.assertInfersOk(std.testing.allocator,
        \\pub fn dsl(comptime template: @Expr<string>) -> @Expr<string> {
        \\    val ctx = template.context();
        \\    val file: string = ctx.source.file;
        \\    val line: i32 = ctx.source.line;
        \\    val raw: string = ctx.text;
        \\    val names = template.bindings();
        \\    return template.build("file + raw");
        \\}
    );
}

test "comptime: template fn with expr param compiles through the pipeline" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val c = html """
        \\<p>hello</p>
        \\""";
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
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val c = html """
        \\<p>hi</p>
        \\""";
    );

    // The call site types as the bound `string`, not `expr<string>` —
    // splice + re-check happened during inference.
    try std.testing.expectEqualStrings("string", env.lookup("c").?.deref().named.name);
    try std.testing.expectEqual(@as(u32, 1), env.templateExpansions.count());
}

test "template: generic @Expr<T> return reveals the expansion type per call (F6)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn answer<T>() -> @Expr<T> {
        \\    return @code("42");
        \\}
        \\val n = answer();
        \\val m = n + 1;
    );

    // `n` carries the expansion's own type — the generic `@Expr<T>` return
    // revealed it, and `n + 1` typechecked against it.
    try std.testing.expectEqualStrings("i32", env.lookup("n").?.deref().named.name);
}

test "template: explicit value lift via @expr builtin (F6)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn port() -> @Expr<i32> {
        \\    return @expr(8080);
        \\}
        \\val p = port();
    );
    try std.testing.expectEqualStrings("i32", env.lookup("p").?.deref().named.name);
}

test "infer error: splice bound violation at the call site (F6)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn bad() -> @Expr<i32> {
        \\    return @expr("not an int");
        \\}
        \\val d = bad();
    );
}

test "infer error: template body not expandable by the V1 driver (F6)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn hard(comptime t: @Expr<string>) -> @Expr<string> {
        \\    val x = t.text();
        \\    return t;
        \\}
        \\val c = hard "SELECT 1";
    );
}

/// Compile `src` through the full node pipeline and require a `.ok` outcome —
/// snapshot-only assertions accept error outcomes as a SOURCE-only snapshot,
/// which silently hides template-evaluation failures.
fn assertCompilesOk(comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const io = std.testing.io;
    const build_root = comptime h.buildRootPathFromSrc(loc);
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "", .source = src }},
        io,
        .node,
        build_root,
    );
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[0].outcome;
    if (outcome == .typeError) {
        const desc = try h.renderTypeError(std.testing.allocator, src, outcome.typeError);
        defer std.testing.allocator.free(desc);
        std.debug.print("\nunexpected type error:\n{s}\n", .{desc});
    }
    try std.testing.expect(outcome == .ok);
}

// ── F6-full: runtime-backed template bodies ───────────────────────────────────

test "comptime: runtime template body ---- text() + build() end to end" {
    const src =
        \\pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
        \\    val t = q.text();
        \\    return q.build("\"" + t + "!\"");
        \\}
        \\val s = shout "hey";
    ;
    try assertCompilesOk(@src(), src);
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
}

test "comptime: runtime template body ---- lookup miss drives control flow" {
    const src =
        \\pub struct Button {
        \\    label: string,
        \\}
        \\pub fn need(comptime t: @Expr<string>) -> @Expr<string> {
        \\    val hit = t.lookup("Buttom");
        \\    if (hit) { b ->
        \\        return t.fail("should be missing");
        \\    };
        \\    return t.build("\"ok\"");
        \\}
        \\val r = need "x";
    ;
    try assertCompilesOk(@src(), src);
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
}

test "comptime: runtime template body ---- @expr lifts a computed value" {
    const src =
        \\pub fn six(comptime t: @Expr<string>) -> @Expr<i32> {
        \\    val n = 2 + 4;
        \\    return @expr(n);
        \\}
        \\val n = six "ignored";
    ;
    try assertCompilesOk(@src(), src);
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
}

test "template: runtime fail() maps into the caller's template" {
    const src =
        \\pub fn lint(comptime q: @Expr<string>) -> @Expr<string> {
        \\    val t = q.text();
        \\    q.fail("template rejected: " + t);
        \\    return q;
        \\}
        \\val s = lint "bad";
    ;
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "", .source = src }},
        io,
        .node,
        ".botopinkbuild/comptime/runtime_fail_maps_into_template",
    );
    defer session.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), session.outputs.items.len);
    const outcome = session.outputs.items[0].outcome;
    try std.testing.expect(outcome == .typeError);
    const te = outcome.typeError;
    // The diagnostic points at the template literal in the caller's file.
    try std.testing.expectEqual(@as(usize, 6), te.loc.?.line);
    const msg = try te.message(std.testing.allocator);
    defer std.testing.allocator.free(msg);
    try std.testing.expectEqualStrings("template rejected: bad", msg);
}

test "comptime: runtime template body ---- parts() with a hole splices the caller expression" {
    const src =
        \\pub fn html(comptime q: @Expr<string>) -> @Expr<string> {
        \\    var acc = "\"\"";
        \\    loop (q.parts()) { p ->
        \\        if (p.kind == "Text") {
        \\            acc = acc + " + \"" + p.text + "\"";
        \\        };
        \\        if (p.kind == "Interp") {
        \\            acc = acc + " + " + p.code;
        \\        };
        \\    };
        \\    return q.build(acc);
        \\}
        \\val name = "world";
        \\val page = html """<p>${name}</p>""";
    ;
    try assertCompilesOk(@src(), src);
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
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
        \\pub fn dsl<T>(comptime e: @Expr<string>) -> @ExprCustom<T> {
        \\    val code = e.build("[1, 2]");
        \\    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: []);
        \\    return e.custom(root, code);
        \\}
    );
    try std.testing.expect(env.templateFns.contains("dsl"));
}

test "comptime: q.custom executes `code` identically + the tree is retrievable by loc" {
    const src =
        \\pub struct Item { id: i32 }
        \\pub fn dsl<T>(comptime e: @Expr<string>) -> @ExprCustom<T> {
        \\    val code = e.build("41");
        \\    val leaf = CustomNode(kind: "field", span: Span(5, 9, 1), label: "property", ref: e.lookup("Item"), children: []);
        \\    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: [leaf]);
        \\    return e.custom(root, code);
        \\}
        \\val rows = dsl "select id";
        \\val answer = rows + 1;
    ;
    const io = std.testing.io;
    var session = try comptimeMod.compile(
        std.testing.allocator,
        &.{.{ .path = "", .source = src }},
        io,
        .node,
        ".botopinkbuild/comptime/expr_custom_carrier",
    );
    defer session.deinit(std.testing.allocator);

    try std.testing.expectEqual(@as(usize, 1), session.outputs.items.len);
    const outcome = session.outputs.items[0].outcome;
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
    try std.testing.expectEqual(@as(usize, 8), entry.line);

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
    // `ref` carries the resolved origin-scope Binding (a `q.lookup` result).
    try std.testing.expect(leaf.ref != null);
    try std.testing.expectEqualStrings("Item", leaf.ref.?.name);
    try std.testing.expectEqualStrings("Struct", leaf.ref.?.kind);
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
        \\val cfg = (record { server: record { port: 8080 }, debug: true });
        \\val p = cfg.server.port;
        \\val d = cfg.debug;
    );
    try std.testing.expectEqualStrings("i32", env.lookup("p").?.deref().named.name);
    try std.testing.expectEqualStrings("bool", env.lookup("d").?.deref().named.name);
}

test "infer error: unknown field on an anonymous record" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val cfg = (record { port: 8080 });
        \\val x = cfg.prot;
    );
}

test "comptime: yaml model ---- static record lift reveals the structure (V1 driver)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
        \\    return @expr(record { port: 8080, debug: true });
        \\}
        \\val cfg = conf "server:";
        \\val p = cfg.port + 1;
        \\val d = cfg.debug;
    );
    try std.testing.expectEqualStrings("i32", env.lookup("p").?.deref().named.name);
    try std.testing.expectEqualStrings("bool", env.lookup("d").?.deref().named.name);
}

// ── mixed signatures ──────────────────────────────────────────────────────────

test "template: mixed signature ---- plain string literal arg is collected alongside capture" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    // V1 driver can expand a pass-through even with a plain arg present.
    try inferInto(&env, alloc,
        \\pub fn wrap(comptime template: @Expr<string>, prefix: string) -> @Expr<string> {
        \\    return template;
        \\}
        \\val c = wrap("hello", "pre:");
    );
    // The expansion replaces the call with the capture node (the string "hello").
    const exp = env.templateExpansions.get(.{ .line = 4, .col = 9 });
    try std.testing.expect(exp != null);
}

test "template: mixed signature ---- number literal arg is accepted" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn port<T>(comptime template: @Expr<string>, base: i32) -> @Expr<T> {
        \\    return template;
        \\}
        \\val c = port("8080", 80);
    );
    const exp = env.templateExpansions.get(.{ .line = 4, .col = 9 });
    try std.testing.expect(exp != null);
}

test "infer error: non-@Expr template param must receive a literal (V1)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn wrap(comptime template: @Expr<string>, prefix: string) -> @Expr<string> {
        \\    return template;
        \\}
        \\val p = "pre:";
        \\val c = wrap("hello", p);
    );
}

// ── hole loc mapping ─────────────────────────────────────────────────────────

test "template: holed fallback span ---- hole on first non-opening line maps correctly" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    const src =
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\val name = "world";
        \\val c = html """
        \\<p>${name}</p>
        \\""";
    ;
    try inferInto(&env, alloc, src);

    const captures = try onlyCaptures(&env);
    const cap = &captures[0];
    try std.testing.expect(cap.text == null); // has holes

    // The hole is on the second template line (1-based = line 2 in the template);
    // capture.loc.line = 5 (opening `"""`), so the expected source line is 5+2-1 = 6.
    const loc = template.mapSpanToLoc(cap, .{ .start = 0, .end = 0, .line = 2 });
    try std.testing.expectEqual(@as(usize, 6), loc.line);
}

// ── net-new (v0.beta.13 · A7): expr-templates ─────────────────────────────────

// A template called with a `${…}` hole that is a bare VARIABLE reference (not a
// literal) captures the variable as an unevaluated `.identifier` expression.
test "template: net-new ---- a hole captures a bare variable reference" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn tpl(comptime t: @Expr<string>) -> @Expr<string> {
        \\    return t;
        \\}
        \\val name = "world";
        \\val page = tpl """${name}""";
    );

    const captures = try onlyCaptures(&env);
    const cap = captures[0];
    // A hole is present, so there is no contiguous text — the variable lives in
    // the parts as an unevaluated identifier reference.
    try std.testing.expect(cap.text == null);
    const parts = cap.node.literal.kind.stringTemplate.parts;
    var sawIdentHole = false;
    for (parts) |p| {
        if (p == .expr and p.expr.* == .identifier) sawIdentHole = true;
    }
    try std.testing.expect(sawIdentHole);
}

// An empty template (`tpl ""`) is handled gracefully — it captures empty text
// with no holes and does not crash inference.
test "template: net-new ---- an empty template is handled gracefully" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var env = try freshTestEnv(alloc);
    defer env.deinit();

    try inferInto(&env, alloc,
        \\pub fn tpl(comptime t: @Expr<string>) -> @Expr<string> {
        \\    return t;
        \\}
        \\val c = tpl "";
    );

    const captures = try onlyCaptures(&env);
    const cap = captures[0];
    try std.testing.expect(cap.text != null);
    try std.testing.expectEqualStrings("", cap.text.?);
    try std.testing.expect(!cap.multiline);
}

// A splice whose lifted value expands to a TYPE error is reported at the splice
// site (the caller's `port()` call), not at the template definition: `@expr`
// lifts a `bool`, but the bound is `@Expr<i32>`.
test "infer error: net-new ---- splice type error reports at the splice site" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn port() -> @Expr<i32> {
        \\    return @expr(true);
        \\}
        \\val p = port();
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
        \\pub fn tpl(comptime q: @Expr<string>) -> @Expr<string> {
        \\    return q;
        \\}
        \\val a = tpl "one";
        \\val b = tpl "two";
    );

    try std.testing.expectEqual(@as(u32, 2), env.templateExpansions.count());
}

// A nested template — `outer`'s built code itself calls the template fn `inner`
// with a literal. Expanding `outer` splices in `inner("deep")`, which then
// expands in turn: each template fn expands once for its own call site.
test "comptime: net-new ---- nested template call inside a template body" {
    const src =
        \\pub fn inner(comptime q: @Expr<string>) -> @Expr<string> {
        \\    return q;
        \\}
        \\pub fn outer(comptime q: @Expr<string>) -> @Expr<string> {
        \\    return q.build("inner(\"deep\")");
        \\}
        \\val s = outer "x";
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
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn fragment(items: Element[]) -> Element { Element(); }
        \\fn Page1() -> Element { Element(); }
        \\fn Page2() -> Element { Element(); }
        \\pub fn html(comptime q: @Expr<string>) -> @Expr<Element> {
        \\    return q.build("fragment([Page1(), Page2()])");
        \\}
        \\val page = html """<Page1/><Page2/>""";
    );
}

test "template: markup DSL ---- ${expr} splices as a text child" {
    try assertCompilesOk(@src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn fragment(items: Element[]) -> Element { Element(); }
        \\fn text(value: string) -> Element { Element(); }
        \\pub fn html(comptime q: @Expr<string>) -> @Expr<Element> {
        \\    var acc = "fragment([";
        \\    loop (q.parts()) { p ->
        \\        if (p.kind == "Interp") {
        \\            acc = acc + "text(" + p.code + "),";
        \\        };
        \\    };
        \\    return q.build(acc + "])");
        \\}
        \\val name = "world";
        \\val page = html """<p>${name}</p>""";
    );
}
