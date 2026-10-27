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

pub type DeclKind = __DeclKind;

pub type DeclAnnotation = __Decl__Annotation;

pub type Param = __Decl__Param;

pub type Field = __Decl__Field;

pub type Method = __Decl__Method;

pub type Variant = __Decl__Variant;

pub type HookNode = __HookNode;

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
              "type": "__DeclKind"
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
          "return_type": "__DeclKind"
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
          "return_type": "__Decl__Field[]"
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
          "return_type": "__Decl__Method[]"
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
          "return_type": "__Decl__Param[]"
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
          "return_type": "__Decl__Annotation[]"
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
          "return_type": "__Decl__Variant[]"
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
      "ast": "typeAlias"
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

