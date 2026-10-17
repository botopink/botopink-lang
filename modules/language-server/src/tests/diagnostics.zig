/// Diagnostic tests — covers `compiler_mod.LspCompiler` + parse errors.
///
/// Analogous to BotoPink tests/compilation.rs (6 tests)
const std = @import("std");
const bp = @import("botopink");
const h = @import("./helpers.zig");
const proto = @import("../protocol.zig");
const engine = @import("../engine.zig");
const snap = @import("./snapshot.zig");
const test_scratch = @import("test_scratch");
const server_mod = @import("../server.zig");

// ── D1 — empty file ────────────────────────────────────────────────────────

test "diagnostics: empty source compiles without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, "");
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D2 — valid source ─────────────────────────────────────────────────────────

test "diagnostics: simple val compiles without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, "val x = 42;");
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D3 — multiple valid declarations ────────────────────────────────────────

test "diagnostics: multiple declarations compile without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\val x = 1;
        \\val s = "hello";
        \\fn f(a: i32) { return a; }
    );
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D4 — parse error — unexpected token ─────────────────────────────────────

test "diagnostics: parse error on unexpected token" {
    const gpa = std.testing.allocator;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const source = "val = 1;"; // missing binding name
    var lexer = bp.Lexer.init(source);
    const tokens = try lexer.scanAll(arena.allocator());

    var parser = bp.Parser.init(tokens);
    const result = parser.parse(arena.allocator());
    try std.testing.expectError(error.UnexpectedToken, result);
    try std.testing.expect(parser.parseError != null);
}

// ── D5 — parse error — missing close ─────────────────────────────────────

test "diagnostics: parse error on unclosed expression" {
    const gpa = std.testing.allocator;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const source = "fn f( =";
    var lexer = bp.Lexer.init(source);
    const tokens = try lexer.scanAll(arena.allocator());

    var parser = bp.Parser.init(tokens);
    const result = parser.parse(arena.allocator());
    try std.testing.expectError(error.UnexpectedToken, result);
}

// ── D6 — valid struct ──

test "diagnostics: struct declaration compiles without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\val Point = type(x: i32, y: i32);
        \\val p = Point(x: 1, y: 2);
    );
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D7 — valid enum ──

test "diagnostics: enum declaration compiles without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\val Color = type { Red, Green, Blue };
        \\val c = Color.Red;
    );
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D8 — fn with type annotations ──

test "diagnostics: annotated function compiles without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\fn add(x: i32, y: i32) { return x; }
    );
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D9 — a type error becomes a located diagnostic squiggle ─────────────────

test "diagnostics: type mismatch surfaces a located typeError" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\val x: i32 = "hello";
    );
    defer c.deinit(gpa);

    // A type error means there is no successful (.ok) output.
    try std.testing.expect(!c.isOk());

    var found = false;
    for (c.result.session.outputs.items) |o| {
        if (o.outcome == .typeError) {
            found = true;
            try std.testing.expect(o.outcome.typeError.loc != null);
            const msg = try o.outcome.typeError.message(gpa);
            defer gpa.free(msg);
            try std.testing.expect(std.mem.indexOf(u8, msg, "mismatch") != null);
        }
    }
    try std.testing.expect(found);
}

// ── D10 — comptime annotation failure surfaces as a diagnostic ────────────────
//
// A comptime annotation `fail` surfaces as a diagnostic. The validation of an
// `#[@External.<Target>(…)]` annotation's arguments runs during inference (no
// node eval needed), so it is the deterministic, node-free representative of
// that path. (The node-backed
// `decorator_eval` `fail`/`failAt` path is exercised by the libraries'
// decorator cells.) The error is located at the annotation, as every
// `TypeError` is (`snapshots/comptime/errors/external_wrong_arity.snap.md`,
// `main.bp:1:3`); here we pin the diagnostic fires.
test "diagnostics: a misused #[@External.<Target>] annotation surfaces a typeError diagnostic" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\#[@External.Erlang(..)]
        \\pub declare fn length(s: string) -> i32;
    );
    defer c.deinit(gpa);

    // The refused annotation means there is no successful (.ok) output: `..`
    // stands where the module and symbol string literals go.
    try std.testing.expect(!c.isOk());

    var found = false;
    for (c.result.session.outputs.items) |o| {
        if (o.outcome != .typeError) continue;
        const msg = try o.outcome.typeError.message(gpa);
        defer gpa.free(msg);
        if (std.mem.indexOf(u8, msg, "external") != null) found = true;
    }
    try std.testing.expect(found);
}

// ── D11 — a checker warning is a diagnostic of severity Warning ─────────────
//
// Decision 57: `OkData.warnings` fail nothing; `botopink check` prints them
// under `warning:`, and the editor shows the same one as a Warning.

test "diagnostics: a checker warning surfaces with severity Warning" {
    const gpa = std.testing.allocator;
    const source =
        \\pub fn main() {
        \\    var out = [];
        \\    @print("x");
        \\}
    ;
    var result = try engine.diagnose(gpa, std.testing.io, h.TEST_URI, source, null, &.{});
    defer result.deinit(gpa);
    try std.testing.expect(result.diagnostics.len > 0);
    for (result.diagnostics) |d| try std.testing.expectEqual(@as(?u32, proto.DiagnosticSeverity.Warning), d.severity);
    try snap.assertDiagnostics(gpa, "diagnostics_checker_warning", source, result.diagnostics);
}

// ── D12 — the import-source refusals `check` makes (front 26 step 8) ────────
//
// Decisions 206, 242 and 309: `from` names a package — std, a bundled package
// or a declared dependency, never the importing package itself. The compile binds `from "<own module>"` and the editor
// showed it resolving until `botopink check` refused it; the LSP now reports
// both refusals with the CLI's message, at the source string.

test "diagnostics: from naming a module of this package is module-import-with-from" {
    const gpa = std.testing.allocator;
    const source =
        \\import {area} from "geometry";
        \\
        \\pub fn main() {
        \\    @print(area(2));
        \\}
    ;
    const package = [_]engine.ModuleSource{
        .{ .uri = "file:///proj/src/geometry.bp", .source = "pub fn area(x: i32) -> i32 { return x * x; }" },
    };
    const diags = try engine.importDiagnostics(gpa, "file:///proj/src/main.bp", source, &package, "/proj/src", &.{}, "");
    defer {
        for (diags) |d| gpa.free(d.message);
        gpa.free(diags);
    }
    try std.testing.expectEqual(@as(usize, 1), diags.len);
    try snap.assertDiagnostics(gpa, "diagnostics_import_module_with_from", source, diags);
}

test "diagnostics: from naming an undeclared package is an unresolved import source" {
    const gpa = std.testing.allocator;
    const source =
        \\import {start} from "starter";
        \\import {greet} from "core";
        \\
        \\pub fn main() {
        \\    @print(start() + greet());
        \\}
    ;
    const diags = try engine.importDiagnostics(gpa, "file:///proj/src/main.bp", source, &.{}, "/proj/src", &.{"starter"}, "");
    defer {
        for (diags) |d| gpa.free(d.message);
        gpa.free(diags);
    }
    try std.testing.expectEqual(@as(usize, 1), diags.len);
    try snap.assertDiagnostics(gpa, "diagnostics_import_unresolved_source", source, diags);
}

test "diagnostics: from naming this package itself is module-import-with-from" {
    const gpa = std.testing.allocator;
    const source =
        \\import {area} from "shapes.geometry";
        \\
        \\pub fn main() {
        \\    @print(area(2));
        \\}
    ;
    const package = [_]engine.ModuleSource{
        .{ .uri = "file:///proj/src/geometry.bp", .source = "pub fn area(x: i32) -> i32 { return x * x; }" },
    };
    const diags = try engine.importDiagnostics(gpa, "file:///proj/src/main.bp", source, &package, "/proj/src", &.{}, "shapes");
    defer {
        for (diags) |d| gpa.free(d.message);
        gpa.free(diags);
    }
    try std.testing.expectEqual(@as(usize, 1), diags.len);
    try snap.assertDiagnostics(gpa, "diagnostics_import_own_package_with_from", source, diags);
}

// The server half: the package name is the open document's manifest `name`.
test "diagnostics: the server names the package by its manifest for the 309 refusal" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "lsp-own-package");
    defer test_scratch.remove(io, "lsp-own-package");

    const source =
        \\import {area} from "shapes.geometry";
        \\
        \\pub fn main() {
        \\    @print(area(2));
        \\}
        \\
    ;
    const files = [_]struct { rel: []const u8, data: []const u8 }{
        .{ .rel = test_scratch.path(io, "lsp-own-package/shapes/botopink.json"), .data =
        \\{ "name": "shapes" }
        },
        .{ .rel = test_scratch.path(io, "lsp-own-package/shapes/src/geometry.bp"), .data = "pub fn area(x: i32) -> i32 { return x * x; }" },
        .{ .rel = test_scratch.path(io, "lsp-own-package/shapes/src/main.bp"), .data = source },
    };
    for (files) |f| {
        if (std.fs.path.dirname(f.rel)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = f.rel, .data = f.data });
    }

    var server = server_mod.Server.init(gpa, io, null);
    defer server.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const diags = try server.importDiagnostics(arena.allocator(), test_scratch.uri(io, "lsp-own-package/shapes/src/main.bp"), source);
    defer {
        for (diags) |d| gpa.free(d.message);
        gpa.free(diags);
    }
    try std.testing.expectEqual(@as(usize, 1), diags.len);
    try std.testing.expectEqualStrings("\"shapes.geometry\" is this package — write import {geometry.area};", diags[0].message);
}
