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

----- ERLANG -- std/compiler.erl
```erlang
-module(std@compiler).

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

%% behavior Compiler

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
pub fn shout(syntax q: string) -> string {
    val t = compiler.text(q).trim();
    val words = t.split(" ").map({ w -> w.toUpper() });
    val lead = t.slice(0, 5);
    val rest = t.slice(6, t.length);
    val all = words.append(["END"]).reverse();
    val at = if (words.at(1) == "BIG") { "at"; } else { "-"; };
    val big = if (t.contains("big")) { "contains"; } else { "-"; };
    val greet = if (lead.startsWith("hel")) { "startsWith"; } else { "-"; };
    val where = if (words.indexOf("WORLD") == 2) { "indexOf"; } else { "-"; };
    return compiler.build("\"" + all.join(",") + "|" + lead + "|" + rest + "|" + at + "|" + big + "|" + greet + "|" + where + "\"");
}

val s = shout @` hello big world `;

fn main() {
    @print(s);
}
import {compiler} from "std";
```

----- COMPTIME WAT -- template shout
```wat
(func $shout/1 (param $a0 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32) (local $s5 i32) (local $s6 i32) (local $s7 i32) (local $s8 i32) (local $s9 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  i32.const 1
  call $rt_tuple
  local.set $s1
  local.get $s1
  i32.const 0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  call $bp_comptime_template:text/1
  call $rt_pending
  br_if $L4
  br $L3
  )
  call $rt_class
  local.set $s2
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L5 (result i32)
  (block $L6
  local.get $s2
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 2
  call $rt_int
  i64.const 27
  call $rt_int
  local.get $s4
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L5
  )
  local.get $s2
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L3
  )
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L7 (result i32)
  (block $L8
  local.get $s1
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L8
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s2
  local.get $s2
  local.set $s2
  (block $L9 (result i32)
  (block $L10
  local.get $s2
  call $__bp_prim_trim/1
  call $rt_pending
  br_if $L10
  br $L9
  )
  call $rt_class
  local.set $s2
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L11 (result i32)
  (block $L12
  local.get $s2
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L12
  local.get $s3
  local.set $s4
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 2
  call $rt_int
  i64.const 27
  call $rt_int
  local.get $s4
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s4
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L11
  )
  local.get $s2
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L9
  )
  br $L7
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L14
  (block $L13
  local.get $s1
  local.set $s2
  br $L14
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
  (block $L15 (result i32)
  (block $L16
  local.get $s2
  global.get $__lit
  i32.const 304
  i32.add
  i32.const 1
  call $rt_bin
  call $__bp_prim_split/2
  call $rt_pending
  br_if $L16
  br $L15
  )
  call $rt_class
  local.set $s3
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L17 (result i32)
  (block $L18
  local.get $s3
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L18
  local.get $s4
  local.set $s5
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 17
  call $rt_int
  local.get $s5
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s5
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L17
  )
  local.get $s3
  local.get $s4
  call $rt_raise
  drop
  br $raise
  )
  br $L15
  )
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  call $rt_nil
  local.set $s3
  global.get $__tbase
  i32.const 0
  i32.add
  i32.const 1
  local.get $s3
  call $rt_make_fun
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L19 (result i32)
  (block $L20
  local.get $s1
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L20
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
  (block $L21 (result i32)
  (block $L22
  local.get $s3
  local.get $s4
  call $__bp_prim_map/2
  call $rt_pending
  br_if $L22
  br $L21
  )
  call $rt_class
  local.set $s3
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L23 (result i32)
  (block $L24
  local.get $s3
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L24
  local.get $s4
  local.set $s5
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 17
  call $rt_int
  local.get $s5
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s5
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L23
  )
  local.get $s3
  local.get $s4
  call $rt_raise
  drop
  br $raise
  )
  br $L21
  )
  br $L19
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L26
  (block $L25
  local.get $s1
  local.set $s3
  br $L26
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  (block $L27 (result i32)
  (block $L28
  local.get $s2
  i64.const 0
  call $rt_int
  i64.const 5
  call $rt_int
  call $__bp_prim_slice/3
  call $rt_pending
  br_if $L28
  br $L27
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s4
  call $rt_clear
  (block $L29 (result i32)
  (block $L30
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L30
  local.get $s4
  local.set $s5
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 4
  call $rt_int
  i64.const 16
  call $rt_int
  local.get $s5
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s5
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L29
  )
  local.get $s1
  local.get $s4
  call $rt_raise
  drop
  br $raise
  )
  br $L27
  )
  local.set $s1
  (block $L32
  (block $L31
  local.get $s1
  local.set $s4
  br $L32
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
  local.get $s2
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  i64.const 6
  call $rt_int
  call $rt_tset
  drop
  local.get $s1
  i32.const 2
  local.get $s2
  global.get $__lit
  i32.const 312
  i32.add
  i32.const 6
  call $rt_atom
  call $bp_comptime_template:__bp_len/2
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L33 (result i32)
  (block $L34
  local.get $s1
  call $rt_tuple_arity
  i32.const 3
  i32.ne
  br_if $L34
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s5
  local.get $s5
  local.set $s5
  local.get $s1
  i32.const 1
  call $rt_elem
  local.set $s6
  local.get $s6
  local.set $s6
  local.get $s1
  i32.const 2
  call $rt_elem
  local.set $s7
  local.get $s7
  local.set $s7
  (block $L35 (result i32)
  (block $L36
  local.get $s5
  local.get $s6
  local.get $s7
  call $__bp_prim_slice/3
  call $rt_pending
  br_if $L36
  br $L35
  )
  call $rt_class
  local.set $s5
  call $rt_reason
  local.set $s6
  call $rt_clear
  (block $L37 (result i32)
  (block $L38
  local.get $s5
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L38
  local.get $s6
  local.set $s7
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 5
  call $rt_int
  i64.const 16
  call $rt_int
  local.get $s7
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s7
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L37
  )
  local.get $s5
  local.get $s6
  call $rt_raise
  drop
  br $raise
  )
  br $L35
  )
  br $L33
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L40
  (block $L39
  local.get $s1
  local.set $s5
  br $L40
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
  i32.const 2
  call $rt_tuple
  local.set $s6
  local.get $s6
  i32.const 0
  local.get $s3
  call $rt_tset
  drop
  local.get $s6
  i32.const 1
  global.get $__lit
  i32.const 320
  i32.add
  i32.const 3
  call $rt_bin
  local.set $s7
  call $rt_nil
  local.set $s8
  local.get $s7
  local.get $s8
  call $rt_cons
  call $rt_tset
  drop
  local.get $s6
  local.set $s6
  (block $L41 (result i32)
  (block $L42
  local.get $s6
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L42
  local.get $s6
  i32.const 0
  call $rt_elem
  local.set $s7
  local.get $s7
  local.set $s7
  local.get $s6
  i32.const 1
  call $rt_elem
  local.set $s8
  local.get $s8
  local.set $s8
  (block $L43 (result i32)
  (block $L44
  local.get $s7
  local.get $s8
  call $__bp_prim_append/2
  call $rt_pending
  br_if $L44
  br $L43
  )
  call $rt_class
  local.set $s7
  call $rt_reason
  local.set $s8
  call $rt_clear
  (block $L45 (result i32)
  (block $L46
  local.get $s7
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L46
  local.get $s8
  local.set $s9
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 6
  call $rt_int
  i64.const 15
  call $rt_int
  local.get $s9
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s9
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L45
  )
  local.get $s7
  local.get $s8
  call $rt_raise
  drop
  br $raise
  )
  br $L43
  )
  br $L41
  )
  local.get $s6
  call $rt_case_clause
  drop
  br $raise
  )
  call $rt_tset
  drop
  local.get $s1
  local.set $s1
  (block $L47 (result i32)
  (block $L48
  local.get $s1
  call $rt_tuple_arity
  i32.const 1
  i32.ne
  br_if $L48
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s6
  local.get $s6
  local.set $s6
  (block $L49 (result i32)
  (block $L50
  local.get $s6
  call $__bp_prim_reverse/1
  call $rt_pending
  br_if $L50
  br $L49
  )
  call $rt_class
  local.set $s6
  call $rt_reason
  local.set $s7
  call $rt_clear
  (block $L51 (result i32)
  (block $L52
  local.get $s6
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L52
  local.get $s7
  local.set $s8
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 6
  call $rt_int
  i64.const 15
  call $rt_int
  local.get $s8
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s8
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L51
  )
  local.get $s6
  local.get $s7
  call $rt_raise
  drop
  br $raise
  )
  br $L49
  )
  br $L47
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L54
  (block $L53
  local.get $s1
  local.set $s6
  br $L54
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  (block $L55 (result i32)
  (block $L56
  local.get $s3
  i64.const 1
  call $rt_int
  call $__bp_prim_at/2
  call $rt_pending
  br_if $L56
  br $L55
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s7
  call $rt_clear
  (block $L57 (result i32)
  (block $L58
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L58
  local.get $s7
  local.set $s8
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 7
  call $rt_int
  i64.const 18
  call $rt_int
  local.get $s8
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s8
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L57
  )
  local.get $s1
  local.get $s7
  call $rt_raise
  drop
  br $raise
  )
  br $L55
  )
  global.get $__lit
  i32.const 328
  i32.add
  i32.const 3
  call $rt_bin
  call $rt_eqx
  call $rt_bool
  local.set $s1
  (block $L59 (result i32)
  (block $L60
  local.get $s1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L60
  global.get $__lit
  i32.const 344
  i32.add
  i32.const 2
  call $rt_bin
  br $L59
  )
  (block $L61
  local.get $s1
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L61
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  br $L59
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L63
  (block $L62
  local.get $s1
  local.set $s7
  br $L63
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  (block $L64 (result i32)
  (block $L65
  local.get $s2
  global.get $__lit
  i32.const 368
  i32.add
  i32.const 3
  call $rt_bin
  call $__bp_prim_contains/2
  call $rt_pending
  br_if $L65
  br $L64
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L66 (result i32)
  (block $L67
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L67
  local.get $s2
  local.set $s8
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 8
  call $rt_int
  i64.const 19
  call $rt_int
  local.get $s8
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s8
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L66
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L64
  )
  local.set $s1
  (block $L68 (result i32)
  (block $L69
  local.get $s1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L69
  global.get $__lit
  i32.const 376
  i32.add
  i32.const 8
  call $rt_bin
  br $L68
  )
  (block $L70
  local.get $s1
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L70
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  br $L68
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L72
  (block $L71
  local.get $s1
  local.set $s2
  br $L72
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  (block $L73 (result i32)
  (block $L74
  local.get $s4
  global.get $__lit
  i32.const 384
  i32.add
  i32.const 3
  call $rt_bin
  call $__bp_prim_startsWith/2
  call $rt_pending
  br_if $L74
  br $L73
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s8
  call $rt_clear
  (block $L75 (result i32)
  (block $L76
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L76
  local.get $s8
  local.set $s9
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 9
  call $rt_int
  i64.const 21
  call $rt_int
  local.get $s9
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s9
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L75
  )
  local.get $s1
  local.get $s8
  call $rt_raise
  drop
  br $raise
  )
  br $L73
  )
  local.set $s1
  (block $L77 (result i32)
  (block $L78
  local.get $s1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L78
  global.get $__lit
  i32.const 392
  i32.add
  i32.const 10
  call $rt_bin
  br $L77
  )
  (block $L79
  local.get $s1
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L79
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  br $L77
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L81
  (block $L80
  local.get $s1
  local.set $s8
  br $L81
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  (block $L82 (result i32)
  (block $L83
  local.get $s3
  global.get $__lit
  i32.const 408
  i32.add
  i32.const 5
  call $rt_bin
  call $__bp_prim_indexOf/2
  call $rt_pending
  br_if $L83
  br $L82
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s3
  call $rt_clear
  (block $L84 (result i32)
  (block $L85
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L85
  local.get $s3
  local.set $s9
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 10
  call $rt_int
  i64.const 21
  call $rt_int
  local.get $s9
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s9
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L84
  )
  local.get $s1
  local.get $s3
  call $rt_raise
  drop
  br $raise
  )
  br $L82
  )
  i64.const 2
  call $rt_int
  call $rt_eqx
  call $rt_bool
  local.set $s1
  (block $L86 (result i32)
  (block $L87
  local.get $s1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L87
  global.get $__lit
  i32.const 416
  i32.add
  i32.const 7
  call $rt_bin
  br $L86
  )
  (block $L88
  local.get $s1
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L88
  global.get $__lit
  i32.const 360
  i32.add
  i32.const 1
  call $rt_bin
  br $L86
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L90
  (block $L89
  local.get $s1
  local.set $s3
  br $L90
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
  local.get $s0
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 424
  i32.add
  i32.const 1
  call $rt_bin
  (block $L91 (result i32)
  (block $L92
  local.get $s6
  global.get $__lit
  i32.const 432
  i32.add
  i32.const 1
  call $rt_bin
  call $__bp_prim_join/2
  call $rt_pending
  br_if $L92
  br $L91
  )
  call $rt_class
  local.set $s0
  call $rt_reason
  local.set $s6
  call $rt_clear
  (block $L93 (result i32)
  (block $L94
  local.get $s0
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L94
  local.get $s6
  local.set $s9
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 11
  call $rt_int
  i64.const 34
  call $rt_int
  local.get $s9
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s9
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L93
  )
  local.get $s0
  local.get $s6
  call $rt_raise
  drop
  br $raise
  )
  br $L91
  )
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 440
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s4
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 440
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s5
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 440
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s7
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 440
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s2
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 440
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s8
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 440
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  local.get $s3
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 424
  i32.add
  i32.const 1
  call $rt_bin
  call $bp_comptime_template:__bp_add/2
  call $rt_pending
  br_if $raise
  call $rt_tset
  drop
  local.get $s1
  local.set $s0
  (block $L95 (result i32)
  (block $L96
  local.get $s0
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L96
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
  (block $L97 (result i32)
  (block $L98
  local.get $s1
  local.get $s2
  call $bp_comptime_template:build/2
  call $rt_pending
  br_if $L98
  br $L97
  )
  call $rt_class
  local.set $s1
  call $rt_reason
  local.set $s2
  call $rt_clear
  (block $L99 (result i32)
  (block $L100
  local.get $s1
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L100
  local.get $s2
  local.set $s3
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 11
  call $rt_int
  i64.const 21
  call $rt_int
  local.get $s3
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $s3
  call $rt_raise
  drop
  br $raise
  call $rt_nil
  br $L99
  )
  local.get $s1
  local.get $s2
  call $rt_raise
  drop
  br $raise
  )
  br $L97
  )
  br $L95
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

(func $fun1:shout/1 (param $self i32) (param $a0 i32) (result i32)
  (local $s0 i32) (local $t2 i32) (local $V___BpF4 i32)
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
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $t2
  local.set $V___BpF4
  global.get $__lit
  i32.const 296
  i32.add
  i32.const 7
  call $rt_bin
  i64.const 3
  call $rt_int
  i64.const 41
  call $rt_int
  local.get $V___BpF4
  call $bp_comptime_template:__bp_push/4
  call $rt_pending
  br_if $raise
  drop
  global.get $__lit
  i32.const 72
  i32.add
  i32.const 5
  call $rt_atom
  local.get $V___BpF4
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

(func $__bp_prim_trim/1 (param $a0 i32) (result i32)
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
  call $rt_string_trim
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
  i32.const 496
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 520
  i32.add
  i32.const 4
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

(func $__bp_prim_split/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32) (local $s2 i32) (local $t3 i32) (local $t5 i32)
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
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 2
  i32.add
  i32.const 2
  local.get $s2
  call $rt_make_fun
  local.set $s2
  local.get $V_Recv
  local.set $t3
  local.get $s1
  local.set $s1
  local.get $s2
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t5
  local.get $s2
  local.get $t3
  local.get $s1
  local.get $t5
  call_indirect (param i32 i32 i32) (result i32)
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
  i32.const 496
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 536
  i32.add
  i32.const 5
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

(func $fun3:__bp_prim_split/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V___S i32) (local $s1 i32) (local $s2 i32) (local $t4 i32) (local $V___C i32) (local $t5 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___S
  local.get $a1
  global.get $__lit
  i32.const 528
  i32.add
  i32.const 0
  call $rt_bin_is
  i32.eqz
  br_if $L2
  call $rt_nil
  local.set $s1
  local.get $V___S
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  local.set $s2
  local.get $s2
  local.set $s2
  local.get $s2
  local.set $s2
  (block $L3
  (loop $L4
  local.get $s2
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L3
  local.get $s2
  call $rt_hd
  local.set $t4
  local.get $s2
  call $rt_tl
  local.set $s2
  (block $L5
  local.get $t4
  local.set $V___C
  call $rt_bb_new
  local.set $t5
  local.get $t5
  local.get $V___C
  call $rt_bb_utf8
  call $rt_pending
  br_if $raise
  drop
  local.get $t5
  call $rt_bb_end
  local.get $s1
  call $rt_cons
  local.set $s1
  )
  br $L4
  )
  )
  local.get $s1
  call $rt_lists_reverse
  br $L1
  )
  (block $L6
  local.get $a0
  local.set $V___S
  local.get $a1
  local.set $s1
  local.get $V___S
  local.get $s1
  global.get $__lit
  i32.const 528
  i32.add
  i32.const 3
  call $rt_atom
  call $rt_string_split3
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
  i32.const 496
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 544
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
  i32.const 496
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 552
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
  i32.const 496
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 560
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

(func $__bp_prim_append/2 (param $a0 i32) (param $a1 i32) (result i32)
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
  local.get $V_Recv
  local.get $s1
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
  i32.const 496
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 568
  i32.add
  i32.const 6
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

(func $__bp_prim_reverse/1 (param $a0 i32) (result i32)
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
  call $rt_lists_reverse
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
  i32.const 496
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $t1
  i32.const 1
  global.get $__lit
  i32.const 576
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

(func $__bp_prim_at/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32) (local $t5 i32)
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
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 3
  i32.add
  i32.const 2
  local.get $s2
  call $rt_make_fun
  local.set $s2
  local.get $V_Recv
  local.set $s3
  local.get $s1
  local.set $s4
  local.get $s2
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t5
  local.get $s2
  local.get $s3
  local.get $s4
  local.get $t5
  call_indirect (param i32 i32 i32) (result i32)
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
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 4
  i32.add
  i32.const 2
  local.get $s2
  call $rt_make_fun
  local.set $s2
  local.get $V_Recv
  local.set $s3
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
  local.get $s3
  local.get $s1
  local.get $s4
  call_indirect (param i32 i32 i32) (result i32)
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
  i32.const 496
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
  i32.const 2
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

(func $fun4:__bp_prim_at/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V___L i32) (local $s1 i32) (local $s2 i32) (local $V___N i32) (local $t5 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___L
  local.get $a1
  local.set $s1
  local.get $V___L
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  local.set $s2
  (block $L4
  (block $L3
  local.get $s2
  local.set $V___N
  br $L4
  )
  local.get $s2
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s2
  drop
  local.get $s1
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
  local.set $s2
  (block $L5 (result i32)
  (block $L6
  local.get $s2
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L6
  local.get $s1
  local.get $V___N
  call $rt_add
  call $rt_pending
  br_if $raise
  br $L5
  )
  (block $L7
  local.get $s2
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L7
  local.get $s1
  br $L5
  )
  local.get $s2
  call $rt_case_clause
  drop
  br $raise
  )
  local.set $s1
  (block $L9
  (block $L8
  local.get $s1
  local.set $s2
  br $L9
  )
  local.get $s1
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s1
  drop
  local.get $s2
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.ge_s
  call $rt_bool
  local.set $s1
  local.get $s1
  call $rt_truth
  local.set $t5
  local.get $t5
  i32.const 2
  i32.eq
  (if
    (then
  local.get $s1
  call $rt_badarg_of
  drop
  br $raise
    )
  )
  local.get $t5
  (if (result i32)
    (then
  local.get $s2
  local.get $V___N
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
    )
    (else
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
    )
  )
  local.set $s1
  (block $L10 (result i32)
  (block $L11
  local.get $s1
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L11
  local.get $s2
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.get $V___L
  call $rt_lists_nth
  call $rt_pending
  br_if $raise
  br $L10
  )
  (block $L12
  local.get $s1
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L12
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 9
  call $rt_atom
  br $L10
  )
  local.get $s1
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

(func $fun5:__bp_prim_at/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $V___N i32) (local $t6 i32)
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
  local.set $s2
  br $L4
  )
  local.get $s0
  call $rt_badmatch
  drop
  br $raise
  )
  local.get $s0
  drop
  local.get $s2
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
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L8
  local.get $s1
  local.get $V___N
  call $rt_add
  call $rt_pending
  br_if $raise
  br $L7
  )
  (block $L9
  local.get $s0
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L9
  local.get $s1
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
  i64.const 0
  call $rt_int
  call $rt_cmp
  i32.const 0
  i32.ge_s
  call $rt_bool
  local.set $s0
  local.get $s0
  call $rt_truth
  local.set $t6
  local.get $t6
  i32.const 2
  i32.eq
  (if
    (then
  local.get $s0
  call $rt_badarg_of
  drop
  br $raise
    )
  )
  local.get $t6
  (if (result i32)
    (then
  local.get $s1
  local.get $V___N
  call $rt_cmp
  i32.const 0
  i32.lt_s
  call $rt_bool
    )
    (else
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
    )
  )
  local.set $s0
  (block $L12 (result i32)
  (block $L13
  local.get $s0
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L13
  local.get $s1
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.get $s2
  call $rt_lists_nth
  call $rt_pending
  br_if $raise
  local.set $s1
  call $rt_nil
  local.set $s2
  local.get $s1
  local.get $s2
  call $rt_cons
  call $rt_unicode_characters_to_binary
  call $rt_pending
  br_if $raise
  br $L12
  )
  (block $L14
  local.get $s0
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L14
  global.get $__lit
  i32.const 120
  i32.add
  i32.const 9
  call $rt_atom
  br $L12
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
  i32.const 584
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
  i32.const 496
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

(func $__bp_prim_startsWith/2 (param $a0 i32) (param $a1 i32) (result i32)
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
  local.get $s1
  call $rt_string_prefix
  call $rt_pending
  br_if $raise
  global.get $__lit
  i32.const 584
  i32.add
  i32.const 7
  call $rt_atom
  call $rt_eqx
  i32.eqz
  call $rt_bool
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
  i32.const 496
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 392
  i32.add
  i32.const 10
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

(func $__bp_prim_indexOf/2 (param $a0 i32) (param $a1 i32) (result i32)
  (local $V_Recv i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32) (local $t5 i32)
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
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 5
  i32.add
  i32.const 2
  local.get $s2
  call $rt_make_fun
  local.set $s2
  local.get $V_Recv
  local.set $s3
  local.get $s1
  local.set $s4
  local.get $s2
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t5
  local.get $s2
  local.get $s3
  local.get $s4
  local.get $t5
  call_indirect (param i32 i32 i32) (result i32)
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
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 7
  i32.add
  i32.const 2
  local.get $s2
  call $rt_make_fun
  local.set $s2
  local.get $V_Recv
  local.set $s3
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
  local.get $s3
  local.get $s1
  local.get $s4
  call_indirect (param i32 i32 i32) (result i32)
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
  i32.const 496
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 416
  i32.add
  i32.const 7
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

(func $fun6:__bp_prim_indexOf/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $t7 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s0
  local.get $a1
  local.set $s1
  i32.const 1
  call $rt_tuple
  local.set $s2
  local.get $s2
  i32.const 0
  local.get $s1
  call $rt_tset
  drop
  local.get $s2
  local.set $s1
  global.get $__tbase
  i32.const 6
  i32.add
  i32.const 2
  local.get $s1
  call $rt_make_fun
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
  local.get $s2
  local.set $s1
  i64.const 0
  call $rt_int
  local.set $s2
  local.get $s0
  local.set $s0
  local.get $s1
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $t7
  local.get $s1
  local.get $s2
  local.get $s0
  local.get $t7
  call_indirect (param i32 i32 i32) (result i32)
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

(func $fun7:__bp_prim_indexOf/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $s0 i32) (local $s1 i32) (local $s2 i32) (local $s3 i32) (local $s4 i32)
  (block $raise
  local.get $self
  call $rt_fun_env
  i32.const 0
  call $rt_elem
  local.set $s0
  local.get $self
  local.set $s1
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $s2
  local.get $a1
  i32.const 12
  call $rt_is
  i32.eqz
  br_if $L2
  local.get $a1
  call $rt_hd
  local.set $s3
  local.get $a1
  call $rt_tl
  local.set $s4
  local.get $s3
  local.set $s3
  local.get $s4
  local.set $s4
  local.get $s3
  local.get $s0
  call $rt_eqx
  call $rt_bool
  local.set $s0
  (block $L3 (result i32)
  (block $L4
  local.get $s0
  global.get $__lit
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  local.get $s2
  br $L3
  )
  (block $L5
  local.get $s0
  global.get $__lit
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  local.get $s1
  local.set $s1
  local.get $s2
  i64.const 1
  call $rt_int
  call $rt_add
  call $rt_pending
  br_if $raise
  local.set $s2
  local.get $s4
  local.set $s3
  local.get $s1
  i32.const 2
  call $rt_nil
  call $rt_fun_index
  call $rt_pending
  br_if $raise
  local.set $s4
  local.get $s1
  local.get $s2
  local.get $s3
  local.get $s4
  call_indirect (param i32 i32 i32) (result i32)
  call $rt_pending
  br_if $raise
  br $L3
  )
  local.get $s0
  call $rt_case_clause
  drop
  br $raise
  )
  br $L1
  )
  (block $L6
  local.get $a1
  i32.const 11
  call $rt_is
  i32.eqz
  br_if $L6
  i64.const -1
  call $rt_int
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

(func $fun8:__bp_prim_indexOf/2 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
  (local $V___S i32) (local $s1 i32) (local $t1 i32) (local $s3 i32)
  (block $raise
  (block $L1 (result i32)
  (block $L2
  local.get $a0
  local.set $V___S
  local.get $a1
  local.set $s1
  local.get $s1
  local.set $t1
  (block $L3 (result i32)
  (block $L4
  local.get $t1
  global.get $__lit
  i32.const 528
  i32.add
  i32.const 0
  call $rt_bin_is
  i32.eqz
  br_if $L4
  i64.const 0
  call $rt_int
  br $L3
  )
  (block $L5
  local.get $V___S
  local.get $s1
  call $rt_binary_match
  call $rt_pending
  br_if $raise
  local.set $s1
  (block $L6 (result i32)
  (block $L7
  local.get $s1
  global.get $__lit
  i32.const 584
  i32.add
  i32.const 7
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L7
  i64.const -1
  call $rt_int
  br $L6
  )
  (block $L8
  local.get $s1
  call $rt_tuple_arity
  i32.const 2
  i32.ne
  br_if $L8
  local.get $s1
  i32.const 0
  call $rt_elem
  local.set $s3
  local.get $s3
  local.set $s3
  local.get $V___S
  i64.const 0
  call $rt_int
  local.get $s3
  call $rt_binary_part
  call $rt_pending
  br_if $raise
  call $rt_unicode_characters_to_list
  call $rt_pending
  br_if $raise
  call $rt_erlang_length
  call $rt_pending
  br_if $raise
  br $L6
  )
  local.get $s1
  call $rt_case_clause
  drop
  br $raise
  )
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
  i32.const 8
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
  i32.const 496
  i32.add
  i32.const 21
  call $rt_atom
  call $rt_tset
  drop
  local.get $s1
  i32.const 1
  global.get $__lit
  i32.const 592
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

(func $fun9:__bp_prim_join/2 (param $self i32) (param $a0 i32) (result i32)
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
  i32.const 336
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
  i32.const 120
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
  i32.const 336
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
  i32.const 352
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
  i32.const 120
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
  i32.const 336
  i32.add
  i32.const 4
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L4
  call $rt_nil
  local.set $s4
  global.get $__tbase
  i32.const 9
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
  i32.const 352
  i32.add
  i32.const 5
  call $rt_atom
  call $rt_eqx
  i32.eqz
  br_if $L5
  call $rt_nil
  local.set $s2
  global.get $__tbase
  i32.const 10
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

(func $fun10:string_slice/3 (param $self i32) (param $a0 i32) (param $a1 i32) (param $a2 i32) (result i32)
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
  i32.const 336
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
  i32.const 352
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
  i32.const 336
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
  i32.const 352
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

(func $fun11:string_slice/3 (param $self i32) (param $a0 i32) (param $a1 i32) (result i32)
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
  i32.const 336
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
  i32.const 352
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
;;     '__bp_capture' => <<"q">>,
;;     text => <<" hello big world ">>,
;;     source => #{file => <<"">>, line => 14, col => 15},
;;     context => #{
;;         source => #{file => <<"">>, line => 14, col => 15},
;;         text => <<" hello big world ">>,
;;         multiline => false
;;     },
;;     bindings => [],
;;     words => [<<"hello">>, <<"big">>, <<"world">>]
;; }
```

----- COMPTIME REPLY -- template shout
```json
{
  "kind": "code",
  "source": "\"END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf\""
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, s/0, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2]).

%% behavior String

%% behavior Array

array_range(Start, Stop) ->
    case ((Stop - Start) =< 0) of
        true ->
            [];
        false ->
            case ((Stop - Start) =:= 1) of
                true ->
                    [Start];
                false ->
                    Count = (Stop - Start),
                    Low = array_range(Start, (Start + (Count div 2))),
                    High = array_range((Start + (Count div 2)), Stop),
                    '__bp_prim_append'(Low, High)
            end
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Half = array_repeat(Value, (Times div 2)),
            case ((Times rem 2) =:= 0) of
                true ->
                    '__bp_prim_append'(Half, Half);
                false ->
                    '__bp_prim_append'('__bp_prim_append'(Half, Half), [Value])
            end
    end.

s() ->
    <<"END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf">>.

main() ->
    '__bp_print'([s()]).

%% import compiler

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).
```

----- RUN LOG -----
```logs
END,WORLD,BIG,HELLO|hello|big world|at|contains|startsWith|indexOf
```
