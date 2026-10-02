//! .d.ts emitter: template fns (`@Expr<…>` / `@ExprCustom<…>`) are skipped.
//! The runtime contract is that template fns expand at their call site and
//! never reach codegen; the `.d.ts` surface mirrors that drop. This test
//! asserts no `Expr<` substring leaks into the typedef output.

const std = @import("std");
const codegen = @import("../../codegen.zig");
const Module = codegen.Module;
const helpers = @import("./helpers.zig");

/// Asserts the typedef of `src` carries no `Expr<`/`ExprCustom<`, contains every
/// `present` needle (so a typedef that dropped everything cannot pass) and none
/// of the `absent` ones (the template members themselves).
fn assertNoExprInDts(src: []const u8, present: []const []const u8, absent: []const []const u8) !void {
    const alloc = std.testing.allocator;
    const io = std.testing.io;
    var outputs = try codegen.generate(
        alloc,
        &.{.{ .path = "", .source = src }},
        io,
        helpers.configs[0],
    );
    defer {
        for (outputs.items) |*o| o.result.deinit(alloc);
        outputs.deinit(alloc);
    }
    try std.testing.expect(outputs.items.len >= 1);
    const dts = outputs.items[0].result.typedef orelse return error.MissingTypedef;
    if (std.mem.indexOf(u8, dts, "Expr<")) |off| {
        std.debug.print("\nUNEXPECTED `Expr<` in .d.ts at offset {d}:\n{s}\n", .{ off, dts });
        return error.TemplateLeakedIntoDts;
    }
    if (std.mem.indexOf(u8, dts, "ExprCustom<")) |off| {
        std.debug.print("\nUNEXPECTED `ExprCustom<` in .d.ts at offset {d}:\n{s}\n", .{ off, dts });
        return error.CustomTemplateLeakedIntoDts;
    }
    for (present) |needle| {
        if (std.mem.indexOf(u8, dts, needle) == null) {
            std.debug.print("\nmissing `{s}` in .d.ts:\n{s}\n", .{ needle, dts });
            return error.NeedleNotFound;
        }
    }
    for (absent) |needle| {
        if (std.mem.indexOf(u8, dts, needle) != null) {
            std.debug.print("\nunexpected `{s}` in .d.ts:\n{s}\n", .{ needle, dts });
            return error.UnexpectedNeedle;
        }
    }
}

test ".d.ts: free fn returning @Expr<T> is skipped" {
    try assertNoExprInDts(
        \\pub fn html(template: string) -> @Expr<string> {
        \\    return @expr("hello");
        \\}
        \\pub fn plain(x: i32) -> i32 { return x + 1; }
    , &.{"export declare function plain("}, &.{"function html("});
}

test ".d.ts: interface method returning @Expr<T> is skipped" {
    try assertNoExprInDts(
        \\pub behavior Tpl {
        \\    fn render(self: Self) -> @Expr<string>;
        \\    fn name(self: Self) -> string;
        \\}
    , &.{ "export declare interface Tpl {", "name(): string;" }, &.{"render("});
}

// Decision 8 §3's union `A | B` reaches the `.d.ts` as TypeScript's own union.
// It rides on `TypeRef.generic` under the reserved name `ast.union_type_name`
// (`"|"`), and the generic path wrote it out as `|<A, B>` — a declaration file
// that is not TypeScript, the defect step 6's T2 named for the primitive names.
// No snapshot: the typedef is the only output that moves, and a snapshot would
// carry this program's JavaScript through all four backends.
test ".d.ts: a union is `A | B`, not `|<A, B>` (step 6 T3)" {
    try helpers.assertDtsContains(
        std.testing.allocator,
        \\pub type A(x: i32)
        \\pub type B(y: string)
        \\pub fn pick(v: A | B) -> A | B { return v; }
        \\pub fn u(x: unknown) -> unknown { return x; }
        \\pub fn opt(x: ?i32) -> ?i32 { return x; }
    ,
        &.{
            "export declare function pick(v: A | B): A | B;",
            "export declare function u(x: unknown): unknown;",
            "export declare function opt(x: number | null): number | null;",
        },
        &.{"|<"},
    );
}

// A public signature naming a type the module keeps private: a `type` written
// without `pub`, and the prelude record `SourceLocation` the comptime pass
// splices into a module that names it (std's `testing/snapshots` —
// `pub fn path(loc: SourceLocation)`). The `.js` defines each class and
// exports none of them; the `.d.ts` named them and declared nothing, which
// `tsc --strict` refused (`Cannot find name 'SourceLocation'`). Each is
// declared without `export` — `Inner`, named only by the private `Outer`, too
// — and `export {};` keeps TypeScript from exporting them implicitly. The
// private `Unused`, which no public signature names, stays out.
test ".d.ts: a private type a public signature names is declared, not exported" {
    try helpers.assertDtsContains(
        std.testing.allocator,
        \\type Inner(n: i32)
        \\type Outer(inner: Inner)
        \\type Unused(z: i32)
        \\type Mode { Fast, Slow(by: i32) }
        \\pub fn wrap(n: i32, m: Mode) -> Outer { return Outer(inner: Inner(n: n)); }
        \\pub fn where(loc: SourceLocation) -> string { return loc.file; }
    ,
        &.{
            "export declare function wrap(n: number, m: Mode): Outer;",
            "export declare function where(loc: SourceLocation): string;",
            \\declare class SourceLocation {
            \\    readonly file: string;
            \\    readonly line: number;
            \\    readonly column: number;
            \\    readonly fnName: string;
            \\    constructor(file: string, line: number, column: number, fnName: string);
            \\}
            ,
            \\declare class Outer {
            \\    readonly inner: Inner;
            ,
            "declare class Inner {",
            \\declare class Mode {
            \\    readonly tag: "Fast" | "Slow";
            ,
            "\nexport {};\n",
        },
        &.{ "export declare class", "Unused" },
    );
}

// A module whose public signatures name only public types keeps its `.d.ts`
// as it was: no private declaration, no `export {};`.
test ".d.ts: no private type named, no `export {}`" {
    try helpers.assertDtsContains(
        std.testing.allocator,
        \\type Hidden(n: i32)
        \\pub type Shown(n: i32)
        \\pub fn make(n: i32) -> Shown { return Shown(n: n); }
    ,
        &.{ "export declare class Shown {", "export declare function make(n: number): Shown;" },
        &.{ "Hidden", "export {}" },
    );
}

// A private `behavior` a public signature names is declared the same way (a
// type alias needs nothing: the checker erases it, so the signature spells its
// target); the std prelude's `Array<T>` behavior, which the comptime pass
// prepends to a module calling into it, is not — `Array<…>` in a signature is
// TypeScript's own `Array`.
test ".d.ts: a private behavior is declared; the prelude's Array is not" {
    try helpers.assertDtsContains(
        std.testing.allocator,
        \\behavior Shape {
        \\    fn area(self: Self) -> f64;
        \\}
        \\type Name = string;
        \\pub fn names(xs: Array<Name>, s: Shape) -> Array<Name> { return xs.map(fn(x) { return x; }); }
    ,
        &.{
            "export declare function names(xs: Array<string>, s: Shape): Array<string>;",
            \\declare interface Shape {
            \\    area(): number;
            \\}
            ,
            "\nexport {};\n",
        },
        &.{ "interface Array", "Name" },
    );
}
