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
//// - The point: `src()`, `module`, `package`, `isStd`.
//// - The outputs, a decorator's only (`compiler-output-outside-decorator`):
////   `setMeta`, `addMeta`, `addMember`, `addType`, `init`,
////   `implement`.
//// - The reads of a `syntax` (decision 576 (2)): `text`, `name`, `source`,
////   `context`, `lookup`, `bindings`, `holes` (decision 637), `fail`.
//// - A template's call site: `build`, `ast`, `isSyntax`, `buildType`,
////   `note`, `tagDecl`, `annotate`, `custom` (decisions 578 (3), 625 (2),
////   637).
//// - The typed AST `ast` builds code from (decision 625 (2)): `Node` and its
////   kinds `Name`, `Lit`, `Member`, `Call`, `Arg`, `List`, `Tuple`,
////   `Binary`, `Unary`, `If`, `Lambda`, `Syntax` (decision 638), `Fn`,
////   `FnParam`, `Return` and the type nodes `NamedType`, `ArrayType`,
////   `TupleType`, `LabeledTupleType`, `OptionalType`, `FnType`,
////   `GenericType`, `UnionType` (decision 753).
//// - A declaration handle's reads (decision 576 (3)): `name`, `kind`,
////   `moduleOf`, `meta`, `metaAll`, `attr`, `component`, `hooks`, `fields`,
////   `methods`, `params`, `returnType`, `owner`, `annotations`, `variants`.
//// - The program: `find`, `typeInfo`, `load` (decisions 780, 782, 786), and
////   what `load` answers: `Module` — run by `m.run()` (decisions 787, 792),
////   its tests by `` m.`test`() `` (decision 993) —, `Refused`, `Diagnostic`,
////   and what `` `test`() `` answers, `TestReport` and `TestCase`.
//// - The crossing (decisions 550, 1035 (4), 1038 (3)): what crosses into and
////   out of a comptime evaluation as JSON — `Json`, `jsonRead`, `jsonText`,
////   `jsonSorted`, `jsonPretty`; the values a body hands back, `BuildValue`;
////   the three replies `DecoratorReply`, `TemplateReply`, `BlockReply` with
////   their encoders and readers; an error reply's text, `raisedText`; what
////   crosses in — the opaque declaration handle `Decl` (`declOf`, decision
////   1058 (1)), a template's `Capture`, the hooks, the typed meta and the
////   main argument `Input`, each with a reader and a writer; and the
////   evaluation's ends `evalDecorator`, `evalTemplate`, `evalBlock`
////   (decisions 1059, 1063 (3)).
////
//// `setBuiltin`, `embed`, `fields` over a type,
//// `optional` and `required` join it with the steps that build them.

pub behavior Compiler {
    // ── The point ─────────────────────────────────────────────────────────
    // The module and the package the point is written in; whether it is std.
    val module: string;
    val package: string;
    val isStd: bool;

    // Where the point is: the annotated declaration in a decorator, the call
    // site elsewhere — always called, `comptime compiler.src()`; a run-time
    // function that needs its caller's place takes it as an argument the
    // caller writes (decision 718).
    fn src(self: Self) -> SourceLocation;

    // ── Reporting ─────────────────────────────────────────────────────────
    // An error at the argument or the declaration `at` holds (at `span`
    // inside it when given), else at `src`; the body goes on.
    fn fail(self: Self, message: string, syntax at: ?unknown = null, span: ?Span = null) -> void;
    // A note at the template's call site (decision 426 (4)).
    fn note(self: Self, message: string) -> void;

    // ── The outputs (a decorator's only) ──────────────────────────────────
    // A typed meta value, one per type per declaration (decision 298).
    fn setMeta<M>(self: Self, syntax value: M) -> void;
    // A typed meta value that repeats (decision 298).
    fn addMeta<M>(self: Self, syntax value: M) -> void;
    // A member of the annotated type, a function written at the call
    // (decision 370 (2)).
    fn addMember<F>(self: Self, name: string, syntax member: F) -> void;
    // An associated type of the annotated type (decision 216 (3)).
    fn addType(self: Self, name: string, comptime source: string) -> void;
    // Run-time code compiled beside the annotated declaration, run once
    // before `main` in the program's init list: modules in dependency order,
    // declarations in source order, calls in order (decisions 575 (3), 615).
    fn init(self: Self, syntax executor: fn()) -> void;
    // A host source of the annotated `declare fn` (decision 575 (6)): one per
    // target (`implementation-twice`), never on a declaration with a body
    // (`implement-with-body`).
    fn implement(self: Self, comptime source: Implementation) -> void;

    // ── The reads of a `syntax` (decision 576 (2)) ─────────────────────────
    // The expression as written.
    fn text(self: Self, syntax e: unknown) -> string;
    // The name the expression is written as, or the declaration's name;
    // `null` for an expression that has none — a lambda, a literal, a call,
    // `a + b` — and never on a declaration (decision 643).
    fn name(self: Self, syntax e: unknown) -> ?string;
    // A template text's source and the context it stands in.
    fn source(self: Self, syntax e: unknown) -> Source;
    fn context(self: Self, syntax e: unknown) -> ExprContext;
    // A name resolved where the call stands, and every name in scope there.
    fn lookup(self: Self, syntax e: unknown, name: string) -> unknown;
    fn bindings(self: Self, syntax e: unknown) -> unknown[];
    // The `${…}` holes of a template text, in order (decision 637): the
    // i-th the i-th hole's expression, a `syntax` value — opaque, typed in
    // the caller's scope where it is spliced. A text a body that runs at
    // build hands a template holds each hole's value there.
    fn holes(self: Self, syntax t: string) -> unknown[];

    // ── A template's call site ────────────────────────────────────────────
    // Code built from source text, typed at the call (decisions 426 (1),
    // 578 (3)).
    fn build(self: Self, comptime source: string) -> anyvalue;
    // Code built from a tree of `Node`s, typed at the call (decision 625
    // (2)); a tree that is no code — an `Arg` outside a `Call`, a `Name`
    // nothing binds — is refused here, naming the node.
    fn ast(self: Self, comptime node: Node) -> anyvalue;
    // Whether `v` is a `syntax` value — code as written — rather than a
    // value known at build: what a hole of `code` is spliced as (`Syntax(e)`
    // or `Lit(v)`, decisions 637, 638).
    fn isSyntax(self: Self, v: unknown) -> bool;
    // A type built from source text — the one way a type is built
    // (decision 578 (3)).
    fn buildType(self: Self, comptime source: string) -> anytype;
    // A tag's declaration handle (decision 302), and a handle's annotation.
    fn tagDecl(self: Self, kind: DeclKind, name: string, syntax attrs: unknown) -> unknown;
    fn annotate(self: Self, syntax d: unknown, at: Span) -> unknown;
    // The reference tree the language server reads, by call location.
    fn custom(self: Self, ast: CustomNode) -> void;

    // ── A declaration handle's reads (decision 576 (3)) ───────────────────
    fn kind(self: Self, syntax d: unknown) -> DeclKind;
    fn moduleOf(self: Self, syntax d: unknown) -> string;
    fn meta<M>(self: Self, syntax d: unknown, comptime m: type<M>) -> ?M;
    fn metaAll<M>(self: Self, syntax d: unknown, comptime m: type<M>) -> M[];
    fn attr(self: Self, syntax d: unknown, name: string) -> ?string;
    fn component(self: Self, syntax d: unknown) -> unknown;
    fn hooks(self: Self, syntax d: unknown) -> HookNode[];
    fn fields(self: Self, syntax d: unknown) -> Field[];
    fn methods(self: Self, syntax d: unknown) -> Method[];
    fn params(self: Self, syntax d: unknown) -> Param[];
    fn returnType(self: Self, syntax d: unknown) -> string;
    fn owner(self: Self, syntax d: unknown) -> unknown;
    fn annotations(self: Self, syntax d: unknown) -> DeclAnnotation[];
    fn variants(self: Self, syntax d: unknown) -> Variant[];

    // ── The program ───────────────────────────────────────────────────────
    // The declarations marked with a decorator (decisions 253, 581 (3)),
    // read at build.
    fn find(self: Self, with: unknown, member: ?string = null) -> unknown[];
    // A type's reflection (decision 253).
    fn typeInfo<T>(self: Self, comptime t: type<T>) -> TypeInfo<T>;
    // A package compiled at build (decisions 780, 782, 786, 982): `path`
    // names a directory, relative to the caller's `botopink.json` (no
    // absolute path, no `..`), holding its own `botopink.json` and
    // `src/main.bp`, compiled from its `src/main.bp` under its own manifest
    // and checked for its own targets, never joining the caller's program —
    // a file or a directory short of either is `load-not-a-package`. `Ok`
    // the loaded package's `Module` when it compiles, `Error` a `Refused` —
    // that `Module` and its refusals in the order `botopink build` prints
    // them, never empty and never a refusal of the caller; read with
    // `try … catch` or `try` (decision 783).
    fn load(self: Self, comptime path: string) -> Result<Module, Refused>;
}

// The value the module's import binds (decision 579): its value is given by
// the compiler at each point, so it has no body.
#[builtin]
pub default declare val compiler: Compiler;

// ── The annotations the compiler reads itself (decisions 606 (4), 663, 774) ──
// Members of `compiler`, as `external` is: written `#[compiler.<name>(…)]`, and
// read by the compiler where they stand, so their bodies run over nothing.
// The bare `#[stage(…)]` / `#[beamMemory(…)]` and the old `#[@Stage.Any]` /
// `#[@BeamMemory.<Mode>]` are refused.

// A function's stage (decision 681), written only `#[compiler.stage(.Any)]`: a
// host function is `Run` unless it says `Any`, and may then be called inside
// a `comptime`. `Build` and `Run` follow from what a body reads and are never
// written — `#[compiler.stage(.Build)]` / `#[compiler.stage(.Run)]` are
// refused at the argument (`infer.zig` `hostStage`).
pub fn stage(syntax decl: unknown, comptime s: Stage) -> void {}

// How the BEAM holds a module `var` (decision 547): a `var` is one value for
// the whole program on every target; `Ets`, what a `var` with no annotation
// means, is a one-row ETS table, `x = f(x)` atomic; `PersistentTerm` suits a
// `var` written rarely and read much — a write scans every process. Off the
// BEAM the annotation is accepted and changes nothing (`ast.zig`
// `ValDecl.memory`, `infer.zig` `validateMemoryAnnotations`).
pub type BeamMemory {
    Ets,
    PersistentTerm,
}

pub fn beamMemory(syntax decl: unknown, comptime m: BeamMemory) -> void {}

// ── The typed AST `compiler.ast` builds code from (decision 625 (2)) ──────
// One record per kind of expression a template answers, each with a field
// set of its own: a body that runs at build reads a record by its fields.
pub type Node = Name | Lit | Member | Call | Arg | List | Tuple | Binary | Unary | If | Lambda | Syntax | Fn | FnParam | Return | NamedType | ArrayType | TupleType | LabeledTupleType | OptionalType | FnType | GenericType | UnionType;

// A name, resolved in the module that wrote the tree: `Name("double")`.
pub type Name(name: string)

// A value known at build, spliced as its literal: `Lit(3)`, `Lit("a")`,
// `Lit([1, 2])`.
pub type Lit(value: unknown)

// `target.member`.
pub type Member(target: Node, member: string)

// A call: `callee` a `Name`, a `Member` (a method call) or any node; each
// argument a node (positional) or an `Arg` (labelled).
pub type Call(callee: Node, args: Node[])

// A labelled argument, `name: value` — only an argument of a `Call`.
pub type Arg(name: string, value: Node)

// `[a, b]`.
pub type List(items: Node[])

// `#(a, b)`.
pub type Tuple(elems: Node[])

// `lhs op rhs`, `op` one of `+ - * / % == != < > <= >= && ||`.
pub type Binary(op: string, lhs: Node, rhs: Node)

// `op operand`, `op` one of `-` and `!`.
pub type Unary(op: string, operand: Node)

// `if (cond) then else otherwise`.
pub type If(cond: Node, then: Node, otherwise: Node)

// `{ a, b -> body }`.
pub type Lambda(params: string[], body: Node)

// The code a `syntax` value holds, spliced as it was written and typed where
// the splice stands (decision 638).
pub type Syntax(e: unknown)

// A typed function, `fn(a: A, b: B) -> R { … }` (decision 753): each
// parameter an `FnParam`, `ret` a type node, `body` its statements in order.
// `Lambda` stays the untyped one.
pub type Fn(params: FnParam[], ret: Node, body: Node[])

// A typed parameter, `name: annotation` — only an element of `Fn.params`.
pub type FnParam(name: string, annotation: Node)

// `return result`.
pub type Return(result: Node)

// The type nodes (decision 753), one per kind of the parser's type grammar;
// a type node stands only where a type is written — an `FnParam`'s
// annotation, a `Fn`'s `ret`, inside another type node.

// A type by its name: `string`, `Self`, `Greeter`.
pub type NamedType(named: string)

// `T[]`.
pub type ArrayType(elem: Node)

// `#(A, B)`.
pub type TupleType(types: Node[])

// `#(a: A, b: B)`.
pub type LabeledTupleType(types: Node[], labels: string[])

// `?T`.
pub type OptionalType(inner: Node)

// `fn(A, B) -> R`.
pub type FnType(params: Node[], returns: Node)

// `Name<A, B>`: `Result<T, E>`, `Dict<K, V>`.
pub type GenericType(name: string, args: Node[])

// `A | B`.
pub type UnionType(members: Node[])

// ── A refusal `compiler.load` answers (decisions 780 (2), 781) ────────────
// One refusal of the loaded package, as `botopink build` prints it: `message`
// the text after `error: ` (after `error[<code>]: ` when the refusal carries
// its code there), `code` the refusal's code (`""` when it has none), `file`
// relative to the loaded package's root with `line` and `column` where the refusal
// points (`""` and `0` when it points nowhere), `label` the text beside the
// caret when there is one, `` `from` `` the calls (decision 532) a refusal raised at
// build in another file crossed after the innermost one, each
// `<file>:<line>:<col>`, innermost first (`[]` when there are none).
pub type Diagnostic(
    code: string,
    message: string,
    file: string,
    line: i32,
    column: i32,
    label: ?string,
    `from`: string[],
)

// ── What `compiler.load` answers (decisions 786, 787, 792, 811) ──────────
// The loaded package (decisions 786 (1), 805 (4), 982 (4)): `name()` its
// manifest's name, `path()` the directory as written (`cases/<case>`),
// `buildOutput()` what its build printed (a top-level `comptime` block's
// `print`, in order, each line ending in `\n`, before its refusals — decisions
// 904, 989 (4); `""` when none), `mainAsync()` whether its `main` is `async`
// (what `run()`'s type follows; read at build, `if (comptime
// m.mainAsync())` keeping one branch — decision 998 (4)). No target — comptime
// reads none — and no dependency list: the loaded package still resolves its
// own to compile. Opaque (decision 811 (4)): only `compiler.load` answers one,
// through `of`, which no program names — `Module(…)` written outside is
// `opaque-construction`, `m.name` `opaque-field`.
//
// `m.run() -> Result<string, RunFailure>` (decisions 787, 792, 806, 989) runs
// the loaded package's `main`; `Async<Result<string, RunFailure>>`, its `main`
// awaited, when that `main` is `async` (989 (2)). It is written directly in a `compiler.init` body
// (`run-outside-init`): the package — its `mod` tree and its own
// dependencies, named from its path (`bp_load__<path>`) — joins the program,
// and at every `run()` its `val`s, `var`s, module body and `compiler.init`s
// run anew, just before `main`; what the build folded is not recomputed.
// `Ok` when `main` returns, holding what the package wrote to standard output
// while it ran — its body's prints and its `main`'s, byte for byte, none of it
// reaching the program's own output (989 (1)) —, `Error(RunFailure)`
// otherwise — nothing the package runs propagates out of `run()`. The `Module` of a `Refused` is
// `run-module-refused`, a file with no `main` `load-no-main`. The method is
// declared here and typed by this signature in every module that reads a
// `Module`; each call is lowered by the checker (`comptime/infer.zig`
// `inferModuleRun`) to the loaded package's `main`, so the body below never
// runs.
pub opaque type Module(
    name: string,
    path: string,
    buildOutput: string,
    mainAsync: bool,
) {
    // What `compiler.load`'s answer is built by (`comptime/load.zig`).
    fn of(name: string, path: string, buildOutput: string, mainAsync: bool) -> Module {
        return Module(name: name, path: path, buildOutput: buildOutput, mainAsync: mainAsync);
    }

    pub fn name(self: Self) -> string {
        return self.name;
    }

    pub fn path(self: Self) -> string {
        return self.path;
    }

    pub fn buildOutput(self: Self) -> string {
        return self.buildOutput;
    }

    pub fn mainAsync(self: Self) -> bool {
        return self.mainAsync;
    }

    pub fn run(self: Self) -> Result<string, RunFailure> {
        throw RunFailure(kind: .Abort, message: "Module.run: every call is lowered to the loaded main", output: "");
    }

    // Decision 993 (3) — `` m.`test`() `` (`test` is a keyword, written
    // between backticks, decision 561) runs the loaded package's tests: its
    // `test` blocks, compiled in test mode (513) beside its modules, each run
    // in turn with what it printed kept as its own; its dependencies' tests
    // never run. `Ok` a `TestReport` of one `TestCase` per test (none for a
    // package with no test) — a test that fails, by an `assert`, a `try`, a
    // `throw` or a crash, is a case with `ok: false`, and the next runs —;
    // `Error(RunFailure)` only for a package the built target refuses
    // (`.Refused`, `.Excluded`, 989 (3)) or a crash outside every test
    // (`.Abort`). `Async` of the answer when a test awaits (989 (2)). Written
    // where `run()` is, lowered as it is (`comptime/infer.zig`
    // `inferModuleTest`), so the body below never runs.
    pub fn `test`(self: Self) -> Result<TestReport, RunFailure> {
        throw RunFailure(kind: .Abort, message: "Module.test: every call is lowered to the loaded tests", output: "");
    }

    // Decision 989 (1) — the capture a lowered `run()` opens around the
    // loaded package's run: from `captureOpen` to `captureClose` what the
    // program writes to standard output is kept, not written, and
    // `captureClose` answers it. `captureOpen` answers the capture it
    // replaces, which `captureClose` restores, so a run inside a run keeps
    // its own. The lowering's calls alone (no `pub`): no program captures.
    fn captureOpen() -> string {
        return openCapture();
    }

    fn captureClose(open: string) -> string {
        return closeCapture(open);
    }

    // Decisions 772, 993 (3) — what a lowered `` `test`() `` sets, as
    // `botopink test`'s runner does: `BOTOPINK_TEST_TMPDIR` names a new
    // directory of the call's own while its tests run, removed after
    // (`testTmpOpen` / `testTmpClose`); `BOTOPINK_TEST_NAME` the running
    // test's name while its body runs (`testNameOpen` / `testNameClose`),
    // where `snap` reads it. Each open answers what it replaced, which its
    // close restores, so a `` `test`() `` inside a test keeps the outer
    // values. The lowering's calls alone (no `pub`).
    fn testTmpOpen() -> string {
        return openTestTmp();
    }

    fn testTmpClose(open: string) -> void {
        closeTestTmp(open);
    }

    fn testNameOpen(name: string) -> string {
        return openTestName(name);
    }

    fn testNameClose(open: string) -> void {
        closeTestName(open);
    }
}

// The capture per target (989 (1)): commonJS swaps `process.stdout.write`
// for one that keeps the text; erlang and beam make a process the caller's
// group leader, answering the io protocol's output requests by keeping their
// text; wasm points the print helper's `$__write_bytes` at a string. The
// handle each answers is the capture it replaced, typed `string` only to
// cross the call: nothing reads it but `closeCapture`.
#[compiler.external(
    .JavaScript("""(() => { const __s = globalThis.process.stdout; const __o = __s.write; const __b = []; __s.write = function (__c, __e, __k) { __b.push(typeof __c === "string" ? __c : Buffer.from(__c).toString(typeof __e === "string" ? __e : "utf8")); const __d = typeof __e === "function" ? __e : __k; if (typeof __d === "function") { __d(); } return true; }; return { write: __o, kept: __b }; })()"""),
    .Erlang("""(fun() -> BpCapOld = erlang:group_leader(), BpCapPid = erlang:spawn(fun() -> (fun BpCapLoop(BpCapAcc) -> receive {io_request, BpCapFrom, BpCapAs, BpCapReq} -> {BpCapReply, BpCapAcc2} = (fun BpCapDo(BpCapR, BpCapA) -> case BpCapR of {put_chars, _, BpCapM, BpCapF, BpCapArgs} -> {ok, [BpCapA, erlang:apply(BpCapM, BpCapF, BpCapArgs)]}; {put_chars, BpCapM, BpCapF, BpCapArgs} -> {ok, [BpCapA, erlang:apply(BpCapM, BpCapF, BpCapArgs)]}; {put_chars, _, BpCapChars} -> {ok, [BpCapA, BpCapChars]}; {put_chars, BpCapChars} -> {ok, [BpCapA, BpCapChars]}; {requests, BpCapRs} -> lists:foldl(fun(BpCapOne, {_, BpCapIn}) -> BpCapDo(BpCapOne, BpCapIn) end, {ok, BpCapA}, BpCapRs); _ -> {{error, enotsup}, BpCapA} end end)(BpCapReq, BpCapAcc), BpCapFrom ! {io_reply, BpCapAs, BpCapReply}, BpCapLoop(BpCapAcc2); {bp_capture_take, BpCapTo, BpCapRef} -> BpCapTo ! {BpCapRef, unicode:characters_to_binary(BpCapAcc)} end end)([]) end), erlang:group_leader(BpCapPid, erlang:self()), {bp_capture, BpCapOld, BpCapPid} end)()"""),
    .Wasm(wasi: .CaptureOpen),
)]
declare fn openCapture() -> string;

#[compiler.external(
    .JavaScript("""((__t) => { globalThis.process.stdout.write = __t.write; return __t.kept.join(""); })($0)"""),
    .Erlang("""(fun({bp_capture, BpCapOld2, BpCapPid2}) -> erlang:group_leader(BpCapOld2, erlang:self()), BpCapRef2 = erlang:make_ref(), BpCapPid2 ! {bp_capture_take, erlang:self(), BpCapRef2}, receive {BpCapRef2, BpCapText} -> BpCapText end end)($0)"""),
    .Wasm(wasi: .CaptureClose),
)]
declare fn closeCapture(open: string) -> string;

// The test variables per target (decisions 772, 993 (3)): commonJS writes
// `process.env`, erlang and beam the `os` environment — what `env.read`
// reads there. The handle each open answers holds the value it replaced,
// typed `string` only to cross the call. wasm has no environment to write
// (`env.read` has no wasm binding, and `botopink test` sets none there): the
// four do nothing.
#[compiler.external(
    .JavaScript("""(() => { const __e = globalThis.process.env; const __d = require("fs").mkdtempSync(require("path").join(require("os").tmpdir(), "botopink-test-")); const __o = __e.BOTOPINK_TEST_TMPDIR; __e.BOTOPINK_TEST_TMPDIR = __d; return { dir: __d, old: __o }; })()"""),
    .Erlang("""(fun() -> BpTmpOld = os:getenv("BOTOPINK_TEST_TMPDIR"), BpTmpBase = case os:getenv("TMPDIR") of false -> "/tmp"; "" -> "/tmp"; BpTmpT -> BpTmpT end, BpTmpDir = filename:join(BpTmpBase, "botopink-test-" ++ os:getpid() ++ "-" ++ integer_to_list(erlang:unique_integer([positive])) ++ "-" ++ integer_to_list(rand:uniform(16#7FFFFFFF))), ok = file:make_dir(BpTmpDir), os:putenv("BOTOPINK_TEST_TMPDIR", BpTmpDir), {bp_test_tmp, BpTmpDir, BpTmpOld} end)()"""),
    .Wasm(body: noTestEnvOpen),
)]
declare fn openTestTmp() -> string;

#[compiler.external(
    .JavaScript("""((__t) => { require("fs").rmSync(__t.dir, { recursive: true, force: true }); if (__t.old === undefined) { delete globalThis.process.env.BOTOPINK_TEST_TMPDIR; } else { globalThis.process.env.BOTOPINK_TEST_TMPDIR = __t.old; } })($0)"""),
    .Erlang("""(fun({bp_test_tmp, BpTmpDir2, BpTmpOld2}) -> file:del_dir_r(BpTmpDir2), case BpTmpOld2 of false -> os:unsetenv("BOTOPINK_TEST_TMPDIR"); _ -> os:putenv("BOTOPINK_TEST_TMPDIR", BpTmpOld2) end end)($0)"""),
    .Wasm(body: noTestEnvClose),
)]
declare fn closeTestTmp(open: string) -> void;

#[compiler.external(
    .JavaScript("""((__n) => { const __e = globalThis.process.env; const __o = __e.BOTOPINK_TEST_NAME; __e.BOTOPINK_TEST_NAME = __n; return { old: __o }; })($0)"""),
    .Erlang("""(fun(BpTnName) -> BpTnOld = os:getenv("BOTOPINK_TEST_NAME"), os:putenv("BOTOPINK_TEST_NAME", binary_to_list(BpTnName)), {bp_test_name, BpTnOld} end)($0)"""),
    .Wasm(body: noTestNameOpen),
)]
declare fn openTestName(name: string) -> string;

#[compiler.external(
    .JavaScript("""((__t) => { if (__t.old === undefined) { delete globalThis.process.env.BOTOPINK_TEST_NAME; } else { globalThis.process.env.BOTOPINK_TEST_NAME = __t.old; } })($0)"""),
    .Erlang("""(fun({bp_test_name, BpTnOld2}) -> case BpTnOld2 of false -> os:unsetenv("BOTOPINK_TEST_NAME"); _ -> os:putenv("BOTOPINK_TEST_NAME", BpTnOld2) end end)($0)"""),
    .Wasm(body: noTestEnvClose),
)]
declare fn closeTestName(open: string) -> void;

fn noTestEnvOpen() -> string {
    return "";
}

fn noTestNameOpen(name: string) -> string {
    return "";
}

fn noTestEnvClose(open: string) -> void {
    return;
}

// What `m.run()` answers on its `Error` side (decision 806): `.Failed` when
// the loaded `main` returns `Error(e)`, `message` the text `print` writes for
// `e`; `.Abort` when the package crashes — a `panic`, a host failure or a
// run-time crash, in its body, its executors or its `main` —, `message` the
// crash's. `output` is what the package wrote to standard output before it
// failed (decision 989 (1)). Decision 989 (3): `.Refused` when the built
// target refuses the loaded package at `emit` (a host binding it lacks
// there), `.Excluded` when its manifest's `targets` leave the built target
// out — refused there too, as the audit at `emit` requires
// (`load-excluded-target-compiles`) —, each `message` the refusal's text;
// nothing of the package runs. `failure.Failure`, what `attempt` answers, is
// another type.
pub type RunFailure(
    kind: RunFailureKind,
    message: string,
    output: string,
)

// The kinds of a `RunFailure`.
pub type RunFailureKind { Failed, Abort, Refused, Excluded }

// What `` m.`test`() `` answers on its `Ok` side (decision 993 (3)): one
// `TestCase` per test of the loaded package: its root's tests in the order
// they are written, then each `mod` it declares, in order, the same way down.
pub type TestReport(cases: TestCase[])

// One test (the fields of `botopink test --json`): `name` the test's (`test_<k>`
// for the `k`-th anonymous one of its module), `file` and `line` where it is
// written — `file` relative to the loaded package —, `ok` whether it passed,
// `output` what it wrote to standard output, `message` why it failed (`""`
// when it passed), `at` the test's `<file>:<line>` when it failed (`""` when it
// passed), `durationMs` the time it ran — `0` until every target reads a
// monotonic clock (wasm reads none).
pub type TestCase(
    name: string,
    file: string,
    line: i32,
    ok: bool,
    output: string,
    message: string,
    at: string,
    durationMs: i32,
)

// A load that refused: the loaded file's `Module` and its refusals, never
// empty.
pub type Refused(
    module: Module,
    diagnostics: Diagnostic[],
)

// ── The types `compiler` answers (decision 576 (13)) ──────────────────────
// No prelude name: a file naming one imports it, `import {compiler.Span} from
// "std";`. Each is the compiler's own type, written here under its name.
pub type Span = __Span;

pub type Source = __Source;

pub type ExprContext = __ExprContext;

pub type CustomNode = __CustomNode;

pub type HookNode = __HookNode;

// ── The reflection records (decisions 576 (13), 848, 1071 (1)) ─────────────
// What a declaration handle's reads answer — `compiler.fields(d)` a
// `Field[]`, `compiler.variants(d)` a `Variant[]`, `compiler.kind(d)` a
// `DeclKind` —, each with a run-time form: a function of the program takes,
// keeps and reads one as any record (`fn row(v: compiler.Variant) -> string`).
// Only the crossing below builds one (`declOf`, as `Decl` and `Module`, decision
// 792 (3)); outside std, `Field(…)` is `reflection-construction`. A body is
// checked against the compiler's own records of these names (`__Decl__Field`,
// … in `comptime.zig` `decl_reflection_src`), which hold the same fields in the
// same order (`comptime/tests/reflection_records.zig`); `compiler.Field<T>`
// (decision 599 (3), `Type.Field<T>`) is another type, the generic field key.

// What kind of declaration a handle is.
pub type DeclKind { Type, Behavior, Fn, Method, Field, Val, Element, Component }

// One annotation (`#[name(args…)]`): its raw argument lexemes and the
// qualified name of the decorator its name names (`main@@column`) — a name,
// not a function value (decision 1071 (1)).
pub type DeclAnnotation(name: string, args: string[], decorator: string)

pub type Param(name: string, typeName: string)

pub type Field(name: string, typeName: string, annotations: DeclAnnotation[])

pub type Method(
    name: string,
    params: Param[],
    returnType: string,
    annotations: DeclAnnotation[],
)

// One constructible variant (decision 848): `section` the enclosing sections'
// names joined by `.`, `null` at the top level.
pub type Variant(
    name: string,
    fields: Field[],
    annotations: DeclAnnotation[],
    section: ?string,
)

// ── The crossing (decisions 550, 1035 (4), 1038 (3)) ───────────────────────
// What crosses into and out of a comptime evaluation is JSON in the core
// unit's memory, read and written by the botopink code below and compiled by
// the program's generator; the reply each evaluation answers is the one the
// Erlang path answers (434 (5)), byte for byte once the compiler's
// `COMPTIME REPLY` rendering (keys sorted, indented by two) has read it.
//
// - `Json`: one JSON document. `jsonRead` reads one (an integer stays an
//   `i64`, a number with a fraction or an exponent is an `f64`); `jsonText`
//   writes it compact, members in their order, strings escaped as OTP's
//   `json:encode` escapes them; `jsonSorted` orders every object's members by
//   their names' bytes; `jsonPretty` is the `COMPTIME REPLY` section's text.
// - `BuildValue`: a value a body computed at build, as the reply carries it —
//   `null`, a boolean, an integer, a float, a string, an array, a tuple, a
//   record, an enum variant without payload (an atom), a function value (its
//   index among the body's function values) and a resource (its text).
// - The three replies: `DecoratorReply` (`ok` / `fail` / `error`, each with the
//   lines the body printed), `TemplateReply` (`code` / `ast` / `value` /
//   `capture` / `custom` with the `build` index and the `notes`, `need`,
//   `fail`, `error`) and `BlockReply` (`value` / `error`). A template's value
//   writes a tuple as `{"$tuple": […]}` and a variant as its name; a block's
//   lifts every kind into its own object (`{"tuple": …}`, `{"record": …}`,
//   `{"atom": …}`, `{"float": …}`, `{"fn": …}`, `{"resource": …}`).
// - `raisedText(class, reason)`: an error reply's `message`, the raise as
//   `Class:Reason`'s `{Class,Reason}` term written by `~p` (std-wasm's
//   `io_lib`, no line breaking) — what the compiler's matchers read
//   (`{error,badarith}`, the division by zero, an unseeded draw,
//   `run-in-build`). `divisionByZero`, `noMatch` and `badArith` are the
//   reasons a GC body raises through an explicit check where its wasm
//   instruction would trap (1038 (3)); an index out of range answers `null`,
//   as `Array.at` does, and raises nothing.

pub type Json {
    JsonNull,
    JsonBool(value: bool),
    JsonInt(value: i64),
    JsonFloat(value: f64),
    JsonString(value: string),
    JsonArray(items: Json[]),
    JsonObject(fields: JsonField[]),
}

pub type JsonField(key: string, value: Json)

pub type BuildValue {
    NullValue,
    BoolValue(value: bool),
    IntValue(value: i64),
    FloatValue(value: f64),
    StringValue(value: string),
    ArrayValue(items: BuildValue[]),
    TupleValue(items: BuildValue[]),
    RecordValue(fields: BuildField[]),
    AtomValue(name: string),
    FnValue(index: ?i64),
    ResourceValue(text: string),
}

pub type BuildField(name: string, value: BuildValue)

// One located call an error crossed (decision 532), innermost first.
pub type Frame(file: string, line: i64, col: i64)

// A decorator's outputs, in call order (decision 216): `kind` one of `emit`,
// `member`, `memberFn`, `meta`, `assoc`, `typedMeta`, `compile`,
// `implement`; the fields its kind writes, the others `null`.
pub type Contribution(
    kind: string,
    source: ?string,
    key: ?string,
    value: ?string,
    name: ?string,
    index: ?i64,
    data: ?Json,
)

// Where a decorator's `fail` points: nowhere, a `Span`, or the argument at
// `index` (decision 364 (3)).
pub type FailSpan {
    NoSpan,
    SpanAt(start: i64, end: i64, line: i64),
    ArgAt(index: i64),
}

pub type DecoratorReply {
    DecoratorOk(contributions: Contribution[], printed: ?string),
    DecoratorFail(message: string, span: FailSpan, printed: ?string),
    DecoratorError(message: string, frames: Frame[], printed: ?string),
}

// What a template's body returned: `build(src)` / `code(src)` (`code`),
// `ast(node)`, `expr(v)` (`value`), the capture itself (`capture`), `custom`.
pub type TemplateAnswer {
    CodeAnswer(source: string),
    AstAnswer(node: BuildValue),
    ValueAnswer(value: BuildValue),
    CaptureAnswer(param: string),
    CustomAnswer(source: string, tree: BuildValue),
}

// A tag a template asks the compiler to run (decision 302): its kind, name,
// attributes and the answer it is (`-1` for a fresh one).
pub type TagRequest(kind: string, name: string, attrs: TagAttr[], answer: i64)

pub type TagAttr(name: string, value: BuildValue)

pub type TemplateReply {
    TemplateDone(answer: TemplateAnswer, build: ?i64, notes: string[]),
    TemplateNeed(request: TagRequest, span: BuildValue),
    TemplateFail(message: string, param: ?string, span: BuildValue),
    TemplateError(message: string, frames: ?Frame[]),
}

pub type BlockReply {
    BlockValue(value: BuildValue, printed: ?string),
    BlockError(message: string, frames: Frame[], printed: ?string),
}

// ── writing JSON ──────────────────────────────────────────────────────────────

// `j` compact, members in their order: what the evaluation hands the
// compiler.
pub fn jsonText(j: Json) -> string {
    return case j {
        JsonNull -> "null";
        JsonBool(value: b) -> boolText(b);
        JsonInt(value: n) -> n.toString();
        JsonFloat(value: x) -> x.toString();
        JsonString(value: s) -> quoteJson(s, true);
        JsonArray(items: _) -> arrayText(itemsOf(j));
        JsonObject(fields: _) -> objectText(fieldsOf(j));
    };
}

// `j` with every object's members ordered by their names' bytes, at every
// depth (`comptime/runtime/reply_order.zig`).
pub fn jsonSorted(j: Json) -> Json {
    return case j {
        JsonArray(items: _) -> Json.JsonArray(items: sortedItems(itemsOf(j)));
        JsonObject(fields: _) -> Json.JsonObject(fields: sortFields(sortedMembers(fieldsOf(j))));
        _ -> j;
    };
}

// `j` as the `COMPTIME REPLY` section shows it: indented by two, one member
// or item a line, an empty array `[]` and an empty object `{}`.
pub fn jsonPretty(j: Json) -> string {
    return prettyAt(j, "");
}

fn prettyAt(j: Json, indent: string) -> string {
    return case j {
        JsonArray(items: _) -> prettyArray(itemsOf(j), indent);
        JsonObject(fields: _) -> prettyObject(fieldsOf(j), indent);
        JsonString(value: s) -> quoteJson(s, false);
        JsonFloat(value: x) -> decimalText(x.toString());
        _ -> jsonText(j);
    };
}

// A float as the section writes it (Zig's `std.json`): its shortest digits in
// plain decimal, no exponent, no `.0` — `1.0e21` is `1000000000000000000000`,
// `1.0e-7` `0.0000001`, `-0.0` `-0`. `text` is `f64.toString()`'s.
fn decimalText(text: string) -> string {
    val cs = text.chars();
    val negative = (cs.at(0) ?? "") == "-";
    val unsigned = if (negative) cs.slice(1, cs.length) else cs;
    var mantissa: string[] = [];
    var exponent: string[] = [];
    var inExponent = false;
    var n = 0;
    while (n < unsigned.length) {
        val c = unsigned.at(n) ?? "";
        if (c == "e" || c == "E") inExponent = true else if (inExponent) {
            if (c != "+") exponent.push(c);
        } else mantissa.push(c);
        n = n + 1;
    }
    val dot = mantissa.indexOf(".");
    val point = if (dot < 0) mantissa.length else dot;
    val digits = mantissa.filter({ c -> c != "." });
    val shift = exponent.join("").parseInt().unwrapOr(noInt());
    val at = point + shift.toI32();
    var whole: string[] = [];
    var fraction: string[] = [];
    var k = at;
    while (k < 0) {
        fraction.push("0");
        k = k + 1;
    }
    var i = 0;
    while (i < at || i < digits.length) {
        val d = digits.at(i) ?? "0";
        if (i < at) {
            if (whole.length > 0 || d != "0") whole.push(d);
        } else fraction.push(d);
        i = i + 1;
    }
    var last = fraction.length;
    while (last > 0 && (fraction.at(last - 1) ?? "") == "0") {
        last = last - 1;
    }
    fraction = fraction.slice(0, last);
    val integral = if (whole.length == 0) "0" else whole.join("");
    val sign = if (negative) "-" else "";
    if (fraction.length == 0) return sign + integral;
    return sign + integral + "." + fraction.join("");
}

fn boolText(b: bool) -> string {
    if (b) return "true";
    return "false";
}

// A JSON string literal: `"` and `\` escaped, `\n` `\r` `\t` `\b` `\f`, any
// other control character as `\u00XX` — upper-case hex as OTP's
// `json:encode` writes it (`upper`), lower-case as the compiler's renderer
// does — and every other code point as it is.
fn quoteJson(s: string, upper: bool) -> string {
    val cps = s.chars().map({ c -> c.charCodeAt(0) });
    val texts = s.chars();
    var out: string[] = ["\""];
    var i = 0;
    while (i < cps.length) {
        out.push(jsonChar(cps.at(i) ?? 0, texts.at(i) ?? "", upper));
        i = i + 1;
    }
    out.push("\"");
    return out.join("");
}

fn jsonChar(c: i32, text: string, upper: bool) -> string {
    if (c == 34) return "\\\"";
    if (c == 92) return "\\\\";
    if (c == 10) return "\\n";
    if (c == 13) return "\\r";
    if (c == 9) return "\\t";
    if (c == 8) return "\\b";
    if (c == 12) return "\\f";
    if (c < 32)
        return "\\u00" + hexDigit(c / 16, upper) + hexDigit(c % 16, upper);
    return text;
}

fn hexDigit(d: i32, upper: bool) -> string {
    val digits = if (upper) "0123456789ABCDEF" else "0123456789abcdef";
    return digits.chars().at(d) ?? "";
}

// Insertion by name: the members of `fs` ordered by their names' code points,
// which is their UTF-8 bytes' order; two of one name keep theirs.
fn sortFields(fs: JsonField[]) -> JsonField[] {
    var out: JsonField[] = [];
    var i = 0;
    while (i < fs.length) {
        val f = fs.at(i) ?? JsonField(key: "", value: Json.JsonNull);
        var next: JsonField[] = [];
        var placed = false;
        var k = 0;
        while (k < out.length) {
            val g = out.at(k) ?? f;
            if (!placed && textBefore(f.key, g.key)) {
                next.push(f);
                placed = true;
            }
            next.push(g);
            k = k + 1;
        }
        if (!placed) next.push(f);
        out = next;
        i = i + 1;
    }
    return out;
}

// Whether `a` sorts strictly before `b`, code point by code point.
fn textBefore(a: string, b: string) -> bool {
    val x = a.chars().map({ c -> c.charCodeAt(0) });
    val y = b.chars().map({ c -> c.charCodeAt(0) });
    var i = 0;
    var answer = x.length < y.length;
    var decided = false;
    while (!decided && i < x.length && i < y.length) {
        val p = x.at(i) ?? 0;
        val q = y.at(i) ?? 0;
        if (p != q) {
            answer = p < q;
            decided = true;
        }
        i = i + 1;
    }
    return answer;
}

// ── reading JSON ──────────────────────────────────────────────────────────────

type Reading(cps: i32[], texts: string[])

type ReadJson(value: Json, next: i32)

type ReadText(text: string, next: i32)

// One RFC 8259 document. An integer without a fraction or an exponent is a
// `JsonInt` when an `i64` holds it; any other number — `-0` and a whole
// number beyond an `i64` included — a `JsonFloat`. An error names the code point
// index where reading stopped.
pub fn jsonRead(text: string) -> Result<Json, string> {
    val doc = Reading(cps: text
        .chars()
        .map({ c -> c.charCodeAt(0) }), texts: text.chars());
    val read = try readJson(doc, skipSpace(doc, 0));
    val end = skipSpace(doc, read.next);
    if (end < doc.cps.length) throw readProblem(end, "text after the value");
    return read.value;
}

fn cpAt(doc: Reading, i: i32) -> i32 {
    return doc.cps.at(i) ?? (0 - 1);
}

fn skipSpace(doc: Reading, start: i32) -> i32 {
    var i = start;
    while (cpAt(doc, i) == 32
        || cpAt(doc, i) == 9
        || cpAt(doc, i) == 10
        || cpAt(doc, i) == 13) {
        i = i + 1;
    }
    return i;
}

fn readProblem(at: i32, what: string) -> string {
    return ["compiler.jsonRead: ", what, " at ", at.toString()].join("");
}

fn readJson(doc: Reading, i: i32) -> Result<ReadJson, string> {
    val c = cpAt(doc, i);
    if (c == 123) return try readObject(doc, skipSpace(doc, i + 1));
    if (c == 91) return try readArray(doc, skipSpace(doc, i + 1));
    if (c == 34) {
        val s = try readString(doc, i);
        return ReadJson(value: Json.JsonString(value: s.text), next: s.next);
    }
    if (c == 116)
        return try readWord(doc, i, "true", Json.JsonBool(value: true));
    if (c == 102)
        return try readWord(doc, i, "false", Json.JsonBool(value: false));
    if (c == 110) return try readWord(doc, i, "null", Json.JsonNull);
    if (c == 45 || (c >= 48 && c <= 57)) return try readNumber(doc, i);
    throw readProblem(i, "no JSON value");
}

fn readWord(doc: Reading, i: i32, word: string, value: Json) -> Result<ReadJson, string> {
    val want = word.chars();
    var ok = true;
    var k = 0;
    while (k < want.length) {
        if ((doc.texts.at(i + k) ?? "") != (want.at(k) ?? "")) ok = false;
        k = k + 1;
    }
    if (!ok) throw readProblem(i, "no JSON value");
    return ReadJson(value: value, next: i + want.length);
}

fn readNumber(doc: Reading, i: i32) -> Result<ReadJson, string> {
    var k = i;
    var whole = true;
    var go = true;
    while (go) {
        val c = cpAt(doc, k);
        if (c >= 48 && c <= 57 || c == 45 && k == i) k = k + 1 else if (c == 46
            || c == 101
            || c == 69
            || c == 43
            || c == 45) {
            whole = false;
            k = k + 1;
        } else go = false;
    }
    val numeral = doc.texts.slice(i, k).join("");
    // A whole number an `i64` holds is a `JsonInt`; `-0` (which an `i64`
    // has not) and one beyond an `i64` are read as the float they write.
    if (whole && numeral != "-0") {
        val n = numeral.parseInt();
        if (!n.isError())
            return ReadJson(value: Json.JsonInt(value: n.unwrapOr(noInt())), next: k);
    }
    val x = numeral.parseFloat();
    if (x.isError()) throw readProblem(i, "a malformed number");
    return ReadJson(value: Json.JsonFloat(value: x.unwrapOr(0.0)), next: k);
}

fn readString(doc: Reading, i: i32) -> Result<ReadText, string> {
    var out: string[] = [];
    var k = i + 1;
    var problem = "";
    var done = false;
    while (!done) {
        val c = cpAt(doc, k);
        if (c < 0) {
            problem = readProblem(k, "an unterminated string");
            done = true;
        } else if (c == 34) done = true else if (c == 92) {
            val e = cpAt(doc, k + 1);
            if (e == 117) {
                out.push(string.fromCodepoint(hexValue(doc, k + 2)));
                k = k + 6;
            } else {
                out.push(escapedChar(e));
                k = k + 2;
            }
        } else {
            out.push(doc.texts.at(k) ?? "");
            k = k + 1;
        }
    }
    if (problem != "") throw problem;
    return ReadText(text: out.join(""), next: k + 1);
}

fn escapedChar(e: i32) -> string {
    if (e == 110) return "\n";
    if (e == 114) return "\r";
    if (e == 116) return "\t";
    if (e == 98) return string.fromCodepoint(8);
    if (e == 102) return string.fromCodepoint(12);
    return string.fromCodepoint(e);
}

// The four hex digits at `i`, as a code point (no surrogate pair: a reply's
// `\u` escapes are control characters).
fn hexValue(doc: Reading, i: i32) -> i32 {
    var v = 0;
    var k = 0;
    while (k < 4) {
        val c = cpAt(doc, i + k);
        val d = if (c >= 97) c - 87 else if (c >= 65) c - 55 else c - 48;
        v = v * 16 + d;
        k = k + 1;
    }
    return v;
}

fn readArray(doc: Reading, start: i32) -> Result<ReadJson, string> {
    var items: Json[] = [];
    var i = start;
    if (cpAt(doc, i) == 93)
        return ReadJson(value: Json.JsonArray(items: items), next: i + 1);
    var more = true;
    while (more) {
        val item = readJson(doc, i);
        if (item.isError()) {
            more = false;
            i = 0 - 1;
        } else {
            val r = item.unwrapOr(ReadJson(value: Json.JsonNull, next: 0));
            items.push(r.value);
            val after = skipSpace(doc, r.next);
            if (cpAt(doc, after) == 44) i = skipSpace(doc, after + 1) else {
                more = false;
                i = if (cpAt(doc, after) == 93) after + 1 else 0 - 1 - after;
            }
        }
    }
    if (i < 0) throw readProblem(0 - 1 - i, "a malformed array");
    return ReadJson(value: Json.JsonArray(items: items), next: i);
}

fn readObject(doc: Reading, start: i32) -> Result<ReadJson, string> {
    var fields: JsonField[] = [];
    var i = start;
    if (cpAt(doc, i) == 125)
        return ReadJson(value: Json.JsonObject(fields: fields), next: i + 1);
    var more = true;
    while (more) {
        val member = readMember(doc, i);
        if (member.isError()) {
            more = false;
            i = 0 - 1;
        } else {
            val r = member.unwrapOr(ReadMember(field: JsonField(key: "", value: Json.JsonNull), next: 0));
            fields.push(r.field);
            val after = skipSpace(doc, r.next);
            if (cpAt(doc, after) == 44) i = skipSpace(doc, after + 1) else {
                more = false;
                i = if (cpAt(doc, after) == 125) after + 1 else 0 - 1 - after;
            }
        }
    }
    if (i < 0) throw readProblem(0 - 1 - i, "a malformed object");
    return ReadJson(value: Json.JsonObject(fields: fields), next: i);
}

type ReadMember(field: JsonField, next: i32)

fn readMember(doc: Reading, i: i32) -> Result<ReadMember, string> {
    if (cpAt(doc, i) != 34) throw readProblem(i, "a member without a name");
    val key = try readString(doc, i);
    val colon = skipSpace(doc, key.next);
    if (cpAt(doc, colon) != 58)
        throw readProblem(colon, "a member without `:`");
    val value = try readJson(doc, skipSpace(doc, colon + 1));
    return ReadMember(field: JsonField(key: key.text, value: value.value), next: value.next);
}

// ── reading a decoded document ────────────────────────────────────────────────

// The member `key` of an object, `null` when there is none.
pub fn jsonField(j: Json, key: string) -> ?Json {
    val fs = fieldsOf(j);
    var hit: ?Json = null;
    var i = fs.length - 1;
    while (i >= 0) {
        val f = fs.at(i) ?? JsonField(key: "", value: Json.JsonNull);
        if (f.key == key) hit = f.value;
        i = i - 1;
    }
    return hit;
}

fn textField(j: Json, key: string) -> ?string {
    val v = jsonField(j, key) ?? Json.JsonNull;
    return case v {
        JsonString(value: s) -> s;
        _ -> null;
    };
}

fn intField(j: Json, key: string) -> ?i64 {
    val v = jsonField(j, key) ?? Json.JsonNull;
    return case v {
        JsonInt(value: n) -> n;
        _ -> null;
    };
}

fn itemsOf(j: Json) -> Json[] {
    return case j {
        JsonArray(items: xs) -> xs;
        _ -> [];
    };
}

fn fieldsOf(j: Json) -> JsonField[] {
    return case j {
        JsonObject(fields: fs) -> fs;
        _ -> [];
    };
}

// ── build values ──────────────────────────────────────────────────────────────

// `v` as a template's reply writes it (`'__bp_json'/1`): `null`, a tuple as
// `{"$tuple": […]}`, a record as an object, a variant as its name.
pub fn templateValueJson(v: BuildValue) -> Json {
    return case v {
        NullValue -> Json.JsonNull;
        BoolValue(value: b) -> Json.JsonBool(value: b);
        IntValue(value: n) -> Json.JsonInt(value: n);
        FloatValue(value: x) -> Json.JsonFloat(value: x);
        StringValue(value: s) -> Json.JsonString(value: s);
        ArrayValue(items: _) -> Json.JsonArray(items: templateItems(valueItems(v)));
        TupleValue(items: _) -> tagged("$tuple", Json.JsonArray(items: templateItems(valueItems(v))));
        RecordValue(fields: _) -> Json.JsonObject(fields: templateFields(valueFields(v)));
        AtomValue(name: a) -> Json.JsonString(value: a);
        FnValue(index: _) -> Json.JsonNull;
        ResourceValue(text: t) -> Json.JsonString(value: t);
    };
}

// The template reading of a reply's JSON value: an object holding only
// `$tuple` is a tuple, any other object a record, a string a string.
pub fn templateValueOf(j: Json) -> BuildValue {
    return case j {
        JsonNull -> BuildValue.NullValue;
        JsonBool(value: b) -> BuildValue.BoolValue(value: b);
        JsonInt(value: n) -> BuildValue.IntValue(value: n);
        JsonFloat(value: x) -> BuildValue.FloatValue(value: x);
        JsonString(value: s) -> BuildValue.StringValue(value: s);
        JsonArray(items: _) -> BuildValue.ArrayValue(items: templateValuesOf(itemsOf(j)));
        JsonObject(fields: _) -> templateObjectOf(fieldsOf(j));
    };
}

fn templateObjectOf(fs: JsonField[]) -> BuildValue {
    val only = fs.at(0) ?? JsonField(key: "", value: Json.JsonNull);
    if (fs.length == 1 && only.key == "$tuple")
        return BuildValue.TupleValue(items: itemsOf(only.value).map({ x -> templateValueOf(x) }));
    return BuildValue.RecordValue(fields: fs.map({ f -> BuildField(name: f.key, value: templateValueOf(f.value)) }));
}

// Whether `v` holds a function value anywhere: OTP's `json:encode` refuses
// one, so a template that answers one replies with that refusal.
fn holdsFn(v: BuildValue) -> bool {
    return case v {
        FnValue(index: _) -> true;
        ArrayValue(items: _) -> anyHoldsFn(valueItems(v));
        TupleValue(items: _) -> anyHoldsFn(valueItems(v));
        RecordValue(fields: _) -> anyHoldsFn(valueFields(v).map({ f -> f.value }));
        _ -> false;
    };
}

// `v` as a block's reply lifts it (`'__bp_lift'/2`): every kind JSON has no
// form for in an object of its own.
pub fn blockValueJson(v: BuildValue) -> Json {
    return case v {
        NullValue -> Json.JsonNull;
        BoolValue(value: b) -> Json.JsonBool(value: b);
        IntValue(value: n) -> Json.JsonInt(value: n);
        FloatValue(value: x) -> tagged("float", Json.JsonFloat(value: x));
        StringValue(value: s) -> Json.JsonString(value: s);
        ArrayValue(items: _) -> Json.JsonArray(items: blockItems(valueItems(v)));
        TupleValue(items: _) -> tagged("tuple", Json.JsonArray(items: blockItems(valueItems(v))));
        RecordValue(fields: _) -> tagged("record", Json.JsonObject(fields: blockFields(valueFields(v))));
        AtomValue(name: a) -> tagged("atom", Json.JsonString(value: a));
        FnValue(index: i) -> tagged("fn", optionalInt(i));
        ResourceValue(text: t) -> tagged("resource", Json.JsonString(value: t));
    };
}

// The block reading of a reply's JSON value (`block_eval.readValue`).
pub fn blockValueOf(j: Json) -> BuildValue {
    return case j {
        JsonNull -> BuildValue.NullValue;
        JsonBool(value: b) -> BuildValue.BoolValue(value: b);
        JsonInt(value: n) -> BuildValue.IntValue(value: n);
        JsonFloat(value: x) -> BuildValue.FloatValue(value: x);
        JsonString(value: s) -> BuildValue.StringValue(value: s);
        JsonArray(items: _) -> BuildValue.ArrayValue(items: blockValuesOf(itemsOf(j)));
        JsonObject(fields: _) -> blockObjectOf(fieldsOf(j));
    };
}

fn blockObjectOf(fs: JsonField[]) -> BuildValue {
    val only = fs.at(0) ?? JsonField(key: "", value: Json.JsonNull);
    val inner = only.value;
    if (only.key == "float")
        return BuildValue.FloatValue(value: floatOf(inner));
    if (only.key == "tuple")
        return BuildValue.TupleValue(items: itemsOf(inner).map({ x -> blockValueOf(x) }));
    if (only.key == "record")
        return BuildValue.RecordValue(fields: fieldsOf(inner).map({ f -> BuildField(name: f.key, value: blockValueOf(f.value)) }));
    if (only.key == "atom") return BuildValue.AtomValue(name: stringOf(inner));
    if (only.key == "fn") return BuildValue.FnValue(index: intOf(inner));
    return BuildValue.ResourceValue(text: stringOf(inner));
}

fn tagged(tag: string, value: Json) -> Json {
    return Json.JsonObject(fields: [JsonField(key: tag, value: value)]);
}

// The `i64` zero an absent integer reads as.
fn noInt() -> i64 {
    return 0;
}

fn optionalInt(n: ?i64) -> Json {
    if (n != null) return Json.JsonInt(value: n);
    return Json.JsonNull;
}

fn optionalText(s: ?string) -> Json {
    if (s != null) return Json.JsonString(value: s);
    return Json.JsonNull;
}

fn floatOf(j: Json) -> f64 {
    return case j {
        JsonFloat(value: x) -> x;
        JsonInt(value: n) -> n.toF64();
        _ -> 0.0;
    };
}

fn stringOf(j: Json) -> string {
    return case j {
        JsonString(value: s) -> s;
        _ -> "";
    };
}

fn intOf(j: Json) -> ?i64 {
    return case j {
        JsonInt(value: n) -> n;
        _ -> null;
    };
}

// ── the replies ───────────────────────────────────────────────────────────────

// An object of the members whose value is not absent, ordered by name.
fn replyObject(fields: JsonField[]) -> Json {
    return jsonSorted(Json.JsonObject(fields: fields));
}

fn withPrinted(fields: JsonField[], printed: ?string) -> JsonField[] {
    var out: JsonField[] = fields.map({ f -> f });
    if (printed != null)
        out.push(JsonField(key: "printed", value: Json.JsonString(value: printed)));
    return out;
}

fn framesJson(frames: Frame[]) -> Json {
    return Json.JsonArray(items: frames.map({ f -> Json.JsonArray(items: [Json.JsonString(value: f.file), Json.JsonInt(value: f.line), Json.JsonInt(value: f.col)]) }));
}

fn framesOf(j: Json) -> Frame[] {
    return itemsOf(j).map({ f -> frameOf(itemsOf(f)) });
}

fn frameOf(parts: Json[]) -> Frame {
    return Frame(file: stringOf(parts.at(0) ?? Json.JsonNull), line: wholeOf(parts.at(1) ?? Json.JsonNull), col: wholeOf(parts.at(2) ?? Json.JsonNull));
}

// An integer's value, `0` for any other kind.
fn wholeOf(j: Json) -> i64 {
    return case j {
        JsonInt(value: n) -> n;
        _ -> noInt();
    };
}

pub fn decoratorReplyJson(r: DecoratorReply) -> Json {
    return case r {
        DecoratorOk(contributions: _, printed: p) -> replyObject(withPrinted([
            JsonField(key: "kind", value: Json.JsonString(value: "ok")),
            JsonField(key: "contributions", value: Json.JsonArray(items: contributionsJson(decoratorContributions(r)))),
        ], p));
        DecoratorFail(message: m, span: s, printed: p) -> replyObject(withPrinted([
            JsonField(key: "kind", value: Json.JsonString(value: "fail")),
            JsonField(key: "message", value: Json.JsonString(value: m)),
            JsonField(key: "span", value: failSpanJson(s)),
        ], p));
        DecoratorError(message: m, frames: _, printed: p) -> replyObject(withPrinted([
            JsonField(key: "kind", value: Json.JsonString(value: "error")),
            JsonField(key: "message", value: Json.JsonString(value: m)),
            JsonField(key: "frames", value: framesJson(decoratorFrames(r))),
        ], p));
    };
}

fn contributionsJson(cs: Contribution[]) -> Json[] {
    return cs.map({ c -> contributionJson(c) });
}

fn contributionJson(c: Contribution) -> Json {
    var fs: JsonField[] = [JsonField(key: "kind", value: Json.JsonString(value: c.kind))];
    if (c.source != null)
        fs.push(JsonField(key: "source", value: optionalText(c.source)));
    if (c.key != null)
        fs.push(JsonField(key: "key", value: optionalText(c.key)));
    if (c.value != null)
        fs.push(JsonField(key: "value", value: optionalText(c.value)));
    if (c.name != null)
        fs.push(JsonField(key: "name", value: optionalText(c.name)));
    if (c.index != null)
        fs.push(JsonField(key: "index", value: optionalInt(c.index)));
    if (c.data != null)
        fs.push(JsonField(key: "data", value: c.data ?? Json.JsonNull));
    return replyObject(fs);
}

fn failSpanJson(s: FailSpan) -> Json {
    return case s {
        NoSpan -> Json.JsonNull;
        SpanAt(start: a, end: b, line: l) -> replyObject([
            JsonField(key: "start", value: Json.JsonInt(value: a)),
            JsonField(key: "end", value: Json.JsonInt(value: b)),
            JsonField(key: "line", value: Json.JsonInt(value: l)),
        ]);
        ArgAt(index: i) -> replyObject([JsonField(key: "arg", value: Json.JsonInt(value: i))]);
    };
}

pub fn decoratorReplyOf(j: Json) -> DecoratorReply {
    val kind = textField(j, "kind") ?? "";
    val printed = textField(j, "printed");
    if (kind == "ok")
        return DecoratorReply.DecoratorOk(contributions: itemsOf(jsonField(j, "contributions") ?? Json.JsonNull).map({ c -> contributionOf(c) }), printed: printed);
    if (kind == "fail")
        return DecoratorReply.DecoratorFail(message: textField(j, "message") ?? "", span: failSpanOf(jsonField(j, "span") ?? Json.JsonNull), printed: printed);
    return DecoratorReply.DecoratorError(message: textField(j, "message") ?? "", frames: framesOf(jsonField(j, "frames") ?? Json.JsonNull), printed: printed);
}

fn contributionOf(j: Json) -> Contribution {
    return Contribution(
        kind: textField(j, "kind") ?? "",
        source: textField(j, "source"),
        key: textField(j, "key"),
        value: textField(j, "value"),
        name: textField(j, "name"),
        index: intField(j, "index"),
        data: jsonField(j, "data"),
    );
}

fn failSpanOf(j: Json) -> FailSpan {
    val arg = intField(j, "arg");
    if (arg != null) return FailSpan.ArgAt(index: arg);
    val start = intField(j, "start");
    if (start != null)
        return FailSpan.SpanAt(start: start, end: wholeOf(jsonField(j, "end") ?? Json.JsonNull), line: wholeOf(jsonField(j, "line") ?? Json.JsonNull));
    return FailSpan.NoSpan;
}

pub fn templateReplyJson(r: TemplateReply) -> Json {
    return case r {
        TemplateDone(answer: a, build: b, notes: _) -> templateDoneJson(a, b, templateNotes(r));
        TemplateNeed(request: q, span: s) -> replyObject([
            JsonField(key: "kind", value: Json.JsonString(value: "need")),
            JsonField(key: "decl", value: tagRequestJson(q)),
            JsonField(key: "span", value: templateValueJson(s)),
        ]);
        TemplateFail(message: m, param: p, span: s) -> replyObject([
            JsonField(key: "kind", value: Json.JsonString(value: "fail")),
            JsonField(key: "message", value: Json.JsonString(value: m)),
            JsonField(key: "param", value: optionalText(p)),
            JsonField(key: "span", value: templateValueJson(s)),
        ]);
        TemplateError(message: m, frames: _) -> replyObject(errorFields(m, templateFrames(r)));
    };
}

fn errorFields(message: string, frames: ?Frame[]) -> JsonField[] {
    var out: JsonField[] = [
        JsonField(key: "kind", value: Json.JsonString(value: "error")),
        JsonField(key: "message", value: Json.JsonString(value: message)),
    ];
    if (frames != null)
        out.push(JsonField(key: "frames", value: framesJson(frames)));
    return out;
}

fn templateDoneJson(a: TemplateAnswer, build: ?i64, notes: string[]) -> Json {
    val unsupported = case a {
        ValueAnswer(value: v) -> holdsFn(v);
        AstAnswer(node: v) -> holdsFn(v);
        CustomAnswer(source: _, tree: v) -> holdsFn(v);
        _ -> false;
    };
    if (unsupported)
        return replyObject(errorFields(raisedText("error", BuildValue.TupleValue(items: [BuildValue.AtomValue(name: "unsupported_type"), BuildValue.FnValue(index: null)])), null));
    var fs = case a {
        CodeAnswer(source: s) -> [JsonField(key: "kind", value: Json.JsonString(value: "code")), JsonField(key: "source", value: Json.JsonString(value: s))];
        AstAnswer(node: v) -> [JsonField(key: "kind", value: Json.JsonString(value: "ast")), JsonField(key: "node", value: templateValueJson(v))];
        ValueAnswer(value: v) -> [JsonField(key: "kind", value: Json.JsonString(value: "value")), JsonField(key: "value", value: templateValueJson(v))];
        CaptureAnswer(param: p) -> [JsonField(key: "kind", value: Json.JsonString(value: "capture")), JsonField(key: "param", value: Json.JsonString(value: p))];
        CustomAnswer(source: s, tree: v) -> [JsonField(key: "kind", value: Json.JsonString(value: "custom")), JsonField(key: "source", value: Json.JsonString(value: s)), JsonField(key: "ast", value: templateValueJson(v))];
    };
    if (build != null)
        fs.push(JsonField(key: "build", value: optionalInt(build)));
    if (notes.length > 0)
        fs.push(JsonField(key: "notes", value: Json.JsonArray(items: notes.map({ n -> Json.JsonString(value: n) }))));
    return replyObject(fs);
}

fn tagRequestJson(q: TagRequest) -> Json {
    return replyObject([
        JsonField(key: "kind", value: Json.JsonString(value: q.kind)),
        JsonField(key: "name", value: Json.JsonString(value: q.name)),
        JsonField(key: "attrs", value: Json.JsonArray(items: q.attrs.map({ a -> templateValueJson(BuildValue.TupleValue(items: [BuildValue.StringValue(value: a.name), a.value])) }))),
        JsonField(key: "answer", value: Json.JsonInt(value: q.answer)),
    ]);
}

pub fn templateReplyOf(j: Json) -> TemplateReply {
    val kind = textField(j, "kind") ?? "";
    if (kind == "need") {
        val d = jsonField(j, "decl") ?? Json.JsonNull;
        return TemplateReply.TemplateNeed(
            request: TagRequest(
                kind: textField(d, "kind") ?? "",
                name: textField(d, "name") ?? "",
                attrs: itemsOf(jsonField(d, "attrs") ?? Json.JsonNull).map({ a -> tagAttrOf(templateValueOf(a)) }),
                answer: wholeOf(jsonField(d, "answer") ?? Json.JsonNull),
            ),
            span: templateValueOf(jsonField(j, "span") ?? Json.JsonNull),
        );
    }
    if (kind == "fail")
        return TemplateReply.TemplateFail(message: textField(j, "message") ?? "", param: textField(j, "param"), span: templateValueOf(jsonField(j, "span") ?? Json.JsonNull));
    if (kind == "error") {
        val frames = jsonField(j, "frames");
        val read: ?Frame[] = if (frames == null) null else framesOf(frames);
        return TemplateReply.TemplateError(message: textField(j, "message") ?? "", frames: read);
    }
    val notes = itemsOf(jsonField(j, "notes") ?? Json.JsonNull).map({ n -> stringOf(n) });
    return TemplateReply.TemplateDone(answer: templateAnswerOf(kind, j), build: intField(j, "build"), notes: notes);
}

fn templateAnswerOf(kind: string, j: Json) -> TemplateAnswer {
    if (kind == "ast")
        return TemplateAnswer.AstAnswer(node: templateValueOf(jsonField(j, "node") ?? Json.JsonNull));
    if (kind == "value")
        return TemplateAnswer.ValueAnswer(value: templateValueOf(jsonField(j, "value") ?? Json.JsonNull));
    if (kind == "capture")
        return TemplateAnswer.CaptureAnswer(param: textField(j, "param") ?? "");
    if (kind == "custom")
        return TemplateAnswer.CustomAnswer(source: textField(j, "source") ?? "", tree: templateValueOf(jsonField(j, "ast") ?? Json.JsonNull));
    return TemplateAnswer.CodeAnswer(source: textField(j, "source") ?? "");
}

fn tagAttrOf(v: BuildValue) -> TagAttr {
    val items = case v {
        TupleValue(items: xs) -> xs;
        _ -> [];
    };
    val name = case items.at(0) ?? BuildValue.NullValue {
        StringValue(value: s) -> s;
        _ -> "";
    };
    return TagAttr(name: name, value: items.at(1) ?? BuildValue.NullValue);
}

pub fn blockReplyJson(r: BlockReply) -> Json {
    return case r {
        BlockValue(value: v, printed: p) -> replyObject(withPrinted([
            JsonField(key: "kind", value: Json.JsonString(value: "value")),
            JsonField(key: "value", value: blockValueJson(v)),
        ], p));
        BlockError(message: m, frames: _, printed: p) -> replyObject(withPrinted(errorFields(m, blockFrames(r)), p));
    };
}

pub fn blockReplyOf(j: Json) -> BlockReply {
    val printed = textField(j, "printed");
    if ((textField(j, "kind") ?? "") == "error")
        return BlockReply.BlockError(message: textField(j, "message") ?? "", frames: framesOf(jsonField(j, "frames") ?? Json.JsonNull), printed: printed);
    return BlockReply.BlockValue(value: blockValueOf(jsonField(j, "value") ?? Json.JsonNull), printed: printed);
}

// ── an error's text (1038 (3)) ────────────────────────────────────────────────

// An error reply's `message`: `{Class,Reason}` as `~p` writes it.
pub fn raisedText(class: string, reason: BuildValue) -> string {
    return termText(BuildValue.TupleValue(items: [BuildValue.AtomValue(name: class), reason]));
}

// The reason of a division or a remainder by zero (`'__bp_cdz'/1`, decision
// 533): `{bp_wat_runtime,<<"division by zero">>}`.
pub fn divisionByZero() -> BuildValue {
    return BuildValue.TupleValue(items: [BuildValue.AtomValue(name: "bp_wat_runtime"), BuildValue.StringValue(value: "division by zero")]);
}

// The reason of a `case` no arm matched: `{case_clause,Value}`.
pub fn noMatch(value: BuildValue) -> BuildValue {
    return BuildValue.TupleValue(items: [BuildValue.AtomValue(name: "case_clause"), value]);
}

// The reason of any other arithmetic error (decision 472): `badarith`.
pub fn badArith() -> BuildValue {
    return BuildValue.AtomValue(name: "badarith");
}

// `v` as `~p` writes it on one line (std-wasm's `io_lib.writeTerm`): `null`
// is `undefined`, a string a binary, a record a map with its keys in order.
pub fn termText(v: BuildValue) -> string {
    return case v {
        NullValue -> "undefined";
        BoolValue(value: b) -> boolText(b);
        IntValue(value: n) -> n.toString();
        FloatValue(value: x) -> x.toString();
        StringValue(value: s) -> binaryText(s);
        ArrayValue(items: _) -> listText(valueItems(v));
        TupleValue(items: _) -> tupleText(valueItems(v));
        RecordValue(fields: _) -> mapText(sortBuildFields(valueFields(v)));
        AtomValue(name: a) -> atomText(a);
        FnValue(index: _) -> "#Fun<bp_wat>";
        ResourceValue(text: t) -> t;
    };
}

fn sortBuildFields(fs: BuildField[]) -> BuildField[] {
    val sorted = sortFields(fs.map({ f -> JsonField(key: f.name, value: Json.JsonNull) }));
    return sorted.map({ s -> (fs.filter({ f -> f.name == s.key }).at(0) ?? BuildField(name: s.key, value: BuildValue.NullValue)) });
}

fn printableLatin1(c: i32) -> bool {
    return c >= 32 && c <= 126
        || c >= 160 && c <= 255
        || c == 10
        || c == 13
        || c == 9
        || c == 11
        || c == 8
        || c == 12
        || c == 27
        || c == 7;
}

fn printableUnicode(c: i32) -> bool {
    return printableLatin1(c)
        || c > 255
            && c <= 1114111
            && !(c >= 55296 && c <= 57343)
            && c != 65534
            && c != 65535;
}

fn escapeLetter(c: i32) -> string {
    if (c == 10) return "n";
    if (c == 13) return "r";
    if (c == 9) return "t";
    if (c == 11) return "v";
    if (c == 8) return "b";
    if (c == 12) return "f";
    if (c == 27) return "e";
    if (c == 7) return "d";
    if (c == 92) return "\\";
    return "";
}

fn termChar(c: i32, text: string) -> string {
    val letter = escapeLetter(c);
    if (letter != "") return "\\" + letter;
    if (c == 34) return "\\\"";
    return text;
}

fn binaryText(s: string) -> string {
    val cps = s.chars().map({ c -> c.charCodeAt(0) });
    val texts = s.chars();
    val ascii = cps.filter({ c -> !printableLatin1(c) || c >= 128 }).length
        == 0;
    val unicode = cps.filter({ c -> !printableUnicode(c) }).length == 0;
    if (ascii || unicode && cps.length > 0) {
        var out: string[] = ["<<\""];
        var i = 0;
        while (i < cps.length) {
            out.push(termChar(cps.at(i) ?? 0, texts.at(i) ?? ""));
            i = i + 1;
        }
        out.push(if (ascii) "\">>" else "\"/utf8>>");
        return out.join("");
    }
    return ["<<", utf8Bytes(cps)
        .map({ b -> b.toString() })
        .join(","), ">>"].join("");
}

fn utf8Bytes(cps: i32[]) -> i32[] {
    var out: i32[] = [];
    var i = 0;
    while (i < cps.length) {
        val c = cps.at(i) ?? 0;
        if (c < 128) out.push(c) else if (c < 2048) {
            out.push(192 + c / 64);
            out.push(128 + c % 64);
        } else if (c < 65536) {
            out.push(224 + c / 4096);
            out.push(128 + c / 64 % 64);
            out.push(128 + c % 64);
        } else {
            out.push(240 + c / 262144);
            out.push(128 + c / 4096 % 64);
            out.push(128 + c / 64 % 64);
            out.push(128 + c % 64);
        }
        i = i + 1;
    }
    return out;
}

fn listText(xs: BuildValue[]) -> string {
    if (xs.length == 0) return "[]";
    val codes = xs.filter({ x -> printableCode(x) }).length == xs.length;
    if (codes)
        return ["\"", xs
            .map({ x -> termChar(codeOf(x), string.fromCodepoint(codeOf(x))) })
            .join(""), "\""].join("");
    return ["[", xs.map({ x -> termText(x) }).join(","), "]"].join("");
}

fn printableCode(v: BuildValue) -> bool {
    return case v {
        IntValue(value: n) -> n >= 0
            && n <= 1114111
            && printableUnicode(n.toI32());
        _ -> false;
    };
}

fn codeOf(v: BuildValue) -> i32 {
    return case v {
        IntValue(value: n) -> n.toI32();
        _ -> 0;
    };
}

fn atomText(name: string) -> string {
    val cps = name.chars().map({ c -> c.charCodeAt(0) });
    val first = cps.at(0) ?? 0;
    val plain = cps.length > 0
        && first >= 97
        && first <= 122
        && cps.filter({ c -> !(c >= 97 && c <= 122 || c >= 65 && c <= 90 || c >= 48 && c <= 57 || c == 95 || c == 64) }).length
            == 0
        && !reservedWord(name);
    if (plain) return name;
    val texts = name.chars();
    var out: string[] = ["'"];
    var i = 0;
    while (i < cps.length) {
        val c = cps.at(i) ?? 0;
        if (c == 39 || c == 92) out.push("\\");
        out.push(texts.at(i) ?? "");
        i = i + 1;
    }
    out.push("'");
    return out.join("");
}

fn reservedWord(name: string) -> bool {
    return ["after", "and", "andalso", "band", "begin", "bnot", "bor", "bsl", "bsr", "bxor", "case", "catch", "cond", "div", "end", "fun", "if", "let", "maybe", "not", "of", "or", "orelse", "receive", "rem", "try", "when", "xor", "else"].filter({ w -> w == name }).length
        > 0;
}

fn arrayText(xs: Json[]) -> string {
    return ["[", xs.map({ x -> jsonText(x) }).join(","), "]"].join("");
}

fn objectText(fs: JsonField[]) -> string {
    return ["{", fs
        .map({ f -> [quoteJson(f.key, true), ":", jsonText(f.value)].join("") })
        .join(","), "}"].join("");
}

fn sortedItems(xs: Json[]) -> Json[] {
    return xs.map({ x -> jsonSorted(x) });
}

fn sortedMembers(fs: JsonField[]) -> JsonField[] {
    return fs.map({ f -> JsonField(key: f.key, value: jsonSorted(f.value)) });
}

fn prettyArray(xs: Json[], indent: string) -> string {
    if (xs.length == 0) return "[]";
    val inner = indent + "  ";
    return ["[\n", xs
        .map({ x -> inner + prettyAt(x, inner) })
        .join(",\n"), "\n", indent, "]"].join("");
}

fn prettyObject(fs: JsonField[], indent: string) -> string {
    if (fs.length == 0) return "{}";
    val inner = indent + "  ";
    return ["{\n", fs
        .map({ f -> [inner, quoteJson(f.key, false), ": ", prettyAt(f.value, inner)].join("") })
        .join(",\n"), "\n", indent, "}"].join("");
}

// The items of an array or a tuple, `[]` for any other value.
fn valueItems(v: BuildValue) -> BuildValue[] {
    return case v {
        ArrayValue(items: xs) -> xs;
        TupleValue(items: xs) -> xs;
        _ -> [];
    };
}

// The fields of a record, `[]` for any other value.
fn valueFields(v: BuildValue) -> BuildField[] {
    return case v {
        RecordValue(fields: fs) -> fs;
        _ -> [];
    };
}

fn templateItems(xs: BuildValue[]) -> Json[] {
    return xs.map({ x -> templateValueJson(x) });
}

fn templateFields(fs: BuildField[]) -> JsonField[] {
    return fs.map({ f -> JsonField(key: f.name, value: templateValueJson(f.value)) });
}

fn templateValuesOf(xs: Json[]) -> BuildValue[] {
    return xs.map({ x -> templateValueOf(x) });
}

fn anyHoldsFn(xs: BuildValue[]) -> bool {
    return xs.filter({ x -> holdsFn(x) }).length > 0;
}

fn blockItems(xs: BuildValue[]) -> Json[] {
    return xs.map({ x -> blockValueJson(x) });
}

fn blockFields(fs: BuildField[]) -> JsonField[] {
    return fs.map({ f -> JsonField(key: f.name, value: blockValueJson(f.value)) });
}

fn blockValuesOf(xs: Json[]) -> BuildValue[] {
    return xs.map({ x -> blockValueOf(x) });
}

fn tupleText(xs: BuildValue[]) -> string {
    return ["{", xs.map({ x -> termText(x) }).join(","), "}"].join("");
}

fn mapText(fs: BuildField[]) -> string {
    return ["#{", fs
        .map({ f -> [atomText(f.name), " => ", termText(f.value)].join("") })
        .join(","), "}"].join("");
}

fn decoratorContributions(r: DecoratorReply) -> Contribution[] {
    return case r {
        DecoratorOk(contributions: cs, printed: _) -> cs;
        _ -> [];
    };
}

fn decoratorFrames(r: DecoratorReply) -> Frame[] {
    return case r {
        DecoratorError(message: _, frames: fs, printed: _) -> fs;
        _ -> [];
    };
}

fn templateNotes(r: TemplateReply) -> string[] {
    return case r {
        TemplateDone(answer: _, build: _, notes: ns) -> ns;
        _ -> [];
    };
}

fn templateFrames(r: TemplateReply) -> ?Frame[] {
    return case r {
        TemplateError(message: _, frames: fs) -> fs;
        _ -> null;
    };
}

fn blockFrames(r: BlockReply) -> Frame[] {
    return case r {
        BlockError(message: _, frames: fs, printed: _) -> fs;
        _ -> [];
    };
}

// ── what crosses in (decisions 1035 (4), 1058 (1)) ───────────────────────────
// The input of an evaluation, JSON in the core unit's memory: each value the
// Erlang path hands a body as a term (C0's I1–I9) with one spelling — a map an
// object of the same keys, a binary a string, an atom a string (`kind`,
// `stage`), `undefined` `null`, a tuple an array; a typed meta value (I5),
// whose type is the body's, as a template's value is written (`{"$tuple":
// […]}`, a variant its name). A key the Erlang path writes only when it holds
// something (a capture's `value`, `holes`, `__bp_annotations`) is written only
// then. Each shape has a reader (`…Of(Json)`) and a writer (`…Json`); the
// records are closed — no `unknown` —: the reflection records a body reads
// (`Field`, `Method`, `Variant`, `Param`, `DeclAnnotation`, `DeclKind`) are
// the ones declared above under their public names (decision 1071 (1)), the
// kind and the stage enums written as their variants' names; what has no
// public name of its own (`HookNode`, `Declared`, `TypeInfo`) crosses as an
// `…Entry` record.

// One typed meta value a decorator recorded (decision 298): the record type's
// name and its value (JSON key `type`).
pub type MetaEntry(typeName: string, value: BuildValue)

// One string meta entry of a declaration (`<decorator>.<key>`).
pub type MetaPair(key: string, value: string)

// A declaration a hook reads (`Declared<unknown>`): its `value` is `null` at
// build (decision 364 (3)), so it does not cross.
pub type DeclaredEntry(
    name: string,
    module: string,
    meta: MetaPair[],
    returnTypeName: string,
)

// A `use`'s explicit type argument (`TypeInfo<unknown>`).
pub type TypeArgEntry(
    name: string,
    module: string,
    fields: Field[],
    methods: Method[],
    meta: MetaPair[],
    methodMeta: MethodMeta[],
)

pub type HookUseEntry(
    hook: ?DeclaredEntry,
    annotations: DeclAnnotation[],
    at: string,
    typeArgs: TypeArgEntry[],
    context: ?DeclaredEntry,
)

pub type HookCallEntry(callee: ?DeclaredEntry, at: string)

// One node of `compiler.hooks(d)` (decisions 277, 375, 376); `stage` is
// `Build`, `Run` or `Any`.
pub type HookEntry(
    function: DeclaredEntry,
    uses: HookUseEntry[],
    calls: HookCallEntry[],
    async: bool,
    stage: Stage,
)

// The typed meta values a method's decorators recorded (decision 298),
// what `compiler.meta<M>(m)` reads: they cross beside the method, in its
// JSON object, and the codec keeps them here by the method's name — `Method`
// holds the compiler's reflection fields alone (decision 1075 (1)).
pub type MethodMeta(method: string, meta: MetaEntry[])

// What a handle `compiler.lookup` answered carries (decision 415 (2)): the
// typed meta its decorators recorded — `pending` while they have not run
// (`{'__bp_pending', Name}`) —, its identity and the name the scope spells.
pub type DeclLookup(
    meta: MetaEntry[],
    pending: bool,
    identity: string,
    local: string,
)

// What a tag's handle carries (decision 302): its static attributes and the
// typed meta recorded on it.
pub type AttrEntry(name: string, value: string)

pub type DeclTag(attrs: AttrEntry[], meta: MetaEntry[])

// The declaration handle a comptime body reads (decisions 576 (3), 1058 (1)):
// C0's I3 fields, `component` and `owner` optional, `lookup` on a handle
// `compiler.lookup` answered, `tag` on a tag's. Opaque: only `declOf` builds
// one, and no program reads a field — the checker types `syntax decl` as
// `unknown` and reads it through `compiler.X(decl)`; after the check, the
// erased body's lowering declares the handle as this type and each
// `compiler.X(decl)` becomes a read of its field.
pub opaque type Decl(
    kind: DeclKind,
    name: string,
    fields: Field[],
    variants: Variant[],
    methods: Method[],
    methodMeta: MethodMeta[],
    returnType: string,
    annotations: DeclAnnotation[],
    hooks: HookEntry[],
    params: Param[],
    component: ?Decl,
    module: string,
    owner: ?DeclaredEntry,
    package: string,
    lookup: ?DeclLookup,
    tag: ?DeclTag,
) {
    fn of(j: Json) -> Decl {
        val component = jsonField(j, "component") ?? Json.JsonNull;
        val owner = jsonField(j, "owner") ?? Json.JsonNull;
        return Decl(
            kind: declKindOf(textField(j, "kind") ?? ""),
            name: textField(j, "name") ?? "",
            fields: fieldListOf(jsonField(j, "fields") ?? Json.JsonNull),
            variants: itemsOf(jsonField(j, "variants") ?? Json.JsonNull).map({ v -> variantOf(v) }),
            methods: methodListOf(jsonField(j, "methods") ?? Json.JsonNull),
            methodMeta: methodMetaListOf(jsonField(j, "methods") ?? Json.JsonNull),
            returnType: textField(j, "returnType") ?? "",
            annotations: declAnnotationListOf(jsonField(j, "annotations") ?? Json.JsonNull),
            hooks: itemsOf(jsonField(j, "hooks") ?? Json.JsonNull).map({ h -> hookEntryOf(h) }),
            params: paramListOf(jsonField(j, "params") ?? Json.JsonNull),
            component: if (isNull(component)) null else Decl.of(component),
            module: textField(j, "module") ?? "",
            owner: if (isNull(owner)) null else declaredEntryOf(owner),
            package: textField(j, "package") ?? "",
            lookup: declLookupOf(j),
            tag: declTagOf(j),
        );
    }

    // The handle as the input writes it, its keys in the Erlang path's
    // order.
    fn json(self: Self) -> Json {
        var fs: JsonField[] = [
            JsonField(key: "kind", value: Json.JsonString(value: declKindName(self.kind))),
            JsonField(key: "name", value: Json.JsonString(value: self.name)),
            JsonField(key: "fields", value: fieldListJson(self.fields)),
            JsonField(key: "variants", value: Json.JsonArray(items: self.variants.map({ v -> variantJson(v) }))),
            JsonField(key: "methods", value: methodListJson(self.methods, self.methodMeta)),
            JsonField(key: "returnType", value: Json.JsonString(value: self.returnType)),
            JsonField(key: "annotations", value: declAnnotationListJson(self.annotations)),
            JsonField(key: "hooks", value: Json.JsonArray(items: self.hooks.map({ h -> hookEntryJson(h) }))),
            JsonField(key: "params", value: paramListJson(self.params)),
            JsonField(key: "component", value: optionalDeclJson(self.component)),
            JsonField(key: "module", value: Json.JsonString(value: self.module)),
            JsonField(key: "owner", value: optionalDeclaredJson(self.owner)),
            JsonField(key: "package", value: Json.JsonString(value: self.package)),
        ];
        val lookup = self.lookup;
        if (lookup != null) {
            fs.push(JsonField(key: "meta", value: if (lookup.pending)
                Json.JsonArray(items: [Json.JsonString(value: "__bp_pending"), Json.JsonString(value: self.name)])
            else
                metaEntriesJson(lookup.meta)));
            fs.push(JsonField(key: "identity", value: Json.JsonString(value: lookup.identity)));
            fs.push(JsonField(key: "local", value: Json.JsonString(value: lookup.local)));
        }
        val tag = self.tag;
        if (tag != null) {
            fs.push(JsonField(key: "attrs", value: Json.JsonArray(items: tag.attrs.map({ a -> Json.JsonArray(items: [Json.JsonString(value: a.name), Json.JsonString(value: a.value)]) }))));
            fs.push(JsonField(key: "meta", value: metaEntriesJson(tag.meta)));
        }
        return Json.JsonObject(fields: fs);
    }

    // The scope's view of a handle a capture's binding holds.
    fn binding(self: Self) -> Binding {
        val lookup = self.lookup;
        val identity = if (lookup != null) lookup.identity else "";
        val local = if (lookup != null) lookup.local else self.name;
        return Binding(name: self.name, kind: declKindName(self.kind), identity: identity, local: local, handle: self);
    }
}

// A `DeclKind` crosses as its variant's name (`"Fn"`); the Erlang path
// writes no other.
fn declKindOf(name: string) -> DeclKind {
    if (name == "Behavior") return DeclKind.Behavior;
    if (name == "Fn") return DeclKind.Fn;
    if (name == "Method") return DeclKind.Method;
    if (name == "Field") return DeclKind.Field;
    if (name == "Val") return DeclKind.Val;
    if (name == "Element") return DeclKind.Element;
    if (name == "Component") return DeclKind.Component;
    return DeclKind.Type;
}

fn declKindName(k: DeclKind) -> string {
    return case k {
        Type -> "Type";
        Behavior -> "Behavior";
        Fn -> "Fn";
        Method -> "Method";
        Field -> "Field";
        Val -> "Val";
        Element -> "Element";
        Component -> "Component";
    };
}

// The handle `j` holds (decision 792 (3)'s opaque shape: the one way to build
// a `Decl`).
pub fn declOf(j: Json) -> Decl {
    return Decl.of(j);
}

pub fn declJson(d: Decl) -> Json {
    return d.json();
}

fn optionalDeclJson(d: ?Decl) -> Json {
    if (d != null) return d.json();
    return Json.JsonNull;
}

fn isNull(j: Json) -> bool {
    return case j {
        JsonNull -> true;
        _ -> false;
    };
}

fn isArray(j: Json) -> bool {
    return case j {
        JsonArray(items: _) -> true;
        _ -> false;
    };
}

fn boolField(j: Json, key: string) -> bool {
    val v = jsonField(j, key) ?? Json.JsonNull;
    return case v {
        JsonBool(value: b) -> b;
        _ -> false;
    };
}

fn textsOfJson(j: Json) -> string[] {
    return itemsOf(j).map({ x -> stringOf(x) });
}

fn textsJson(xs: string[]) -> Json {
    return Json.JsonArray(items: xs.map({ x -> Json.JsonString(value: x) }));
}

pub fn declAnnotationOf(j: Json) -> DeclAnnotation {
    return DeclAnnotation(name: textField(j, "name") ?? "", args: textsOfJson(jsonField(j, "args") ?? Json.JsonNull), decorator: textField(j, "decorator") ?? "");
}

pub fn declAnnotationJson(a: DeclAnnotation) -> Json {
    return Json.JsonObject(fields: [
        JsonField(key: "name", value: Json.JsonString(value: a.name)),
        JsonField(key: "args", value: textsJson(a.args)),
        JsonField(key: "decorator", value: Json.JsonString(value: a.decorator)),
    ]);
}

fn declAnnotationListOf(j: Json) -> DeclAnnotation[] {
    return itemsOf(j).map({ a -> declAnnotationOf(a) });
}

fn declAnnotationListJson(xs: DeclAnnotation[]) -> Json {
    return Json.JsonArray(items: xs.map({ a -> declAnnotationJson(a) }));
}

fn paramListOf(j: Json) -> Param[] {
    return itemsOf(j).map({ p -> Param(name: textField(p, "name") ?? "", typeName: textField(p, "typeName") ?? "") });
}

fn paramListJson(xs: Param[]) -> Json {
    return Json.JsonArray(items: xs.map({ p -> Json.JsonObject(fields: [JsonField(key: "name", value: Json.JsonString(value: p.name)), JsonField(key: "typeName", value: Json.JsonString(value: p.typeName))]) }));
}

pub fn fieldOf(j: Json) -> Field {
    return Field(name: textField(j, "name") ?? "", typeName: textField(j, "typeName") ?? "", annotations: declAnnotationListOf(jsonField(j, "annotations") ?? Json.JsonNull));
}

pub fn fieldJson(f: Field) -> Json {
    return Json.JsonObject(fields: [
        JsonField(key: "name", value: Json.JsonString(value: f.name)),
        JsonField(key: "typeName", value: Json.JsonString(value: f.typeName)),
        JsonField(key: "annotations", value: declAnnotationListJson(f.annotations)),
    ]);
}

fn fieldListOf(j: Json) -> Field[] {
    return itemsOf(j).map({ f -> fieldOf(f) });
}

fn fieldListJson(xs: Field[]) -> Json {
    return Json.JsonArray(items: xs.map({ f -> fieldJson(f) }));
}

// A typed meta value (I5): `{"type": name, "value": v}`, `v` written as a
// template's value is.
pub fn metaEntryOf(j: Json) -> MetaEntry {
    return MetaEntry(typeName: textField(j, "type") ?? "", value: templateValueOf(jsonField(j, "value") ?? Json.JsonNull));
}

pub fn metaEntryJson(m: MetaEntry) -> Json {
    return Json.JsonObject(fields: [
        JsonField(key: "type", value: Json.JsonString(value: m.typeName)),
        JsonField(key: "value", value: templateValueJson(m.value)),
    ]);
}

fn metaEntriesOf(j: Json) -> MetaEntry[] {
    return itemsOf(j).map({ m -> metaEntryOf(m) });
}

fn metaEntriesJson(xs: MetaEntry[]) -> Json {
    return Json.JsonArray(items: xs.map({ m -> metaEntryJson(m) }));
}

pub fn methodOf(j: Json) -> Method {
    return Method(
        name: textField(j, "name") ?? "",
        params: paramListOf(jsonField(j, "params") ?? Json.JsonNull),
        returnType: textField(j, "returnType") ?? "",
        annotations: declAnnotationListOf(jsonField(j, "annotations") ?? Json.JsonNull),
    );
}

// A method as the input writes it, its meta (`meta`, the last key) the one
// `metas` keeps under its name, `[]` when none.
pub fn methodJson(m: Method, metas: MethodMeta[]) -> Json {
    return Json.JsonObject(fields: [
        JsonField(key: "name", value: Json.JsonString(value: m.name)),
        JsonField(key: "params", value: paramListJson(m.params)),
        JsonField(key: "returnType", value: Json.JsonString(value: m.returnType)),
        JsonField(key: "annotations", value: declAnnotationListJson(m.annotations)),
        JsonField(key: "meta", value: metaEntriesJson(metaOfMethod(m.name, metas))),
    ]);
}

fn metaOfMethod(name: string, metas: MethodMeta[]) -> MetaEntry[] {
    val found = metas.filter({ mm -> mm.method == name });
    if (found.length == 0) return [];
    return found[0]!.meta;
}

fn methodMetaListOf(j: Json) -> MethodMeta[] {
    return itemsOf(j).map({ m -> MethodMeta(method: textField(m, "name") ?? "", meta: metaEntriesOf(jsonField(m, "meta") ?? Json.JsonNull)) });
}

fn methodListOf(j: Json) -> Method[] {
    return itemsOf(j).map({ m -> methodOf(m) });
}

fn methodListJson(xs: Method[], metas: MethodMeta[]) -> Json {
    return Json.JsonArray(items: xs.map({ m -> methodJson(m, metas) }));
}

pub fn variantOf(j: Json) -> Variant {
    return Variant(
        name: textField(j, "name") ?? "",
        fields: fieldListOf(jsonField(j, "fields") ?? Json.JsonNull),
        annotations: declAnnotationListOf(jsonField(j, "annotations") ?? Json.JsonNull),
        section: textField(j, "section"),
    );
}

pub fn variantJson(v: Variant) -> Json {
    return Json.JsonObject(fields: [
        JsonField(key: "name", value: Json.JsonString(value: v.name)),
        JsonField(key: "fields", value: fieldListJson(v.fields)),
        JsonField(key: "annotations", value: declAnnotationListJson(v.annotations)),
        JsonField(key: "section", value: optionalText(v.section)),
    ]);
}

fn metaPairsOf(j: Json) -> MetaPair[] {
    return itemsOf(j).map({ m -> MetaPair(key: textField(m, "key") ?? "", value: textField(m, "value") ?? "") });
}

fn metaPairsJson(xs: MetaPair[]) -> Json {
    return Json.JsonArray(items: xs.map({ m -> Json.JsonObject(fields: [JsonField(key: "key", value: Json.JsonString(value: m.key)), JsonField(key: "value", value: Json.JsonString(value: m.value))]) }));
}

pub fn declaredEntryOf(j: Json) -> DeclaredEntry {
    return DeclaredEntry(
        name: textField(j, "name") ?? "",
        module: textField(j, "module") ?? "",
        meta: metaPairsOf(jsonField(j, "meta") ?? Json.JsonNull),
        returnTypeName: textField(j, "returnTypeName") ?? "",
    );
}

pub fn declaredEntryJson(d: DeclaredEntry) -> Json {
    return Json.JsonObject(fields: [
        JsonField(key: "name", value: Json.JsonString(value: d.name)),
        JsonField(key: "module", value: Json.JsonString(value: d.module)),
        JsonField(key: "meta", value: metaPairsJson(d.meta)),
        JsonField(key: "returnTypeName", value: Json.JsonString(value: d.returnTypeName)),
        JsonField(key: "value", value: Json.JsonNull),
    ]);
}

fn optionalDeclaredOf(j: ?Json) -> ?DeclaredEntry {
    val v = j ?? Json.JsonNull;
    if (isNull(v)) return null;
    return declaredEntryOf(v);
}

fn optionalDeclaredJson(d: ?DeclaredEntry) -> Json {
    if (d != null) return declaredEntryJson(d);
    return Json.JsonNull;
}

fn typeArgEntryOf(j: Json) -> TypeArgEntry {
    return TypeArgEntry(
        name: textField(j, "name") ?? "",
        module: textField(j, "module") ?? "",
        fields: fieldListOf(jsonField(j, "fields") ?? Json.JsonNull),
        methods: methodListOf(jsonField(j, "methods") ?? Json.JsonNull),
        meta: metaPairsOf(jsonField(j, "meta") ?? Json.JsonNull),
        methodMeta: methodMetaListOf(jsonField(j, "methods") ?? Json.JsonNull),
    );
}

fn typeArgEntryJson(t: TypeArgEntry) -> Json {
    return Json.JsonObject(fields: [
        JsonField(key: "name", value: Json.JsonString(value: t.name)),
        JsonField(key: "module", value: Json.JsonString(value: t.module)),
        JsonField(key: "fields", value: fieldListJson(t.fields)),
        JsonField(key: "methods", value: methodListJson(t.methods, t.methodMeta)),
        JsonField(key: "meta", value: metaPairsJson(t.meta)),
    ]);
}

fn hookUseEntryOf(j: Json) -> HookUseEntry {
    return HookUseEntry(
        hook: optionalDeclaredOf(jsonField(j, "hook")),
        annotations: declAnnotationListOf(jsonField(j, "annotations") ?? Json.JsonNull),
        at: textField(j, "at") ?? "",
        typeArgs: itemsOf(jsonField(j, "typeArgs") ?? Json.JsonNull).map({ t -> typeArgEntryOf(t) }),
        context: optionalDeclaredOf(jsonField(j, "context")),
    );
}

fn hookUseEntryJson(u: HookUseEntry) -> Json {
    return Json.JsonObject(fields: [
        JsonField(key: "hook", value: optionalDeclaredJson(u.hook)),
        JsonField(key: "annotations", value: declAnnotationListJson(u.annotations)),
        JsonField(key: "at", value: Json.JsonString(value: u.at)),
        JsonField(key: "typeArgs", value: Json.JsonArray(items: u.typeArgs.map({ t -> typeArgEntryJson(t) }))),
        JsonField(key: "context", value: optionalDeclaredJson(u.context)),
    ]);
}

// A `Stage` crosses as its variant's name (`"Run"`).
fn stageOf(name: string) -> Stage {
    if (name == "Build") return Stage.Build;
    if (name == "Run") return Stage.Run;
    return Stage.Any;
}

fn stageName(s: Stage) -> string {
    return case s {
        Build -> "Build";
        Run -> "Run";
        Any -> "Any";
    };
}

pub fn hookEntryOf(j: Json) -> HookEntry {
    return HookEntry(
        function: declaredEntryOf(jsonField(j, "function") ?? Json.JsonNull),
        uses: itemsOf(jsonField(j, "uses") ?? Json.JsonNull).map({ u -> hookUseEntryOf(u) }),
        calls: itemsOf(jsonField(j, "calls") ?? Json.JsonNull).map({ c -> HookCallEntry(callee: optionalDeclaredOf(jsonField(c, "callee")), at: textField(c, "at") ?? "") }),
        async: boolField(j, "async"),
        stage: stageOf(textField(j, "stage") ?? ""),
    );
}

pub fn hookEntryJson(h: HookEntry) -> Json {
    return Json.JsonObject(fields: [
        JsonField(key: "function", value: declaredEntryJson(h.function)),
        JsonField(key: "uses", value: Json.JsonArray(items: h.uses.map({ u -> hookUseEntryJson(u) }))),
        JsonField(key: "calls", value: Json.JsonArray(items: h.calls.map({ c -> Json.JsonObject(fields: [JsonField(key: "callee", value: optionalDeclaredJson(c.callee)), JsonField(key: "at", value: Json.JsonString(value: c.at))]) }))),
        JsonField(key: "async", value: Json.JsonBool(value: h.async)),
        JsonField(key: "stage", value: Json.JsonString(value: stageName(h.stage))),
    ]);
}

// A lookup handle's three keys, when `identity` is there; its `meta` the
// pending pair `["__bp_pending", name]` while its decorators have not run.
fn declLookupOf(j: Json) -> ?DeclLookup {
    if (textField(j, "identity") == null || jsonField(j, "attrs") != null)
        return null;
    val identity = textField(j, "identity") ?? "";
    val meta = jsonField(j, "meta") ?? Json.JsonNull;
    val first = itemsOf(meta).at(0) ?? Json.JsonNull;
    val pending = case first {
        JsonString(value: s) -> s == "__bp_pending";
        _ -> false;
    };
    return DeclLookup(meta: if (pending)
        []
    else
        metaEntriesOf(meta), pending: pending, identity: identity, local: textField(j, "local") ?? "");
}

fn declTagOf(j: Json) -> ?DeclTag {
    if (jsonField(j, "attrs") == null) return null;
    val attrs = jsonField(j, "attrs") ?? Json.JsonNull;
    return DeclTag(
        attrs: itemsOf(attrs).map({ a -> AttrEntry(name: stringOf(itemsOf(a).at(0) ?? Json.JsonNull), value: stringOf(itemsOf(a).at(1) ?? Json.JsonNull)) }),
        meta: metaEntriesOf(jsonField(j, "meta") ?? Json.JsonNull),
    );
}

// ── a template's capture (I7, I8) ─────────────────────────────────────────────

pub type CaptureSource(file: string, line: i64, col: i64, root: string)

pub type CaptureContext(source: CaptureSource, text: string, multiline: bool)

// A word of the text the scope binds (decision 237): the declaration's name,
// kind, identity and the name the scope spells, or the whole handle when the
// call site computed it (decision 415 (2)).
pub type Binding(
    name: string,
    kind: string,
    identity: string,
    local: string,
    handle: ?Decl,
)

// A tag answer `compiler.annotate` has had (decision 302): the tag's handle
// and the answer's index (`'__bp_answer'`).
pub type TagAnswer(decl: Decl, answer: i64)

// A `syntax` parameter's capture (`'__bp_capture'` the parameter's name):
// `value` the literal's text when the body reads it, `holes` each `${…}` a
// capture of its own (decision 637), `annotations` the tag answers so far.
pub type Capture(
    param: string,
    text: string,
    source: CaptureSource,
    context: CaptureContext,
    bindings: Binding[],
    words: string[],
    name: ?string,
    value: ?string,
    holes: Capture[],
    annotations: TagAnswer[],
)

fn captureSourceOf(j: Json) -> CaptureSource {
    return CaptureSource(file: textField(j, "file") ?? "", line: wholeOf(jsonField(j, "line") ?? Json.JsonNull), col: wholeOf(jsonField(j, "col") ?? Json.JsonNull), root: textField(j, "root") ?? "");
}

fn captureSourceJson(s: CaptureSource) -> Json {
    return Json.JsonObject(fields: [
        JsonField(key: "file", value: Json.JsonString(value: s.file)),
        JsonField(key: "line", value: Json.JsonInt(value: s.line)),
        JsonField(key: "col", value: Json.JsonInt(value: s.col)),
        JsonField(key: "root", value: Json.JsonString(value: s.root)),
    ]);
}

pub fn bindingOf(j: Json) -> Binding {
    if (jsonField(j, "fields") != null) return Decl.of(j).binding();
    return Binding(name: textField(j, "name") ?? "", kind: textField(j, "kind") ?? "", identity: textField(j, "identity") ?? "", local: textField(j, "local") ?? "", handle: null);
}

pub fn bindingJson(b: Binding) -> Json {
    val handle = b.handle;
    if (handle != null) return handle.json();
    return Json.JsonObject(fields: [
        JsonField(key: "name", value: Json.JsonString(value: b.name)),
        JsonField(key: "kind", value: Json.JsonString(value: b.kind)),
        JsonField(key: "identity", value: Json.JsonString(value: b.identity)),
        JsonField(key: "local", value: Json.JsonString(value: b.local)),
    ]);
}

pub fn captureOf(j: Json) -> Capture {
    val context = jsonField(j, "context") ?? Json.JsonNull;
    return Capture(
        param: textField(j, "__bp_capture") ?? "",
        text: textField(j, "text") ?? "",
        source: captureSourceOf(jsonField(j, "source") ?? Json.JsonNull),
        context: CaptureContext(source: captureSourceOf(jsonField(context, "source") ?? Json.JsonNull), text: textField(context, "text") ?? "", multiline: boolField(context, "multiline")),
        bindings: itemsOf(jsonField(j, "bindings") ?? Json.JsonNull).map({ b -> bindingOf(b) }),
        words: textsOfJson(jsonField(j, "words") ?? Json.JsonNull),
        name: textField(j, "name"),
        value: textField(j, "value"),
        holes: itemsOf(jsonField(j, "holes") ?? Json.JsonNull).map({ h -> captureOf(h) }),
        annotations: itemsOf(jsonField(j, "__bp_annotations") ?? Json.JsonNull).map({ a -> TagAnswer(decl: Decl.of(a), answer: wholeOf(jsonField(a, "__bp_answer") ?? Json.JsonNull)) }),
    );
}

pub fn captureJson(c: Capture) -> Json {
    var fs: JsonField[] = [
        JsonField(key: "__bp_capture", value: Json.JsonString(value: c.param)),
        JsonField(key: "text", value: Json.JsonString(value: c.text)),
        JsonField(key: "source", value: captureSourceJson(c.source)),
        JsonField(key: "context", value: Json.JsonObject(fields: [
            JsonField(key: "source", value: captureSourceJson(c.context.source)),
            JsonField(key: "text", value: Json.JsonString(value: c.context.text)),
            JsonField(key: "multiline", value: Json.JsonBool(value: c.context.multiline)),
        ])),
        JsonField(key: "bindings", value: Json.JsonArray(items: c.bindings.map({ b -> bindingJson(b) }))),
        JsonField(key: "words", value: textsJson(c.words)),
        JsonField(key: "name", value: optionalText(c.name)),
    ];
    if (c.value != null)
        fs.push(JsonField(key: "value", value: optionalText(c.value)));
    if (c.holes.length > 0)
        fs.push(JsonField(key: "holes", value: Json.JsonArray(items: c.holes.map({ h -> captureJson(h) }))));
    if (c.annotations.length > 0)
        fs.push(JsonField(key: "__bp_annotations", value: Json.JsonArray(items: c.annotations.map({ a -> tagAnswerJson(a) }))));
    return Json.JsonObject(fields: fs);
}

fn tagAnswerJson(a: TagAnswer) -> Json {
    var fs = fieldsOf(a.decl.json());
    fs.push(JsonField(key: "__bp_answer", value: Json.JsonInt(value: a.answer)));
    return Json.JsonObject(fields: fs);
}

// ── the main argument (I1, I2) ────────────────────────────────────────────────

// One parameter's slot of `main`'s argument: the annotated declaration's
// handle, a `syntax` parameter's capture, a plain value (a string, a bool, a
// number, a literal's raw source as a string), or nothing — the literal stays
// in the module.
pub type InputArg {
    HandleArg(decl: Decl),
    CaptureArg(capture: Capture),
    PlainArg(value: BuildValue),
    Unbound,
}

// A plain argument's text as written and the name it is written as
// (`compiler.text(x)` / `compiler.name(x)` of a decorator's argument,
// decision 576 (2)).
pub type ArgText(text: string, name: ?string)

// What an evaluation is handed: one slot per parameter of the body (none
// for a `comptime { }` block), and, for a decorator whose body reads
// `compiler.text`, the texts of its plain arguments — the JSON then the pair
// `[[slots…], [[text, name]…]]`.
pub type Input(args: InputArg[], texts: ?ArgText[])

pub fn argOf(j: Json) -> InputArg {
    return case j {
        JsonNull -> InputArg.Unbound;
        JsonObject(fields: _) -> objectArgOf(j);
        _ -> InputArg.PlainArg(value: templateValueOf(j));
    };
}

fn objectArgOf(j: Json) -> InputArg {
    if (jsonField(j, "__bp_capture") != null)
        return InputArg.CaptureArg(capture: captureOf(j));
    return InputArg.HandleArg(decl: Decl.of(j));
}

pub fn argJson(a: InputArg) -> Json {
    return case a {
        HandleArg(decl: d) -> d.json();
        CaptureArg(capture: c) -> captureJson(c);
        PlainArg(value: v) -> templateValueJson(v);
        Unbound -> Json.JsonNull;
    };
}

pub fn inputOf(j: Json) -> Input {
    val items = itemsOf(j);
    val first = items.at(0) ?? Json.JsonNull;
    val paired = items.length == 2 && isArray(first);
    if (paired)
        return Input(args: itemsOf(first).map({ a -> argOf(a) }), texts: itemsOf(items.at(1) ?? Json.JsonNull).map({ t -> argTextOf(t) }));
    return Input(args: items.map({ a -> argOf(a) }), texts: null);
}

fn argTextOf(j: Json) -> ArgText {
    val pair = itemsOf(j);
    val name = pair.at(1) ?? Json.JsonNull;
    return ArgText(text: stringOf(pair.at(0) ?? Json.JsonNull), name: if (isNull(name))
        null
    else
        stringOf(name));
}

pub fn inputJson(i: Input) -> Json {
    val args = Json.JsonArray(items: i.args.map({ a -> argJson(a) }));
    val texts = i.texts;
    if (texts == null) return args;
    return Json.JsonArray(items: [args, Json.JsonArray(items: texts.map({ t -> Json.JsonArray(items: [Json.JsonString(value: t.text), optionalText(t.name)]) }))]);
}

// ── the evaluation's two ends (decisions 1059 (1), (2), 1063 (3)) ──────────
// What the evaluated module's `__bp_comptime_eval(ptr, len)` runs (C1 wires
// the export and hands `input` over from the core's memory): the input read
// into its `Input`, the body run, and the reply's text. The unit's `__bp_init`
// has opened the core's capture (`__cap_begin`), so what the body prints is
// kept there; the end closes it (`__cap_end`, `printedSoFar`) and writes it as
// the reply's `printed` — absent when nothing was printed, as the Erlang path
// writes it. A template's reply has no `printed`: what its body prints is
// closed and dropped, as there. An input that is no JSON is an `error` reply
// naming it. A raise that leaves the body — a trap — ends the evaluation with
// no reply written: the host's reply then, with what it captured
// (1059 (2), 1063 (3)). `decoratorEnd` and `blockEnd` are the writing alone.

pub fn evalDecorator(input: string, body: fn(Input) -> DecoratorReply) -> string {
    val read = jsonRead(input);
    val reply = if (read.isError())
        DecoratorReply.DecoratorError(message: unreadableInput(read), frames: [], printed: null)
    else
        body(inputOf(read.unwrapOr(Json.JsonNull)));
    return decoratorEnd(reply, printedSoFar());
}

pub fn evalTemplate(input: string, body: fn(Input) -> TemplateReply) -> string {
    val read = jsonRead(input);
    val reply = if (read.isError())
        TemplateReply.TemplateError(message: unreadableInput(read), frames: null)
    else
        body(inputOf(read.unwrapOr(Json.JsonNull)));
    printedSoFar();
    return jsonText(templateReplyJson(reply));
}

pub fn evalBlock(body: fn() -> BlockReply) -> string {
    val reply = body();
    return blockEnd(reply, printedSoFar());
}

// A decorator's reply text, `printed` what the body printed (`""` none).
pub fn decoratorEnd(reply: DecoratorReply, printed: string) -> string {
    return jsonText(decoratorReplyJson(decoratorWithPrinted(reply, printedOf(printed))));
}

// A block's reply text, `printed` what the body printed (`""` none).
pub fn blockEnd(reply: BlockReply, printed: string) -> string {
    return jsonText(blockReplyJson(blockWithPrinted(reply, printedOf(printed))));
}

// What the body printed since the evaluated unit's `__bp_init` opened the
// core's capture, the capture closed. Only a comptime unit opens one: on
// erlang and commonJS, which run no comptime unit, nothing was kept.
#[compiler.external(
    .JavaScript("\"\""),
    .Erlang("""<<>>"""),
    .Wasm(body: printedSoFarOnWasm),
)]
declare fn printedSoFar() -> string;

// `__cap_end` of the capture `__bp_init` opened, restoring an empty one: what
// the core writes after it is kept there, read by no one.
fn printedSoFarOnWasm() -> string {
    return closeCapture("");
}

fn unreadableInput(read: Result<Json, string>) -> string {
    return case read {
        Error(e) -> "the evaluation's input is no JSON: " + e;
        _ -> "";
    };
}

fn printedOf(kept: string) -> ?string {
    if (kept == "") return null;
    return kept;
}

// `r` with `printed` the kept text (a reply the body built carries none).
pub fn decoratorWithPrinted(r: DecoratorReply, printed: ?string) -> DecoratorReply {
    return case r {
        DecoratorOk(contributions: cs, printed: _) -> DecoratorReply.DecoratorOk(contributions: cs, printed: printed);
        DecoratorFail(message: m, span: s, printed: _) -> DecoratorReply.DecoratorFail(message: m, span: s, printed: printed);
        DecoratorError(message: m, frames: fs, printed: _) -> DecoratorReply.DecoratorError(message: m, frames: fs, printed: printed);
    };
}

pub fn blockWithPrinted(r: BlockReply, printed: ?string) -> BlockReply {
    return case r {
        BlockValue(value: v, printed: _) -> BlockReply.BlockValue(value: v, printed: printed);
        BlockError(message: m, frames: fs, printed: _) -> BlockReply.BlockError(message: m, frames: fs, printed: printed);
    };
}

```

----- TYPED AST JSON -- std/compiler.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "Compiler",
      "fields": {
        "module": "string",
        "package": "string",
        "isStd": "bool"
      },
      "methods": [
        {
          "name": "src",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "SourceLocation"
        },
        {
          "name": "fail",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "message",
              "type": "string"
            },
            {
              "name": "at",
              "type": "?unknown",
              "is_comptime": true
            },
            {
              "name": "span",
              "type": "?__Span"
            }
          ],
          "return_type": "void"
        },
        {
          "name": "note",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "message",
              "type": "string"
            }
          ],
          "return_type": "void"
        },
        {
          "name": "setMeta",
          "generic_params": [
            "M"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "value",
              "type": "M",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "addMeta",
          "generic_params": [
            "M"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "value",
              "type": "M",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "addMember",
          "generic_params": [
            "F"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "name",
              "type": "string"
            },
            {
              "name": "member",
              "type": "F",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "addType",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "name",
              "type": "string"
            },
            {
              "name": "source",
              "type": "string",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "init",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "executor",
              "type": "fn() -> void",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "implement",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "source",
              "type": "Implementation",
              "is_comptime": true
            }
          ],
          "return_type": "void"
        },
        {
          "name": "text",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "string"
        },
        {
          "name": "name",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "?string"
        },
        {
          "name": "source",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__Source"
        },
        {
          "name": "context",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__ExprContext"
        },
        {
          "name": "lookup",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            },
            {
              "name": "name",
              "type": "string"
            }
          ],
          "return_type": "unknown"
        },
        {
          "name": "bindings",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "e",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "unknown[]"
        },
        {
          "name": "holes",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "t",
              "type": "string",
              "is_comptime": true
            }
          ],
          "return_type": "unknown[]"
        },
        {
          "name": "build",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "source",
              "type": "string",
              "is_comptime": true
            }
          ],
          "return_type": "anyvalue"
        },
        {
          "name": "ast",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "node",
              "type": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>",
              "is_comptime": true
            }
          ],
          "return_type": "anyvalue"
        },
        {
          "name": "isSyntax",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "v",
              "type": "unknown"
            }
          ],
          "return_type": "bool"
        },
        {
          "name": "buildType",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "source",
              "type": "string",
              "is_comptime": true
            }
          ],
          "return_type": "typeparam"
        },
        {
          "name": "tagDecl",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "kind",
              "type": "DeclKind"
            },
            {
              "name": "name",
              "type": "string"
            },
            {
              "name": "attrs",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "unknown"
        },
        {
          "name": "annotate",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            },
            {
              "name": "at",
              "type": "__Span"
            }
          ],
          "return_type": "unknown"
        },
        {
          "name": "custom",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "ast",
              "type": "__CustomNode"
            }
          ],
          "return_type": "void"
        },
        {
          "name": "kind",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "DeclKind"
        },
        {
          "name": "moduleOf",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "string"
        },
        {
          "name": "meta",
          "generic_params": [
            "M"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            },
            {
              "name": "m",
              "type": "typeparam M",
              "is_comptime": true
            }
          ],
          "return_type": "?M"
        },
        {
          "name": "metaAll",
          "generic_params": [
            "M"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            },
            {
              "name": "m",
              "type": "typeparam M",
              "is_comptime": true
            }
          ],
          "return_type": "M[]"
        },
        {
          "name": "attr",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            },
            {
              "name": "name",
              "type": "string"
            }
          ],
          "return_type": "?string"
        },
        {
          "name": "component",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "unknown"
        },
        {
          "name": "hooks",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "__HookNode[]"
        },
        {
          "name": "fields",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "Field[]"
        },
        {
          "name": "methods",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "Method[]"
        },
        {
          "name": "params",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "Param[]"
        },
        {
          "name": "returnType",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "string"
        },
        {
          "name": "owner",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "unknown"
        },
        {
          "name": "annotations",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "DeclAnnotation[]"
        },
        {
          "name": "variants",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "d",
              "type": "unknown",
              "is_comptime": true
            }
          ],
          "return_type": "Variant[]"
        },
        {
          "name": "find",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "with",
              "type": "unknown"
            },
            {
              "name": "member",
              "type": "?string"
            }
          ],
          "return_type": "unknown[]"
        },
        {
          "name": "typeInfo",
          "generic_params": [
            "T"
          ],
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "t",
              "type": "typeparam T",
              "is_comptime": true
            }
          ],
          "return_type": "TypeInfo<T>"
        },
        {
          "name": "load",
          "params": [
            {
              "name": "self",
              "type": "Self"
            },
            {
              "name": "path",
              "type": "string",
              "is_comptime": true
            }
          ],
          "return_type": "@Result<Module, Refused>"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "stage",
      "is_pub": true,
      "params": [
        {
          "name": "decl",
          "type": "__Decl",
          "is_comptime": true
        },
        {
          "name": "s",
          "type": "Stage",
          "is_comptime": true
        }
      ],
      "return_type": "void",
      "body": []
    },
    {
      "ast": "enum_def",
      "name": "BeamMemory",
      "variants": [
        {
          "name": "Ets"
        },
        {
          "name": "PersistentTerm"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "beamMemory",
      "is_pub": true,
      "params": [
        {
          "name": "decl",
          "type": "__Decl",
          "is_comptime": true
        },
        {
          "name": "m",
          "type": "BeamMemory",
          "is_comptime": true
        }
      ],
      "return_type": "void",
      "body": []
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "record_def",
      "name": "Name",
      "fields": {
        "name": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "Lit",
      "fields": {
        "value": "unknown"
      }
    },
    {
      "ast": "record_def",
      "name": "Member",
      "fields": {
        "target": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>",
        "member": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "Call",
      "fields": {
        "callee": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>",
        "args": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Arg",
      "fields": {
        "name": "string",
        "value": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>"
      }
    },
    {
      "ast": "record_def",
      "name": "List",
      "fields": {
        "items": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Tuple",
      "fields": {
        "elems": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Binary",
      "fields": {
        "op": "string",
        "lhs": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>",
        "rhs": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>"
      }
    },
    {
      "ast": "record_def",
      "name": "Unary",
      "fields": {
        "op": "string",
        "operand": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>"
      }
    },
    {
      "ast": "record_def",
      "name": "If",
      "fields": {
        "cond": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>",
        "then": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>",
        "otherwise": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>"
      }
    },
    {
      "ast": "record_def",
      "name": "Lambda",
      "fields": {
        "params": "string[]",
        "body": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>"
      }
    },
    {
      "ast": "record_def",
      "name": "Syntax",
      "fields": {
        "e": "unknown"
      }
    },
    {
      "ast": "record_def",
      "name": "Fn",
      "fields": {
        "params": "FnParam[]",
        "ret": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>",
        "body": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>[]"
      }
    },
    {
      "ast": "record_def",
      "name": "FnParam",
      "fields": {
        "name": "string",
        "annotation": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>"
      }
    },
    {
      "ast": "record_def",
      "name": "Return",
      "fields": {
        "result": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>"
      }
    },
    {
      "ast": "record_def",
      "name": "NamedType",
      "fields": {
        "named": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "ArrayType",
      "fields": {
        "elem": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>"
      }
    },
    {
      "ast": "record_def",
      "name": "TupleType",
      "fields": {
        "types": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>[]"
      }
    },
    {
      "ast": "record_def",
      "name": "LabeledTupleType",
      "fields": {
        "types": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>[]",
        "labels": "string[]"
      }
    },
    {
      "ast": "record_def",
      "name": "OptionalType",
      "fields": {
        "inner": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>"
      }
    },
    {
      "ast": "record_def",
      "name": "FnType",
      "fields": {
        "params": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>[]",
        "returns": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>"
      }
    },
    {
      "ast": "record_def",
      "name": "GenericType",
      "fields": {
        "name": "string",
        "args": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>[]"
      }
    },
    {
      "ast": "record_def",
      "name": "UnionType",
      "fields": {
        "members": "|<Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType>[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Diagnostic",
      "fields": {
        "code": "string",
        "message": "string",
        "file": "string",
        "line": "i32",
        "column": "i32",
        "label": "?string",
        "`from`": "string[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Module",
      "fields": {
        "name": "string",
        "path": "string",
        "buildOutput": "string",
        "mainAsync": "bool"
      },
      "methods": [
        {
          "name": "of",
          "params": [
            {
              "name": "name",
              "type": "string"
            },
            {
              "name": "path",
              "type": "string"
            },
            {
              "name": "buildOutput",
              "type": "string"
            },
            {
              "name": "mainAsync",
              "type": "bool"
            }
          ],
          "return_type": "Module"
        },
        {
          "name": "name",
          "is_pub": true,
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "string"
        },
        {
          "name": "path",
          "is_pub": true,
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "string"
        },
        {
          "name": "buildOutput",
          "is_pub": true,
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "string"
        },
        {
          "name": "mainAsync",
          "is_pub": true,
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "bool"
        },
        {
          "name": "run",
          "is_pub": true,
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "@Result<string, RunFailure>"
        },
        {
          "name": "`test`",
          "is_pub": true,
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "@Result<TestReport, RunFailure>"
        },
        {
          "name": "captureOpen",
          "params": [],
          "return_type": "string"
        },
        {
          "name": "captureClose",
          "params": [
            {
              "name": "open",
              "type": "string"
            }
          ],
          "return_type": "string"
        },
        {
          "name": "testTmpOpen",
          "params": [],
          "return_type": "string"
        },
        {
          "name": "testTmpClose",
          "params": [
            {
              "name": "open",
              "type": "string"
            }
          ],
          "return_type": "void"
        },
        {
          "name": "testNameOpen",
          "params": [
            {
              "name": "name",
              "type": "string"
            }
          ],
          "return_type": "string"
        },
        {
          "name": "testNameClose",
          "params": [
            {
              "name": "open",
              "type": "string"
            }
          ],
          "return_type": "void"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "openCapture",
      "is_pub": false,
      "params": [],
      "return_type": "string",
      "body": []
    },
    {
      "ast": "fn_def",
      "name": "closeCapture",
      "is_pub": false,
      "params": [
        {
          "name": "open",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": []
    },
    {
      "ast": "fn_def",
      "name": "openTestTmp",
      "is_pub": false,
      "params": [],
      "return_type": "string",
      "body": []
    },
    {
      "ast": "fn_def",
      "name": "closeTestTmp",
      "is_pub": false,
      "params": [
        {
          "name": "open",
          "type": "string"
        }
      ],
      "return_type": "void",
      "body": []
    },
    {
      "ast": "fn_def",
      "name": "openTestName",
      "is_pub": false,
      "params": [
        {
          "name": "name",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": []
    },
    {
      "ast": "fn_def",
      "name": "closeTestName",
      "is_pub": false,
      "params": [
        {
          "name": "open",
          "type": "string"
        }
      ],
      "return_type": "void",
      "body": []
    },
    {
      "ast": "fn_def",
      "name": "noTestEnvOpen",
      "is_pub": false,
      "params": [],
      "return_type": "string",
      "body": [
        {
          "source": "return \"\";"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "noTestNameOpen",
      "is_pub": false,
      "params": [
        {
          "name": "name",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return \"\";"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "noTestEnvClose",
      "is_pub": false,
      "params": [
        {
          "name": "open",
          "type": "string"
        }
      ],
      "return_type": "void",
      "body": [
        {
          "source": "return;"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "RunFailure",
      "fields": {
        "kind": "RunFailureKind",
        "message": "string",
        "output": "string"
      }
    },
    {
      "ast": "enum_def",
      "name": "RunFailureKind",
      "variants": [
        {
          "name": "Failed"
        },
        {
          "name": "Abort"
        },
        {
          "name": "Refused"
        },
        {
          "name": "Excluded"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "TestReport",
      "fields": {
        "cases": "TestCase[]"
      }
    },
    {
      "ast": "record_def",
      "name": "TestCase",
      "fields": {
        "name": "string",
        "file": "string",
        "line": "i32",
        "ok": "bool",
        "output": "string",
        "message": "string",
        "at": "string",
        "durationMs": "i32"
      }
    },
    {
      "ast": "record_def",
      "name": "Refused",
      "fields": {
        "module": "Module",
        "diagnostics": "Diagnostic[]"
      }
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "typeAlias"
    },
    {
      "ast": "enum_def",
      "name": "DeclKind",
      "variants": [
        {
          "name": "Type"
        },
        {
          "name": "Behavior"
        },
        {
          "name": "Fn"
        },
        {
          "name": "Method"
        },
        {
          "name": "Field"
        },
        {
          "name": "Val"
        },
        {
          "name": "Element"
        },
        {
          "name": "Component"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "DeclAnnotation",
      "fields": {
        "name": "string",
        "args": "string[]",
        "decorator": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "Param",
      "fields": {
        "name": "string",
        "typeName": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "Field",
      "fields": {
        "name": "string",
        "typeName": "string",
        "annotations": "DeclAnnotation[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Method",
      "fields": {
        "name": "string",
        "params": "Param[]",
        "returnType": "string",
        "annotations": "DeclAnnotation[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Variant",
      "fields": {
        "name": "string",
        "fields": "Field[]",
        "annotations": "DeclAnnotation[]",
        "section": "?string"
      }
    },
    {
      "ast": "enum_def",
      "name": "Json",
      "variants": [
        {
          "name": "JsonNull"
        },
        {
          "name": "JsonBool",
          "fields": {
            "value": "bool"
          }
        },
        {
          "name": "JsonInt",
          "fields": {
            "value": "i64"
          }
        },
        {
          "name": "JsonFloat",
          "fields": {
            "value": "f64"
          }
        },
        {
          "name": "JsonString",
          "fields": {
            "value": "string"
          }
        },
        {
          "name": "JsonArray",
          "fields": {
            "items": "Json[]"
          }
        },
        {
          "name": "JsonObject",
          "fields": {
            "fields": "JsonField[]"
          }
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "JsonField",
      "fields": {
        "key": "string",
        "value": "Json"
      }
    },
    {
      "ast": "enum_def",
      "name": "BuildValue",
      "variants": [
        {
          "name": "NullValue"
        },
        {
          "name": "BoolValue",
          "fields": {
            "value": "bool"
          }
        },
        {
          "name": "IntValue",
          "fields": {
            "value": "i64"
          }
        },
        {
          "name": "FloatValue",
          "fields": {
            "value": "f64"
          }
        },
        {
          "name": "StringValue",
          "fields": {
            "value": "string"
          }
        },
        {
          "name": "ArrayValue",
          "fields": {
            "items": "BuildValue[]"
          }
        },
        {
          "name": "TupleValue",
          "fields": {
            "items": "BuildValue[]"
          }
        },
        {
          "name": "RecordValue",
          "fields": {
            "fields": "BuildField[]"
          }
        },
        {
          "name": "AtomValue",
          "fields": {
            "name": "string"
          }
        },
        {
          "name": "FnValue",
          "fields": {
            "index": "?i64"
          }
        },
        {
          "name": "ResourceValue",
          "fields": {
            "text": "string"
          }
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "BuildField",
      "fields": {
        "name": "string",
        "value": "BuildValue"
      }
    },
    {
      "ast": "record_def",
      "name": "Frame",
      "fields": {
        "file": "string",
        "line": "i64",
        "col": "i64"
      }
    },
    {
      "ast": "record_def",
      "name": "Contribution",
      "fields": {
        "kind": "string",
        "source": "?string",
        "key": "?string",
        "value": "?string",
        "name": "?string",
        "index": "?i64",
        "data": "?Json"
      }
    },
    {
      "ast": "enum_def",
      "name": "FailSpan",
      "variants": [
        {
          "name": "NoSpan"
        },
        {
          "name": "SpanAt",
          "fields": {
            "start": "i64",
            "end": "i64",
            "line": "i64"
          }
        },
        {
          "name": "ArgAt",
          "fields": {
            "index": "i64"
          }
        }
      ]
    },
    {
      "ast": "enum_def",
      "name": "DecoratorReply",
      "variants": [
        {
          "name": "DecoratorOk",
          "fields": {
            "contributions": "Contribution[]",
            "printed": "?string"
          }
        },
        {
          "name": "DecoratorFail",
          "fields": {
            "message": "string",
            "span": "FailSpan",
            "printed": "?string"
          }
        },
        {
          "name": "DecoratorError",
          "fields": {
            "message": "string",
            "frames": "Frame[]",
            "printed": "?string"
          }
        }
      ]
    },
    {
      "ast": "enum_def",
      "name": "TemplateAnswer",
      "variants": [
        {
          "name": "CodeAnswer",
          "fields": {
            "source": "string"
          }
        },
        {
          "name": "AstAnswer",
          "fields": {
            "node": "BuildValue"
          }
        },
        {
          "name": "ValueAnswer",
          "fields": {
            "value": "BuildValue"
          }
        },
        {
          "name": "CaptureAnswer",
          "fields": {
            "param": "string"
          }
        },
        {
          "name": "CustomAnswer",
          "fields": {
            "source": "string",
            "tree": "BuildValue"
          }
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "TagRequest",
      "fields": {
        "kind": "string",
        "name": "string",
        "attrs": "TagAttr[]",
        "answer": "i64"
      }
    },
    {
      "ast": "record_def",
      "name": "TagAttr",
      "fields": {
        "name": "string",
        "value": "BuildValue"
      }
    },
    {
      "ast": "enum_def",
      "name": "TemplateReply",
      "variants": [
        {
          "name": "TemplateDone",
          "fields": {
            "answer": "TemplateAnswer",
            "build": "?i64",
            "notes": "string[]"
          }
        },
        {
          "name": "TemplateNeed",
          "fields": {
            "request": "TagRequest",
            "span": "BuildValue"
          }
        },
        {
          "name": "TemplateFail",
          "fields": {
            "message": "string",
            "param": "?string",
            "span": "BuildValue"
          }
        },
        {
          "name": "TemplateError",
          "fields": {
            "message": "string",
            "frames": "?Frame[]"
          }
        }
      ]
    },
    {
      "ast": "enum_def",
      "name": "BlockReply",
      "variants": [
        {
          "name": "BlockValue",
          "fields": {
            "value": "BuildValue",
            "printed": "?string"
          }
        },
        {
          "name": "BlockError",
          "fields": {
            "message": "string",
            "frames": "Frame[]",
            "printed": "?string"
          }
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "jsonText",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "jsonSorted",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "jsonPretty",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return prettyAt(j, \"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "prettyAt",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        },
        {
          "name": "indent",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "decimalText",
      "is_pub": false,
      "params": [
        {
          "name": "text",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val cs = text.chars();"
        },
        {
          "source": "val negative = (cs.at(0) ?? \"\") == \"-\";"
        },
        {
          "source": "val unsigned = if (negative) cs.slice(1, cs.length) else cs;"
        },
        {
          "source": "var mantissa: string[] = [];"
        },
        {
          "source": "var exponent: string[] = [];"
        },
        {
          "source": "var inExponent = false;"
        },
        {
          "source": "var n = 0;"
        },
        {
          "source": "while (n < unsigned.length) {"
        },
        {
          "source": "val dot = mantissa.indexOf(\".\");"
        },
        {
          "source": "val point = if (dot < 0) mantissa.length else dot;"
        },
        {
          "source": "val digits = mantissa.filter({ c -> c != \".\" });"
        },
        {
          "source": "val shift = exponent.join(\"\").parseInt().unwrapOr(noInt());"
        },
        {
          "source": "val at = point + shift.toI32();"
        },
        {
          "source": "var whole: string[] = [];"
        },
        {
          "source": "var fraction: string[] = [];"
        },
        {
          "source": "var k = at;"
        },
        {
          "source": "while (k < 0) {"
        },
        {
          "source": "var i = 0;"
        },
        {
          "source": "while (i < at || i < digits.length) {"
        },
        {
          "source": "var last = fraction.length;"
        },
        {
          "source": "while (last > 0 && (fraction.at(last - 1) ?? \"\") == \"0\") {"
        },
        {
          "source": "fraction = fraction.slice(0, last);"
        },
        {
          "source": "val integral = if (whole.length == 0) \"0\" else whole.join(\"\");"
        },
        {
          "source": "val sign = if (negative) \"-\" else \"\";"
        },
        {
          "source": "if (fraction.length == 0) return sign + integral;"
        },
        {
          "source": "return sign + integral + \".\" + fraction.join(\"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "boolText",
      "is_pub": false,
      "params": [
        {
          "name": "b",
          "type": "bool"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "if (b) return \"true\";"
        },
        {
          "source": "return \"false\";"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "quoteJson",
      "is_pub": false,
      "params": [
        {
          "name": "s",
          "type": "string"
        },
        {
          "name": "upper",
          "type": "bool"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val cps = s.chars().map({ c -> c.charCodeAt(0) });"
        },
        {
          "source": "val texts = s.chars();"
        },
        {
          "source": "var out: string[] = [\"\\\"\"];"
        },
        {
          "source": "var i = 0;"
        },
        {
          "source": "while (i < cps.length) {"
        },
        {
          "source": "out.push(\"\\\"\");"
        },
        {
          "source": "return out.join(\"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "jsonChar",
      "is_pub": false,
      "params": [
        {
          "name": "c",
          "type": "i32"
        },
        {
          "name": "text",
          "type": "string"
        },
        {
          "name": "upper",
          "type": "bool"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "if (c == 34) return \"\\\\\\\"\";"
        },
        {
          "source": "if (c == 92) return \"\\\\\\\\\";"
        },
        {
          "source": "if (c == 10) return \"\\\\n\";"
        },
        {
          "source": "if (c == 13) return \"\\\\r\";"
        },
        {
          "source": "if (c == 9) return \"\\\\t\";"
        },
        {
          "source": "if (c == 8) return \"\\\\b\";"
        },
        {
          "source": "if (c == 12) return \"\\\\f\";"
        },
        {
          "source": "if (c < 32)"
        },
        {
          "source": "return text;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "hexDigit",
      "is_pub": false,
      "params": [
        {
          "name": "d",
          "type": "i32"
        },
        {
          "name": "upper",
          "type": "bool"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val digits = if (upper) \"0123456789ABCDEF\" else \"0123456789abcdef\";"
        },
        {
          "source": "return digits.chars().at(d) ?? \"\";"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "sortFields",
      "is_pub": false,
      "params": [
        {
          "name": "fs",
          "type": "JsonField[]"
        }
      ],
      "return_type": "JsonField[]",
      "body": [
        {
          "source": "var out: JsonField[] = [];"
        },
        {
          "source": "var i = 0;"
        },
        {
          "source": "while (i < fs.length) {"
        },
        {
          "source": "return out;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "textBefore",
      "is_pub": false,
      "params": [
        {
          "name": "a",
          "type": "string"
        },
        {
          "name": "b",
          "type": "string"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "val x = a.chars().map({ c -> c.charCodeAt(0) });"
        },
        {
          "source": "val y = b.chars().map({ c -> c.charCodeAt(0) });"
        },
        {
          "source": "var i = 0;"
        },
        {
          "source": "var answer = x.length < y.length;"
        },
        {
          "source": "var decided = false;"
        },
        {
          "source": "while (!decided && i < x.length && i < y.length) {"
        },
        {
          "source": "return answer;"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "Reading",
      "fields": {
        "cps": "i32[]",
        "texts": "string[]"
      }
    },
    {
      "ast": "record_def",
      "name": "ReadJson",
      "fields": {
        "value": "Json",
        "next": "i32"
      }
    },
    {
      "ast": "record_def",
      "name": "ReadText",
      "fields": {
        "text": "string",
        "next": "i32"
      }
    },
    {
      "ast": "fn_def",
      "name": "jsonRead",
      "is_pub": true,
      "params": [
        {
          "name": "text",
          "type": "string"
        }
      ],
      "return_type": "Result<Json,string>",
      "body": [
        {
          "source": "val doc = Reading(cps: text"
        },
        {
          "source": "val read = try readJson(doc, skipSpace(doc, 0));"
        },
        {
          "source": "val end = skipSpace(doc, read.next);"
        },
        {
          "source": "if (end < doc.cps.length) throw readProblem(end, \"text after the value\");"
        },
        {
          "source": "return read.value;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "cpAt",
      "is_pub": false,
      "params": [
        {
          "name": "doc",
          "type": "Reading"
        },
        {
          "name": "i",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "return doc.cps.at(i) ?? (0 - 1);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "skipSpace",
      "is_pub": false,
      "params": [
        {
          "name": "doc",
          "type": "Reading"
        },
        {
          "name": "start",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "var i = start;"
        },
        {
          "source": "while (cpAt(doc, i) == 32"
        },
        {
          "source": "return i;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "readProblem",
      "is_pub": false,
      "params": [
        {
          "name": "at",
          "type": "i32"
        },
        {
          "name": "what",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return [\"compiler.jsonRead: \", what, \" at \", at.toString()].join(\"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "readJson",
      "is_pub": false,
      "params": [
        {
          "name": "doc",
          "type": "Reading"
        },
        {
          "name": "i",
          "type": "i32"
        }
      ],
      "return_type": "Result<ReadJson,string>",
      "body": [
        {
          "source": "val c = cpAt(doc, i);"
        },
        {
          "source": "if (c == 123) return try readObject(doc, skipSpace(doc, i + 1));"
        },
        {
          "source": "if (c == 91) return try readArray(doc, skipSpace(doc, i + 1));"
        },
        {
          "source": "if (c == 34) {"
        },
        {
          "source": "if (c == 116)"
        },
        {
          "source": "if (c == 102)"
        },
        {
          "source": "if (c == 110) return try readWord(doc, i, \"null\", Json.JsonNull);"
        },
        {
          "source": "if (c == 45 || (c >= 48 && c <= 57)) return try readNumber(doc, i);"
        },
        {
          "source": "throw readProblem(i, \"no JSON value\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "readWord",
      "is_pub": false,
      "params": [
        {
          "name": "doc",
          "type": "Reading"
        },
        {
          "name": "i",
          "type": "i32"
        },
        {
          "name": "word",
          "type": "string"
        },
        {
          "name": "value",
          "type": "Json"
        }
      ],
      "return_type": "Result<ReadJson,string>",
      "body": [
        {
          "source": "val want = word.chars();"
        },
        {
          "source": "var ok = true;"
        },
        {
          "source": "var k = 0;"
        },
        {
          "source": "while (k < want.length) {"
        },
        {
          "source": "if (!ok) throw readProblem(i, \"no JSON value\");"
        },
        {
          "source": "return ReadJson(value: value, next: i + want.length);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "readNumber",
      "is_pub": false,
      "params": [
        {
          "name": "doc",
          "type": "Reading"
        },
        {
          "name": "i",
          "type": "i32"
        }
      ],
      "return_type": "Result<ReadJson,string>",
      "body": [
        {
          "source": "var k = i;"
        },
        {
          "source": "var whole = true;"
        },
        {
          "source": "var go = true;"
        },
        {
          "source": "while (go) {"
        },
        {
          "source": "val numeral = doc.texts.slice(i, k).join(\"\");"
        },
        {
          "source": "// A whole number an `i64` holds is a `JsonInt`; `-0` (which an `i64`"
        },
        {
          "source": "// has not) and one beyond an `i64` are read as the float they write."
        },
        {
          "source": "if (whole && numeral != \"-0\") {"
        },
        {
          "source": "val x = numeral.parseFloat();"
        },
        {
          "source": "if (x.isError()) throw readProblem(i, \"a malformed number\");"
        },
        {
          "source": "return ReadJson(value: Json.JsonFloat(value: x.unwrapOr(0.0)), next: k);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "readString",
      "is_pub": false,
      "params": [
        {
          "name": "doc",
          "type": "Reading"
        },
        {
          "name": "i",
          "type": "i32"
        }
      ],
      "return_type": "Result<ReadText,string>",
      "body": [
        {
          "source": "var out: string[] = [];"
        },
        {
          "source": "var k = i + 1;"
        },
        {
          "source": "var problem = \"\";"
        },
        {
          "source": "var done = false;"
        },
        {
          "source": "while (!done) {"
        },
        {
          "source": "if (problem != \"\") throw problem;"
        },
        {
          "source": "return ReadText(text: out.join(\"\"), next: k + 1);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "escapedChar",
      "is_pub": false,
      "params": [
        {
          "name": "e",
          "type": "i32"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "if (e == 110) return \"\\n\";"
        },
        {
          "source": "if (e == 114) return \"\\r\";"
        },
        {
          "source": "if (e == 116) return \"\\t\";"
        },
        {
          "source": "if (e == 98) return string.fromCodepoint(8);"
        },
        {
          "source": "if (e == 102) return string.fromCodepoint(12);"
        },
        {
          "source": "return string.fromCodepoint(e);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "hexValue",
      "is_pub": false,
      "params": [
        {
          "name": "doc",
          "type": "Reading"
        },
        {
          "name": "i",
          "type": "i32"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "var v = 0;"
        },
        {
          "source": "var k = 0;"
        },
        {
          "source": "while (k < 4) {"
        },
        {
          "source": "return v;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "readArray",
      "is_pub": false,
      "params": [
        {
          "name": "doc",
          "type": "Reading"
        },
        {
          "name": "start",
          "type": "i32"
        }
      ],
      "return_type": "Result<ReadJson,string>",
      "body": [
        {
          "source": "var items: Json[] = [];"
        },
        {
          "source": "var i = start;"
        },
        {
          "source": "if (cpAt(doc, i) == 93)"
        },
        {
          "source": "var more = true;"
        },
        {
          "source": "while (more) {"
        },
        {
          "source": "if (i < 0) throw readProblem(0 - 1 - i, \"a malformed array\");"
        },
        {
          "source": "return ReadJson(value: Json.JsonArray(items: items), next: i);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "readObject",
      "is_pub": false,
      "params": [
        {
          "name": "doc",
          "type": "Reading"
        },
        {
          "name": "start",
          "type": "i32"
        }
      ],
      "return_type": "Result<ReadJson,string>",
      "body": [
        {
          "source": "var fields: JsonField[] = [];"
        },
        {
          "source": "var i = start;"
        },
        {
          "source": "if (cpAt(doc, i) == 125)"
        },
        {
          "source": "var more = true;"
        },
        {
          "source": "while (more) {"
        },
        {
          "source": "if (i < 0) throw readProblem(0 - 1 - i, \"a malformed object\");"
        },
        {
          "source": "return ReadJson(value: Json.JsonObject(fields: fields), next: i);"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "ReadMember",
      "fields": {
        "field": "JsonField",
        "next": "i32"
      }
    },
    {
      "ast": "fn_def",
      "name": "readMember",
      "is_pub": false,
      "params": [
        {
          "name": "doc",
          "type": "Reading"
        },
        {
          "name": "i",
          "type": "i32"
        }
      ],
      "return_type": "Result<ReadMember,string>",
      "body": [
        {
          "source": "if (cpAt(doc, i) != 34) throw readProblem(i, \"a member without a name\");"
        },
        {
          "source": "val key = try readString(doc, i);"
        },
        {
          "source": "val colon = skipSpace(doc, key.next);"
        },
        {
          "source": "if (cpAt(doc, colon) != 58)"
        },
        {
          "source": "val value = try readJson(doc, skipSpace(doc, colon + 1));"
        },
        {
          "source": "return ReadMember(field: JsonField(key: key.text, value: value.value), next: value.next);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "jsonField",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        },
        {
          "name": "key",
          "type": "string"
        }
      ],
      "return_type": "?Json",
      "body": [
        {
          "source": "val fs = fieldsOf(j);"
        },
        {
          "source": "var hit: ?Json = null;"
        },
        {
          "source": "var i = fs.length - 1;"
        },
        {
          "source": "while (i >= 0) {"
        },
        {
          "source": "return hit;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "textField",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        },
        {
          "name": "key",
          "type": "string"
        }
      ],
      "return_type": "?string",
      "body": [
        {
          "source": "val v = jsonField(j, key) ?? Json.JsonNull;"
        },
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "intField",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        },
        {
          "name": "key",
          "type": "string"
        }
      ],
      "return_type": "?i64",
      "body": [
        {
          "source": "val v = jsonField(j, key) ?? Json.JsonNull;"
        },
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "itemsOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Json[]",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "fieldsOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "JsonField[]",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateValueJson",
      "is_pub": true,
      "params": [
        {
          "name": "v",
          "type": "BuildValue"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateValueOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "BuildValue",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateObjectOf",
      "is_pub": false,
      "params": [
        {
          "name": "fs",
          "type": "JsonField[]"
        }
      ],
      "return_type": "BuildValue",
      "body": [
        {
          "source": "val only = fs.at(0) ?? JsonField(key: \"\", value: Json.JsonNull);"
        },
        {
          "source": "if (fs.length == 1 && only.key == \"$tuple\")"
        },
        {
          "source": "return BuildValue.RecordValue(fields: fs.map({ f -> BuildField(name: f.key, value: templateValueOf(f.value)) }));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "holdsFn",
      "is_pub": false,
      "params": [
        {
          "name": "v",
          "type": "BuildValue"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockValueJson",
      "is_pub": true,
      "params": [
        {
          "name": "v",
          "type": "BuildValue"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockValueOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "BuildValue",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockObjectOf",
      "is_pub": false,
      "params": [
        {
          "name": "fs",
          "type": "JsonField[]"
        }
      ],
      "return_type": "BuildValue",
      "body": [
        {
          "source": "val only = fs.at(0) ?? JsonField(key: \"\", value: Json.JsonNull);"
        },
        {
          "source": "val inner = only.value;"
        },
        {
          "source": "if (only.key == \"float\")"
        },
        {
          "source": "if (only.key == \"tuple\")"
        },
        {
          "source": "if (only.key == \"record\")"
        },
        {
          "source": "if (only.key == \"atom\") return BuildValue.AtomValue(name: stringOf(inner));"
        },
        {
          "source": "if (only.key == \"fn\") return BuildValue.FnValue(index: intOf(inner));"
        },
        {
          "source": "return BuildValue.ResourceValue(text: stringOf(inner));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "tagged",
      "is_pub": false,
      "params": [
        {
          "name": "tag",
          "type": "string"
        },
        {
          "name": "value",
          "type": "Json"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: [JsonField(key: tag, value: value)]);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "noInt",
      "is_pub": false,
      "params": [],
      "return_type": "i64",
      "body": [
        {
          "source": "return 0;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "optionalInt",
      "is_pub": false,
      "params": [
        {
          "name": "n",
          "type": "?i64"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "if (n != null) return Json.JsonInt(value: n);"
        },
        {
          "source": "return Json.JsonNull;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "optionalText",
      "is_pub": false,
      "params": [
        {
          "name": "s",
          "type": "?string"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "if (s != null) return Json.JsonString(value: s);"
        },
        {
          "source": "return Json.JsonNull;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "floatOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "f64",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "stringOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "intOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "?i64",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "replyObject",
      "is_pub": false,
      "params": [
        {
          "name": "fields",
          "type": "JsonField[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return jsonSorted(Json.JsonObject(fields: fields));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "withPrinted",
      "is_pub": false,
      "params": [
        {
          "name": "fields",
          "type": "JsonField[]"
        },
        {
          "name": "printed",
          "type": "?string"
        }
      ],
      "return_type": "JsonField[]",
      "body": [
        {
          "source": "var out: JsonField[] = fields.map({ f -> f });"
        },
        {
          "source": "if (printed != null)"
        },
        {
          "source": "return out;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "framesJson",
      "is_pub": false,
      "params": [
        {
          "name": "frames",
          "type": "Frame[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonArray(items: frames.map({ f -> Json.JsonArray(items: [Json.JsonString(value: f.file), Json.JsonInt(value: f.line), Json.JsonInt(value: f.col)]) }));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "framesOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Frame[]",
      "body": [
        {
          "source": "return itemsOf(j).map({ f -> frameOf(itemsOf(f)) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "frameOf",
      "is_pub": false,
      "params": [
        {
          "name": "parts",
          "type": "Json[]"
        }
      ],
      "return_type": "Frame",
      "body": [
        {
          "source": "return Frame(file: stringOf(parts.at(0) ?? Json.JsonNull), line: wholeOf(parts.at(1) ?? Json.JsonNull), col: wholeOf(parts.at(2) ?? Json.JsonNull));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "wholeOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "i64",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "decoratorReplyJson",
      "is_pub": true,
      "params": [
        {
          "name": "r",
          "type": "DecoratorReply"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "contributionsJson",
      "is_pub": false,
      "params": [
        {
          "name": "cs",
          "type": "Contribution[]"
        }
      ],
      "return_type": "Json[]",
      "body": [
        {
          "source": "return cs.map({ c -> contributionJson(c) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "contributionJson",
      "is_pub": false,
      "params": [
        {
          "name": "c",
          "type": "Contribution"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "var fs: JsonField[] = [JsonField(key: \"kind\", value: Json.JsonString(value: c.kind))];"
        },
        {
          "source": "if (c.source != null)"
        },
        {
          "source": "if (c.key != null)"
        },
        {
          "source": "if (c.value != null)"
        },
        {
          "source": "if (c.name != null)"
        },
        {
          "source": "if (c.index != null)"
        },
        {
          "source": "if (c.data != null)"
        },
        {
          "source": "return replyObject(fs);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "failSpanJson",
      "is_pub": false,
      "params": [
        {
          "name": "s",
          "type": "FailSpan"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return case s {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "decoratorReplyOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "DecoratorReply",
      "body": [
        {
          "source": "val kind = textField(j, \"kind\") ?? \"\";"
        },
        {
          "source": "val printed = textField(j, \"printed\");"
        },
        {
          "source": "if (kind == \"ok\")"
        },
        {
          "source": "if (kind == \"fail\")"
        },
        {
          "source": "return DecoratorReply.DecoratorError(message: textField(j, \"message\") ?? \"\", frames: framesOf(jsonField(j, \"frames\") ?? Json.JsonNull), printed: printed);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "contributionOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Contribution",
      "body": [
        {
          "source": "return Contribution("
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "failSpanOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "FailSpan",
      "body": [
        {
          "source": "val arg = intField(j, \"arg\");"
        },
        {
          "source": "if (arg != null) return FailSpan.ArgAt(index: arg);"
        },
        {
          "source": "val start = intField(j, \"start\");"
        },
        {
          "source": "if (start != null)"
        },
        {
          "source": "return FailSpan.NoSpan;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateReplyJson",
      "is_pub": true,
      "params": [
        {
          "name": "r",
          "type": "TemplateReply"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "errorFields",
      "is_pub": false,
      "params": [
        {
          "name": "message",
          "type": "string"
        },
        {
          "name": "frames",
          "type": "?Frame[]"
        }
      ],
      "return_type": "JsonField[]",
      "body": [
        {
          "source": "var out: JsonField[] = ["
        },
        {
          "source": "if (frames != null)"
        },
        {
          "source": "return out;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateDoneJson",
      "is_pub": false,
      "params": [
        {
          "name": "a",
          "type": "TemplateAnswer"
        },
        {
          "name": "build",
          "type": "?i64"
        },
        {
          "name": "notes",
          "type": "string[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "val unsupported = case a {"
        },
        {
          "source": "if (unsupported)"
        },
        {
          "source": "var fs = case a {"
        },
        {
          "source": "if (build != null)"
        },
        {
          "source": "if (notes.length > 0)"
        },
        {
          "source": "return replyObject(fs);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "tagRequestJson",
      "is_pub": false,
      "params": [
        {
          "name": "q",
          "type": "TagRequest"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return replyObject(["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateReplyOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "TemplateReply",
      "body": [
        {
          "source": "val kind = textField(j, \"kind\") ?? \"\";"
        },
        {
          "source": "if (kind == \"need\") {"
        },
        {
          "source": "if (kind == \"fail\")"
        },
        {
          "source": "if (kind == \"error\") {"
        },
        {
          "source": "val notes = itemsOf(jsonField(j, \"notes\") ?? Json.JsonNull).map({ n -> stringOf(n) });"
        },
        {
          "source": "return TemplateReply.TemplateDone(answer: templateAnswerOf(kind, j), build: intField(j, \"build\"), notes: notes);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateAnswerOf",
      "is_pub": false,
      "params": [
        {
          "name": "kind",
          "type": "string"
        },
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "TemplateAnswer",
      "body": [
        {
          "source": "if (kind == \"ast\")"
        },
        {
          "source": "if (kind == \"value\")"
        },
        {
          "source": "if (kind == \"capture\")"
        },
        {
          "source": "if (kind == \"custom\")"
        },
        {
          "source": "return TemplateAnswer.CodeAnswer(source: textField(j, \"source\") ?? \"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "tagAttrOf",
      "is_pub": false,
      "params": [
        {
          "name": "v",
          "type": "BuildValue"
        }
      ],
      "return_type": "TagAttr",
      "body": [
        {
          "source": "val items = case v {"
        },
        {
          "source": "val name = case items.at(0) ?? BuildValue.NullValue {"
        },
        {
          "source": "return TagAttr(name: name, value: items.at(1) ?? BuildValue.NullValue);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockReplyJson",
      "is_pub": true,
      "params": [
        {
          "name": "r",
          "type": "BlockReply"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockReplyOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "BlockReply",
      "body": [
        {
          "source": "val printed = textField(j, \"printed\");"
        },
        {
          "source": "if ((textField(j, \"kind\") ?? \"\") == \"error\")"
        },
        {
          "source": "return BlockReply.BlockValue(value: blockValueOf(jsonField(j, \"value\") ?? Json.JsonNull), printed: printed);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "raisedText",
      "is_pub": true,
      "params": [
        {
          "name": "class",
          "type": "string"
        },
        {
          "name": "reason",
          "type": "BuildValue"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return termText(BuildValue.TupleValue(items: [BuildValue.AtomValue(name: class), reason]));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "divisionByZero",
      "is_pub": true,
      "params": [],
      "return_type": "BuildValue",
      "body": [
        {
          "source": "return BuildValue.TupleValue(items: [BuildValue.AtomValue(name: \"bp_wat_runtime\"), BuildValue.StringValue(value: \"division by zero\")]);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "noMatch",
      "is_pub": true,
      "params": [
        {
          "name": "value",
          "type": "BuildValue"
        }
      ],
      "return_type": "BuildValue",
      "body": [
        {
          "source": "return BuildValue.TupleValue(items: [BuildValue.AtomValue(name: \"case_clause\"), value]);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "badArith",
      "is_pub": true,
      "params": [],
      "return_type": "BuildValue",
      "body": [
        {
          "source": "return BuildValue.AtomValue(name: \"badarith\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "termText",
      "is_pub": true,
      "params": [
        {
          "name": "v",
          "type": "BuildValue"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "sortBuildFields",
      "is_pub": false,
      "params": [
        {
          "name": "fs",
          "type": "BuildField[]"
        }
      ],
      "return_type": "BuildField[]",
      "body": [
        {
          "source": "val sorted = sortFields(fs.map({ f -> JsonField(key: f.name, value: Json.JsonNull) }));"
        },
        {
          "source": "return sorted.map({ s -> (fs.filter({ f -> f.name == s.key }).at(0) ?? BuildField(name: s.key, value: BuildValue.NullValue)) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "printableLatin1",
      "is_pub": false,
      "params": [
        {
          "name": "c",
          "type": "i32"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "return c >= 32 && c <= 126"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "printableUnicode",
      "is_pub": false,
      "params": [
        {
          "name": "c",
          "type": "i32"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "return printableLatin1(c)"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "escapeLetter",
      "is_pub": false,
      "params": [
        {
          "name": "c",
          "type": "i32"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "if (c == 10) return \"n\";"
        },
        {
          "source": "if (c == 13) return \"r\";"
        },
        {
          "source": "if (c == 9) return \"t\";"
        },
        {
          "source": "if (c == 11) return \"v\";"
        },
        {
          "source": "if (c == 8) return \"b\";"
        },
        {
          "source": "if (c == 12) return \"f\";"
        },
        {
          "source": "if (c == 27) return \"e\";"
        },
        {
          "source": "if (c == 7) return \"d\";"
        },
        {
          "source": "if (c == 92) return \"\\\\\";"
        },
        {
          "source": "return \"\";"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "termChar",
      "is_pub": false,
      "params": [
        {
          "name": "c",
          "type": "i32"
        },
        {
          "name": "text",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val letter = escapeLetter(c);"
        },
        {
          "source": "if (letter != \"\") return \"\\\\\" + letter;"
        },
        {
          "source": "if (c == 34) return \"\\\\\\\"\";"
        },
        {
          "source": "return text;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "binaryText",
      "is_pub": false,
      "params": [
        {
          "name": "s",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val cps = s.chars().map({ c -> c.charCodeAt(0) });"
        },
        {
          "source": "val texts = s.chars();"
        },
        {
          "source": "val ascii = cps.filter({ c -> !printableLatin1(c) || c >= 128 }).length"
        },
        {
          "source": "val unicode = cps.filter({ c -> !printableUnicode(c) }).length == 0;"
        },
        {
          "source": "if (ascii || unicode && cps.length > 0) {"
        },
        {
          "source": "return [\"<<\", utf8Bytes(cps)"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "utf8Bytes",
      "is_pub": false,
      "params": [
        {
          "name": "cps",
          "type": "i32[]"
        }
      ],
      "return_type": "i32[]",
      "body": [
        {
          "source": "var out: i32[] = [];"
        },
        {
          "source": "var i = 0;"
        },
        {
          "source": "while (i < cps.length) {"
        },
        {
          "source": "return out;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "listText",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "BuildValue[]"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "if (xs.length == 0) return \"[]\";"
        },
        {
          "source": "val codes = xs.filter({ x -> printableCode(x) }).length == xs.length;"
        },
        {
          "source": "if (codes)"
        },
        {
          "source": "return [\"[\", xs.map({ x -> termText(x) }).join(\",\"), \"]\"].join(\"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "printableCode",
      "is_pub": false,
      "params": [
        {
          "name": "v",
          "type": "BuildValue"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "codeOf",
      "is_pub": false,
      "params": [
        {
          "name": "v",
          "type": "BuildValue"
        }
      ],
      "return_type": "i32",
      "body": [
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "atomText",
      "is_pub": false,
      "params": [
        {
          "name": "name",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val cps = name.chars().map({ c -> c.charCodeAt(0) });"
        },
        {
          "source": "val first = cps.at(0) ?? 0;"
        },
        {
          "source": "val plain = cps.length > 0"
        },
        {
          "source": "if (plain) return name;"
        },
        {
          "source": "val texts = name.chars();"
        },
        {
          "source": "var out: string[] = [\"'\"];"
        },
        {
          "source": "var i = 0;"
        },
        {
          "source": "while (i < cps.length) {"
        },
        {
          "source": "out.push(\"'\");"
        },
        {
          "source": "return out.join(\"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "reservedWord",
      "is_pub": false,
      "params": [
        {
          "name": "name",
          "type": "string"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "return [\"after\", \"and\", \"andalso\", \"band\", \"begin\", \"bnot\", \"bor\", \"bsl\", \"bsr\", \"bxor\", \"case\", \"catch\", \"cond\", \"div\", \"end\", \"fun\", \"if\", \"let\", \"maybe\", \"not\", \"of\", \"or\", \"orelse\", \"receive\", \"rem\", \"try\", \"when\", \"xor\", \"else\"].filter({ w -> w == name }).length"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "arrayText",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "Json[]"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return [\"[\", xs.map({ x -> jsonText(x) }).join(\",\"), \"]\"].join(\"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "objectText",
      "is_pub": false,
      "params": [
        {
          "name": "fs",
          "type": "JsonField[]"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return [\"{\", fs"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "sortedItems",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "Json[]"
        }
      ],
      "return_type": "Json[]",
      "body": [
        {
          "source": "return xs.map({ x -> jsonSorted(x) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "sortedMembers",
      "is_pub": false,
      "params": [
        {
          "name": "fs",
          "type": "JsonField[]"
        }
      ],
      "return_type": "JsonField[]",
      "body": [
        {
          "source": "return fs.map({ f -> JsonField(key: f.key, value: jsonSorted(f.value)) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "prettyArray",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "Json[]"
        },
        {
          "name": "indent",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "if (xs.length == 0) return \"[]\";"
        },
        {
          "source": "val inner = indent + \"  \";"
        },
        {
          "source": "return [\"[\\n\", xs"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "prettyObject",
      "is_pub": false,
      "params": [
        {
          "name": "fs",
          "type": "JsonField[]"
        },
        {
          "name": "indent",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "if (fs.length == 0) return \"{}\";"
        },
        {
          "source": "val inner = indent + \"  \";"
        },
        {
          "source": "return [\"{\\n\", fs"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "valueItems",
      "is_pub": false,
      "params": [
        {
          "name": "v",
          "type": "BuildValue"
        }
      ],
      "return_type": "BuildValue[]",
      "body": [
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "valueFields",
      "is_pub": false,
      "params": [
        {
          "name": "v",
          "type": "BuildValue"
        }
      ],
      "return_type": "BuildField[]",
      "body": [
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateItems",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "BuildValue[]"
        }
      ],
      "return_type": "Json[]",
      "body": [
        {
          "source": "return xs.map({ x -> templateValueJson(x) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateFields",
      "is_pub": false,
      "params": [
        {
          "name": "fs",
          "type": "BuildField[]"
        }
      ],
      "return_type": "JsonField[]",
      "body": [
        {
          "source": "return fs.map({ f -> JsonField(key: f.name, value: templateValueJson(f.value)) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateValuesOf",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "Json[]"
        }
      ],
      "return_type": "BuildValue[]",
      "body": [
        {
          "source": "return xs.map({ x -> templateValueOf(x) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "anyHoldsFn",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "BuildValue[]"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "return xs.filter({ x -> holdsFn(x) }).length > 0;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockItems",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "BuildValue[]"
        }
      ],
      "return_type": "Json[]",
      "body": [
        {
          "source": "return xs.map({ x -> blockValueJson(x) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockFields",
      "is_pub": false,
      "params": [
        {
          "name": "fs",
          "type": "BuildField[]"
        }
      ],
      "return_type": "JsonField[]",
      "body": [
        {
          "source": "return fs.map({ f -> JsonField(key: f.name, value: blockValueJson(f.value)) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockValuesOf",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "Json[]"
        }
      ],
      "return_type": "BuildValue[]",
      "body": [
        {
          "source": "return xs.map({ x -> blockValueOf(x) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "tupleText",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "BuildValue[]"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return [\"{\", xs.map({ x -> termText(x) }).join(\",\"), \"}\"].join(\"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "mapText",
      "is_pub": false,
      "params": [
        {
          "name": "fs",
          "type": "BuildField[]"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return [\"#{\", fs"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "decoratorContributions",
      "is_pub": false,
      "params": [
        {
          "name": "r",
          "type": "DecoratorReply"
        }
      ],
      "return_type": "Contribution[]",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "decoratorFrames",
      "is_pub": false,
      "params": [
        {
          "name": "r",
          "type": "DecoratorReply"
        }
      ],
      "return_type": "Frame[]",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateNotes",
      "is_pub": false,
      "params": [
        {
          "name": "r",
          "type": "TemplateReply"
        }
      ],
      "return_type": "string[]",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "templateFrames",
      "is_pub": false,
      "params": [
        {
          "name": "r",
          "type": "TemplateReply"
        }
      ],
      "return_type": "?Frame[]",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockFrames",
      "is_pub": false,
      "params": [
        {
          "name": "r",
          "type": "BlockReply"
        }
      ],
      "return_type": "Frame[]",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "MetaEntry",
      "fields": {
        "typeName": "string",
        "value": "BuildValue"
      }
    },
    {
      "ast": "record_def",
      "name": "MetaPair",
      "fields": {
        "key": "string",
        "value": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "DeclaredEntry",
      "fields": {
        "name": "string",
        "module": "string",
        "meta": "MetaPair[]",
        "returnTypeName": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "TypeArgEntry",
      "fields": {
        "name": "string",
        "module": "string",
        "fields": "Field[]",
        "methods": "Method[]",
        "meta": "MetaPair[]",
        "methodMeta": "MethodMeta[]"
      }
    },
    {
      "ast": "record_def",
      "name": "HookUseEntry",
      "fields": {
        "hook": "?DeclaredEntry",
        "annotations": "DeclAnnotation[]",
        "at": "string",
        "typeArgs": "TypeArgEntry[]",
        "context": "?DeclaredEntry"
      }
    },
    {
      "ast": "record_def",
      "name": "HookCallEntry",
      "fields": {
        "callee": "?DeclaredEntry",
        "at": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "HookEntry",
      "fields": {
        "function": "DeclaredEntry",
        "uses": "HookUseEntry[]",
        "calls": "HookCallEntry[]",
        "async": "bool",
        "stage": "Stage"
      }
    },
    {
      "ast": "record_def",
      "name": "MethodMeta",
      "fields": {
        "method": "string",
        "meta": "MetaEntry[]"
      }
    },
    {
      "ast": "record_def",
      "name": "DeclLookup",
      "fields": {
        "meta": "MetaEntry[]",
        "pending": "bool",
        "identity": "string",
        "local": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "AttrEntry",
      "fields": {
        "name": "string",
        "value": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "DeclTag",
      "fields": {
        "attrs": "AttrEntry[]",
        "meta": "MetaEntry[]"
      }
    },
    {
      "ast": "record_def",
      "name": "Decl",
      "fields": {
        "kind": "DeclKind",
        "name": "string",
        "fields": "Field[]",
        "variants": "Variant[]",
        "methods": "Method[]",
        "methodMeta": "MethodMeta[]",
        "returnType": "string",
        "annotations": "DeclAnnotation[]",
        "hooks": "HookEntry[]",
        "params": "Param[]",
        "component": "?Decl",
        "module": "string",
        "owner": "?DeclaredEntry",
        "package": "string",
        "lookup": "?DeclLookup",
        "tag": "?DeclTag"
      },
      "methods": [
        {
          "name": "of",
          "params": [
            {
              "name": "j",
              "type": "Json"
            }
          ],
          "return_type": "Decl"
        },
        {
          "name": "json",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "Json"
        },
        {
          "name": "binding",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "Binding"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declKindOf",
      "is_pub": false,
      "params": [
        {
          "name": "name",
          "type": "string"
        }
      ],
      "return_type": "DeclKind",
      "body": [
        {
          "source": "if (name == \"Behavior\") return DeclKind.Behavior;"
        },
        {
          "source": "if (name == \"Fn\") return DeclKind.Fn;"
        },
        {
          "source": "if (name == \"Method\") return DeclKind.Method;"
        },
        {
          "source": "if (name == \"Field\") return DeclKind.Field;"
        },
        {
          "source": "if (name == \"Val\") return DeclKind.Val;"
        },
        {
          "source": "if (name == \"Element\") return DeclKind.Element;"
        },
        {
          "source": "if (name == \"Component\") return DeclKind.Component;"
        },
        {
          "source": "return DeclKind.Type;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declKindName",
      "is_pub": false,
      "params": [
        {
          "name": "k",
          "type": "DeclKind"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case k {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Decl",
      "body": [
        {
          "source": "return Decl.of(j);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declJson",
      "is_pub": true,
      "params": [
        {
          "name": "d",
          "type": "Decl"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return d.json();"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "optionalDeclJson",
      "is_pub": false,
      "params": [
        {
          "name": "d",
          "type": "?Decl"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "if (d != null) return d.json();"
        },
        {
          "source": "return Json.JsonNull;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "isNull",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "isArray",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "boolField",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        },
        {
          "name": "key",
          "type": "string"
        }
      ],
      "return_type": "bool",
      "body": [
        {
          "source": "val v = jsonField(j, key) ?? Json.JsonNull;"
        },
        {
          "source": "return case v {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "textsOfJson",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "string[]",
      "body": [
        {
          "source": "return itemsOf(j).map({ x -> stringOf(x) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "textsJson",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "string[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonArray(items: xs.map({ x -> Json.JsonString(value: x) }));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declAnnotationOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "DeclAnnotation",
      "body": [
        {
          "source": "return DeclAnnotation(name: textField(j, \"name\") ?? \"\", args: textsOfJson(jsonField(j, \"args\") ?? Json.JsonNull), decorator: textField(j, \"decorator\") ?? \"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declAnnotationJson",
      "is_pub": true,
      "params": [
        {
          "name": "a",
          "type": "DeclAnnotation"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declAnnotationListOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "DeclAnnotation[]",
      "body": [
        {
          "source": "return itemsOf(j).map({ a -> declAnnotationOf(a) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declAnnotationListJson",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "DeclAnnotation[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonArray(items: xs.map({ a -> declAnnotationJson(a) }));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "paramListOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Param[]",
      "body": [
        {
          "source": "return itemsOf(j).map({ p -> Param(name: textField(p, \"name\") ?? \"\", typeName: textField(p, \"typeName\") ?? \"\") });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "paramListJson",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "Param[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonArray(items: xs.map({ p -> Json.JsonObject(fields: [JsonField(key: \"name\", value: Json.JsonString(value: p.name)), JsonField(key: \"typeName\", value: Json.JsonString(value: p.typeName))]) }));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "fieldOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Field",
      "body": [
        {
          "source": "return Field(name: textField(j, \"name\") ?? \"\", typeName: textField(j, \"typeName\") ?? \"\", annotations: declAnnotationListOf(jsonField(j, \"annotations\") ?? Json.JsonNull));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "fieldJson",
      "is_pub": true,
      "params": [
        {
          "name": "f",
          "type": "Field"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "fieldListOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Field[]",
      "body": [
        {
          "source": "return itemsOf(j).map({ f -> fieldOf(f) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "fieldListJson",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "Field[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonArray(items: xs.map({ f -> fieldJson(f) }));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "metaEntryOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "MetaEntry",
      "body": [
        {
          "source": "return MetaEntry(typeName: textField(j, \"type\") ?? \"\", value: templateValueOf(jsonField(j, \"value\") ?? Json.JsonNull));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "metaEntryJson",
      "is_pub": true,
      "params": [
        {
          "name": "m",
          "type": "MetaEntry"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "metaEntriesOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "MetaEntry[]",
      "body": [
        {
          "source": "return itemsOf(j).map({ m -> metaEntryOf(m) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "metaEntriesJson",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "MetaEntry[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonArray(items: xs.map({ m -> metaEntryJson(m) }));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "methodOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Method",
      "body": [
        {
          "source": "return Method("
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "methodJson",
      "is_pub": true,
      "params": [
        {
          "name": "m",
          "type": "Method"
        },
        {
          "name": "metas",
          "type": "MethodMeta[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "metaOfMethod",
      "is_pub": false,
      "params": [
        {
          "name": "name",
          "type": "string"
        },
        {
          "name": "metas",
          "type": "MethodMeta[]"
        }
      ],
      "return_type": "MetaEntry[]",
      "body": [
        {
          "source": "val found = metas.filter({ mm -> mm.method == name });"
        },
        {
          "source": "if (found.length == 0) return [];"
        },
        {
          "source": "return found[0]!.meta;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "methodMetaListOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "MethodMeta[]",
      "body": [
        {
          "source": "return itemsOf(j).map({ m -> MethodMeta(method: textField(m, \"name\") ?? \"\", meta: metaEntriesOf(jsonField(m, \"meta\") ?? Json.JsonNull)) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "methodListOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Method[]",
      "body": [
        {
          "source": "return itemsOf(j).map({ m -> methodOf(m) });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "methodListJson",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "Method[]"
        },
        {
          "name": "metas",
          "type": "MethodMeta[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonArray(items: xs.map({ m -> methodJson(m, metas) }));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "variantOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Variant",
      "body": [
        {
          "source": "return Variant("
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "variantJson",
      "is_pub": true,
      "params": [
        {
          "name": "v",
          "type": "Variant"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "metaPairsOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "MetaPair[]",
      "body": [
        {
          "source": "return itemsOf(j).map({ m -> MetaPair(key: textField(m, \"key\") ?? \"\", value: textField(m, \"value\") ?? \"\") });"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "metaPairsJson",
      "is_pub": false,
      "params": [
        {
          "name": "xs",
          "type": "MetaPair[]"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonArray(items: xs.map({ m -> Json.JsonObject(fields: [JsonField(key: \"key\", value: Json.JsonString(value: m.key)), JsonField(key: \"value\", value: Json.JsonString(value: m.value))]) }));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declaredEntryOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "DeclaredEntry",
      "body": [
        {
          "source": "return DeclaredEntry("
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declaredEntryJson",
      "is_pub": true,
      "params": [
        {
          "name": "d",
          "type": "DeclaredEntry"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "optionalDeclaredOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "?Json"
        }
      ],
      "return_type": "?DeclaredEntry",
      "body": [
        {
          "source": "val v = j ?? Json.JsonNull;"
        },
        {
          "source": "if (isNull(v)) return null;"
        },
        {
          "source": "return declaredEntryOf(v);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "optionalDeclaredJson",
      "is_pub": false,
      "params": [
        {
          "name": "d",
          "type": "?DeclaredEntry"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "if (d != null) return declaredEntryJson(d);"
        },
        {
          "source": "return Json.JsonNull;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "typeArgEntryOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "TypeArgEntry",
      "body": [
        {
          "source": "return TypeArgEntry("
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "typeArgEntryJson",
      "is_pub": false,
      "params": [
        {
          "name": "t",
          "type": "TypeArgEntry"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "hookUseEntryOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "HookUseEntry",
      "body": [
        {
          "source": "return HookUseEntry("
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "hookUseEntryJson",
      "is_pub": false,
      "params": [
        {
          "name": "u",
          "type": "HookUseEntry"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "stageOf",
      "is_pub": false,
      "params": [
        {
          "name": "name",
          "type": "string"
        }
      ],
      "return_type": "Stage",
      "body": [
        {
          "source": "if (name == \"Build\") return Stage.Build;"
        },
        {
          "source": "if (name == \"Run\") return Stage.Run;"
        },
        {
          "source": "return Stage.Any;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "stageName",
      "is_pub": false,
      "params": [
        {
          "name": "s",
          "type": "Stage"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case s {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "hookEntryOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "HookEntry",
      "body": [
        {
          "source": "return HookEntry("
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "hookEntryJson",
      "is_pub": true,
      "params": [
        {
          "name": "h",
          "type": "HookEntry"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declLookupOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "?DeclLookup",
      "body": [
        {
          "source": "if (textField(j, \"identity\") == null || jsonField(j, \"attrs\") != null)"
        },
        {
          "source": "val identity = textField(j, \"identity\") ?? \"\";"
        },
        {
          "source": "val meta = jsonField(j, \"meta\") ?? Json.JsonNull;"
        },
        {
          "source": "val first = itemsOf(meta).at(0) ?? Json.JsonNull;"
        },
        {
          "source": "val pending = case first {"
        },
        {
          "source": "return DeclLookup(meta: if (pending)"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "declTagOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "?DeclTag",
      "body": [
        {
          "source": "if (jsonField(j, \"attrs\") == null) return null;"
        },
        {
          "source": "val attrs = jsonField(j, \"attrs\") ?? Json.JsonNull;"
        },
        {
          "source": "return DeclTag("
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "CaptureSource",
      "fields": {
        "file": "string",
        "line": "i64",
        "col": "i64",
        "root": "string"
      }
    },
    {
      "ast": "record_def",
      "name": "CaptureContext",
      "fields": {
        "source": "CaptureSource",
        "text": "string",
        "multiline": "bool"
      }
    },
    {
      "ast": "record_def",
      "name": "Binding",
      "fields": {
        "name": "string",
        "kind": "string",
        "identity": "string",
        "local": "string",
        "handle": "?Decl"
      }
    },
    {
      "ast": "record_def",
      "name": "TagAnswer",
      "fields": {
        "decl": "Decl",
        "answer": "i64"
      }
    },
    {
      "ast": "record_def",
      "name": "Capture",
      "fields": {
        "param": "string",
        "text": "string",
        "source": "CaptureSource",
        "context": "CaptureContext",
        "bindings": "Binding[]",
        "words": "string[]",
        "name": "?string",
        "value": "?string",
        "holes": "Capture[]",
        "annotations": "TagAnswer[]"
      }
    },
    {
      "ast": "fn_def",
      "name": "captureSourceOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "CaptureSource",
      "body": [
        {
          "source": "return CaptureSource(file: textField(j, \"file\") ?? \"\", line: wholeOf(jsonField(j, \"line\") ?? Json.JsonNull), col: wholeOf(jsonField(j, \"col\") ?? Json.JsonNull), root: textField(j, \"root\") ?? \"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "captureSourceJson",
      "is_pub": false,
      "params": [
        {
          "name": "s",
          "type": "CaptureSource"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "bindingOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Binding",
      "body": [
        {
          "source": "if (jsonField(j, \"fields\") != null) return Decl.of(j).binding();"
        },
        {
          "source": "return Binding(name: textField(j, \"name\") ?? \"\", kind: textField(j, \"kind\") ?? \"\", identity: textField(j, \"identity\") ?? \"\", local: textField(j, \"local\") ?? \"\", handle: null);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "bindingJson",
      "is_pub": true,
      "params": [
        {
          "name": "b",
          "type": "Binding"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "val handle = b.handle;"
        },
        {
          "source": "if (handle != null) return handle.json();"
        },
        {
          "source": "return Json.JsonObject(fields: ["
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "captureOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Capture",
      "body": [
        {
          "source": "val context = jsonField(j, \"context\") ?? Json.JsonNull;"
        },
        {
          "source": "return Capture("
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "captureJson",
      "is_pub": true,
      "params": [
        {
          "name": "c",
          "type": "Capture"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "var fs: JsonField[] = ["
        },
        {
          "source": "if (c.value != null)"
        },
        {
          "source": "if (c.holes.length > 0)"
        },
        {
          "source": "if (c.annotations.length > 0)"
        },
        {
          "source": "return Json.JsonObject(fields: fs);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "tagAnswerJson",
      "is_pub": false,
      "params": [
        {
          "name": "a",
          "type": "TagAnswer"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "var fs = fieldsOf(a.decl.json());"
        },
        {
          "source": "fs.push(JsonField(key: \"__bp_answer\", value: Json.JsonInt(value: a.answer)));"
        },
        {
          "source": "return Json.JsonObject(fields: fs);"
        }
      ]
    },
    {
      "ast": "enum_def",
      "name": "InputArg",
      "variants": [
        {
          "name": "HandleArg",
          "fields": {
            "decl": "Decl"
          }
        },
        {
          "name": "CaptureArg",
          "fields": {
            "capture": "Capture"
          }
        },
        {
          "name": "PlainArg",
          "fields": {
            "value": "BuildValue"
          }
        },
        {
          "name": "Unbound"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "ArgText",
      "fields": {
        "text": "string",
        "name": "?string"
      }
    },
    {
      "ast": "record_def",
      "name": "Input",
      "fields": {
        "args": "InputArg[]",
        "texts": "?ArgText[]"
      }
    },
    {
      "ast": "fn_def",
      "name": "argOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "InputArg",
      "body": [
        {
          "source": "return case j {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "objectArgOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "InputArg",
      "body": [
        {
          "source": "if (jsonField(j, \"__bp_capture\") != null)"
        },
        {
          "source": "return InputArg.HandleArg(decl: Decl.of(j));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "argJson",
      "is_pub": true,
      "params": [
        {
          "name": "a",
          "type": "InputArg"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "return case a {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "inputOf",
      "is_pub": true,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "Input",
      "body": [
        {
          "source": "val items = itemsOf(j);"
        },
        {
          "source": "val first = items.at(0) ?? Json.JsonNull;"
        },
        {
          "source": "val paired = items.length == 2 && isArray(first);"
        },
        {
          "source": "if (paired)"
        },
        {
          "source": "return Input(args: items.map({ a -> argOf(a) }), texts: null);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "argTextOf",
      "is_pub": false,
      "params": [
        {
          "name": "j",
          "type": "Json"
        }
      ],
      "return_type": "ArgText",
      "body": [
        {
          "source": "val pair = itemsOf(j);"
        },
        {
          "source": "val name = pair.at(1) ?? Json.JsonNull;"
        },
        {
          "source": "return ArgText(text: stringOf(pair.at(0) ?? Json.JsonNull), name: if (isNull(name))"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "inputJson",
      "is_pub": true,
      "params": [
        {
          "name": "i",
          "type": "Input"
        }
      ],
      "return_type": "Json",
      "body": [
        {
          "source": "val args = Json.JsonArray(items: i.args.map({ a -> argJson(a) }));"
        },
        {
          "source": "val texts = i.texts;"
        },
        {
          "source": "if (texts == null) return args;"
        },
        {
          "source": "return Json.JsonArray(items: [args, Json.JsonArray(items: texts.map({ t -> Json.JsonArray(items: [Json.JsonString(value: t.text), optionalText(t.name)]) }))]);"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "evalDecorator",
      "is_pub": true,
      "params": [
        {
          "name": "input",
          "type": "string"
        },
        {
          "name": "body",
          "type": "fn(Input) -> DecoratorReply"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val read = jsonRead(input);"
        },
        {
          "source": "val reply = if (read.isError())"
        },
        {
          "source": "return decoratorEnd(reply, printedSoFar());"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "evalTemplate",
      "is_pub": true,
      "params": [
        {
          "name": "input",
          "type": "string"
        },
        {
          "name": "body",
          "type": "fn(Input) -> TemplateReply"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val read = jsonRead(input);"
        },
        {
          "source": "val reply = if (read.isError())"
        },
        {
          "source": "printedSoFar();"
        },
        {
          "source": "return jsonText(templateReplyJson(reply));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "evalBlock",
      "is_pub": true,
      "params": [
        {
          "name": "body",
          "type": "fn() -> BlockReply"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "val reply = body();"
        },
        {
          "source": "return blockEnd(reply, printedSoFar());"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "decoratorEnd",
      "is_pub": true,
      "params": [
        {
          "name": "reply",
          "type": "DecoratorReply"
        },
        {
          "name": "printed",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return jsonText(decoratorReplyJson(decoratorWithPrinted(reply, printedOf(printed))));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockEnd",
      "is_pub": true,
      "params": [
        {
          "name": "reply",
          "type": "BlockReply"
        },
        {
          "name": "printed",
          "type": "string"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return jsonText(blockReplyJson(blockWithPrinted(reply, printedOf(printed))));"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "printedSoFar",
      "is_pub": false,
      "params": [],
      "return_type": "string",
      "body": []
    },
    {
      "ast": "fn_def",
      "name": "printedSoFarOnWasm",
      "is_pub": false,
      "params": [],
      "return_type": "string",
      "body": [
        {
          "source": "return closeCapture(\"\");"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "unreadableInput",
      "is_pub": false,
      "params": [
        {
          "name": "read",
          "type": "Result<Json,string>"
        }
      ],
      "return_type": "string",
      "body": [
        {
          "source": "return case read {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "printedOf",
      "is_pub": false,
      "params": [
        {
          "name": "kept",
          "type": "string"
        }
      ],
      "return_type": "?string",
      "body": [
        {
          "source": "if (kept == \"\") return null;"
        },
        {
          "source": "return kept;"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "decoratorWithPrinted",
      "is_pub": true,
      "params": [
        {
          "name": "r",
          "type": "DecoratorReply"
        },
        {
          "name": "printed",
          "type": "?string"
        }
      ],
      "return_type": "DecoratorReply",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    },
    {
      "ast": "fn_def",
      "name": "blockWithPrinted",
      "is_pub": true,
      "params": [
        {
          "name": "r",
          "type": "BlockReply"
        },
        {
          "name": "printed",
          "type": "?string"
        }
      ],
      "return_type": "BlockReply",
      "body": [
        {
          "source": "return case r {"
        }
      ]
    }
  ]
}
```


----- SOURCE CODE -- shapes.bp
```botopink
pub type Item(id: i32)
```

----- TYPED AST JSON -- shapes.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "Item",
      "fields": {
        "id": "i32"
      }
    }
  ]
}
```


----- SOURCE CODE -- main.bp
```botopink
import {Item} from "shapes";
pub fn dsl(syntax e: string) -> anyvalue {
    val code = compiler.build("41");
    val leaf = CustomNode(kind: "field", span: Span(7, 9, 1), label: "property", ref: compiler.lookup(e, "Item"), children: []);
    val root = CustomNode(kind: "select", span: Span(0, 6, 1), label: "keyword", ref: null, children: [leaf]);
    compiler.custom(root);
    return code;
}
val rows = dsl @`select id from Item`;

import {compiler, compiler.Span, compiler.CustomNode} from "std";
```

----- BOTOPINK TRANSFORM CODE -- main.bp
```botopink
import {Item} from "shapes";

pub val rows = 41;

import {compiler.Span, compiler.CustomNode} from "std";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "fn_def",
      "name": "dsl",
      "is_pub": true,
      "generic_params": [
        "__anyvalue"
      ],
      "params": [
        {
          "name": "e",
          "type": "__Expr<string>",
          "is_comptime": true
        }
      ],
      "return_type": "CustomExpr<'a>",
      "body": [
        {
          "source": "val code = compiler.build(\"41\");"
        },
        {
          "source": "val leaf = CustomNode(kind: \"field\", span: Span(7, 9, 1), label: \"property\", ref: compiler.lookup(e, \"Item\"), children: []);"
        },
        {
          "source": "val root = CustomNode(kind: \"select\", span: Span(0, 6, 1), label: \"keyword\", ref: null, children: [leaf]);"
        },
        {
          "source": "compiler.custom(root);"
        },
        {
          "source": "return code;"
        }
      ]
    },
    {
      "ast": "val",
      "ident": "rows",
      "return_type": "i32"
    },
    {
      "ast": "use",
      "declarations": [
        {
          "ast": "use-declaration",
          "ident": "Item",
          "return_type": "fn(i32) -> Item"
        },
        {
          "ast": "use-declaration",
          "ident": "Span",
          "return_type": "fn(i32, i32, i32) -> __Span"
        },
        {
          "ast": "use-declaration",
          "ident": "CustomNode",
          "return_type": "fn(string, __Span, string, ?__Decl, __CustomNode[]) -> __CustomNode"
        }
      ]
    }
  ]
}
```

