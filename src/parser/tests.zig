const std = @import("std");
const OhSnap = @import("ohsnap");
const Allocator = std.mem.Allocator;
const SourceLocation = std.builtin.SourceLocation;

const lexer_mod = @import("../lexer.zig");
const parser_mod = @import("../parser.zig");

const ParseErrorType = parser_mod.ParseErrorType;
const ast = @import("../ast.zig");
const Lexer = lexer_mod.Lexer;
const Parser = parser_mod.Parser;
const print = @import("../print.zig");

// ── helpers ───────────────────────────────────────────────────────────────────

fn assert_parser(
    allocator: Allocator,
    comptime location: SourceLocation,
    comptime text: []const u8,
    src: []const u8,
) !void {
    var l = Lexer.init(src);
    const tokens = try l.scanAll(allocator);
    defer l.deinit(allocator);

    var p = Parser.init(tokens);
    var program = try p.parse(allocator);
    defer program.deinit(allocator);

    const oh = OhSnap{};
    try oh.snap(location, text).expectEqual(program);
}

/// Asserts that `src` produces a parse error whose rendered output
/// matches the snapshot `expected`.
///
/// Usage:
///   try expect_parse_error(std.testing.allocator,
///       \\error: syntax error
///       \\ --> <test>:1:8
///       \\  |
///       \\1 | wibble = 4
///       \\  |        ^ There must be a 'val' or 'var' to bind a variable to a value
///       \\  |
///       \\  = hint: Use `val <n> = <value>` for bindings.
///       \\
///   , "wibble = 4");
fn expect_parse_error(
    allocator: std.mem.Allocator,
    comptime expected: []const u8,
    src: []const u8,
) !void {
    var l = lexer_mod.Lexer.init(src);
    const tokens = l.scanAll(allocator) catch {
        l.deinit(allocator);
        return error.LexErrorNotParseError;
    };
    defer l.deinit(allocator);

    var p = parser_mod.Parser.initWithSource(tokens, src);
    if (p.parse(allocator)) |*prog| {
        var owned = prog.*;
        owned.deinit(allocator);
        return error.TestExpectedParseError;
    } else |_| {
        const pe = p.parse_error orelse return;
        const actual = try print.renderAlloc(allocator, pe, src, "<test>");
        defer allocator.free(actual);
        try expectEqualOutput(allocator, expected, actual);
    }
}

/// Compares `expected` with `actual` line by line and prints a readable diff
/// if they diverge.
fn expectEqualOutput(
    allocator: std.mem.Allocator,
    expected: []const u8,
    actual: []const u8,
) !void {
    if (std.mem.eql(u8, expected, actual)) return;

    var exp_lines: std.ArrayList([]const u8) = .empty;
    defer exp_lines.deinit(allocator);
    var act_lines: std.ArrayList([]const u8) = .empty;
    defer act_lines.deinit(allocator);

    var it = std.mem.splitScalar(u8, expected, '\n');
    while (it.next()) |line| try exp_lines.append(allocator, line);
    it = std.mem.splitScalar(u8, actual, '\n');
    while (it.next()) |line| try act_lines.append(allocator, line);

    const max_lines = @max(exp_lines.items.len, act_lines.items.len);

    std.debug.print("\n-- parse error output mismatch ------------------------------\n", .{});
    var has_diff = false;
    for (0..max_lines) |i| {
        const e = if (i < exp_lines.items.len) exp_lines.items[i] else "<missing>";
        const a = if (i < act_lines.items.len) act_lines.items[i] else "<missing>";
        if (!std.mem.eql(u8, e, a)) {
            if (!has_diff) std.debug.print("{s:>4}  {s:<40}  {s}\n", .{ "line", "expected", "actual" });
            std.debug.print("{d:>4}  -{s}\n      +{s}\n", .{ i + 1, e, a });
            has_diff = true;
        }
    }
    std.debug.print("-------------------------------------------------------------\n\n", .{});
    if (has_diff) return error.TestOutputMismatch;
}

// ── empty program ─────────────────────────────────────────────────────────────

test "parser: empty program" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    (empty)
    , "");
}

test "parser: whitespace-only source" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    (empty)
    , "   \t\n  ");
}

// ── use decl ─────────────────────────────────────────────────────────────────

test "parser: use {} from \"mylib\" (empty imports)" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          (empty)
        \\        .source: ast.Source
        \\          .StringPath: []const u8
        \\            "mylib"
    , "use {} from \"mylib\"");
}

test "parser: use {foo} from \"lib\"" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          [0]: []const u8
        \\            "foo"
        \\        .source: ast.Source
        \\          .StringPath: []const u8
        \\            "lib"
    , "use {foo} from \"lib\"");
}

test "parser: use {alpha, beta, gamma} from \"pkg\"" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          [0]: []const u8
        \\            "alpha"
        \\          [1]: []const u8
        \\            "beta"
        \\          [2]: []const u8
        \\            "gamma"
        \\        .source: ast.Source
        \\          .StringPath: []const u8
        \\            "pkg"
    , "use {alpha, beta, gamma} from \"pkg\"");
}

test "parser: trailing comma in import list" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          [0]: []const u8
        \\            "a"
        \\          [1]: []const u8
        \\            "b"
        \\        .source: ast.Source
        \\          .StringPath: []const u8
        \\            "x"
    , "use {a, b,} from \"x\"");
}

test "parser: empty string path" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          [0]: []const u8
        \\            "x"
        \\        .source: ast.Source
        \\          .StringPath: []const u8
        \\            ""
    , "use {x} from \"\"");
}

// ── use: source FunctionCall ──────────────────────────────────────────────────

test "parser: use {x} from loader()" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          [0]: []const u8
        \\            "x"
        \\        .source: ast.Source
        \\          .FunctionCall: []const u8
        \\            "loader"
    , "use {x} from loader()");
}

test "parser: use {} from init() (empty imports + FunctionCall)" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          (empty)
        \\        .source: ast.Source
        \\          .FunctionCall: []const u8
        \\            "init"
    , "use {} from init()");
}

// ── use: multiple declarations ────────────────────────────────────────────────

test "parser: two use declarations" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          [0]: []const u8
        \\            "a"
        \\        .source: ast.Source
        \\          .StringPath: []const u8
        \\            "lib1"
        \\    [1]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          [0]: []const u8
        \\            "b"
        \\          [1]: []const u8
        \\            "c"
        \\        .source: ast.Source
        \\          .StringPath: []const u8
        \\            "lib2"
    ,
        \\use {a} from "lib1"
        \\use {b, c} from "lib2"
    );
}

test "parser: mixed StringPath and FunctionCall declarations" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          [0]: []const u8
        \\            "x"
        \\        .source: ast.Source
        \\          .StringPath: []const u8
        \\            "a"
        \\    [1]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          [0]: []const u8
        \\            "y"
        \\        .source: ast.Source
        \\          .FunctionCall: []const u8
        \\            "b"
        \\    [2]: ast.DeclKind
        \\      .Use: ast.UseDecl
        \\        .imports: []const []const u8
        \\          [0]: []const u8
        \\            "z"
        \\        .source: ast.Source
        \\          .StringPath: []const u8
        \\            "c"
    ,
        \\use {x} from "a"
        \\use {y} from b()
        \\use {z} from "c"
    );
}

// ── interface: basic structure ────────────────────────────────────────────────────

test "parser: empty interface" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Interface: ast.InterfaceDecl
        \\        .name: []const u8
        \\          "Drawable"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .fields: []ast.InterfaceField
        \\          (empty)
        \\        .methods: []ast.InterfaceMethod
        \\          (empty)
    , "val Drawable = interface {}");
}

test "parser: interface with one field" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Interface: ast.InterfaceDecl
        \\        .name: []const u8
        \\          "Drawable"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .fields: []ast.InterfaceField
        \\          [0]: ast.InterfaceField
        \\            .name: []const u8
        \\              "color"
        \\            .type_name: []const u8
        \\              "String"
        \\        .methods: []ast.InterfaceMethod
        \\          (empty)
    , "val Drawable = interface { val color: String }");
}

// ── interface: method params ──────────────────────────────────────────────────────

test "parser: abstract method with 1 param (self: Self)" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Interface: ast.InterfaceDecl
        \\        .name: []const u8
        \\          "Drawable"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .fields: []ast.InterfaceField
        \\          (empty)
        \\        .methods: []ast.InterfaceMethod
        \\          [0]: ast.InterfaceMethod
        \\            .name: []const u8
        \\              "draw"
        \\            .generic_params: []ast.GenericParam
        \\              (empty)
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: ?[]ast.Stmt
        \\              null
    , "val Drawable = interface { fn draw(self: Self) }");
}

test "parser: abstract method with multiple params" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Interface: ast.InterfaceDecl
        \\        .name: []const u8
        \\          "Positionable"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .fields: []ast.InterfaceField
        \\          (empty)
        \\        .methods: []ast.InterfaceMethod
        \\          [0]: ast.InterfaceMethod
        \\            .name: []const u8
        \\              "moveTo"
        \\            .generic_params: []ast.GenericParam
        \\              (empty)
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\              [1]: ast.Param
        \\                .name: []const u8
        \\                  "x"
        \\                .type_name: []const u8
        \\                  "Int"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\              [2]: ast.Param
        \\                .name: []const u8
        \\                  "y"
        \\                .type_name: []const u8
        \\                  "Int"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: ?[]ast.Stmt
        \\              null
    , "val Positionable = interface { fn moveTo(self: Self, x: Int, y: Int) }");
}

// ── interface: multiple methods with varying param counts ────────────────────────

test "parser: interface with methods of varying param counts" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Interface: ast.InterfaceDecl
        \\        .name: []const u8
        \\          "Canvas"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .fields: []ast.InterfaceField
        \\          (empty)
        \\        .methods: []ast.InterfaceMethod
        \\          [0]: ast.InterfaceMethod
        \\            .name: []const u8
        \\              "clear"
        \\            .generic_params: []ast.GenericParam
        \\              (empty)
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: ?[]ast.Stmt
        \\              null
        \\          [1]: ast.InterfaceMethod
        \\            .name: []const u8
        \\              "drawLine"
        \\            .generic_params: []ast.GenericParam
        \\              (empty)
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\              [1]: ast.Param
        \\                .name: []const u8
        \\                  "x1"
        \\                .type_name: []const u8
        \\                  "Int"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\              [2]: ast.Param
        \\                .name: []const u8
        \\                  "y1"
        \\                .type_name: []const u8
        \\                  "Int"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: ?[]ast.Stmt
        \\              null
        \\          [2]: ast.InterfaceMethod
        \\            .name: []const u8
        \\              "drawRect"
        \\            .generic_params: []ast.GenericParam
        \\              (empty)
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\              [1]: ast.Param
        \\                .name: []const u8
        \\                  "x"
        \\                .type_name: []const u8
        \\                  "Int"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\              [2]: ast.Param
        \\                .name: []const u8
        \\                  "y"
        \\                .type_name: []const u8
        \\                  "Int"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\              [3]: ast.Param
        \\                .name: []const u8
        \\                  "color"
        \\                .type_name: []const u8
        \\                  "String"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: ?[]ast.Stmt
        \\              null
    ,
        \\val Canvas = interface {
        \\    fn clear(self: Self)
        \\    fn drawLine(self: Self, x1: Int, y1: Int)
        \\    fn drawRect(self: Self, x: Int, y: Int, color: String)
        \\}
    );
}

// ── interface: full Drawable from spec ────────────────────────────────────────────

test "parser: full Drawable interface (field + abstract + default method)" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Interface: ast.InterfaceDecl
        \\        .name: []const u8
        \\          "Drawable"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .fields: []ast.InterfaceField
        \\          [0]: ast.InterfaceField
        \\            .name: []const u8
        \\              "color"
        \\            .type_name: []const u8
        \\              "String"
        \\        .methods: []ast.InterfaceMethod
        \\          [0]: ast.InterfaceMethod
        \\            .name: []const u8
        \\              "draw"
        \\            .generic_params: []ast.GenericParam
        \\              (empty)
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: ?[]ast.Stmt
        \\              null
        \\          [1]: ast.InterfaceMethod
        \\            .name: []const u8
        \\              "log"
        \\            .generic_params: []ast.GenericParam
        \\              (empty)
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: ?[]ast.Stmt
        \\              [0]: ast.Stmt
        \\                .expr: ast.Expr
        \\                  .StaticCall: ast.Expr__struct_<^\d+$>
        \\                    .receiver: []const u8
        \\                      "Console"
        \\                    .method: []const u8
        \\                      "WriteLine"
        \\                    .arg: *ast.Expr
        \\                      .Concat: ast.Expr__struct_<^\d+$>
        \\                        .lhs: *ast.Expr
        \\                          .StringLit: []const u8
        \\                            "Rendering object with color: "
        \\                        .rhs: *ast.Expr
        \\                          .SelfField: []const u8
        \\                            "color"
    ,
        \\val Drawable = interface {
        \\    val color: String
        \\    fn draw(self: Self)
        \\    fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " ++ self.color)
        \\    }
        \\}
    );
}

// ── struct: basic structure ───────────────────────────────────────────────────

test "parser: empty struct" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Struct: ast.StructDecl
        \\        .name: []const u8
        \\          "Account"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .members: []ast.StructMember
        \\          (empty)
    , "val Account = struct {}");
}

test "parser: struct with one private field" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Struct: ast.StructDecl
        \\        .name: []const u8
        \\          "Account"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .members: []ast.StructMember
        \\          [0]: ast.StructMember
        \\            .Field: ast.StructField
        \\              .is_private: bool = true
        \\              .name: []const u8
        \\                "_balance"
        \\              .type_name: []const u8
        \\                "number"
        \\              .init: ast.Expr
        \\                .NumberLit: []const u8
        \\                  "0"
    , "val Account = struct { private val _balance: number = 0 }");
}

test "parser: struct with one public field" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Struct: ast.StructDecl
        \\        .name: []const u8
        \\          "Config"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .members: []ast.StructMember
        \\          [0]: ast.StructMember
        \\            .Field: ast.StructField
        \\              .is_private: bool = false
        \\              .name: []const u8
        \\                "host"
        \\              .type_name: []const u8
        \\                "string"
        \\              .init: ast.Expr
        \\                .StringLit: []const u8
        \\                  "localhost"
    , "val Config = struct { val host: string = \"localhost\" }");
}

// ── struct: getter ────────────────────────────────────────────────────────────

test "parser: struct with a simple getter" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Struct: ast.StructDecl
        \\        .name: []const u8
        \\          "Account"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .members: []ast.StructMember
        \\          [0]: ast.StructMember
        \\            .Getter: ast.StructGetter
        \\              .name: []const u8
        \\                "balance"
        \\              .self_param: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\              .return_type: []const u8
        \\                "number"
        \\              .body: []ast.Stmt
        \\                [0]: ast.Stmt
        \\                  .expr: ast.Expr
        \\                    .Return: *ast.Expr
        \\                      .SelfField: []const u8
        \\                        "_balance"
    ,
        \\val Account = struct {
        \\    get balance(self: Self) -> number {
        \\        return self._balance
        \\    }
        \\}
    );
}

// ── struct: setter ────────────────────────────────────────────────────────────

test "parser: struct with a setter that throws" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Struct: ast.StructDecl
        \\        .name: []const u8
        \\          "Account"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .members: []ast.StructMember
        \\          [0]: ast.StructMember
        \\            .Setter: ast.StructSetter
        \\              .name: []const u8
        \\                "balance"
        \\              .params: []ast.Param
        \\                [0]: ast.Param
        \\                  .name: []const u8
        \\                    "self"
        \\                  .type_name: []const u8
        \\                    "Self"
        \\                  .modifier: ast.ParamModifier
        \\                    .None
        \\                  .typeinfo_constraints: ?[]const []const u8
        \\                    null
        \\                [1]: ast.Param
        \\                  .name: []const u8
        \\                    "value"
        \\                  .type_name: []const u8
        \\                    "number"
        \\                  .modifier: ast.ParamModifier
        \\                    .None
        \\                  .typeinfo_constraints: ?[]const []const u8
        \\                    null
        \\              .body: []ast.Stmt
        \\                [0]: ast.Stmt
        \\                  .expr: ast.Expr
        \\                    .ThrowNew: ast.Expr__struct_<^\d+$>
        \\                      .error_type: []const u8
        \\                        "Error"
        \\                      .message: *ast.Expr
        \\                        .StringLit: []const u8
        \\                          "Saldo nao pode ser negativo"
    ,
        \\val Account = struct {
        \\    set balance(self: Self, value: number) {
        \\        throw new Error("Saldo nao pode ser negativo")
        \\    }
        \\}
    );
}

test "parser: setter with assign" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Struct: ast.StructDecl
        \\        .name: []const u8
        \\          "Account"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .members: []ast.StructMember
        \\          [0]: ast.StructMember
        \\            .Setter: ast.StructSetter
        \\              .name: []const u8
        \\                "balance"
        \\              .params: []ast.Param
        \\                [0]: ast.Param
        \\                  .name: []const u8
        \\                    "self"
        \\                  .type_name: []const u8
        \\                    "Self"
        \\                  .modifier: ast.ParamModifier
        \\                    .None
        \\                  .typeinfo_constraints: ?[]const []const u8
        \\                    null
        \\                [1]: ast.Param
        \\                  .name: []const u8
        \\                    "value"
        \\                  .type_name: []const u8
        \\                    "number"
        \\                  .modifier: ast.ParamModifier
        \\                    .None
        \\                  .typeinfo_constraints: ?[]const []const u8
        \\                    null
        \\              .body: []ast.Stmt
        \\                [0]: ast.Stmt
        \\                  .expr: ast.Expr
        \\                    .SelfFieldAssign: ast.Expr__struct_<^\d+$>
        \\                      .field: []const u8
        \\                        "_balance"
        \\                      .value: *ast.Expr
        \\                        .Ident: []const u8
        \\                          "value"
    ,
        \\val Account = struct {
        \\    set balance(self: Self, value: number) {
        \\        self._balance = value
        \\    }
        \\}
    );
}

// ── struct: method ────────────────────────────────────────────────────────────

test "parser: struct with a fn method (deposit)" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Struct: ast.StructDecl
        \\        .name: []const u8
        \\          "Account"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .members: []ast.StructMember
        \\          [0]: ast.StructMember
        \\            .Method: ast.InterfaceMethod
        \\              .name: []const u8
        \\                "deposit"
        \\              .generic_params: []ast.GenericParam
        \\                (empty)
        \\              .params: []ast.Param
        \\                [0]: ast.Param
        \\                  .name: []const u8
        \\                    "self"
        \\                  .type_name: []const u8
        \\                    "Self"
        \\                  .modifier: ast.ParamModifier
        \\                    .None
        \\                  .typeinfo_constraints: ?[]const []const u8
        \\                    null
        \\                [1]: ast.Param
        \\                  .name: []const u8
        \\                    "amount"
        \\                  .type_name: []const u8
        \\                    "number"
        \\                  .modifier: ast.ParamModifier
        \\                    .None
        \\                  .typeinfo_constraints: ?[]const []const u8
        \\                    null
        \\              .body: ?[]ast.Stmt
        \\                [0]: ast.Stmt
        \\                  .expr: ast.Expr
        \\                    .SelfFieldPlusEq: ast.Expr__struct_<^\d+$>
        \\                      .field: []const u8
        \\                        "_balance"
        \\                      .value: *ast.Expr
        \\                        .Ident: []const u8
        \\                          "amount"
    ,
        \\val Account = struct {
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount
        \\    }
        \\}
    );
}

// ── struct: full Account from spec ────────────────────────────────────────────

test "parser: full Account struct (private field + getter + setter + method)" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Struct: ast.StructDecl
        \\        .name: []const u8
        \\          "Account"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .members: []ast.StructMember
        \\          [0]: ast.StructMember
        \\            .Field: ast.StructField
        \\              .is_private: bool = true
        \\              .name: []const u8
        \\                "_balance"
        \\              .type_name: []const u8
        \\                "number"
        \\              .init: ast.Expr
        \\                .NumberLit: []const u8
        \\                  "0"
        \\          [1]: ast.StructMember
        \\            .Getter: ast.StructGetter
        \\              .name: []const u8
        \\                "balance"
        \\              .self_param: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\              .return_type: []const u8
        \\                "number"
        \\              .body: []ast.Stmt
        \\                [0]: ast.Stmt
        \\                  .expr: ast.Expr
        \\                    .Return: *ast.Expr
        \\                      .SelfField: []const u8
        \\                        "_balance"
        \\          [2]: ast.StructMember
        \\            .Setter: ast.StructSetter
        \\              .name: []const u8
        \\                "balance"
        \\              .params: []ast.Param
        \\                [0]: ast.Param
        \\                  .name: []const u8
        \\                    "self"
        \\                  .type_name: []const u8
        \\                    "Self"
        \\                  .modifier: ast.ParamModifier
        \\                    .None
        \\                  .typeinfo_constraints: ?[]const []const u8
        \\                    null
        \\                [1]: ast.Param
        \\                  .name: []const u8
        \\                    "value"
        \\                  .type_name: []const u8
        \\                    "number"
        \\                  .modifier: ast.ParamModifier
        \\                    .None
        \\                  .typeinfo_constraints: ?[]const []const u8
        \\                    null
        \\              .body: []ast.Stmt
        \\                [0]: ast.Stmt
        \\                  .expr: ast.Expr
        \\                    .SelfFieldAssign: ast.Expr__struct_<^\d+$>
        \\                      .field: []const u8
        \\                        "_balance"
        \\                      .value: *ast.Expr
        \\                        .Ident: []const u8
        \\                          "value"
        \\          [3]: ast.StructMember
        \\            .Method: ast.InterfaceMethod
        \\              .name: []const u8
        \\                "deposit"
        \\              .generic_params: []ast.GenericParam
        \\                (empty)
        \\              .params: []ast.Param
        \\                [0]: ast.Param
        \\                  .name: []const u8
        \\                    "self"
        \\                  .type_name: []const u8
        \\                    "Self"
        \\                  .modifier: ast.ParamModifier
        \\                    .None
        \\                  .typeinfo_constraints: ?[]const []const u8
        \\                    null
        \\                [1]: ast.Param
        \\                  .name: []const u8
        \\                    "amount"
        \\                  .type_name: []const u8
        \\                    "number"
        \\                  .modifier: ast.ParamModifier
        \\                    .None
        \\                  .typeinfo_constraints: ?[]const []const u8
        \\                    null
        \\              .body: ?[]ast.Stmt
        \\                [0]: ast.Stmt
        \\                  .expr: ast.Expr
        \\                    .SelfFieldPlusEq: ast.Expr__struct_<^\d+$>
        \\                      .field: []const u8
        \\                        "_balance"
        \\                      .value: *ast.Expr
        \\                        .Ident: []const u8
        \\                          "amount"
    ,
        \\val Account = struct {
        \\    private val _balance: number = 0
        \\    get balance(self: Self) -> number {
        \\        return self._balance
        \\    }
        \\    set balance(self: Self, value: number) {
        \\        self._balance = value
        \\    }
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount
        \\    }
        \\}
    );
}

// ── record: basic structure ───────────────────────────────────────────────────

test "parser: empty record (no fields, no methods)" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Record: ast.RecordDecl
        \\        .name: []const u8
        \\          "Point"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .fields: []ast.RecordField
        \\          (empty)
        \\        .methods: []ast.InterfaceMethod
        \\          (empty)
    , "val Point = record() {}");
}

test "parser: record with two fields and no methods" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Record: ast.RecordDecl
        \\        .name: []const u8
        \\          "Point"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .fields: []ast.RecordField
        \\          [0]: ast.RecordField
        \\            .name: []const u8
        \\              "x"
        \\            .type_name: []const u8
        \\              "number"
        \\          [1]: ast.RecordField
        \\            .name: []const u8
        \\              "y"
        \\            .type_name: []const u8
        \\              "number"
        \\        .methods: []ast.InterfaceMethod
        \\          (empty)
    , "val Point = record(val x: number, val y: number) {}");
}

test "parser: record with one method" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Record: ast.RecordDecl
        \\        .name: []const u8
        \\          "Point"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .fields: []ast.RecordField
        \\          [0]: ast.RecordField
        \\            .name: []const u8
        \\              "x"
        \\            .type_name: []const u8
        \\              "number"
        \\        .methods: []ast.InterfaceMethod
        \\          [0]: ast.InterfaceMethod
        \\            .name: []const u8
        \\              "show"
        \\            .generic_params: []ast.GenericParam
        \\              (empty)
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: ?[]ast.Stmt
        \\              [0]: ast.Stmt
        \\                .expr: ast.Expr
        \\                  .Return: *ast.Expr
        \\                    .SelfField: []const u8
        \\                      "x"
    ,
        \\val Point = record(val x: number) {
        \\    fn show(self: Self) {
        \\        return self.x
        \\    }
        \\}
    );
}

// ── record: full GPSCoordinates from spec ─────────────────────────────────────

test "parser: full GPSCoordinates record (two fields + toString method)" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Record: ast.RecordDecl
        \\        .name: []const u8
        \\          "GPSCoordinates"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .fields: []ast.RecordField
        \\          [0]: ast.RecordField
        \\            .name: []const u8
        \\              "lat"
        \\            .type_name: []const u8
        \\              "number"
        \\          [1]: ast.RecordField
        \\            .name: []const u8
        \\              "lon"
        \\            .type_name: []const u8
        \\              "number"
        \\        .methods: []ast.InterfaceMethod
        \\          [0]: ast.InterfaceMethod
        \\            .name: []const u8
        \\              "toString"
        \\            .generic_params: []ast.GenericParam
        \\              (empty)
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: ?[]ast.Stmt
        \\              [0]: ast.Stmt
        \\                .expr: ast.Expr
        \\                  .Return: *ast.Expr
        \\                    .Concat: ast.Expr__struct_<^\d+$>
        \\                      .lhs: *ast.Expr
        \\                        .Concat: ast.Expr__struct_<^\d+$>
        \\                          .lhs: *ast.Expr
        \\                            .Concat: ast.Expr__struct_<^\d+$>
        \\                              .lhs: *ast.Expr
        \\                                .StringLit: []const u8
        \\                                  "Lat: "
        \\                              .rhs: *ast.Expr
        \\                                .SelfField: []const u8
        \\                                  "lat"
        \\                          .rhs: *ast.Expr
        \\                            .StringLit: []const u8
        \\                              " Lon: "
        \\                      .rhs: *ast.Expr
        \\                        .SelfField: []const u8
        \\                          "lon"
    ,
        \\val GPSCoordinates = record(val lat: number, val lon: number) {
        \\    fn toString(self: Self) -> String {
        \\        return "Lat: " ++ self.lat ++ " Lon: " ++ self.lon
        \\    }
        \\}
    );
}

// ── impl: basic structure ─────────────────────────────────────────────────────

test "parser: implement with one interface and one unqualified method" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Implement: ast.ImplementDecl
        \\        .name: []const u8
        \\          "Myimplement"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .interfaces: []const []const u8
        \\          [0]: []const u8
        \\            "Drawable"
        \\        .target: []const u8
        \\          "Circle"
        \\        .methods: []ast.ImplementMethod
        \\          [0]: ast.ImplementMethod
        \\            .qualifier: ?[]const u8
        \\              null
        \\            .name: []const u8
        \\              "draw"
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: []ast.Stmt
        \\              (empty)
    ,
        \\val Myimplement = implement Drawable for Circle {
        \\    fn draw(self: Self) {}
        \\}
    );
}

test "parser: implement with two interfaces and qualified methods" {
    try assert_parser(std.testing.allocator, @src(),
        \\ast.Program
        \\  .decls: []ast.DeclKind
        \\    [0]: ast.DeclKind
        \\      .Implement: ast.ImplementDecl
        \\        .name: []const u8
        \\          "CameraPowerCharger"
        \\        .generic_params: []ast.GenericParam
        \\          (empty)
        \\        .interfaces: []const []const u8
        \\          [0]: []const u8
        \\            "UsbCharger"
        \\          [1]: []const u8
        \\            "SolarCharger"
        \\        .target: []const u8
        \\          "SmartCamera"
        \\        .methods: []ast.ImplementMethod
        \\          [0]: ast.ImplementMethod
        \\            .qualifier: ?[]const u8
        \\              "UsbCharger"
        \\            .name: []const u8
        \\              "Conectar"
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: []ast.Stmt
        \\              [0]: ast.Stmt
        \\                .expr: ast.Expr
        \\                  .StaticCall: ast.Expr__struct_<^\d+$>
        \\                    .receiver: []const u8
        \\                      "Console"
        \\                    .method: []const u8
        \\                      "WriteLine"
        \\                    .arg: *ast.Expr
        \\                      .Concat: ast.Expr__struct_<^\d+$>
        \\                        .lhs: *ast.Expr
        \\                          .StringLit: []const u8
        \\                            "Conectado via USB. Bateria atual: "
        \\                        .rhs: *ast.Expr
        \\                          .SelfField: []const u8
        \\                            "batteryLevel"
        \\          [1]: ast.ImplementMethod
        \\            .qualifier: ?[]const u8
        \\              "SolarCharger"
        \\            .name: []const u8
        \\              "Conectar"
        \\            .params: []ast.Param
        \\              [0]: ast.Param
        \\                .name: []const u8
        \\                  "self"
        \\                .type_name: []const u8
        \\                  "Self"
        \\                .modifier: ast.ParamModifier
        \\                  .None
        \\                .typeinfo_constraints: ?[]const []const u8
        \\                  null
        \\            .body: []ast.Stmt
        \\              [0]: ast.Stmt
        \\                .expr: ast.Expr
        \\                  .StaticCall: ast.Expr__struct_<^\d+$>
        \\                    .receiver: []const u8
        \\                      "Console"
        \\                    .method: []const u8
        \\                      "WriteLine"
        \\                    .arg: *ast.Expr
        \\                      .Concat: ast.Expr__struct_<^\d+$>
        \\                        .lhs: *ast.Expr
        \\                          .StringLit: []const u8
        \\                            "Conectado via Painel Solar. Bateria atual: "
        \\                        .rhs: *ast.Expr
        \\                          .SelfField: []const u8
        \\                            "batteryLevel"
    ,
        \\val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
        \\    fn UsbCharger.Conectar(self: Self) {
        \\        Console.WriteLine("Conectado via USB. Bateria atual: " ++ self.batteryLevel)
        \\    }
        \\    fn SolarCharger.Conectar(self: Self) {
        \\        Console.WriteLine("Conectado via Painel Solar. Bateria atual: " ++ self.batteryLevel)
        \\    }
        \\}
    );
}

// ── parse errors: snapshot tests ─────────────────────────────────────────────

test "parser error: assignment without val" {
    try expect_parse_error(std.testing.allocator,
        \\error: syntax error
        \\ --> <test>:1:1
        \\  |
        \\1 | wibble = 4
        \\  | ^^^^^^ There must be a 'val' or 'var' to bind a variable to a value
        \\  |
        \\  = hint: Use `val <n> = <value>` for bindings.
        \\
        \\
    , "wibble = 4");
}

test "parser error: reserved word at top-level" {
    try expect_parse_error(std.testing.allocator,
        \\error: syntax error
        \\ --> <test>:1:1
        \\  |
        \\1 | auto
        \\  | ^^^^ This is a reserved word and cannot be used as a name
        \\  |
        \\  = hint: Choose a different identifier.
        \\
        \\
    , "auto");
}

test "parser error: reserved word in expression" {
    try expect_parse_error(std.testing.allocator,
        \\error: syntax error
        \\ --> <test>:1:1
        \\  |
        \\1 | echo
        \\  | ^^^^ This is a reserved word and cannot be used as a name
        \\  |
        \\  = hint: Choose a different identifier.
        \\
        \\
    , "echo");
}

// ── validateListSpread ────────────────────────────────────────────────────────

test "parser: validateListSpread — empty list is valid" {
    try std.testing.expect(parser_mod.validateListSpread(false, false, 0) == null);
}

test "parser: validateListSpread — [1, 2, ..xs] is valid" {
    try std.testing.expect(parser_mod.validateListSpread(true, true, 2) == null);
}

test "parser: validateListSpread — [..xs, 3] gives ElementsAfterSpread" {
    const result = parser_mod.validateListSpread(true, false, 0);
    try std.testing.expectEqual(parser_mod.ListSpreadError.ElementsAfterSpread, result.?);
}

test "parser: validateListSpread — [..xs] gives UselessSpread" {
    const result = parser_mod.validateListSpread(true, true, 0);
    try std.testing.expectEqual(parser_mod.ListSpreadError.UselessSpread, result.?);
}

// ── listSpreadErrorMessage ────────────────────────────────────────────────────

test "parser: listSpreadErrorMessage.ElementsAfterSpread mentions 'after'" {
    const msgs = parser_mod.listSpreadErrorMessage(.ElementsAfterSpread);
    try std.testing.expect(
        std.mem.indexOf(u8, msgs.message, "after") != null or
            std.mem.indexOf(u8, msgs.message, "expecting") != null,
    );
}

test "parser: listSpreadErrorMessage.UselessSpread mentions spread has no effect" {
    const msgs = parser_mod.listSpreadErrorMessage(.UselessSpread);
    try std.testing.expect(
        std.mem.indexOf(u8, msgs.message, "nothing") != null or
            std.mem.indexOf(u8, msgs.message, "does") != null,
    );
}

// ── ParseErrorInfo ────────────────────────────────────────────────────────────

test "parser: ParseErrorInfo has all expected fields" {
    const info = parser_mod.ParseErrorInfo{
        .kind = .ReservedWord,
        .start = 0,
        .end = 4,
        .lexeme = "auto",
        .detail = "auto",
    };
    try std.testing.expectEqual(ParseErrorType.ReservedWord, info.kind);
    try std.testing.expectEqualStrings("auto", info.lexeme);
    try std.testing.expectEqual(@as(usize, 0), info.start);
    try std.testing.expectEqual(@as(usize, 4), info.end);
}

test "parser: ParseErrorInfo detail is optional" {
    const info = parser_mod.ParseErrorInfo{
        .kind = .NoValBinding,
        .start = 0,
        .end = 6,
        .lexeme = "wibble",
    };
    try std.testing.expect(info.detail == null);
}

// ── Parser.initWithSource ─────────────────────────────────────────────────────

test "parser: initWithSource stores the source" {
    var l = lexer_mod.Lexer.init("");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);

    const p = parser_mod.Parser.initWithSource(tokens, "const x = 1");
    try std.testing.expect(p.source != null);
    try std.testing.expectEqualStrings("const x = 1", p.source.?);
}

test "parser: init has null source" {
    var l = lexer_mod.Lexer.init("");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);

    const p = parser_mod.Parser.init(tokens);
    try std.testing.expect(p.source == null);
}

// ── reserved words recognized by lexer ───────────────────────────────────────

test "parser: reserved words are not Identifier tokens" {
    const reserved_words = [_][]const u8{ "auto", "delegate", "echo", "implement", "macro", "derive" };
    for (reserved_words) |word| {
        var l = lexer_mod.Lexer.init(word);
        const tokens = try l.scanAll(std.testing.allocator);
        defer l.deinit(std.testing.allocator);
        try std.testing.expect(tokens[0].kind != .Identifier);
        try std.testing.expect(lexer_mod.isReservedWord(tokens[0].kind));
    }
}

// ── lexicalErrorMessage ───────────────────────────────────────────────────────

test "lexer: lexicalErrorMessage for DigitOutOfRadix" {
    const msg = lexer_mod.lexicalErrorMessage(.{ .kind = .DigitOutOfRadix, .start = 4, .end = 5, .invalid_char = '8' });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "radix") != null or std.mem.indexOf(u8, msg, "Digit") != null,
    );
}

test "lexer: lexicalErrorMessage for RadixIntNoValue" {
    const msg = lexer_mod.lexicalErrorMessage(.{ .kind = .RadixIntNoValue, .start = 1, .end = 1 });
    try std.testing.expect(msg.len > 0);
}

test "lexer: lexicalErrorMessage for InvalidTripleEqual" {
    const msg = lexer_mod.lexicalErrorMessage(.{ .kind = .InvalidTripleEqual, .start = 0, .end = 3 });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "===") != null or std.mem.indexOf(u8, msg, "botopink") != null,
    );
}

test "lexer: lexicalErrorMessage for UnexpectedSemicolon" {
    const msg = lexer_mod.lexicalErrorMessage(.{ .kind = .UnexpectedSemicolon, .start = 7, .end = 8 });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "semicolon") != null or
            std.mem.indexOf(u8, msg, "Semicolon") != null or
            std.mem.indexOf(u8, msg, "Remove") != null,
    );
}

test "lexer: lexicalErrorMessage for BadStringEscape" {
    const msg = lexer_mod.lexicalErrorMessage(.{ .kind = .BadStringEscape, .start = 1, .end = 3, .invalid_char = 'g' });
    try std.testing.expect(msg.len > 0);
}

test "lexer: lexicalErrorMessage for InvalidUnicodeEscape ExpectedHexDigitOrCloseBrace" {
    const msg = lexer_mod.lexicalErrorMessage(.{
        .kind = .InvalidUnicodeEscape,
        .unicode_kind = .ExpectedHexDigitOrCloseBrace,
        .start = 1,
        .end = 5,
    });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "hex") != null or
            std.mem.indexOf(u8, msg, "Hex") != null or
            std.mem.indexOf(u8, msg, "Expected") != null,
    );
}

test "lexer: lexicalErrorMessage for InvalidUnicodeEscape InvalidCodepoint" {
    const msg = lexer_mod.lexicalErrorMessage(.{
        .kind = .InvalidUnicodeEscape,
        .unicode_kind = .InvalidCodepoint,
        .start = 1,
        .end = 11,
    });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "10FFFF") != null or
            std.mem.indexOf(u8, msg, "codepoint") != null or
            std.mem.indexOf(u8, msg, "Codepoint") != null,
    );
}
