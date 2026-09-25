//! JavaScript / TypeScript abstract syntax — the code model `js_emitter.zig`
//! and `ts_emitter.zig` render.
//!
//! The JS backends (`codegen/commonJS.zig`, `codegen/typescript.zig`) build
//! these nodes and let the emitters produce the text, so the lexical rules of
//! the target — string escaping, reserved-word renaming, parenthesisation,
//! indentation, semicolons — live in exactly one place. The backend owns the
//! *lowering* decisions (what shape a botopink construct becomes); the emitter
//! owns *how that shape is spelled*.
//!
//! `Expr` and `Stmt` are separate types: a statement cannot be built where an
//! expression is required, and an expression cannot be built where a statement
//! is required. Layout is part of the model wherever the emitted bytes depend
//! on it (`Block.Layout`, `Array.Layout`, `Object.Layout`) — the same rule the
//! Erlang model follows for clause and case layout.
//!
//! ## Bridges
//!
//! One form exists only to keep a shape the current lowering still produces but
//! that the model would otherwise forbid. It is the complete list of ways a
//! JS backend can still emit something illegal, it has to be named explicitly
//! at the build site, and it is documented in `AGENTS.md`:
//!
//! * `Pattern.match`              — a match pattern used as a binding target.
//!
//! Nodes borrow their slices: build them in an arena that outlives rendering.

const std = @import("std");

// ── expressions ──────────────────────────────────────────────────────────────

pub const Expr = union(enum) {
    /// String literal built from a botopink string lexeme: the lexer has
    /// already validated every escape, so escape pairs pass through and only
    /// raw control bytes and unescaped quotes are escaped here.
    lexeme_string: []const u8,
    /// `"text"` — text that holds no escapes (a name, a tag, a module path).
    quoted: []const u8,
    /// A numeric literal token, written as the source spelled it.
    number: []const u8,
    null_,
    /// A botopink binding reference. The emitter applies the reserved-word
    /// rename (`delete` → `delete_`), so no build site has to remember to.
    ident: []const u8,
    /// A JS name that is already final: a class, a host symbol, a generated
    /// temporary (`_try0`). Written verbatim.
    name: []const u8,
    this,
    member: Member,
    index: Index,
    call: Call,
    /// `new Callee(args)`.
    new_: Call,
    binary: Binary,
    unary: Unary,
    /// `cond ? then : else`.
    ternary: Ternary,
    /// `target = value` / `target += value` in expression position.
    assign: Assign,
    /// `(inner)`.
    paren: *const Expr,
    arrow: Arrow,
    /// `function (params) { … }` — an anonymous function expression.
    function: FunctionExpr,
    array: Array,
    object: Object,
    /// Host JavaScript from an `#[@External.Node("…")]` annotation, with the
    /// call's arguments rendered into the template's holes. The text parts are
    /// the annotation's own bytes — the one place target text is not ours.
    host: []const HostPart,
    /// `await operand` — a real JS unary expression.
    await_: *const Expr,
    /// `yield` / `yield operand` — a real JS expression inside a generator.
    yield_: ?*const Expr,
    /// A comment in expression position: it is the whole expression.
    comment: Comment,

    pub fn id(n: []const u8) Expr {
        return .{ .ident = n };
    }
    pub fn nm(n: []const u8) Expr {
        return .{ .name = n };
    }
    pub fn num(text: []const u8) Expr {
        return .{ .number = text };
    }
    pub fn str(text: []const u8) Expr {
        return .{ .quoted = text };
    }
};

/// `obj.name` / `obj?.name`. The property is written verbatim: a property
/// position accepts reserved words, so it is never renamed.
pub const Member = struct {
    object: *const Expr,
    name: []const u8,
    optional: bool = false,
};

/// `obj[index]` / `obj?.[index]`.
pub const Index = struct {
    object: *const Expr,
    index: *const Expr,
    optional: bool = false,
};

pub const Call = struct {
    callee: *const Expr,
    args: []const Expr = &.{},
};

/// `(lhs op rhs)`. The parentheses are unconditional by default — that is the
/// backend's existing shape and it makes precedence a non-question.
pub const Binary = struct {
    op: []const u8,
    lhs: *const Expr,
    rhs: *const Expr,
    parens: bool = true,
};

pub const Unary = struct {
    op: []const u8,
    operand: *const Expr,
    parens: bool = true,
};

pub const Ternary = struct {
    cond: *const Expr,
    then: *const Expr,
    else_: *const Expr,
};

pub const Assign = struct {
    target: *const Expr,
    /// `=` or `+=`.
    op: []const u8 = "=",
    value: *const Expr,
};

pub const Arrow = struct {
    params: []const Param = &.{},
    body: Body,

    pub const Body = union(enum) {
        /// `(p) => expr`.
        expr: *const Expr,
        /// `(p) => { … }`.
        block: Block,
    };
};

pub const FunctionExpr = struct {
    /// `function`, `async function`, `function*` or `async function*` — the
    /// annotated `loop`'s generator IIFE is a `function*` expression.
    keyword: []const u8 = "function",
    params: []const Param = &.{},
    body: Block,
};

/// One part of a host template: literal annotation text, or an argument the
/// backend rendered into a hole.
pub const HostPart = union(enum) {
    text: []const u8,
    expr: Expr,
};

// ── aggregates ───────────────────────────────────────────────────────────────

pub const Array = struct {
    elems: []const Expr = &.{},
    spread: ?Spread = null,
    layout: Layout = .inline_,

    pub const Layout = enum {
        /// `[a, b]`.
        inline_,
        /// `[` newline, one element per line at +1 with a trailing `,`,
        /// newline, `]`.
        lines,
    };
};

/// Trailing `...` of an array literal.
pub const Spread = union(enum) {
    /// `...name` — the name is already final.
    name: []const u8,
    /// `...expr`.
    expr: *const Expr,
};

pub const Object = struct {
    props: []const Prop = &.{},
    layout: Layout = .spaced,

    pub const Layout = enum {
        /// `{ a: 1 }`, and `{}` when empty.
        spaced,
        /// `{a: 1}`.
        tight,
        /// `{` newline, one property per line at +1 with a trailing `,`,
        /// newline, `}`.
        lines,
    };

    pub const Prop = union(enum) {
        /// `key: value` — the key is written verbatim.
        kv: struct { key: []const u8, value: Expr },
        /// `key` — shorthand; the key is both property and binding, so the
        /// emitter renames a reserved word into `key: key_`.
        shorthand: []const u8,
        /// `name(params) { … }` — a method shorthand.
        method: struct { name: []const u8, params: []const Param, body: Block },
    };
};

// ── patterns ─────────────────────────────────────────────────────────────────

/// A binding target: what `const`/`let` and a parameter accept.
pub const Pattern = union(enum) {
    /// A botopink name; the emitter applies the reserved-word rename.
    ident: []const u8,
    /// A name that is already final (`_`, a generated temporary). Verbatim.
    name: []const u8,
    object: ObjectPattern,
    array: ArrayPattern,
    /// BRIDGE — a botopink match pattern (a variant, a literal, an
    /// alternation) used as a binding target. JavaScript has no such form, so
    /// this renders botopink's own spelling. See `AGENTS.md` (defect JS-4).
    match: MatchPattern,
};

/// A rest element. It is a field of the pattern, never an element of the
/// element list, which is what makes "a rest element only at the end" a
/// property of the model rather than a rule a build site has to remember.
pub const Rest = union(enum) {
    /// `...name`.
    binding: []const u8,
};

pub const ObjectPattern = struct {
    props: []const Prop = &.{},
    rest: ?Rest = null,

    pub const Prop = struct {
        /// Property name, written verbatim.
        key: []const u8,
        /// The binding it introduces, already final. Null means the binding is
        /// `key` itself — the emitter then writes the shorthand `{ key }`, or
        /// `{ key: key_ }` when `key` is a reserved word and the shorthand
        /// would be a SyntaxError.
        bind: ?[]const u8 = null,
    };
};

pub const ArrayPattern = struct {
    elems: []const Pattern = &.{},
    rest: ?Rest = null,
    /// `[ a, b ]` instead of `[a, b]`.
    spaced: bool = false,
};

/// botopink's match-pattern spelling, reachable only through `Pattern.match`.
pub const MatchPattern = union(enum) {
    /// `Name binding`.
    variant_binding: struct { name: []const u8, binding: []const u8 },
    /// `Name(a, b)` — field binds.
    variant_fields: struct { name: []const u8, fields: []const []const u8 },
    /// `Name(p, q)` — nested patterns.
    variant_patterns: struct { name: []const u8, args: []const Pattern },
    number: []const u8,
    string: []const u8,
    /// `a | b`.
    alt: []const Pattern,
    /// `a, b`.
    multi: []const Pattern,
};

/// A parameter: a binding target plus an optional default.
pub const Param = struct {
    pattern: Pattern,
    /// `= <default>`.
    default: ?Expr = null,

    pub fn id(name: []const u8) Param {
        return .{ .pattern = .{ .ident = name } };
    }
};

// ── statements ───────────────────────────────────────────────────────────────

pub const Stmt = union(enum) {
    /// `<expr>;`
    expr: Expr,
    /// `const`/`let` declaration.
    decl: Decl,
    /// `return;` / `return <expr>;`
    return_: ?Expr,
    /// `throw <expr>;` — the operand is required: `throw;` is a JS
    /// SyntaxError, and botopink rejects a bare `throw` at parse time.
    throw_: Expr,
    /// `continue;`
    continue_,
    /// `continue <label>;` — the only way to continue an OUTER loop, which is
    /// what a self tail call rewritten as a loop needs when it sits inside a
    /// loop of its own (`commonJS.zig` § self tail calls).
    continue_label: []const u8,
    /// `break;`
    break_,
    /// `yield* <expr>; return;` — delegating the rest of an iteration.
    yield_delegate: Expr,
    if_: If,
    for_of: ForOf,
    /// `while (cond) { … }`
    while_: While,
    block: Block,
    /// `function name(params) { … }`
    function: FunctionDecl,
    /// `class Name { … }`
    class: Class,
    comment: Comment,
    /// Statements written one per line at the same indentation — one botopink
    /// construct that lowers to several JS statements.
    group: []const Stmt,
};

pub const Decl = struct {
    kw: Kw = .const_,
    pattern: Pattern,
    value: Expr,

    pub const Kw = enum {
        const_,
        let_,

        pub fn text(self: Kw) []const u8 {
            return switch (self) {
                .const_ => "const",
                .let_ => "let",
            };
        }
    };
};

pub const If = struct {
    cond: Expr,
    then: *const Stmt,
    else_: ?*const Stmt = null,
};

pub const While = struct {
    cond: Expr,
    body: Block,
    /// `<label>: while (…) { … }`. Written verbatim; null for an unlabelled
    /// loop, which is every loop but the self-tail-call one.
    label: ?[]const u8 = null,
};

pub const ForOf = struct {
    /// The loop variable's binding form.
    pattern: Pattern,
    iter: Expr,
    body: Block,
    /// `for await (const x of gen)` — `for await (gen) { x -> … }`.
    is_await: bool = false,
};

/// A braced statement list. The layout is part of the model because the JS
/// backend emits the same construct three ways.
pub const Block = struct {
    stmts: []const Stmt = &.{},
    layout: Layout = .indented,
    /// `.indented`: the level the closing brace sits at; statements go one
    /// level deeper. `.fixed`: the ambient level a multi-line statement's
    /// continuation lines use — it is *not* the level the statements are
    /// written at (see `.fixed`).
    indent: usize = 0,

    pub const Layout = enum {
        /// `{` newline, statements at `indent + 1`, newline, `}` at `indent`.
        /// The nesting-correct form: function, method and class bodies.
        indented,
        /// `{` newline, statements at exactly one level, newline, `}` at
        /// column 0 — regardless of nesting. The legacy shape of arrow and
        /// `for…of` bodies; `indent` still carries the ambient level so a
        /// statement that spans lines keeps indenting its continuations the
        /// way it did before.
        fixed,
        /// `{ a; b; }` — one line, each statement preceded by a space.
        spaced,
        /// `{a; b;}` — one line, statements separated by a space.
        tight,
    };
};

pub const FunctionDecl = struct {
    /// `function`, `async function`, `function*` or `async function*`.
    keyword: []const u8 = "function",
    /// A botopink name; the emitter applies the reserved-word rename.
    name: []const u8,
    params: []const Param = &.{},
    body: Block,
};

pub const Class = struct {
    name: []const u8,
    /// The base class this one extends, when it has one — an enum's variant
    /// subclass extends the enum's own class, which is what makes
    /// `x instanceof Shape` the run-time identity of every `Shape` value
    /// (1.0.5-beta decision 5).
    extends: ?[]const u8 = null,
    ctor: ?Ctor = null,
    members: []const ClassMember = &.{},

    pub const Ctor = struct {
        params: []const Param = &.{},
        body: Block,
    };

    pub const ClassMember = struct {
        kind: Kind = .method,
        name: []const u8,
        params: []const Param = &.{},
        body: Block,
        /// `async name(…) { … }` — the method's body may `await`. A method
        /// carries the flag rather than a keyword string because JS spells a
        /// method's modifiers in a fixed order and without the `function`
        /// word: `static async *name()`.
        is_async: bool = false,
        /// `*name(…) { … }` — the method's body may `yield`.
        is_generator: bool = false,

        pub const Kind = enum { method, static_method, getter, setter };
    };
};

/// `// text`, `/** text */` or `//// text`.
pub const Comment = struct {
    style: Style = .line,
    text: []const u8,

    pub const Style = enum { line, doc, module };

    pub fn line(text: []const u8) Comment {
        return .{ .text = text };
    }
};

// ── module ───────────────────────────────────────────────────────────────────

/// One top-level entry of an emitted module. Generated declarations are
/// separated by a blank line; runtime-support source is written as given.
pub const Item = union(enum) {
    stmt: Stmt,
    /// Fixed runtime-support source (the test harness), not generated from
    /// user code. Written verbatim, including its own newlines, outside the
    /// blank-line separation of the generated declarations.
    runtime: []const u8,
};

// ── typescript ───────────────────────────────────────────────────────────────

/// The `.d.ts` declaration subset. A type is a node, never a bare string: a
/// parameter carries a `TsType`, so it cannot be an empty string that renders
/// as `x: `.
pub const TsType = union(enum) {
    /// A type name, written verbatim (`string`, `i32`, `Person`).
    name: []const u8,
    /// A string-literal type (`"Ok"`) — the discriminant of a tagged union.
    literal: []const u8,
    /// `Name<A, B>`.
    generic: struct { name: []const u8, args: []const TsType },
    /// `inner[]`.
    array: *const TsType,
    /// `[A, B]`.
    tuple: []const TsType,
    /// `A | B`.
    union_: []const TsType,
    /// `(p0: A, p1: B) => R`.
    func: struct { params: []const TsParam, ret: *const TsType },
    /// `{ a: A; b: B }` / `{ a: A, b: B }` — the separator differs between the
    /// inferred-type and the type-reference spellings.
    object: struct { fields: []const TsField, sep: []const u8 = ", " },
};

pub const TsField = struct {
    name: []const u8,
    type: TsType,
};

pub const TsParam = struct {
    /// Null in a function *type*, where TypeScript writes the type alone
    /// (`(string, i32) => void`).
    name: ?[]const u8 = null,
    type: TsType,
};

/// A `.d.ts` member of a class or interface.
pub const TsMember = union(enum) {
    /// `<modifier> name: T;`
    field: struct { modifier: []const u8 = "", name: []const u8, type: TsType },
    /// `<modifier>name(params): R;`
    method: struct { modifier: []const u8 = "", name: []const u8, params: []const TsParam, ret: TsType },
    /// `get name: T;`
    getter: struct { name: []const u8, type: TsType },
    /// `set name(p: T);`
    setter: struct { name: []const u8, params: []const TsParam },
    /// `constructor(params);`
    ctor: struct { params: []const TsParam },
    /// `name = "name",` — an enum member.
    enum_member: struct { name: []const u8, value: []const u8 },
};

/// One `.d.ts` declaration.
pub const TsDecl = union(enum) {
    /// `export declare const name: T;`
    const_: struct { name: []const u8, type: TsType },
    /// `export declare function name(params): R;`
    func: struct { name: []const u8, params: []const TsParam, ret: TsType },
    /// `export declare class Name { … }`
    class: struct { name: []const u8, members: []const TsMember },
    /// `export declare interface Name extends A, B { … }`
    interface: struct { name: []const u8, extends: []const []const u8, members: []const TsMember },
    /// `export declare enum Name { … }`
    enum_: struct { name: []const u8, members: []const TsMember },
    /// `export declare type Name = T;`
    type_alias: struct { name: []const u8, type: TsType },
    /// `import { a, b } from "src";`
    import: struct { names: []const []const u8, source: []const u8 },
    /// Several declarations with no blank line between them.
    group: []const TsDecl,
    /// Nothing at all — a binding with no `.d.ts` surface.
    none,
};

// ── builder ──────────────────────────────────────────────────────────────────

/// Arena-backed construction helpers: copy slices and allocate child nodes so
/// a tree built from runtime values outlives the builder's caller frames.
pub const Builder = struct {
    arena: std.mem.Allocator,

    pub const Error = std.mem.Allocator.Error;

    pub fn ptr(b: Builder, e: Expr) Error!*const Expr {
        const p = try b.arena.create(Expr);
        p.* = e;
        return p;
    }

    pub fn stmtPtr(b: Builder, s: Stmt) Error!*const Stmt {
        const p = try b.arena.create(Stmt);
        p.* = s;
        return p;
    }

    pub fn typePtr(b: Builder, t: TsType) Error!*const TsType {
        const p = try b.arena.create(TsType);
        p.* = t;
        return p;
    }

    pub fn exprs(b: Builder, items: []const Expr) Error![]const Expr {
        return b.arena.dupe(Expr, items);
    }

    pub fn stmts(b: Builder, items: []const Stmt) Error![]const Stmt {
        return b.arena.dupe(Stmt, items);
    }

    pub fn params(b: Builder, items: []const Param) Error![]const Param {
        return b.arena.dupe(Param, items);
    }

    pub fn props(b: Builder, items: []const Object.Prop) Error![]const Object.Prop {
        return b.arena.dupe(Object.Prop, items);
    }

    pub fn patterns(b: Builder, items: []const Pattern) Error![]const Pattern {
        return b.arena.dupe(Pattern, items);
    }

    pub fn types(b: Builder, items: []const TsType) Error![]const TsType {
        return b.arena.dupe(TsType, items);
    }

    pub fn tsParams(b: Builder, items: []const TsParam) Error![]const TsParam {
        return b.arena.dupe(TsParam, items);
    }

    /// `callee(args)`.
    pub fn call(b: Builder, callee: Expr, args: []const Expr) Error!Expr {
        return .{ .call = .{ .callee = try b.ptr(callee), .args = try b.exprs(args) } };
    }

    /// `new Callee(args)`.
    pub fn new_(b: Builder, callee: Expr, args: []const Expr) Error!Expr {
        return .{ .new_ = .{ .callee = try b.ptr(callee), .args = try b.exprs(args) } };
    }

    /// `obj.name`.
    pub fn member(b: Builder, obj: Expr, name: []const u8) Error!Expr {
        return .{ .member = .{ .object = try b.ptr(obj), .name = name } };
    }

    /// `obj?.name` when `optional`, `obj.name` otherwise.
    pub fn memberOpt(b: Builder, obj: Expr, name: []const u8, optional: bool) Error!Expr {
        return .{ .member = .{ .object = try b.ptr(obj), .name = name, .optional = optional } };
    }

    /// `obj[index]`.
    pub fn index(b: Builder, obj: Expr, idx: Expr, optional: bool) Error!Expr {
        return .{ .index = .{ .object = try b.ptr(obj), .index = try b.ptr(idx), .optional = optional } };
    }

    /// `(lhs op rhs)`.
    pub fn binary(b: Builder, op: []const u8, lhs: Expr, rhs: Expr) Error!Expr {
        return .{ .binary = .{ .op = op, .lhs = try b.ptr(lhs), .rhs = try b.ptr(rhs) } };
    }

    /// `lhs op rhs` with no parentheses of its own.
    pub fn binaryBare(b: Builder, op: []const u8, lhs: Expr, rhs: Expr) Error!Expr {
        return .{ .binary = .{ .op = op, .lhs = try b.ptr(lhs), .rhs = try b.ptr(rhs), .parens = false } };
    }

    pub fn unary(b: Builder, op: []const u8, operand: Expr, parens: bool) Error!Expr {
        return .{ .unary = .{ .op = op, .operand = try b.ptr(operand), .parens = parens } };
    }

    pub fn ternary(b: Builder, cond: Expr, then: Expr, else_: Expr) Error!Expr {
        return .{ .ternary = .{ .cond = try b.ptr(cond), .then = try b.ptr(then), .else_ = try b.ptr(else_) } };
    }

    pub fn assign(b: Builder, target: Expr, op: []const u8, value: Expr) Error!Expr {
        return .{ .assign = .{ .target = try b.ptr(target), .op = op, .value = try b.ptr(value) } };
    }

    pub fn paren(b: Builder, inner: Expr) Error!Expr {
        return .{ .paren = try b.ptr(inner) };
    }

    /// `(params) => expr`.
    pub fn arrowExpr(b: Builder, ps: []const Param, body: Expr) Error!Expr {
        return .{ .arrow = .{ .params = try b.params(ps), .body = .{ .expr = try b.ptr(body) } } };
    }

    /// `(params) => { … }`.
    pub fn arrowBlock(b: Builder, ps: []const Param, body: Block) Error!Expr {
        return .{ .arrow = .{ .params = try b.params(ps), .body = .{ .block = body } } };
    }

    pub fn array(b: Builder, elems: []const Expr) Error!Expr {
        return .{ .array = .{ .elems = try b.exprs(elems) } };
    }

    pub fn object(b: Builder, ps: []const Object.Prop) Error!Expr {
        return .{ .object = .{ .props = try b.props(ps) } };
    }

    pub fn objectLayout(b: Builder, ps: []const Object.Prop, layout: Object.Layout) Error!Expr {
        return .{ .object = .{ .props = try b.props(ps), .layout = layout } };
    }

    /// `{ stmts }` on one line, each statement preceded by a space — the body
    /// of a single-line IIFE.
    pub fn spacedBlock(b: Builder, items: []const Stmt) Error!Block {
        return .{ .stmts = try b.stmts(items), .layout = .spaced };
    }

    /// `(() => { … })()` on one line.
    pub fn iife(b: Builder, items: []const Stmt) Error!Expr {
        const arrow = try b.arrowBlock(&.{}, try b.spacedBlock(items));
        return b.call(try b.paren(arrow), &.{});
    }

    pub fn ifStmt(b: Builder, cond: Expr, then: Stmt) Error!Stmt {
        return .{ .if_ = .{ .cond = cond, .then = try b.stmtPtr(then) } };
    }

    pub fn ifElse(b: Builder, cond: Expr, then: Stmt, else_: Stmt) Error!Stmt {
        return .{ .if_ = .{ .cond = cond, .then = try b.stmtPtr(then), .else_ = try b.stmtPtr(else_) } };
    }

    pub fn group(b: Builder, items: []const Stmt) Error!Stmt {
        return .{ .group = try b.stmts(items) };
    }

    pub fn await_(b: Builder, e: Expr) Error!Expr {
        return .{ .await_ = try b.ptr(e) };
    }

    pub fn yield_(b: Builder, e: ?Expr) Error!Expr {
        return .{ .yield_ = if (e) |v| try b.ptr(v) else null };
    }
};
