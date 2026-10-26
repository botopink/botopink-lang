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

function __bp_text(v, s) {
    const a = [];
    let i = 0;
    return __bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

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

////   what `load` answers: `Module` — run by `m.run()` (decisions 787, 792) —,

////   `Refused`, `Diagnostic`.

//// 

//// `setBuiltin`, `embed`, `fields` over a type,

//// `optional` and `required` join it with the steps that build them.

// behavior Compiler
//   module: string
//   package: string
//   isStd: bool
//   fn src(...)
//   fn fail(...)
//   fn note(...)
//   fn setMeta(...)
//   fn addMeta(...)
//   fn addMember(...)
//   fn addType(...)
//   fn init(...)
//   fn implement(...)
//   fn text(...)
//   fn name(...)
//   fn source(...)
//   fn context(...)
//   fn lookup(...)
//   fn bindings(...)
//   fn holes(...)
//   fn build(...)
//   fn ast(...)
//   fn isSyntax(...)
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
//   fn find(...)
//   fn typeInfo(...)
//   fn load(...)

// The value the module's import binds (decision 579): its value is given by

// the compiler at each point, so it has no body.

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

// How the BEAM holds a module `var` (decision 547): a `var` is one value for

// the whole program on every target; `Ets`, what a `var` with no annotation

// means, is a one-row ETS table, `x = f(x)` atomic; `PersistentTerm` suits a

// `var` written rarely and read much — a write scans every process. Off the

// BEAM the annotation is accepted and changes nothing (`ast.zig`

// `ValDecl.memory`, `infer.zig` `validateMemoryAnnotations`).

class BeamMemory {
    toString() {
        return __bp_text(this);
    }
}
BeamMemory.prototype.__bp = "BeamMemory";
class BeamMemory$Ets extends BeamMemory {
}
BeamMemory$Ets.prototype.tag = "Ets";
class BeamMemory$PersistentTerm extends BeamMemory {
}
BeamMemory$PersistentTerm.prototype.tag = "PersistentTerm";
BeamMemory.Ets = new BeamMemory$Ets();
BeamMemory.PersistentTerm = new BeamMemory$PersistentTerm();
exports.BeamMemory = BeamMemory;

// ── The typed AST `compiler.ast` builds code from (decision 625 (2)) ──────

// One record per kind of expression a template answers, each with a field

// set of its own: a body that runs at build reads a record by its fields.

// A name, resolved in the module that wrote the tree: `Name("double")`.

class Name {
    constructor(name) {
        this.name = name;
    }
}
Name.prototype.__bp = "Name";
exports.Name = Name;

// A value known at build, spliced as its literal: `Lit(3)`, `Lit("a")`,

// `Lit([1, 2])`.

class Lit {
    constructor(value) {
        this.value = value;
    }
}
Lit.prototype.__bp = "Lit";
exports.Lit = Lit;

// `target.member`.

class Member {
    constructor(target, member) {
        this.target = target;
        this.member = member;
    }
}
Member.prototype.__bp = "Member";
exports.Member = Member;

// A call: `callee` a `Name`, a `Member` (a method call) or any node; each

// argument a node (positional) or an `Arg` (labelled).

class Call {
    constructor(callee, args) {
        this.callee = callee;
        this.args = args;
    }
}
Call.prototype.__bp = "Call";
exports.Call = Call;

// A labelled argument, `name: value` — only an argument of a `Call`.

class Arg {
    constructor(name, value) {
        this.name = name;
        this.value = value;
    }
}
Arg.prototype.__bp = "Arg";
exports.Arg = Arg;

// `[a, b]`.

class List {
    constructor(items) {
        this.items = items;
    }
}
List.prototype.__bp = "List";
exports.List = List;

// `#(a, b)`.

class Tuple {
    constructor(elems) {
        this.elems = elems;
    }
}
Tuple.prototype.__bp = "Tuple";
exports.Tuple = Tuple;

// `lhs op rhs`, `op` one of `+ - * / % == != < > <= >= && ||`.

class Binary {
    constructor(op, lhs, rhs) {
        this.op = op;
        this.lhs = lhs;
        this.rhs = rhs;
    }
}
Binary.prototype.__bp = "Binary";
exports.Binary = Binary;

// `op operand`, `op` one of `-` and `!`.

class Unary {
    constructor(op, operand) {
        this.op = op;
        this.operand = operand;
    }
}
Unary.prototype.__bp = "Unary";
exports.Unary = Unary;

// `if (cond) then else otherwise`.

class If {
    constructor(cond, then, otherwise) {
        this.cond = cond;
        this.then = then;
        this.otherwise = otherwise;
    }
}
If.prototype.__bp = "If";
exports.If = If;

// `{ a, b -> body }`.

class Lambda {
    constructor(params, body) {
        this.params = params;
        this.body = body;
    }
}
Lambda.prototype.__bp = "Lambda";
exports.Lambda = Lambda;

// The code a `syntax` value holds, spliced as it was written and typed where

// the splice stands (decision 638).

class Syntax {
    constructor(e) {
        this.e = e;
    }
}
Syntax.prototype.__bp = "Syntax";
exports.Syntax = Syntax;

// A typed function, `fn(a: A, b: B) -> R { … }` (decision 753): each

// parameter an `FnParam`, `ret` a type node, `body` its statements in order.

// `Lambda` stays the untyped one.

class Fn {
    constructor(params, ret, body) {
        this.params = params;
        this.ret = ret;
        this.body = body;
    }
}
Fn.prototype.__bp = "Fn";
exports.Fn = Fn;

// A typed parameter, `name: annotation` — only an element of `Fn.params`.

class FnParam {
    constructor(name, annotation) {
        this.name = name;
        this.annotation = annotation;
    }
}
FnParam.prototype.__bp = "FnParam";
exports.FnParam = FnParam;

// `return result`.

class Return {
    constructor(result) {
        this.result = result;
    }
}
Return.prototype.__bp = "Return";
exports.Return = Return;

// The type nodes (decision 753), one per kind of the parser's type grammar;

// a type node stands only where a type is written — an `FnParam`'s

// annotation, a `Fn`'s `ret`, inside another type node.

// A type by its name: `string`, `Self`, `Greeter`.

class NamedType {
    constructor(named) {
        this.named = named;
    }
}
NamedType.prototype.__bp = "NamedType";
exports.NamedType = NamedType;

// `T[]`.

class ArrayType {
    constructor(elem) {
        this.elem = elem;
    }
}
ArrayType.prototype.__bp = "ArrayType";
exports.ArrayType = ArrayType;

// `#(A, B)`.

class TupleType {
    constructor(types) {
        this.types = types;
    }
}
TupleType.prototype.__bp = "TupleType";
exports.TupleType = TupleType;

// `#(a: A, b: B)`.

class LabeledTupleType {
    constructor(types, labels) {
        this.types = types;
        this.labels = labels;
    }
}
LabeledTupleType.prototype.__bp = "LabeledTupleType";
exports.LabeledTupleType = LabeledTupleType;

// `?T`.

class OptionalType {
    constructor(inner) {
        this.inner = inner;
    }
}
OptionalType.prototype.__bp = "OptionalType";
exports.OptionalType = OptionalType;

// `fn(A, B) -> R`.

class FnType {
    constructor(params, returns) {
        this.params = params;
        this.returns = returns;
    }
}
FnType.prototype.__bp = "FnType";
exports.FnType = FnType;

// `Name<A, B>`: `Result<T, E>`, `Dict<K, V>`.

class GenericType {
    constructor(name, args) {
        this.name = name;
        this.args = args;
    }
}
GenericType.prototype.__bp = "GenericType";
exports.GenericType = GenericType;

// `A | B`.

class UnionType {
    constructor(members) {
        this.members = members;
    }
}
UnionType.prototype.__bp = "UnionType";
exports.UnionType = UnionType;

// ── A refusal `compiler.load` answers (decisions 780 (2), 781) ────────────

// One refusal of the loaded package, as `botopink build` prints it: `message`

// the text after `error: ` (after `error[<code>]: ` when the refusal carries

// its code there), `code` the refusal's code (`""` when it has none), `file`

// relative to the loaded package's root with `line` and `column` where the refusal

// points (`""` and `0` when it points nowhere), `label` the text beside the

// caret when there is one, `` `from` `` the calls (decision 532) a refusal raised at

// build in another file crossed after the innermost one, each

// `<file>:<line>:<col>`, innermost first (`[]` when there are none).

class Diagnostic {
    constructor(code, message, file, line, column, label, $60from$60) {
        this.code = code;
        this.message = message;
        this.file = file;
        this.line = line;
        this.column = column;
        this.label = label;
        this["`from`"] = $60from$60;
    }
}
Diagnostic.prototype.__bp = "Diagnostic";
exports.Diagnostic = Diagnostic;

// ── What `compiler.load` answers (decisions 786, 787, 792, 811) ──────────

// The loaded package (decisions 786 (1), 805 (4), 982 (4)): `name()` its

// manifest's name, `path()` the directory as written (`cases/<case>`),

// `buildOutput()` what its build printed (a top-level `comptime` block's

// `print`, in order, each line ending in `\n`, before its refusals — decisions

// 904, 989 (4); `""` when none). No target — comptime

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

class Module {
    constructor(name, path, buildOutput) {
        this.name = name;
        this.path = path;
        this.buildOutput = buildOutput;
    }

    static of(name, path, buildOutput) {
        return new Module(name, path, buildOutput);
    }

    name() {
        return this.name;
    }

    path() {
        return this.path;
    }

    buildOutput() {
        return this.buildOutput;
    }

    run() {
        return ({ error: new RunFailure(RunFailureKind.Abort, "Module.run: every call is lowered to the loaded main", "") });
    }

    static captureOpen() {
        return (() => { const __s = globalThis.process.stdout; const __o = __s.write; const __b = []; __s.write = function (__c, __e, __k) { __b.push(typeof __c === "string" ? __c : Buffer.from(__c).toString(typeof __e === "string" ? __e : "utf8")); const __d = typeof __e === "function" ? __e : __k; if (typeof __d === "function") { __d(); } return true; }; return { write: __o, kept: __b }; })();
    }

    static captureClose(open) {
        return ((__t) => { globalThis.process.stdout.write = __t.write; return __t.kept.join(""); })(open);
    }
}
Module.prototype.__bp = "Module";
exports.Module = Module;

// The capture per target (989 (1)): commonJS swaps `process.stdout.write`

// for one that keeps the text; erlang and beam make a process the caller's

// group leader, answering the io protocol's output requests by keeping their

// text; wasm points the print helper's `$__write_bytes` at a string. The

// handle each answers is the capture it replaced, typed `string` only to

// cross the call: nothing reads it but `closeCapture`.

// openCapture: per-call template (see annotation)

// closeCapture: per-call template (see annotation)

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

class RunFailure {
    constructor(kind, message, output) {
        this.kind = kind;
        this.message = message;
        this.output = output;
    }
}
RunFailure.prototype.__bp = "RunFailure";
exports.RunFailure = RunFailure;

// The kinds of a `RunFailure`.

class RunFailureKind {
    toString() {
        return __bp_text(this);
    }
}
RunFailureKind.prototype.__bp = "RunFailureKind";
class RunFailureKind$Failed extends RunFailureKind {
}
RunFailureKind$Failed.prototype.tag = "Failed";
class RunFailureKind$Abort extends RunFailureKind {
}
RunFailureKind$Abort.prototype.tag = "Abort";
class RunFailureKind$Refused extends RunFailureKind {
}
RunFailureKind$Refused.prototype.tag = "Refused";
class RunFailureKind$Excluded extends RunFailureKind {
}
RunFailureKind$Excluded.prototype.tag = "Excluded";
RunFailureKind.Failed = new RunFailureKind$Failed();
RunFailureKind.Abort = new RunFailureKind$Abort();
RunFailureKind.Refused = new RunFailureKind$Refused();
RunFailureKind.Excluded = new RunFailureKind$Excluded();
exports.RunFailureKind = RunFailureKind;

// A load that refused: the loaded file's `Module` and its refusals, never

// empty.

class Refused {
    constructor(module, diagnostics) {
        this.module = module;
        this.diagnostics = diagnostics;
    }
}
Refused.prototype.__bp = "Refused";
exports.Refused = Refused;

// ── The types `compiler` answers (decision 576 (13)) ──────────────────────

// No prelude name: a file naming one imports it, `import {compiler.Span} from

// "std";`. Each is the compiler's own type, written here under its name.

Object.defineProperty(exports, "__bp_priv__", { value: { BeamMemory, BeamMemory$Ets, BeamMemory$PersistentTerm, Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType, Diagnostic, Module, RunFailure, RunFailureKind, RunFailureKind$Failed, RunFailureKind$Abort, RunFailureKind$Refused, RunFailureKind$Excluded, Refused } });
