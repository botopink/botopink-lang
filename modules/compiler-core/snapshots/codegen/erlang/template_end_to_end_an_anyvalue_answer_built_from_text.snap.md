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
////   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `compile`.
//// - The reads of an `expr` (decision 576 (2)): `text`, `name`, `source`,
////   `context`, `lookup`, `bindings`, `fail`.
//// - A template's call site: `build`, `buildType`, `note`, `tagDecl`,
////   `annotate`, `custom` (decision 578 (3)).
//// - A declaration handle's reads (decision 576 (3)): `name`, `kind`,
////   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,
////   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.
//// - The program: `catalogue`, `typeInfo`.
////
//// `implement`, `setBuiltin`, `embed`, `fields` over a type,
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

%%% the behavior below, member for member.

%%% 

%%% - The point: `src`, `module`, `package`, `isStd`.

%%% - The outputs, a decorator's only (`compiler-output-outside-decorator`):

%%%   `setMeta`, `addMeta`, `addMember`, `addType`, `wrapWith`, `compile`.

%%% - The reads of an `expr` (decision 576 (2)): `text`, `name`, `source`,

%%%   `context`, `lookup`, `bindings`, `fail`.

%%% - A template's call site: `build`, `buildType`, `note`, `tagDecl`,

%%%   `annotate`, `custom` (decision 578 (3)).

%%% - A declaration handle's reads (decision 576 (3)): `name`, `kind`,

%%%   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,

%%%   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.

%%% - The program: `catalogue`, `typeInfo`.

%%% 

%%% `implement`, `setBuiltin`, `embed`, `fields` over a type,

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

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0]).

main() ->
    P = '__bp_int'((8080 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at main.bp:5:23">>),
    '__bp_print'([P]).

%% import compiler

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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
```

----- RUN LOG -----
```logs
8081
```
