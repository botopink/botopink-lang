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
////   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `init`,
////   `implement`.
//// - The reads of a `syntax` (decision 576 (2)): `text`, `name`, `source`,
////   `context`, `lookup`, `bindings`, `fail`.
//// - A template's call site: `build`, `buildType`, `note`, `tagDecl`,
////   `annotate`, `custom` (decision 578 (3)).
//// - A declaration handle's reads (decision 576 (3)): `name`, `kind`,
////   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,
////   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.
//// - The program: `find`, `typeInfo`.
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
    // declarations in source order, calls in order (decisions 575 (3), 615).
    fn init(self: Self, syntax executor: fn());
    // A host source of the annotated `declare fn` (decision 575 (6)): one per
    // target (`implementation-twice`), never on a declaration with a body
    // (`implement-with-body`).
    fn implement(self: Self, comptime source: Implementation);

    // ── The reads of a `syntax` (decision 576 (2)) ─────────────────────────
    // The expression as written.
    fn text(self: Self, syntax e: unknown) -> string;
    // The name the expression is written as, or the declaration's name; an
    // expression that has none — a lambda, a literal, a call, `a + b` — is
    // `syntax-has-no-name` at it (decision 612).
    fn name(self: Self, syntax e: unknown) -> string;
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
    // The declarations marked with a decorator (decisions 253, 581 (3)),
    // read at build.
    fn find(self: Self, with: unknown, member: ?string = null) -> unknown[];
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

----- BEAM ASSEMBLY -- std/compiler.S
```erlang
{module, std@compiler}.
{exports, []}.
{attributes, []}.
{labels, 2}.
%%% The compiler a body that runs at build talks to (decisions 575 (3), 576,
%%% 579).
%%% 
%%% `compiler`, this module's default, is a value, not a keyword: importing
%%% the module binds it — `import {compiler} from "std";` outside std,
%%% `import {compiler};` in a std module, an alias (`import {compiler as c}
%%% from "std";`) included. In a body that runs at build — a decorator, a
%%% template, a function called at build, a `comptime { … }` block — it is the
%%% `Compiler` of that point: the annotated declaration in a decorator, the
%%% call site elsewhere. It is a `Build` resource (decision 376 (1)); a body
%%% that runs only when the program runs is refused there
%%% (`compiler-at-run-time`), and it is read only through its members — never
%%% passed nor stored (`compiler-escapes`). A file that does not import it
%%% has no `compiler`: the name is an ordinary one there.
%%% 
%%% `Compiler` has one implementor, the compiler itself: a unit test holds the
%%% compiler's table of members (`parser/compiler_surface.zig` `members`) to
%%% the behavior below, member for member, each parameter's arrival included
%%% (decision 616): `syntax` receives the code as written — a declaration, an
%%% argument, a lambda —, `comptime` a value known at build, the rest a plain
%%% value.
%%% 
%%% - The point: `src`, `module`, `package`, `isStd`.
%%% - The outputs, a decorator's only (`compiler-output-outside-decorator`):
%%%   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `init`,
%%%   `implement`.
%%% - The reads of a `syntax` (decision 576 (2)): `text`, `name`, `source`,
%%%   `context`, `lookup`, `bindings`, `fail`.
%%% - A template's call site: `build`, `buildType`, `note`, `tagDecl`,
%%%   `annotate`, `custom` (decision 578 (3)).
%%% - A declaration handle's reads (decision 576 (3)): `name`, `kind`,
%%%   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,
%%%   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.
%%% - The program: `find`, `typeInfo`.
%%% 
%%% `setBuiltin`, `embed`, `fields` over a type,
%%% `optional` and `required` join it with the steps that build them.
% The value the module's import binds (decision 579): its value is given by
% the compiler at each point, so it has no body.
% ── The types `compiler` answers (decision 576 (13)) ──────────────────────
% No prelude name: a file naming one imports it, `import {compiler.Span} from
% "std";`. Each is the compiler's own type, written here under its name.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
pub fn describe(syntax decl: unknown) {
    val names = compiler.fields(decl).map({ f -> f.name });
    val upper = names.map({ n -> n.toUpper() }).join("_");
    val hidden = if (names.contains("secret")) { "hidden"; } else { "open"; };
    val short = compiler.name(decl).slice(0, 3);
    val size = if (compiler.name(decl).length() == 4) { "four"; } else { "other"; };
    @emit("pub fn describe" + compiler.name(decl) + "() -> string { return \"" + upper + ":" + hidden + ":" + short + ":" + size + "\"; }");
}

#[describe]
type User(name: string, secret: string, age: i32)

fn main() {
    @print(describeUser());
}
import {compiler} from "std";
```

----- COMPTIME WAT -- decorator describe
```wat
(func $describe/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32) (local $s5 i32) (local $s6 i32) (local $V___BpF11 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  i32.const 2
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 6
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 1
  local.get $s2
  call $rt_make_fun
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L3 (result i32)
  (block $L4
  local.get $s1
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L4
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  local.get $s1
  i32.const 1
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  (block $L5 (result i32)
  (block $L6
  local.get $s2
  local.get $s3
  call $__bp_prim_map/2
  call $rt_pending
  br_if $L6
  br $L5
  )
  call $rt_class
  local.set $s2
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L7 (result i32)
  (block $L8
  local.get $s2
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 2
  call $rt_int
  i64.const 33
  call $rt_int
  local.get $s4
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L7
  )
  local.get $s2
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L5
  )
  br $L3
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L10
  (block $L9
  local.get $s1
  local.set $s2
  br $L10
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  i32.const 2
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  i32.const 2
  call $rt_tuple
  local.set $s3
  local.get $s3
  i32.const 0
  local.get $s2
  call $rt_tset
  drop
  local.get $s3
  i32.const 1
  call $rt_nil
  local.set $s4
  global.get $__tbase
  i32.const 1
  i32.add
  i32.const 1
  local.get $s4
  call $rt_make_fun
  call $rt_tset
  drop
  local.get $s3
  local.set $s3
  (block $L11 (result i32)
  (block $L12
  local.get $s3
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L12
  local.get $s3
  i32.const 0
  call $rt_elem
  local.set $s4
  local.get $s4
  local.set $s4
  local.get $s3
  i32.const 1
  call $rt_elem
  local.set $s5
  local.get $s5
  local.set $s5
  (block $L13 (result i32)
  (block $L14
  local.get $s4
  local.get $s5
  call $__bp_prim_map/2
  call $rt_pending
  br_if $L14
  br $L13
  )
  call $rt_class
  local.set $s4
  call $rt_reason
  local.set $s5
  call $rt_clear
  (block $L15 (result i32)
  (block $L16
  local.get $s4
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L16
  local.get $s5
  local.set $s6
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 17
  call $rt_int
  local.get $s6
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s6
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L15
  )
  local.get $s4
  local.get $s5
  call $rt_raise
  drop
  br $raise
  )
  br $L13
  )
  br $L11
  )
  local.get $s3
  call $rt_case_clause
  drop
  br $raise
  )
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 144
  i32.add
  i32.const 1
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L17 (result i32)
  (block $L18
  local.get $s1
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L18
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  local.get $s1
  i32.const 1
  call $rt_elem
  local.set $s4
  local.get $s4
  local.set $s4
  (block $L19 (result i32)
  (block $L20
  local.get $s3
  local.get $s4
  call $__bp_prim_join/2
  call $rt_pending
  br_if $L20
  br $L19
  )
  call $rt_class
  local.set $s3
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L21 (result i32)
  (block $L22
  local.get $s3
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L22
  local.get $s4
  local.set $s5
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 17
  call $rt_int
  local.get $s5
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s5
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L21
  )
  local.get $s3
  local.get $s4
  call $rt_raise
  drop
  br $raise
  )
  br $L19
  )
  br $L17
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L24
  (block $L23
  local.get $s1
  local.set $s3
  br $L24
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  (block $L25 (result i32)
  (block $L26
  local.get $s2
  global.get $__lit
  i32.const 152
  i32.add
  i32.const 6
  call $rt_bin
  call $__bp_prim_contains/2
  call $rt_pending
  br_if $L26
  br $L25
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L27 (result i32)
  (block $L28
  local.get $s1
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L28
  local.get $s2
  local.set $s4
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 4
  call $rt_int
  i64.const 22
  call $rt_int
  local.get $s4
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L27
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L25
  )
  local.set $s1
  (block $L29 (result i32)
  (block $L30
  local.get $s1
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L30
  global.get $__lit
  i32.const 168
  i32.add
  i32.const 6
  call $rt_bin
  br $L29
  )
  (block $L31
  local.get $s1
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L31
  global.get $__lit
  i32.const 184
  i32.add
  i32.const 4
  call $rt_bin
  br $L29
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L33
  (block $L32
  local.get $s1
  local.set $s2
  br $L33
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  i32.const 3
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 128
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 3
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L34 (result i32)
  (block $L35
  local.get $s1
  call $rt_tuple_arity
  i32.const 3
  i32.ne
  br_if $L35
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s4
  local.get $s4
  local.set $s4
  local.get $s1
  i32.const 1
  call $rt_elem
  local.set $s5
  local.get $s5
  local.set $s5
  local.get $s1
  i32.const 2
  call $rt_elem
  local.set $s6
  local.get $s6
  local.set $s6
  (block $L36 (result i32)
  (block $L37
  local.get $s4
  local.get $s5
  local.get $s6
  call $__bp_prim_slice/3
  call $rt_pending
  br_if $L37
  br $L36
  )
  call $rt_class
  local.set $s4
  call $rt_reason
  local.set $s5
  call $rt_clear
  (block $L38 (result i32)
  (block $L39
  local.get $s4
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L39
  local.get $s5
  local.set $s6
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
  call $rt_int
  i64.const 31
  call $rt_int
  local.get $s6
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s6
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L38
  )
  local.get $s4
  local.get $s5
  call $rt_raise
  drop
  br $raise
  )
  br $L36
  )
  br $L34
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L41
  (block $L40
  local.get $s1
  local.set $s4
  br $L41
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
  i32.const 128
  i32.add
  i32.const 4
  call $rt_atom
  local.get $s0
  call $rt_maps_get
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L42 (result i32)
  (block $L43
  local.get $s1
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L43
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s5
  local.get $s5
  local.set $s5
  (block $L44 (result i32)
  (block $L45
  local.get $s5
  call $__bp_prim_length/1
  call $rt_pending
  br_if $L45
  br $L44
  )
  call $rt_class
  local.set $s5
  call $rt_reason
  local.set $s6
  call $rt_clear
  (block $L46 (result i32)
  (block $L47
  local.get $s5
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L47
  local.get $s6
  local.set $V___BpF11
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 6
  call $rt_int
  i64.const 34
  call $rt_int
  local.get $V___BpF11
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF11
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L46
  )
  local.get $s5
  local.get $s6
  call $rt_raise
  drop
  br $raise
  )
  br $L44
  )
  br $L42
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  i64.const 4
  call $rt_int
  call $rt_eqx
  call $rt_bool
  local.set $s1
  (block $L48 (result i32)
  (block $L49
  local.get $s1
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L49
  global.get $__lit
  i32.const 192
  i32.add
  i32.const 4
  call $rt_bin
  br $L48
  )
  (block $L50
  local.get $s1
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L50
  global.get $__lit
  i32.const 200
  i32.add
  i32.const 5
  call $rt_bin
  br $L48
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L52
  (block $L51
  local.get $s1
  local.set $s5
  br $L52
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
  i32.const 208
  i32.add
  i32.const 15
  call $rt_bin
  global.get $__lit
  i32.const 128
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
  i32.const 224
  i32.add
  i32.const 23
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s3
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s2
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s4
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 248
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s5
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 256
  i32.add
  i32.const 4
  call $rt_bin
  call $bp_comptime_decorator:__bp_add/2
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  local.set $s0
  (block $L53 (result i32)
  (block $L54
  local.get $s0
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L54
  local.get $s0
  i32.const 0
  call $rt_elem
  local.set $s1
  local.get $s1
  local.set $s1
  (block $L55 (result i32)
  (block $L56
  local.get $s1
  call $bp_comptime_decorator:emit/1
  call $rt_pending
  br_if $L56
  br $L55
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L57 (result i32)
  (block $L58
  local.get $s1
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L58
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 7
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
  br $L57
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L55
  )
  br $L53
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

(func $fun1:describe/1 (param $self i32) (param $a0 i32) (result i32)
  (local $V_F i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_F
  global.get $__lit
  i32.const 128
  i32.add
  i32.const 4
  call $rt_atom
  local.get $V_F
  call $rt_maps_get
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

(func $fun2:describe/1 (param $self i32) (param $a0 i32) (result i32)
  (local $s0 i32) (local $t2 i32) (local $V___BpF2 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  call $__bp_prim_toUpper/1
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
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $t2
  local.set $V___BpF2
  global.get $__lit
  i32.const 136
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 34
  call $rt_int
  local.get $V___BpF2
  call $bp_comptime_decorator:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 104
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF2
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

(func $__bp_prim_map/2 (param $a0 i32) (param $a1 i32) (result i32)
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
  local.get $V_Recv
  call $rt_lists_map
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
  i32.const 304
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 3
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

(func $__bp_prim_toUpper/1 (param $a0 i32) (result i32)
  (local $V_Recv i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  (block $L3
  (block $L4
  (block $L5
  local.get $V_Recv
  call $rt_erlang_is_binary
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
  call $rt_string_uppercase
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t1
  local.get $t1
  i32.const 0
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 7
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $t1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t1
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
  i32.const 304
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 344
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
  i32.const 160
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

(func $__bp_prim_contains/2 (param $a0 i32) (param $a1 i32) (result i32)
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
  local.get $V_Recv
  call $rt_lists_member
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  (block $L7
  (block $L8
  (block $L9
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L9
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L8
  br $L7
  )
  call $rt_clear
  )
  br $L6
  )
  local.get $V_Recv
  local.get $s1
  call $rt_string_find
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 7
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 8
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

(func $__bp_prim_slice/3 (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32) (local $V_Arg1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $V_Arg1
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
  local.get $V_Arg1
  call $array_slice/3
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $V_Arg1
  (block $L7
  (block $L8
  (block $L9
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L9
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L8
  br $L7
  )
  call $rt_clear
  )
  br $L6
  )
  local.get $V_Recv
  local.get $s1
  local.get $V_Arg1
  call $string_slice/3
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  global.get $__lit
  i32.const 304
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
  i32.const 5
  call $rt_bin
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  i64.const 2
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

(func $__bp_prim_length/1 (param $a0 i32) (result i32)
  (local $V_Recv i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Recv
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
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V_Recv
  (block $L7
  (block $L8
  (block $L9
  local.get $V_Recv
  call $rt_erlang_is_binary
  call $rt_pending
  br_if $L9
  call $rt_truth
  i32.const 1
  i32.ne
  br_if $L8
  br $L7
  )
  call $rt_clear
  )
  br $L6
  )
  local.get $V_Recv
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  br $L1
  )
  (block $L10
  local.get $a0
  local.set $V_Recv
  i32.const 4
  call $rt_tuple
  local.set $t1
  local.get $t1
  i32.const 0
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 376
  i32.add
  i32.const 6
  call $rt_bin
  call $rt_tset
  drop
  local.get $t1
  i32.const 2
  i64.const 0
  call $rt_int
  call $rt_tset
  drop
  local.get $t1
  i32.const 3
  local.get $V_Recv
  call $rt_tset
  drop
  local.get $t1
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

(func $array_slice/3 (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $V_Self i32) (local $V_Start i32) (local $V_End i32) (local $t1 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V_Self
  local.get $a1
  local.set $V_Start
  local.get $a2
  local.set $V_End
  local.get $V_End
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  local.get $V_Self
  local.get $V_Start
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.get $V_End
  local.get $V_Start
  call $rt_sub
  call $rt_pending
  br_if $raise
  call $rt_lists_sublist3
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L5
  local.get $t1
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  local.get $V_Start
  local.get $V_Self
  call $rt_lists_nthtail
  call $rt_pending
  br_if $raise
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

(func $string_slice/3 (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $t1 i32) (local $s4 i32) (local $t4 i32) (local $t5 i32) (local $t7 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $s2
  local.get $s2
  global.get $__lit
  i32.const 264
  i32.add
  i32.const 9
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  call $rt_nil
  local.set $s4
  global.get $__tbase
  i32.const 3
  i32.add
  i32.const 3
  local.get $s4
  call $rt_make_fun
  local.set $s4
  local.get $s0
  local.set $t4
  local.get $s1
  local.set $t5
  local.get $s2
  local.set $s2
  local.get $s4
  i32.const 3
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t7
  local.get $s4
  local.get $t4
  local.get $t5
  local.get $s2
  local.get $t7
  call_indirect (param i32 i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L3
  )
  (block $L5
  local.get $t1
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 4
  i32.add
  i32.const 2
  local.get $s2
  call $rt_make_fun
  local.set $s2
  local.get $s0
  local.set $s0
  local.get $s1
  local.set $s1
  local.get $s2
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $s4
  local.get $s2
  local.get $s0
  local.get $s1
  local.get $s4
  call_indirect (param i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
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

(func $fun4:string_slice/3 (param $self i32) (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $V___L i32) (local $V___N i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  local.get $a2
  local.set $s2
  local.get $s0
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L4
  (block $L3
  local.get $s0
  local.set $V___L
  br $L4
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $V___L
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L6
  (block $L5
  local.get $s0
  local.set $V___N
  br $L6
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s1
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $s0
  (block $L7 (result i32)
  (block $L8
  local.get $s0
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $V___N
  local.get $s1
  call $rt_add
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  br $L7
  )
  (block $L9
  local.get $s0
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L9
  local.get $s1
  local.get $V___N
  call $rt_erlang_min
  call $rt_pending
  br_if $raise
  br $L7
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s0
  (block $L11
  (block $L10
  local.get $s0
  local.set $s1
  br $L11
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s2
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $s0
  (block $L12 (result i32)
  (block $L13
  local.get $s0
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L13
  local.get $V___N
  local.get $s2
  call $rt_add
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  br $L12
  )
  (block $L14
  local.get $s0
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L14
  local.get $s2
  local.get $V___N
  call $rt_erlang_min
  call $rt_pending
  br_if $raise
  br $L12
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s0
  (block $L16
  (block $L15
  local.get $s0
  local.set $s2
  br $L16
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $V___L
  local.get $s1
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.get $s2
  local.get $s1
  call $rt_sub
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  call $rt_lists_sublist3
  call $rt_pending
  br_if $raise
  call $rt_unicode_characters_to_binary
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

(func $fun5:string_slice/3 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $V___L i32) (local $V___N i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  local.get $s0
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L4
  (block $L3
  local.get $s0
  local.set $V___L
  br $L4
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $V___L
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  local.set $s0
  (block $L6
  (block $L5
  local.get $s0
  local.set $V___N
  br $L6
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s1
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $s0
  (block $L7 (result i32)
  (block $L8
  local.get $s0
  global.get $__lit
  i32.const 160
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $V___N
  local.get $s1
  call $rt_add
  call $rt_pending
  br_if $raise
  i64.const 0
  call $rt_int
  call $rt_erlang_max
  call $rt_pending
  br_if $raise
  br $L7
  )
  (block $L9
  local.get $s0
  global.get $__lit
  i32.const 176
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L9
  local.get $s1
  local.get $V___N
  call $rt_erlang_min
  call $rt_pending
  br_if $raise
  br $L7
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s0
  (block $L11
  (block $L10
  local.get $s0
  local.set $s1
  br $L11
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s1
  local.get $V___L
  call $rt_lists_nthtail
  call $rt_pending
  br_if $raise
  call $rt_unicode_characters_to_binary
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
;;     name => <<"User">>,
;;     fields => [
;;         #{name => <<"name">>, typeName => <<"string">>, annotations => []},
;;         #{name => <<"secret">>, typeName => <<"string">>, annotations => []},
;;         #{name => <<"age">>, typeName => <<"i32">>, annotations => []}
;;     ],
;;     variants => [],
;;     methods => [],
;;     returnType => <<"">>,
;;     annotations => [#{name => <<"describe">>, args => [], decorator => <<"main@@describe">>}],
;;     hooks => [],
;;     params => [],
;;     component => undefined,
;;     module => <<"">>,
;;     owner => undefined,
;;     package => <<"">>
;; }
```

----- COMPTIME REPLY -- decorator describe
```json
{
  "contributions": [
    {
      "kind": "emit",
      "source": "pub fn describeUser() -> string { return \"NAME_SECRET_AGE:hidden:Use:four\"; }"
    }
  ],
  "kind": "ok"
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {describeUser, 0}, {'__bp_priv__Array_range', 2}, {'__bp_priv__Array_repeat', 2}, {'__bp_priv__main', 0}]}.
{attributes, []}.
{labels, 59}.

{function, 'Array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, 'Array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 14}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 15}}.
  {label, 14}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 16}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 19}}.
  {label, 17}.
  {label, 15}.
    {deallocate, 6}.
    return.

{function, 'Array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, 'Array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 20}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 22}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 19}}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 19}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 19}}.
  {label, 23}.
  {label, 21}.
    {deallocate, 6}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call, 0, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, describeUser, 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, describeUser}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"NAME_SECRET_AGE:hidden:Use:four">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.

{function, '__bp_priv__Array_range', 2, 54}.
  {label, 53}.
    {line, [{location, "test@main.erl", 8}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_range'}, 2}.
  {label, 54}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__Array_repeat', 2, 56}.
  {label, 55}.
    {line, [{location, "test@main.erl", 9}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Array_repeat'}, 2}.
  {label, 56}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__main', 0, 58}.
  {label, 57}.
    {line, [{location, "test@main.erl", 10}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__main'}, 0}.
  {label, 58}.
    {call_only, 0, {f, 7}}.

{function, '__bp_print', 1, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 25}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 29}.
  {label, 28}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 29}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '-bp_show_elem-', 1, 31}.
  {label, 30}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 31}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '__bp_show', 2, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 27}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 39}, [{x, 0}]}.
    {test, is_eq, {f, 38}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 40}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 42}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 41}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 41}, [{x, 0}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 47}}.
  {label, 46}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 47}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 27}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 44}, [{x, 0}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, undefined}]}.
  {label, 43}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 33}, 2}.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 45}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 33}.
  {label, 32}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 33}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 48}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 48}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 48}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 35}, 3}.
  {label, 49}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 35}.
  {label, 34}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 35}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 50}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 51}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 37}.
  {label, 36}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 37}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 27}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 19}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 52}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 52}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- test@main@@User.S
```erlang
{module, test@main@@User}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@User.erl", 3}]}.
    {func_info, {atom, test@main@@User}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, secret}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, age}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "test@main@@User.erl", 3}]}.
    {func_info, {atom, test@main@@User}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"age">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"secret">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"User">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
NAME_SECRET_AGE:hidden:Use:four
```
