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
//// the behavior below, member for member, each parameter's arrival included
//// (decision 616): `syntax` receives the code as written — a declaration, an
//// argument, a lambda —, `comptime` a value known at build, the rest a plain
//// value.
////
//// - The point: `src`, `module`, `package`, `isStd`.
//// - The outputs, a decorator's only (`compiler-output-outside-decorator`):
////   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `compile`,
////   `implement`.
//// - The reads of a `syntax` (decision 576 (2)): `text`, `name`, `source`,
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
    fn fail(self: Self, message: string, syntax at: ?unknown = null, span: ?Span = null);
    // A note at the template's call site (decision 426 (4)).
    fn note(self: Self, message: string);

    // ── The outputs (a decorator's only) ──────────────────────────────────
    // A typed meta value, one per type per declaration (decision 298).
    fn setMeta<M>(self: Self, syntax value: M);
    // A typed meta value that repeats (decision 298).
    fn addMeta<M>(self: Self, syntax value: M);
    // A member of the annotated type, a function written at the call
    // (decision 370 (2)).
    fn addMember<F>(self: Self, name: string, syntax member: F);
    // An associated type of the annotated type (decision 216 (3)).
    fn addType(self: Self, name: string, comptime source: string);
    // A wrapper of the annotated function, a lambda written at the call
    // (decision 316).
    fn wrapWith<F>(self: Self, syntax wrapper: F);
    // Run-time code compiled beside the annotated declaration, run once
    // before `main` in the program's init list: modules in dependency order,
    // declarations in source order, calls in order (decision 575 (3)).
    fn compile(self: Self, syntax executor: fn());
    // A host source of the annotated `declare fn` (decision 575 (6)): one per
    // target (`implementation-twice`), never on a declaration with a body
    // (`implement-with-body`).
    fn implement(self: Self, comptime source: Implementation);

    // ── The reads of a `syntax` (decision 576 (2)) ─────────────────────────
    // The expression as written.
    fn text(self: Self, syntax e: unknown) -> string;
    // The name the expression is written as, or the declaration's name;
    // `null` for a lambda or `a + b`.
    fn name(self: Self, syntax e: unknown) -> ?string;
    // A template text's source and the context it stands in.
    fn source(self: Self, syntax e: unknown) -> Source;
    fn context(self: Self, syntax e: unknown) -> ExprContext;
    // A name resolved where the call stands, and every name in scope there.
    fn lookup(self: Self, syntax e: unknown, name: string) -> unknown;
    fn bindings(self: Self, syntax e: unknown) -> unknown[];

    // ── A template's call site ────────────────────────────────────────────
    // Code built from source text, typed at the call (decisions 426 (1),
    // 578 (3)).
    fn build(self: Self, comptime source: string) -> anyvalue;
    // A type built from source text — the one way a type is built
    // (decision 578 (3)).
    fn buildType(self: Self, comptime source: string) -> anytype;
    // A tag's declaration handle (decision 302), and a handle's annotation.
    fn tagDecl(self: Self, kind: DeclKind, name: string, syntax attrs: unknown) -> unknown;
    fn annotate(self: Self, syntax d: unknown, at: Span) -> unknown;
    // The reference tree the language server reads, by call location.
    fn custom(self: Self, ast: CustomNode);

    // ── A declaration handle's reads (decision 576 (3)) ───────────────────
    fn kind(self: Self, syntax d: unknown) -> DeclKind;
    fn moduleOf(self: Self, syntax d: unknown) -> string;
    fn meta<M>(self: Self, syntax d: unknown) -> ?M;
    fn metaAll<M>(self: Self, syntax d: unknown) -> M[];
    fn attr(self: Self, syntax d: unknown, name: string) -> ?string;
    fn component(self: Self, syntax d: unknown) -> unknown;
    fn hooks(self: Self, syntax d: unknown) -> HookNode[];
    fn fields(self: Self, syntax d: unknown) -> Field[];
    fn methods(self: Self, syntax d: unknown) -> Method[];
    fn params(self: Self, syntax d: unknown) -> Param[];
    fn returnType(self: Self, syntax d: unknown) -> string;
    fn owner(self: Self, syntax d: unknown) -> unknown;
    fn annotations(self: Self, syntax d: unknown) -> DeclAnnotation[];
    fn variants(self: Self, syntax d: unknown) -> string[];

    // ── The program ───────────────────────────────────────────────────────
    // The declarations a decorator marks (decision 253), read at build.
    fn catalogue(self: Self, with: unknown, member: ?string = null) -> unknown[];
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

//// the behavior below, member for member, each parameter's arrival included

//// (decision 616): `syntax` receives the code as written — a declaration, an

//// argument, a lambda —, `comptime` a value known at build, the rest a plain

//// value.

//// 

//// - The point: `src`, `module`, `package`, `isStd`.

//// - The outputs, a decorator's only (`compiler-output-outside-decorator`):

////   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `compile`,

////   `implement`.

//// - The reads of a `syntax` (decision 576 (2)): `text`, `name`, `source`,

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
    fail(message: string, at: unknown | null, span: __Span | null): void;
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
    catalogue(with_: unknown, member: string | null): unknown[];
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
pub fn component(syntax decl: unknown) {
    var args: Array<string> = [];
    compiler.fields(decl).forEach({ f ->
        var valKey = "";
        f.annotations.forEach({ a -> if (a.name == "value") { valKey = a.args.join(""); } });
        val expr = if (valKey != "") {
            "prop(" + valKey + ")";
        } else {
            "make" + f.typeName + "()";
        };
        args.push(f.name + ": " + expr);
    });
    @emit("pub fn wire" + compiler.name(decl)! + "() -> string { return \"" + compiler.name(decl)! + "(" + args.join(", ") + ")\"; }");
}

#[component]
type Service(
    #[value(port)]
    port: i32,
    name: string,
)

fn collect(xs: Array<i32>) -> Array<string> {
    var out: Array<string> = [];
    out.push("start");
    xs.forEach({ x ->
        val doubled = x * 2;
        out.push("v" + doubled.toString());
    });
    return out;
}

fn main() {
    @print(wireService());
    @print(collect([1, 2, 3]).join(","));
}
import {compiler} from "std";
```

----- COMPTIME WAT -- decorator component
```wat
(func $component/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  call $rt_nil
  local.set $s1
  (block $L4
  (block $L3
  local.get $s1
  local.set $s2
  br $L4
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  call $rt_nil
  local.set $s1
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 2
  local.get $s1
  call $rt_make_fun
  local.get $s2
  global.get $__lit
  i32.const 232
  i32.add
  i32.const 6
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_lists_foldl
  call $rt_pending
  br_if $raise
  local.set $s1
  (block $L6
  (block $L5
  local.get $s1
  local.set $s2
  br $L6
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  i32.const 1
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 240
  i32.add
  i32.const 11
  call $rt_bin
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 23
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 280
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  (block $L7 (result i32)
  (block $L8
  local.get $s2
  global.get $__lit
  i32.const 288
  i32.add
  i32.const 2
  call $rt_bin
  call $__bp_prim_join/2
  call $rt_pending
  br_if $L8
  br $L7
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L9 (result i32)
  (block $L10
  local.get $s0
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L10
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 13
  call $rt_int
  i64.const 108
  call $rt_int
  local.get $s3
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s3
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L9
  )
  local.get $s0
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L7
  )
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 5
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  local.set $s0
  (block $L11 (result i32)
  (block $L12
  local.get $s0
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L12
  local.get $s0
  i32.const 0
  call $rt_elem
  local.set $s1
  local.get $s1
  local.set $s1
  (block $L13 (result i32)
  (block $L14
  local.get $s1
  call $bp_comptime_decorator:emit/1
  call $rt_pending
  br_if $L14
  br $L13
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L15 (result i32)
  (block $L16
  local.get $s1
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L16
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 13
  call $rt_int
  i64.const 5
  call $rt_int
  local.get $s3
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s3
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L15
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L13
  )
  br $L11
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
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

(func $fun1:component/1 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 1
  i32.add
  i32.const 2
  local.get $s2
  call $rt_make_fun
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 0
  call $rt_bin
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 11
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_lists_foldl
  call $rt_pending
  br_if $raise
  local.set $s2
  (block $L4
  (block $L3
  local.get $s2
  local.set $s3
  br $L4
  )
  local.get $s2
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s2
  drop
  local.get $s3
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 0
  call $rt_bin
  call $rt_eqx
  i32.eqz
  call $rt_bool
  local.set $s2
  (block $L5 (result i32)
  (block $L6
  local.get $s2
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 5
  call $rt_bin
  local.get $s3
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 184
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  br $L5
  )
  (block $L7
  local.get $s2
  global.get $__lit
  i32.const 192
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L7
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 4
  call $rt_bin
  global.get $__lit
  i32.const 208
  i32.add
  i32.const 8
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 216
  i32.add
  i32.const 2
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  br $L5
  )
  local.get $s2
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s2
  (block $L9
  (block $L8
  local.get $s2
  local.set $s3
  br $L9
  )
  local.get $s2
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s2
  drop
  i32.const 2
  call $rt_tuple
  local.set $s2
  local.get $s2
  i32.const 0
  local.get $s1
  call $rt_tset
  drop
  local.get $s2
  i32.const 1
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 224
  i32.add
  i32.const 2
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s3
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s2
  local.set $s0
  (block $L10 (result i32)
  (block $L11
  local.get $s0
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L11
  local.get $s0
  i32.const 0
  call $rt_elem
  local.set $s1
  local.get $s1
  local.set $s1
  local.get $s0
  i32.const 1
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  (block $L12 (result i32)
  (block $L13
  local.get $s1
  local.get $s2
  call $__bp_prim_push/2
  call $rt_pending
  br_if $L13
  br $L12
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L14 (result i32)
  (block $L15
  local.get $s1
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L15
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 11
  call $rt_int
  i64.const 9
  call $rt_int
  local.get $s3
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s3
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L14
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L12
  )
  br $L10
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s0
  (block $L17
  (block $L16
  local.get $s0
  local.set $s1
  br $L17
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s1
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

(func $fun2:component/1 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $s0 i32) (local $V_ValKey i32) (local $t1 i32) (local $s3 i32) (local $s4 i32) (local $V___BpF1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $V_ValKey
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 128
  i32.add
  i32.const 5
  call $rt_bin
  call $rt_eqx
  call $rt_bool
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  i32.const 2
  call $rt_tuple
  local.set $s3
  local.get $s3
  i32.const 0
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s3
  i32.const 1
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 0
  call $rt_bin
  call $rt_tset
  drop
  local.get $s3
  local.set $s0
  (block $L5 (result i32)
  (block $L6
  local.get $s0
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L6
  local.get $s0
  i32.const 0
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  local.get $s0
  i32.const 1
  call $rt_elem
  local.set $s4
  local.get $s4
  local.set $s4
  (block $L7 (result i32)
  (block $L8
  local.get $s3
  local.get $s4
  call $__bp_prim_join/2
  call $rt_pending
  br_if $L8
  br $L7
  )
  call $rt_class
  local.set $s3
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L9 (result i32)
  (block $L10
  local.get $s3
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L10
  local.get $s4
  local.set $V___BpF1
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
  call $rt_int
  i64.const 72
  call $rt_int
  local.get $V___BpF1
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF1
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L9
  )
  local.get $s3
  local.get $s4
  call $rt_raise
  drop
  br $raise
  )
  br $L7
  )
  br $L5
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  br $L3
  )
  (block $L11
  local.get $V_ValKey
  br $L3
  )
  local.get $t1
  call $rt_case_clause
  drop
  br $raise
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

(func $__bp_prim_join/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $s1
  call $rt_nil
  local.set $s1
  global.get $__tbase
  i32.const 2
  i32.add
  i32.const 1
  local.get $s1
  call $rt_make_fun
  local.get $V_Recv
  call $rt_lists_map
  call $rt_pending
  br_if $raise
  call $rt_lists_join
  call $rt_pending
  br_if $raise
  call $rt_erlang_iolist_to_binary
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 344
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 368
  i32.add
  i32.const 4
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $s1
  call $rt_error
  call $rt_pending
  br_if $raise
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

(func $fun3:__bp_prim_join/2 (param $self i32) (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  (block $L5
  (block $L6
  (block $L7
  local.get $s0
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L7
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L6
  br $L5
  )
  call $rt_clear
  )
  br $L4
  )
  local.get $s0
  br $L3
  )
  (block $L8
  (block $L9
  (block $L10
  (block $L11
  local.get $s0
  call $rt_erlang_is_integer
  call $rt_pending
  br_if $L11
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L10
  br $L9
  )
  call $rt_clear
  )
  br $L8
  )
  local.get $s0
  call $rt_erlang_integer_to_binary
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L12
  (block $L13
  (block $L14
  (block $L15
  local.get $s0
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L15
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L14
  br $L13
  )
  call $rt_clear
  )
  br $L12
  )
  local.get $s0
  br $L3
  )
  (block $L16
  (block $L17
  (block $L18
  (block $L19
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L18
  br $L17
  )
  call $rt_clear
  )
  br $L16
  )
  call $rt_nil
  local.set $s1
  i64.const 112
  call $rt_int
  local.get $s1
  call $rt_cons
  local.set $s1
  i64.const 126
  call $rt_int
  local.get $s1
  call $rt_cons
  local.get $s0
  local.set $s0
  call $rt_nil
  local.set $s1
  local.get $s0
  local.get $s1
  call $rt_cons
  call $rt_io_lib_format
  call $rt_pending
  br_if $raise
  call $rt_erlang_iolist_to_binary
  call $rt_pending
  br_if $raise
  br $L3
  )
  call $rt_if_clause
  drop
  br $raise
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

(func $__bp_prim_push/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32) (local $t2 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_list
  call $rt_pending
  br_if $L5
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L4
  br $L3
  )
  call $rt_clear
  )
  br $L2
  )
  local.get $V_Recv
  local.get $s1
  local.set $s1
  call $rt_nil
  local.set $t2
  local.get $s1
  local.get $t2
  call $rt_cons
  call $rt_append
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 344
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 376
  i32.add
  i32.const 4
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 1
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $s1
  call $rt_error
  call $rt_pending
  br_if $raise
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
;;     kind => 'Type',
;;     name => <<"Service">>,
;;     fields => [
;;         #{
;;             name => <<"port">>,
;;             typeName => <<"i32">>,
;;             annotations => [#{name => <<"value">>, args => [<<"port">>], decorator => <<"main@@value">>}]
;;         },
;;         #{name => <<"name">>, typeName => <<"string">>, annotations => []}
;;     ],
;;     variants => [],
;;     methods => [],
;;     returnType => <<"">>,
;;     annotations => [#{name => <<"component">>, args => [], decorator => <<"main@@component">>}],
;;     hooks => [],
;;     params => [],
;;     component => undefined,
;;     module => <<"">>,
;;     owner => undefined,
;;     package => <<"">>
;; }
```

----- COMPTIME REPLY -- decorator component
```json
{
  "contributions": [
    {
      "kind": "emit",
      "source": "pub fn wireService() -> string { return \"Service(port: prop(port), name: makestring())\"; }"
    }
  ],
  "kind": "ok"
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

class Service {
    constructor(port, name) {
        this.port = port;
        this.name = name;
    }
}
Service.prototype.__bp = "Service";

function collect(xs) {
    let out = [];
    out = out.concat(["start"]);
    xs.forEach((x) => {
    const doubled = __bp_int((x * 2), -2147483648, 2147483647, "* on i32 at main.bp:27:25");
    return out.push(("v" + doubled.toString()));
});
    return out;
}

function main() {
    __bp_print(wireService());
    __bp_print(collect([1, 2, 3]).join(","));
}

const compiler = require("./std/compiler.js");

function wireService() {
    return "Service(port: prop(port), name: makestring())";
}
exports.wireService = wireService;

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Service, collect, main, compiler, wireService } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript








export declare function wireService(): string;

```

----- RUN LOG -----
```logs
Service(port: prop(port), name: makestring())
start,v2,v4,v6
```
