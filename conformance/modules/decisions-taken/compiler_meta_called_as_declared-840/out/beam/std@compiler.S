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
%%% - The point: `src()`, `module`, `package`, `isStd`.
%%% - The outputs, a decorator's only (`compiler-output-outside-decorator`):
%%%   `setMeta`, `addMeta`, `addMember`, `addType`, `init`,
%%%   `implement`.
%%% - The reads of a `syntax` (decision 576 (2)): `text`, `name`, `source`,
%%%   `context`, `lookup`, `bindings`, `holes` (decision 637), `fail`.
%%% - A template's call site: `build`, `ast`, `isSyntax`, `buildType`,
%%%   `note`, `tagDecl`, `annotate`, `custom` (decisions 578 (3), 625 (2),
%%%   637).
%%% - The typed AST `ast` builds code from (decision 625 (2)): `Node` and its
%%%   kinds `Name`, `Lit`, `Member`, `Call`, `Arg`, `List`, `Tuple`,
%%%   `Binary`, `Unary`, `If`, `Lambda`, `Syntax` (decision 638), `Fn`,
%%%   `FnParam`, `Return` and the type nodes `NamedType`, `ArrayType`,
%%%   `TupleType`, `LabeledTupleType`, `OptionalType`, `FnType`,
%%%   `GenericType`, `UnionType` (decision 753).
%%% - A declaration handle's reads (decision 576 (3)): `name`, `kind`,
%%%   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,
%%%   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.
%%% - The program: `find`, `typeInfo`, `load` (decisions 780, 782, 786), and
%%%   what `load` answers: `Module` — run by `m.run()` (decisions 787, 792) —,
%%%   `Refused`, `Diagnostic`.
%%% 
%%% `setBuiltin`, `embed`, `fields` over a type,
%%% `optional` and `required` join it with the steps that build them.
% The value the module's import binds (decision 579): its value is given by
% the compiler at each point, so it has no body.
% ── The annotations the compiler reads itself (decisions 606 (4), 663, 774) ──
% Members of `compiler`, as `external` is: written `#[compiler.<name>(…)]`, and
% read by the compiler where they stand, so their bodies run over nothing.
% The bare `#[stage(…)]` / `#[beamMemory(…)]` and the old `#[@Stage.Any]` /
% `#[@BeamMemory.<Mode>]` are refused.
% A function's stage (decision 681), written only `#[compiler.stage(.Any)]`: a
% host function is `Run` unless it says `Any`, and may then be called inside
% a `comptime`. `Build` and `Run` follow from what a body reads and are never
% written — `#[compiler.stage(.Build)]` / `#[compiler.stage(.Run)]` are
% refused at the argument (`infer.zig` `hostStage`).
% How the BEAM holds a module `var` (decision 547): a `var` is one value for
% the whole program on every target; `Ets`, what a `var` with no annotation
% means, is a one-row ETS table, `x = f(x)` atomic; `PersistentTerm` suits a
% `var` written rarely and read much — a write scans every process. Off the
% BEAM the annotation is accepted and changes nothing (`ast.zig`
% `ValDecl.memory`, `infer.zig` `validateMemoryAnnotations`).
% ── The typed AST `compiler.ast` builds code from (decision 625 (2)) ──────
% One record per kind of expression a template answers, each with a field
% set of its own: a body that runs at build reads a record by its fields.
% A name, resolved in the module that wrote the tree: `Name("double")`.
% A value known at build, spliced as its literal: `Lit(3)`, `Lit("a")`,
% `Lit([1, 2])`.
% `target.member`.
% A call: `callee` a `Name`, a `Member` (a method call) or any node; each
% argument a node (positional) or an `Arg` (labelled).
% A labelled argument, `name: value` — only an argument of a `Call`.
% `[a, b]`.
% `#(a, b)`.
% `lhs op rhs`, `op` one of `+ - * / % == != < > <= >= && ||`.
% `op operand`, `op` one of `-` and `!`.
% `if (cond) then else otherwise`.
% `{ a, b -> body }`.
% The code a `syntax` value holds, spliced as it was written and typed where
% the splice stands (decision 638).
% A typed function, `fn(a: A, b: B) -> R { … }` (decision 753): each
% parameter an `FnParam`, `ret` a type node, `body` its statements in order.
% `Lambda` stays the untyped one.
% A typed parameter, `name: annotation` — only an element of `Fn.params`.
% `return result`.
% The type nodes (decision 753), one per kind of the parser's type grammar;
% a type node stands only where a type is written — an `FnParam`'s
% annotation, a `Fn`'s `ret`, inside another type node.
% A type by its name: `string`, `Self`, `Greeter`.
% `T[]`.
% `#(A, B)`.
% `#(a: A, b: B)`.
% `?T`.
% `fn(A, B) -> R`.
% `Name<A, B>`: `Result<T, E>`, `Dict<K, V>`.
% `A | B`.
% ── A refusal `compiler.load` answers (decisions 780 (2), 781) ────────────
% One refusal of the loaded package, as `botopink build` prints it: `message`
% the text after `error: ` (after `error[<code>]: ` when the refusal carries
% its code there), `code` the refusal's code (`""` when it has none), `file`
% relative to the loaded package's root with `line` and `column` where the refusal
% points (`""` and `0` when it points nowhere), `label` the text beside the
% caret when there is one, `` `from` `` the calls (decision 532) a refusal raised at
% build in another file crossed after the innermost one, each
% `<file>:<line>:<col>`, innermost first (`[]` when there are none).
% ── What `compiler.load` answers (decisions 786, 787, 792, 811) ──────────
% The loaded package (decisions 786 (1), 805 (4), 982 (4)): `name()` its
% manifest's name, `path()` the directory as written (`cases/<case>`),
% `buildOutput()` what its build printed (a top-level `comptime` block's
% `print`, in order, each line ending in `\n`, before its refusals — decisions
% 904, 989 (4); `""` when none). No target — comptime
% reads none — and no dependency list: the loaded package still resolves its
% own to compile. Opaque (decision 811 (4)): only `compiler.load` answers one,
% through `of`, which no program names — `Module(…)` written outside is
% `opaque-construction`, `m.name` `opaque-field`.
% 
% `m.run() -> Result<string, RunFailure>` (decisions 787, 792, 806, 989) runs
% the loaded package's `main`; `Async<Result<string, RunFailure>>`, its `main`
% awaited, when that `main` is `async` (989 (2)). It is written directly in a `compiler.init` body
% (`run-outside-init`): the package — its `mod` tree and its own
% dependencies, named from its path (`bp_load__<path>`) — joins the program,
% and at every `run()` its `val`s, `var`s, module body and `compiler.init`s
% run anew, just before `main`; what the build folded is not recomputed.
% `Ok` when `main` returns, holding what the package wrote to standard output
% while it ran — its body's prints and its `main`'s, byte for byte, none of it
% reaching the program's own output (989 (1)) —, `Error(RunFailure)`
% otherwise — nothing the package runs propagates out of `run()`. The `Module` of a `Refused` is
% `run-module-refused`, a file with no `main` `load-no-main`. The method is
% declared here and typed by this signature in every module that reads a
% `Module`; each call is lowered by the checker (`comptime/infer.zig`
% `inferModuleRun`) to the loaded package's `main`, so the body below never
% runs.
% The capture per target (989 (1)): commonJS swaps `process.stdout.write`
% for one that keeps the text; erlang and beam make a process the caller's
% group leader, answering the io protocol's output requests by keeping their
% text; wasm points the print helper's `$__write_bytes` at a string. The
% handle each answers is the capture it replaced, typed `string` only to
% cross the call: nothing reads it but `closeCapture`.
% What `m.run()` answers on its `Error` side (decision 806): `.Failed` when
% the loaded `main` returns `Error(e)`, `message` the text `print` writes for
% `e`; `.Abort` when the package crashes — a `panic`, a host failure or a
% run-time crash, in its body, its executors or its `main` —, `message` the
% crash's. `output` is what the package wrote to standard output before it
% failed (decision 989 (1)). Decision 989 (3): `.Refused` when the built
% target refuses the loaded package at `emit` (a host binding it lacks
% there), `.Excluded` when its manifest's `targets` leave the built target
% out — refused there too, as the audit at `emit` requires
% (`load-excluded-target-compiles`) —, each `message` the refusal's text;
% nothing of the package runs. `failure.Failure`, what `attempt` answers, is
% another type.
% The kinds of a `RunFailure`.
% A load that refused: the loaded file's `Module` and its refusals, never
% empty.
% ── The types `compiler` answers (decision 576 (13)) ──────────────────────
% No prelude name: a file naming one imports it, `import {compiler.Span} from
% "std";`. Each is the compiler's own type, written here under its name.
