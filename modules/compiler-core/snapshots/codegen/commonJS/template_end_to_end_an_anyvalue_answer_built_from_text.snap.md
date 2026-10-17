----- SOURCE CODE -- std/compiler.bp
```botopink
//// The compiler a body that runs at build talks to (decisions 575 (3), 576,
//// 579).
////
//// `compiler`, this module's default, is a value, not a keyword: importing
//// the module binds it — `import {compiler} from "std";` outside std,
//// `import {compiler};` in a std module, an alias (`import {compiler as c}
//// from "std";`) included. In a body that runs at build — a decorator, a
//// template, a function called at build, a `comptime { … }` block — it is the
//// `Compiler` of that point: the annotated declaration in a decorator, the
//// call site elsewhere. It is a `Build` resource (decision 376 (1)); a body
//// that runs only when the program runs is refused there
//// (`compiler-at-run-time`), and it is read only through its members — never
//// passed nor stored (`compiler-escapes`). A file that does not import it
//// has no `compiler`: the name is an ordinary one there.
////
//// `Compiler` has one implementor, the compiler itself: a unit test holds the
//// compiler's table of members (`parser/compiler_surface.zig` `members`) to
//// the behavior below, member for member.
////
//// - The point: `src`, `module`, `package`, `isStd`.
//// - The outputs, a decorator's only (`compiler-output-outside-decorator`):
////   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `compile`,
////   `implement`.
//// - The reads of an `expr` (decision 576 (2)): `text`, `name`, `source`,
////   `context`, `lookup`, `bindings`, `fail`.
//// - A template's call site: `build`, `buildType`, `note`, `tagDecl`,
////   `annotate`, `custom` (decision 578 (3)).
//// - A declaration handle's reads (decision 576 (3)): `name`, `kind`,
////   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,
////   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.
//// - The program: `catalogue`, `typeInfo`.
////
//// `setBuiltin`, `embed`, `fields` over a type,
//// `optional` and `required` join it with the steps that build them.

pub behavior Compiler {
    // ── The point ─────────────────────────────────────────────────────────
    // Where the point is: the annotated declaration in a decorator, the call
    // site elsewhere.
    val src: SourceLocation;
    // The module and the package the point is written in; whether it is std.
    val module: string;
    val package: string;
    val isStd: bool;

    // ── Reporting ─────────────────────────────────────────────────────────
    // An error at the argument or the declaration `at` holds (at `span`
    // inside it when given), else at `src`; the body goes on.
    fn fail(self: Self, message: string, at: unknown, span: ?Span);
    // A note at the template's call site (decision 426 (4)).
    fn note(self: Self, message: string);

    // ── The outputs (a decorator's only) ──────────────────────────────────
    // A typed meta value, one per type per declaration (decision 298).
    fn setMeta<M>(self: Self, value: M);
    // A typed meta value that repeats (decision 298).
    fn addMeta<M>(self: Self, value: M);
    // A member of the annotated type, a function written at the call
    // (decision 370 (2)).
    fn addMember<F>(self: Self, name: string, member: F);
    // An associated type of the annotated type (decision 216 (3)).
    fn addType(self: Self, name: string, source: string);
    // A wrapper of the annotated function, a lambda written at the call
    // (decision 316).
    fn wrapWith<F>(self: Self, wrapper: F);
    // Run-time code compiled beside the annotated declaration, run once
    // before `main` in the program's init list: modules in dependency order,
    // declarations in source order, calls in order (decision 575 (3)).
    fn compile(self: Self, executor: fn());
    // A host source of the annotated `declare fn` (decision 575 (6)): one per
    // target (`implementation-twice`), never on a declaration with a body
    // (`implement-with-body`).
    fn implement(self: Self, source: Implementation);

    // ── The reads of an `expr` (decision 576 (2)) ─────────────────────────
    // The expression as written.
    fn text(self: Self, e: unknown) -> string;
    // The name the expression is written as, or the declaration's name;
    // `null` for a lambda or `a + b`.
    fn name(self: Self, e: unknown) -> ?string;
    // A template text's source and the context it stands in.
    fn source(self: Self, e: unknown) -> Source;
    fn context(self: Self, e: unknown) -> ExprContext;
    // A name resolved where the call stands, and every name in scope there.
    fn lookup(self: Self, e: unknown, name: string) -> unknown;
    fn bindings(self: Self, e: unknown) -> unknown[];

    // ── A template's call site ────────────────────────────────────────────
    // Code built from source text, typed at the call (decisions 426 (1),
    // 578 (3)).
    fn build(self: Self, source: string) -> anyvalue;
    // A type built from source text — the one way a type is built
    // (decision 578 (3)).
    fn buildType(self: Self, source: string) -> anytype;
    // A tag's declaration handle (decision 302), and a handle's annotation.
    fn tagDecl(self: Self, kind: DeclKind, name: string, attrs: unknown) -> unknown;
    fn annotate(self: Self, d: unknown, at: Span) -> unknown;
    // The reference tree the language server reads, by call location.
    fn custom(self: Self, ast: CustomNode);

    // ── A declaration handle's reads (decision 576 (3)) ───────────────────
    fn kind(self: Self, d: unknown) -> DeclKind;
    fn moduleOf(self: Self, d: unknown) -> string;
    fn meta<M>(self: Self, d: unknown) -> ?M;
    fn metaAll<M>(self: Self, d: unknown) -> M[];
    fn attr(self: Self, d: unknown, name: string) -> ?string;
    fn component(self: Self, d: unknown) -> unknown;
    fn hooks(self: Self, d: unknown) -> HookNode[];
    fn fields(self: Self, d: unknown) -> Field[];
    fn methods(self: Self, d: unknown) -> Method[];
    fn params(self: Self, d: unknown) -> Param[];
    fn returnType(self: Self, d: unknown) -> string;
    fn owner(self: Self, d: unknown) -> unknown;
    fn annotations(self: Self, d: unknown) -> DeclAnnotation[];
    fn variants(self: Self, d: unknown) -> string[];

    // ── The program ───────────────────────────────────────────────────────
    // The declarations a decorator marks (decision 253), read at build.
    fn catalogue(self: Self, with: unknown, member: unknown) -> unknown[];
    // A type's reflection (decision 253).
    fn typeInfo<T>(self: Self, comptime t: type<T>) -> TypeInfo<T>;
}

// The value the module's import binds (decision 579): its value is given by
// the compiler at each point, so it has no body.
#[builtin]
pub default declare val compiler: Compiler;

// ── The types `compiler` answers (decision 576 (13)) ──────────────────────
// No prelude name: a file naming one imports it, `import {compiler.Span} from
// "std";`. Each is the compiler's own type, written here under its name.
pub type Span = __Span;

pub type Source = __Source;

pub type ExprContext = __ExprContext;

pub type CustomNode = __CustomNode;

pub type DeclKind = __DeclKind;

pub type DeclAnnotation = __Decl__Annotation;

pub type Param = __Decl__Param;

pub type Field = __Decl__Field;

pub type Method = __Decl__Method;

pub type HookNode = __HookNode;

```

----- JAVASCRIPT -- std/compiler.js
```javascript
//// The compiler a body that runs at build talks to (decisions 575 (3), 576,

//// 579).

//// 

//// `compiler`, this module's default, is a value, not a keyword: importing

//// the module binds it — `import {compiler} from "std";` outside std,

//// `import {compiler};` in a std module, an alias (`import {compiler as c}

//// from "std";`) included. In a body that runs at build — a decorator, a

//// template, a function called at build, a `comptime { … }` block — it is the

//// `Compiler` of that point: the annotated declaration in a decorator, the

//// call site elsewhere. It is a `Build` resource (decision 376 (1)); a body

//// that runs only when the program runs is refused there

//// (`compiler-at-run-time`), and it is read only through its members — never

//// passed nor stored (`compiler-escapes`). A file that does not import it

//// has no `compiler`: the name is an ordinary one there.

//// 

//// `Compiler` has one implementor, the compiler itself: a unit test holds the

//// compiler's table of members (`parser/compiler_surface.zig` `members`) to

//// the behavior below, member for member.

//// 

//// - The point: `src`, `module`, `package`, `isStd`.

//// - The outputs, a decorator's only (`compiler-output-outside-decorator`):

////   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `compile`,

////   `implement`.

//// - The reads of an `expr` (decision 576 (2)): `text`, `name`, `source`,

////   `context`, `lookup`, `bindings`, `fail`.

//// - A template's call site: `build`, `buildType`, `note`, `tagDecl`,

////   `annotate`, `custom` (decision 578 (3)).

//// - A declaration handle's reads (decision 576 (3)): `name`, `kind`,

////   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,

////   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.

//// - The program: `catalogue`, `typeInfo`.

//// 

//// `setBuiltin`, `embed`, `fields` over a type,

//// `optional` and `required` join it with the steps that build them.

// behavior Compiler
//   src: SourceLocation
//   module: string
//   package: string
//   isStd: bool
//   fn fail(...)
//   fn note(...)
//   fn setMeta(...)
//   fn addMeta(...)
//   fn addMember(...)
//   fn addType(...)
//   fn wrapWith(...)
//   fn compile(...)
//   fn implement(...)
//   fn text(...)
//   fn name(...)
//   fn source(...)
//   fn context(...)
//   fn lookup(...)
//   fn bindings(...)
//   fn build(...)
//   fn buildType(...)
//   fn tagDecl(...)
//   fn annotate(...)
//   fn custom(...)
//   fn kind(...)
//   fn moduleOf(...)
//   fn meta(...)
//   fn metaAll(...)
//   fn attr(...)
//   fn component(...)
//   fn hooks(...)
//   fn fields(...)
//   fn methods(...)
//   fn params(...)
//   fn returnType(...)
//   fn owner(...)
//   fn annotations(...)
//   fn variants(...)
//   fn catalogue(...)
//   fn typeInfo(...)

// The value the module's import binds (decision 579): its value is given by

// the compiler at each point, so it has no body.

// ── The types `compiler` answers (decision 576 (13)) ──────────────────────

// No prelude name: a file naming one imports it, `import {compiler.Span} from

// "std";`. Each is the compiler's own type, written here under its name.
```

----- TYPESCRIPT TYPEDEF -- std/compiler.d.ts
```typescript
export declare interface Compiler {
    src: SourceLocation;
    module: string;
    package: string;
    isStd: boolean;
    fail(message: string, at: unknown, span: __Span | null): void;
    note(message: string): void;
    setMeta<M>(value: M): void;
    addMeta<M>(value: M): void;
    addMember<F>(name: string, member: F): void;
    addType(name: string, source: string): void;
    wrapWith<F>(wrapper: F): void;
    compile(executor: () => void): void;
    implement(source: Implementation): void;
    text(e: unknown): string;
    name(e: unknown): string | null;
    source(e: unknown): __Source;
    context(e: unknown): __ExprContext;
    lookup(e: unknown, name: string): unknown;
    bindings(e: unknown): unknown[];
    build(source: string): anyvalue;
    buildType(source: string): any;
    tagDecl(kind: __DeclKind, name: string, attrs: unknown): unknown;
    annotate(d: unknown, at: __Span): unknown;
    custom(ast: __CustomNode): void;
    kind(d: unknown): __DeclKind;
    moduleOf(d: unknown): string;
    meta<M>(d: unknown): M | null;
    metaAll<M>(d: unknown): M[];
    attr(d: unknown, name: string): string | null;
    component(d: unknown): unknown;
    hooks(d: unknown): __HookNode[];
    fields(d: unknown): __Decl__Field[];
    methods(d: unknown): __Decl__Method[];
    params(d: unknown): __Decl__Param[];
    returnType(d: unknown): string;
    owner(d: unknown): unknown;
    annotations(d: unknown): __Decl__Annotation[];
    variants(d: unknown): string[];
    catalogue(with_: unknown, member: unknown): unknown[];
    typeInfo<T>(t: any): TypeInfo<T>;
}


export declare type Span = __Span;


export declare type Source = __Source;


export declare type ExprContext = __ExprContext;


export declare type CustomNode = __CustomNode;


export declare type DeclKind = __DeclKind;


export declare type DeclAnnotation = __Decl__Annotation;


export declare type Param = __Decl__Param;


export declare type Field = __Decl__Field;


export declare type Method = __Decl__Method;


export declare type HookNode = __HookNode;


declare class __Decl__Annotation {
    readonly name: string;
    readonly args: string[];
    readonly decorator: Decorator;
    constructor(name: string, args: string[], decorator: Decorator);
}


declare class __Decl__Param {
    readonly name: string;
    readonly typeName: string;
    constructor(name: string, typeName: string);
}


declare class __Decl__Field {
    readonly name: string;
    readonly typeName: string;
    readonly annotations: __Decl__Annotation[];
    constructor(name: string, typeName: string, annotations: __Decl__Annotation[]);
}


declare class __Decl__Method {
    readonly name: string;
    readonly params: __Decl__Param[];
    readonly returnType: string;
    readonly annotations: __Decl__Annotation[];
    constructor(name: string, params: __Decl__Param[], returnType: string, annotations: __Decl__Annotation[]);
}


declare class SourceLocation {
    readonly file: string;
    readonly line: number;
    readonly column: number;
    readonly fnName: string;
    constructor(file: string, line: number, column: number, fnName: string);
}


declare interface Decorator {
    same(other: Decorator): boolean;
}


export {};

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
pub fn port(expr q: string) -> anyvalue {
    return compiler.build("8080");
}
fn main() {
    val p = port @`x` + 1;
    @print(p);
}
import {compiler} from "std";
```

----- COMPTIME WAT -- template port
```wat
(func $port/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $t2 i32) (local $V___BpF0 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $L4
  br $L3
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $t2
  call $rt_clear
  (block $L5 (result i32)
  (block $L6
  local.get $s0
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $t2
  local.set $V___BpF0
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 2
  call $rt_int
  i64.const 21
  call $rt_int
  local.get $V___BpF0
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF0
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L5
  )
  local.get $s0
  local.get $t2
  call $rt_raise
  drop
  br $raise
  )
  br $L3
  )
  br $L1
  )
  call $rt_function_clause
  drop
  br $raise
  )
  return
  )
  i32.const 0
)

;; main/1 argument — an external term, not part of the module:
;; Arg0 = #{
;;     '__bp_capture' => <<"q">>,
;;     text => <<"x">>,
;;     source => #{file => <<"">>, line => 5, col => 18},
;;     context => #{
;;         source => #{file => <<"">>, line => 5, col => 18},
;;         text => <<"x">>,
;;         multiline => false
;;     },
;;     bindings => [],
;;     words => [<<"x">>]
;; }
```

----- COMPTIME REPLY -- template port
```json
{
  "kind": "code",
  "source": "8080"
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_f64(v) {
    if (Number.isNaN(v)) { return "NaN"; }
    if (!Number.isFinite(v)) { return (v < 0) ? "-Infinity" : "Infinity"; }
    if (v === 0) { return Object.is(v, -0) ? "-0.0" : "0.0"; }
    const t = Math.abs(v).toExponential();
    const i = t.indexOf("e");
    const d = t.slice(0, i).replace(".", "");
    const e = Number(t.slice(i + 1));
    const g = (v < 0) ? "-" : "";
    const x = g + d[0] + "." + ((d.length > 1) ? d.slice(1) : "0") + "e" + e;
    const p = e + 1;
    const f = g + ((p <= 0) ? "0." + "0".repeat(-p) + d : (p >= d.length) ? d + "0".repeat(p - d.length) + ".0" : d.slice(0, p) + "." + d.slice(p));
    return ((f.length <= x.length) && (Math.abs(v) < 9007199254740992)) ? f : x;
}

function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "bigint")) {
        a.push(String(v));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(__bp_f64(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if ((((typeof v === "object") && (v != null)) && (typeof v.__bp !== "string"))) {
        const k = Object.keys(v);
        if (((k.length === 1) && ((k[0] === "ok") || (k[0] === "error")))) {
            return ((((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a)) + ")");
        }
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof Object.getPrototypeOf(v).tag === "string") ? ((v.__bp + ".") + Object.getPrototypeOf(v).tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], v.__bp_s?.[n], false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function main() {
    const p = __bp_int((8080 + 1), -2147483648, 2147483647, "+ on i32 at main.bp:5:23");
    __bp_print(p);
}
exports.main = main;

const compiler = require("./std/compiler.js");

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { main, compiler } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
8081
```
