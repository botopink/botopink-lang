----- SOURCE CODE -- std/context.bp
```botopink
//// Contexts (decisions 354, 378, 379) — what a component's body reads from
//// above it, React's context in botopink's spelling.
////
//// A context's identity is its value's type. `createContext(value)` at
//// module level declares a context value carrying the default of that type
//// — one declaration per type in the program:
////
////     pub val themeContext = comptime createContext(Theme(mode: .Light));
////
//// A component provides a context to everything it renders below it, and a
//// body reads through a context value it declares or imports — the nearest
//// context of that value's type provided above it, else the value's own
//// default (decisions 722, 723):
////
////     val c = comptime createContext(Theme(mode: .Dark));
////     use provide(c);                                    // the children's
////     val theme = use context(themeContext);             // the nearest above
////
//// Both are hooks, so they are `use`d, never called for a value; `provide`
//// only in a `component` body answering `Component<R>`, in the order
//// written: what the body resolves after it reads it, what it resolved
//// before does not (decision 812 (3)). `use` exists only where there
//// is a render tree — a decorator body, a template body and a
//// `comptime { … }` have none (`use-outside-render-tree`). A read naming a
//// bare type (`use context(Theme)`) is refused at the argument
//// (`context-read-by-type`).
////
//// A component at run time is a function over a `Scope` and a `Place`
//// (decisions 809, 815, 819): calling `Card(item)` only makes it, and std's
//// `resolve(c, scope, key)` runs it — the one way a component runs: `use c`
//// in a component body, each child a render library meets, and the root,
//// which a program runs with `await run(App())` (decisions 822, 825). Each
//// component body opens its own cell, `scope.childAt(key)`, a child of the
//// cell it was handed; a `use provide(…)` writes the body's cell, so what
//// the body resolves after it — its subtree — reads it, and a `use
//// context(…)` reads the contexts the cell held when the body entered
//// (decisions 809 (8), 812). The scope travels explicitly: no "current
//// context", on any target.
////
//// The work is the compiler's: each `use provide(…)` / `use context(…)` is
//// lowered where it is written — `provide` makes the children's scope and
//// `context` looks the received one up, the declared default when nothing
//// of its type is provided. Neither hook below is ever called: the checker
//// refuses every reference to them but a `use`'s operand, and the bodies
//// panic.

import {compiler, failure.panic};

// A context of `T`: the value a provider gives, or a type's declared default.
pub type Context<T>(contextValue: T)

// A context of `value`'s type. At module level it declares that type's
// default (decisions 378, 379); inside a component it makes the context a
// `use provide(…)` gives.
pub fn createContext<T>(value: T) -> Context<T> {
    return Context(contextValue: value);
}

// Gives `ctx` to every component this component renders below it — never
// to itself or a sibling; the nearest provider of a type wins.
pub component fn provide<T>(ctx: Context<T>) -> Component<void> {
    panic(
        "`use provide` / `use context` are lowered where they are written; this body never runs",
    );
}

// The value of the context of `ctx`'s type provided nearest above this body,
// or `ctx`'s own default: `use context(themeContext)` names a context value
// the module declares or imports, never a bare type (decisions 722, 723).
pub component fn context<T>(ctx: Context<T>) -> Component<T> {
    panic(
        "`use provide` / `use context` are lowered where they are written; this body never runs",
    );
}

// Decision 416 — the record `T` built from the contexts of its fields'
// types: each field the nearest context of its type provided above, else
// that type's declared default, else the field's own default (`use
// inject(Deps)`). `T` is a record; a behavior is read with `use context`.
// `createContext(value, Behavior)` keys a context by the behavior its value
// implements, so a field typed by the behavior reads it.
pub component fn inject(comptime t: anytype) -> Component<unknown> {
    panic(
        "`use inject` is lowered where it is written; this body never runs",
    );
}

// ── the place (decisions 819, 820, 884, 891) ─────────────────────────────────

// Where a component stands among its siblings (819 (2)): the number of the
// call that made it, and its item half — absent, a count the call's
// component body or plain function made (821), a list runner's index, or a
// key. A program passes `Place.none()` (the place the value carries), or
// runs one by hand with `Place.key(k)` / `Place.index(i)` (819 (3), 884).
pub type Place(callNo: i32, item: PlaceItem, itemNo: i32, keyValue: unknown) {
    // The place the component's value carries (820 (2)): what `use c` and a
    // root pass.
    pub fn none() -> Place {
        return Place(callNo: 0, item: PlaceItem.Absent, itemNo: 0, keyValue: null);
    }

    // `k` in the item's stead, the call's number kept (819 (3)).
    pub fn key<K>(k: K) -> Place {
        return Place(callNo: 0, item: PlaceItem.Key, itemNo: 0, keyValue: k);
    }

    // Position `i` in a list run — `all`'s entries and a render library's
    // children (884, 891).
    pub fn index(i: i32) -> Place {
        return Place(callNo: 0, item: PlaceItem.Index, itemNo: i, keyValue: null);
    }

    // This place as `key` says it is run (820 (2), 884 (1), 891 (1)): a key
    // replaces the item half; an index fills an absent one or a plain
    // function's count and keeps a body's count and a key; `Place.none()`
    // keeps it whole.
    pub fn with(self: Self, key: Place) -> Place {
        if (key.item == PlaceItem.Key)
            return Place(callNo: self.callNo, item: PlaceItem.Key, itemNo: 0, keyValue: key.keyValue);
        if (key.item == PlaceItem.Index)
            if (self.item == PlaceItem.Absent || self.item == PlaceItem.Plain)
                return Place(callNo: self.callNo, item: PlaceItem.Index, itemNo: key.itemNo, keyValue: null);
        return self;
    }
}

// A place's item half (891 (1)).
pub type PlaceItem { Absent, Body, Plain, Index, Key }

// ── the scope (decisions 809 (8), 817, 824, 825) ─────────────────────────────

// A cell of a render's tree: the contexts provided above it, a persistent map
// keyed by each context's identity. Opaque — made only by `Scope.root()`, a
// cell's `childAt` and `detach`. A root's whole tree is one entry: on erlang
// and beam an entry `{bp_scope, Ref}` of the process dictionary of the
// process that made the root, ended by that process or by `close()`; on
// commonJS a plain object, on wasm a heap cell (824). A scope used after its
// root's `close()` fails `scope-closed` on every target (825 (2)); one read in
// another process than the root's fails `scope-foreign` (824 (3)).
pub opaque type Scope(scopeStore: unknown, scopeCell: i32, scopeOwner: unknown, scopeCarried: unknown) implement Closeable {
    // A new root: an empty tree, nothing provided. Closed by whoever made it
    // (`run` closes its own, 825 (1)).
    pub fn root() -> Scope {
        return Scope(scopeStore: storeOf(null), scopeCell: 0, scopeOwner: ownerSelf(), scopeCarried: null);
    }

    // The child cell of this one at `key`: it starts from this cell's contexts
    // as they stand (817 (5)). Each component body opens its own with it.
    pub fn childAt(self: Self, key: Place) -> Scope {
        return Scope(scopeStore: self.scopeStore, scopeCell: grow(self.scopeStore, self.scopeOwner, self.scopeCarried, self.scopeCell), scopeOwner: self.scopeOwner, scopeCarried: self.scopeCarried);
    }

    // Ends the root's tree (`Closeable`, 539): every scope of it fails
    // `scope-closed` after, and on erlang and beam its process-dictionary
    // entry is erased (825 (2)). Closing a closed root does nothing.
    pub fn close(self: Self) -> void {
        closeStore(self.scopeStore);
    }

    // A new root over this cell's contexts as they stand, with no tree — what
    // crosses a process (824 (3)): it carries the contexts, and each process
    // that reads it keeps its tree in its own entry; closed by whoever made it.
    pub fn detach(self: Self) -> Scope {
        val carried = Carried(frames: framesAt(self.scopeStore, self.scopeOwner, self.scopeCarried, self.scopeCell));
        return Scope(scopeStore: storeNew(), scopeCell: 0, scopeOwner: null, scopeCarried: carried);
    }

    // The root's store, the cell's id and the root's process — what the
    // lowering's functions below read the tree by.
    fn storeRef(self: Self) -> unknown {
        return self.scopeStore;
    }

    fn cellId(self: Self) -> i32 {
        return self.scopeCell;
    }

    fn ownerRef(self: Self) -> unknown {
        return self.scopeOwner;
    }

    fn carriedRef(self: Self) -> unknown {
        return self.scopeCarried;
    }
}

// A root's tree: whether it is closed, the count of its cells, and each
// cell's contexts, the latest entry for an id first. Public as `Frame` is: a
// program never names it.
pub type ScopeTree(treeClosed: bool, treeCount: i32, treeCells: unknown)

// The contexts a detached root carries across processes (824 (3)).
pub type Carried(frames: unknown)

// One cell's contexts in a root's tree.
pub type CellEntry(cellNo: i32, cellFrames: unknown, cellNext: unknown)

// A new root's store, its one cell holding `frames`.
fn storeOf(frames: unknown) -> unknown {
    val store = storeNew();
    storeSet(store, ScopeTree(treeClosed: false, treeCount: 1, treeCells: CellEntry(cellNo: 0, cellFrames: frames, cellNext: null)));
    return store;
}

// The root's tree, live and in its own process; a detached root's starts in
// each process that reads it from the contexts it carries.
fn treeOf(store: unknown, owner: unknown, carried: unknown) -> ScopeTree {
    if (ownerForeign(owner))
        panic("scope-foreign: a scope is read in another process than its root's — pass `scope.detach()` to another process (decision 824 (3))");
    if (!storeLive(store))
        if (carried is Carried) {
            val c: Carried = carried;
            val t = ScopeTree(treeClosed: false, treeCount: 1, treeCells: CellEntry(cellNo: 0, cellFrames: carriedFrames(c), cellNext: null));
            storeSet(store, t);
            return t;
        }
    if (storeLive(store)) {
        val raw = storeGet(store);
        if (raw is ScopeTree) {
            val t: ScopeTree = raw;
            if (!t.treeClosed) return t;
        }
    }
    panic("scope-closed: a scope is used after its root's `close()` (decision 825 (2))");
}

// A new cell under cell `parent`, starting from its contexts: its id.
fn grow(store: unknown, owner: unknown, carried: unknown, parent: i32) -> i32 {
    val t = treeOf(store, owner, carried);
    val id = t.treeCount;
    storeSet(store, ScopeTree(treeClosed: false, treeCount: id
        + 1, treeCells: CellEntry(cellNo: id, cellFrames: framesOf(t.treeCells, parent), cellNext: t.treeCells)));
    return id;
}

// The contexts cell `id` holds now.
fn framesAt(store: unknown, owner: unknown, carried: unknown, id: i32) -> unknown {
    return framesOf(treeOf(store, owner, carried).treeCells, id);
}

fn carriedFrames(c: Carried) -> unknown {
    return c.frames;
}

// `value` provided for `key` in cell `id`.
fn provideAt(store: unknown, owner: unknown, carried: unknown, id: i32, key: string, value: unknown) -> void {
    val t = treeOf(store, owner, carried);
    val frames = Frame(key: key, value: value, parent: framesOf(t.treeCells, id));
    storeSet(store, ScopeTree(treeClosed: false, treeCount: t.treeCount, treeCells: CellEntry(cellNo: id, cellFrames: frames, cellNext: t.treeCells)));
}

// The root's tree closed; a closed one is left as it is.
fn closeStore(store: unknown) -> void {
    if (!storeLive(store)) return;
    storeClose(store, ScopeTree(treeClosed: true, treeCount: 0, treeCells: null));
}

// The contexts of cell `id` in `cells`.
fn framesOf(cells: unknown, id: i32) -> unknown {
    var cur = cells;
    loop {
        if (cur is CellEntry) {
            val e: CellEntry = cur;
            if (e.cellNo == id) return entryFrames(e);
            cur = entryNext(e);
        } else return null;
    }
}

fn entryFrames(e: CellEntry) -> unknown {
    return e.cellFrames;
}

fn entryNext(e: CellEntry) -> unknown {
    return e.cellNext;
}

// ── resolving and running (decisions 809 (6), 815 (5), 819, 822, 825) ───────

// Runs `c` over `scope` at `key` and hands back its answer as it came — a
// value, or the task of a component that awaits —, nothing awaited inside.
pub fn resolve<T>(c: Component<T>, scope: Scope, key: Place) -> T | Async<T> {
    if (c is Composable<T>) return c.compose()(scope, key);
    return c(scope, key);
}

// Runs a root: `c` resolved over `scope`, or over a root of its own that it
// closes when `c` settles or fails (825 (1)), awaited only when it answered a
// task (822, 823): `val page = await run(App());`.
pub async fn run<T>(c: Component<T>, scope: ?Scope = null) -> Async<T> {
    if (scope != null) {
        val handed = resolve(c, scope, Place.none());
        if (handed is Async<unknown>) return await handed;
        return handed;
    }
    val root = Scope.root();
    defer root.close();
    val r = resolve(c, root, Place.none());
    if (r is Async<unknown>) return await r;
    return r;
}

// ── what the scope lowering calls (decisions 809 (8), 812, 819) ──────────────
//
// A program never names these: the compiler imports them under names no
// source can spell. A component body is lowered to `{ scope, key -> … }`
// opening `enter(scope, key)`, its own cell; `use provide(c)` is
// `provideIn(<cell>, <T's identity>, c)` (a context is its value at run time:
// the compiler writes `createContext(v)` as `v`), `use context(ctx)` is
// `find(<the cell's contexts at entry>, <ctx's type's identity>, ctx)`, a
// `use` of a hook or a component calls its value with the cell and
// `Place.none()`, and each `return v` answers `answer(v)`. A context's
// identity is its value's type (379) — the compiler writes it, never a
// program.

// One provided value over the frames it was provided in.
pub type Frame(key: string, value: unknown, parent: unknown)

// The cell a body opens: `scope`'s child at `key`.
pub fn enter(scope: unknown, key: unknown) -> unknown {
    if (scope is Scope) {
        if (key is Place) return scope.childAt(key);
        return scope.childAt(Place.none());
    }
    panic("a component is run with a `Scope` (decision 819)");
}

// The contexts `cell` holds now — what a body's `use context` reads.
pub fn received(cell: unknown) -> unknown {
    if (cell is Scope)
        return framesAt(cell.storeRef(), cell.ownerRef(), cell.carriedRef(), cell.cellId());
    panic("a component is run with a `Scope` (decision 819)");
}

// `value` provided for `key` in `cell`: what is resolved under it afterwards
// reads it (809 (8), 812 (3)).
pub fn provideIn(cell: unknown, key: string, value: unknown) -> unknown {
    if (cell is Scope) {
        provideAt(cell.storeRef(), cell.ownerRef(), cell.carriedRef(), cell.cellId(), key, value);
        return null;
    }
    panic("a component is run with a `Scope` (decision 819)");
}

// The value provided nearest above for `key` in `frames`, else `fallback` —
// the type's declared default (decision 378 (3): no read is unbound).
// The two `unknown` fields are read through `frameValue` / `frameParent`: wasm boxes a field read as `unknown` only as a function's answer.
pub fn find(frames: unknown, key: string, fallback: unknown) -> unknown {
    var cur = frames;
    loop {
        if (cur is Frame) {
            val f: Frame = cur;
            if (f.key == key) return frameValue(f);
            cur = frameParent(f);
        } else return frameValue(Frame(key: key, value: fallback, parent: null)); // the default read back as a provided value is
    }
}

// A body's answer, as it is (the word wasm moves through it, decision 504).
pub fn answer(value: unknown) -> unknown {
    return value;
}

// The place a `use` passes (820 (2)).
pub fn nowhere() -> unknown {
    return Place.none();
}

// A fresh root, for a `use` written outside every component body.
pub fn root() -> unknown {
    return Scope.root();
}

fn frameValue(f: Frame) -> unknown {
    return f.value;
}

fn frameParent(f: Frame) -> unknown {
    return f.parent;
}

// ── the store's host side (decision 824) ─────────────────────────────────────

#[compiler.external(
    .JavaScript("""({ v: undefined })"""),
    .Erlang("""erlang:make_ref()"""),
    .Wasm(wasi: .CellNew),
)]
declare fn storeNew() -> unknown;

#[compiler.external(
    .JavaScript("""($0.v !== undefined)"""),
    .Erlang("""(erlang:get({bp_scope, $0}) =/= undefined)"""),
    .Wasm(wasi: .CellFilled),
)]
declare fn storeLive(store: unknown) -> bool;

#[compiler.external(
    .JavaScript("""$0.v"""),
    .Erlang("""erlang:get({bp_scope, $0})"""),
    .Wasm(wasi: .CellGet),
)]
declare fn storeGet(store: unknown) -> unknown;

#[compiler.external(
    .JavaScript("""((__s, __v) => { __s.v = __v; return undefined; })($0, $1)"""),
    .Erlang("""(fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)($0, $1)"""),
    .Wasm(wasi: .CellSet),
)]
declare fn storeSet(store: unknown, value: unknown) -> void;

// The closed tree written over the root's: on erlang and beam the entry goes
// instead, so the process keeps no `{bp_scope, _}` (825 (2), (3)).
#[compiler.external(
    .JavaScript("""((__s, __v) => { __s.v = __v; return undefined; })($0, $1)"""),
    .Erlang("""(fun(__S, _) -> erlang:erase({bp_scope, __S}), undefined end)($0, $1)"""),
    .Wasm(wasi: .CellSet),
)]
declare fn storeClose(store: unknown, closed: unknown) -> void;

// The process a root is made in: its pid on erlang and beam; elsewhere one
// process holds every root, and a token no test reads stands for it.
#[compiler.external(
    .JavaScript("""null"""),
    .Erlang("""self()"""),
    .Wasm(wasi: .CellNew),
)]
declare fn ownerSelf() -> unknown;

// Whether `owner` is another process than this one: never off the BEAM (an
// owner token there is an empty cell).
#[compiler.external(
    .JavaScript("""false"""),
    .Erlang("""(($0 =/= undefined) andalso ($0 =/= self()))"""),
    .Wasm(wasi: .CellFilled),
)]
declare fn ownerForeign(owner: unknown) -> bool;

```

----- JAVASCRIPT -- std/context.js
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

function __bp_text(v, s) {
    const a = [];
    let i = 0;
    return __bp_show(v, s == null ? null : s, true, a).replace(/%[sO]/g, () => String(a[i++]));
}

function __bp_await(t) {
    return (t != null && t.__bp_fails === true) ? t.then((v) => ({ ok: v }), (e) => { if (t.__bp_failure === true) { return { error: e }; } throw e; }) : t;
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function __bp_eq_PlaceItem(a, b) {
    if (a === b) return true;
    if (a.tag !== b.tag) return false;
    return true;
}

//// Contexts (decisions 354, 378, 379) — what a component's body reads from

//// above it, React's context in botopink's spelling.

//// 

//// A context's identity is its value's type. `createContext(value)` at

//// module level declares a context value carrying the default of that type

//// — one declaration per type in the program:

//// 

////     pub val themeContext = comptime createContext(Theme(mode: .Light));

//// 

//// A component provides a context to everything it renders below it, and a

//// body reads through a context value it declares or imports — the nearest

//// context of that value's type provided above it, else the value's own

//// default (decisions 722, 723):

//// 

////     val c = comptime createContext(Theme(mode: .Dark));

////     use provide(c);                                    // the children's

////     val theme = use context(themeContext);             // the nearest above

//// 

//// Both are hooks, so they are `use`d, never called for a value; `provide`

//// only in a `component` body answering `Component<R>`, in the order

//// written: what the body resolves after it reads it, what it resolved

//// before does not (decision 812 (3)). `use` exists only where there

//// is a render tree — a decorator body, a template body and a

//// `comptime { … }` have none (`use-outside-render-tree`). A read naming a

//// bare type (`use context(Theme)`) is refused at the argument

//// (`context-read-by-type`).

//// 

//// A component at run time is a function over a `Scope` and a `Place`

//// (decisions 809, 815, 819): calling `Card(item)` only makes it, and std's

//// `resolve(c, scope, key)` runs it — the one way a component runs: `use c`

//// in a component body, each child a render library meets, and the root,

//// which a program runs with `await run(App())` (decisions 822, 825). Each

//// component body opens its own cell, `scope.childAt(key)`, a child of the

//// cell it was handed; a `use provide(…)` writes the body's cell, so what

//// the body resolves after it — its subtree — reads it, and a `use

//// context(…)` reads the contexts the cell held when the body entered

//// (decisions 809 (8), 812). The scope travels explicitly: no "current

//// context", on any target.

//// 

//// The work is the compiler's: each `use provide(…)` / `use context(…)` is

//// lowered where it is written — `provide` makes the children's scope and

//// `context` looks the received one up, the declared default when nothing

//// of its type is provided. Neither hook below is ever called: the checker

//// refuses every reference to them but a `use`'s operand, and the bodies

//// panic.

// A context of `T`: the value a provider gives, or a type's declared default.

class Context {
    constructor(contextValue) {
        this.contextValue = contextValue;
    }
}
Context.prototype.__bp = "Context";
exports.Context = Context;

// A context of `value`'s type. At module level it declares that type's

// default (decisions 378, 379); inside a component it makes the context a

// `use provide(…)` gives.

function createContext(value) {
    return new Context(value);
}
exports.createContext = createContext;

// Gives `ctx` to every component this component renders below it — never

// to itself or a sibling; the nearest provider of a type wins.

function provide(ctx) {
    (() => { throw Object.defineProperty(new Error("`use provide` / `use context` are lowered where they are written; this body never runs"), '__bp_panic', { value: true }) })();
}
exports.provide = provide;

// The value of the context of `ctx`'s type provided nearest above this body,

// or `ctx`'s own default: `use context(themeContext)` names a context value

// the module declares or imports, never a bare type (decisions 722, 723).

function context(ctx) {
    (() => { throw Object.defineProperty(new Error("`use provide` / `use context` are lowered where they are written; this body never runs"), '__bp_panic', { value: true }) })();
}
exports.context = context;

// Decision 416 — the record `T` built from the contexts of its fields'

// types: each field the nearest context of its type provided above, else

// that type's declared default, else the field's own default (`use

// inject(Deps)`). `T` is a record; a behavior is read with `use context`.

// `createContext(value, Behavior)` keys a context by the behavior its value

// implements, so a field typed by the behavior reads it.

function inject(t) {
    (() => { throw Object.defineProperty(new Error("`use inject` is lowered where it is written; this body never runs"), '__bp_panic', { value: true }) })();
}
exports.inject = inject;

// ── the place (decisions 819, 820, 884, 891) ─────────────────────────────────

// Where a component stands among its siblings (819 (2)): the number of the

// call that made it, and its item half — absent, a count the call's

// component body or plain function made (821), a list runner's index, or a

// key. A program passes `Place.none()` (the place the value carries), or

// runs one by hand with `Place.key(k)` / `Place.index(i)` (819 (3), 884).

class Place {
    constructor(callNo, item, itemNo, keyValue) {
        this.callNo = callNo;
        this.item = item;
        this.itemNo = itemNo;
        this.keyValue = keyValue;
    }

    static none() {
        return new Place(0, PlaceItem.Absent, 0, null);
    }

    static key(k) {
        return new Place(0, PlaceItem.Key, 0, k);
    }

    static index(i) {
        return new Place(0, PlaceItem.Index, i, null);
    }

    with(key) {
        if (__bp_eq_PlaceItem(key.item, PlaceItem.Key)) { return new Place(this.callNo, PlaceItem.Key, 0, key.keyValue); }
        if (__bp_eq_PlaceItem(key.item, PlaceItem.Index)) { if ((__bp_eq_PlaceItem(this.item, PlaceItem.Absent) || __bp_eq_PlaceItem(this.item, PlaceItem.Plain))) { return new Place(this.callNo, PlaceItem.Index, key.itemNo, null); } }
        return this;
    }
}
Place.prototype.__bp = "Place";
exports.Place = Place;

// A place's item half (891 (1)).

class PlaceItem {
    toString() {
        return __bp_text(this);
    }
}
PlaceItem.prototype.__bp = "PlaceItem";
class PlaceItem$Absent extends PlaceItem {
}
PlaceItem$Absent.prototype.tag = "Absent";
class PlaceItem$Body extends PlaceItem {
}
PlaceItem$Body.prototype.tag = "Body";
class PlaceItem$Plain extends PlaceItem {
}
PlaceItem$Plain.prototype.tag = "Plain";
class PlaceItem$Index extends PlaceItem {
}
PlaceItem$Index.prototype.tag = "Index";
class PlaceItem$Key extends PlaceItem {
}
PlaceItem$Key.prototype.tag = "Key";
PlaceItem.Absent = new PlaceItem$Absent();
PlaceItem.Body = new PlaceItem$Body();
PlaceItem.Plain = new PlaceItem$Plain();
PlaceItem.Index = new PlaceItem$Index();
PlaceItem.Key = new PlaceItem$Key();
exports.PlaceItem = PlaceItem;

// ── the scope (decisions 809 (8), 817, 824, 825) ─────────────────────────────

// A cell of a render's tree: the contexts provided above it, a persistent map

// keyed by each context's identity. Opaque — made only by `Scope.root()`, a

// cell's `childAt` and `detach`. A root's whole tree is one entry: on erlang

// and beam an entry `{bp_scope, Ref}` of the process dictionary of the

// process that made the root, ended by that process or by `close()`; on

// commonJS a plain object, on wasm a heap cell (824). A scope used after its

// root's `close()` fails `scope-closed` on every target (825 (2)); one read in

// another process than the root's fails `scope-foreign` (824 (3)).

class Scope {
    constructor(scopeStore, scopeCell, scopeOwner, scopeCarried) {
        this.scopeStore = scopeStore;
        this.scopeCell = scopeCell;
        this.scopeOwner = scopeOwner;
        this.scopeCarried = scopeCarried;
    }

    static root() {
        return new Scope(storeOf(null), 0, null, null);
    }

    childAt(key) {
        return new Scope(this.scopeStore, grow(this.scopeStore, this.scopeOwner, this.scopeCarried, this.scopeCell), this.scopeOwner, this.scopeCarried);
    }

    close() {
        closeStore(this.scopeStore);
    }

    detach() {
        const carried = new Carried(framesAt(this.scopeStore, this.scopeOwner, this.scopeCarried, this.scopeCell));
        return new Scope(({ v: undefined }), 0, null, carried);
    }

    storeRef() {
        return this.scopeStore;
    }

    cellId() {
        return this.scopeCell;
    }

    ownerRef() {
        return this.scopeOwner;
    }

    carriedRef() {
        return this.scopeCarried;
    }
}
Scope.prototype.__bp = "Scope";
Scope.prototype.__bp_b_Closeable = true;
exports.Scope = Scope;

// A root's tree: whether it is closed, the count of its cells, and each

// cell's contexts, the latest entry for an id first. Public as `Frame` is: a

// program never names it.

class ScopeTree {
    constructor(treeClosed, treeCount, treeCells) {
        this.treeClosed = treeClosed;
        this.treeCount = treeCount;
        this.treeCells = treeCells;
    }
}
ScopeTree.prototype.__bp = "ScopeTree";
exports.ScopeTree = ScopeTree;

// The contexts a detached root carries across processes (824 (3)).

class Carried {
    constructor(frames) {
        this.frames = frames;
    }
}
Carried.prototype.__bp = "Carried";
exports.Carried = Carried;

// One cell's contexts in a root's tree.

class CellEntry {
    constructor(cellNo, cellFrames, cellNext) {
        this.cellNo = cellNo;
        this.cellFrames = cellFrames;
        this.cellNext = cellNext;
    }
}
CellEntry.prototype.__bp = "CellEntry";
exports.CellEntry = CellEntry;

// A new root's store, its one cell holding `frames`.

function storeOf(frames) {
    const store = ({ v: undefined });
    ((__s, __v) => { __s.v = __v; return undefined; })(store, new ScopeTree(false, 1, new CellEntry(0, frames, null)));
    return store;
}

// The root's tree, live and in its own process; a detached root's starts in

// each process that reads it from the contexts it carries.

function treeOf(store, owner, carried) {
    (() => { if (false) { return (() => { throw Object.defineProperty(new Error("scope-foreign: a scope is read in another process than its root's — pass `scope.detach()` to another process (decision 824 (3))"), '__bp_panic', { value: true }) })(); } })();
    if ((!(store.v !== undefined))) { if (carried instanceof Carried) { const c = carried; const t = new ScopeTree(false, 1, new CellEntry(0, carriedFrames(c), null)); ((__s, __v) => { __s.v = __v; return undefined; })(store, t); return t; } }
    if ((store.v !== undefined)) { const raw = store.v; if (raw instanceof ScopeTree) { const t = raw; if ((!t.treeClosed)) { return t; } } }
    (() => { throw Object.defineProperty(new Error("scope-closed: a scope is used after its root's `close()` (decision 825 (2))"), '__bp_panic', { value: true }) })();
}

// A new cell under cell `parent`, starting from its contexts: its id.

function grow(store, owner, carried, parent) {
    const t = treeOf(store, owner, carried);
    const id = t.treeCount;
    ((__s, __v) => { __s.v = __v; return undefined; })(store, new ScopeTree(false, __bp_int((id + 1), -2147483648, 2147483647, "+ on i32 at src/context.bp:232:9"), new CellEntry(id, framesOf(t.treeCells, parent), t.treeCells)));
    return id;
}

// The contexts cell `id` holds now.

function framesAt(store, owner, carried, id) {
    return framesOf(treeOf(store, owner, carried).treeCells, id);
}

function carriedFrames(c) {
    return c.frames;
}

// `value` provided for `key` in cell `id`.

function provideAt(store, owner, carried, id, key, value) {
    const t = treeOf(store, owner, carried);
    const frames = new Frame(key, value, framesOf(t.treeCells, id));
    ((__s, __v) => { __s.v = __v; return undefined; })(store, new ScopeTree(false, t.treeCount, new CellEntry(id, frames, t.treeCells)));
}

// The root's tree closed; a closed one is left as it is.

function closeStore(store) {
    if ((!(store.v !== undefined))) { return; }
    ((__s, __v) => { __s.v = __v; return undefined; })(store, new ScopeTree(true, 0, null));
}

// The contexts of cell `id` in `cells`.

function framesOf(cells, id) {
    let cur = cells;
    while (true) {
    if (cur instanceof CellEntry) { const e = cur; if ((e.cellNo === id)) { return entryFrames(e); } cur = entryNext(e); } else { return null; }
}
}

function entryFrames(e) {
    return e.cellFrames;
}

function entryNext(e) {
    return e.cellNext;
}

// ── resolving and running (decisions 809 (6), 815 (5), 819, 822, 825) ───────

// Runs `c` over `scope` at `key` and hands back its answer as it came — a

// value, or the task of a component that awaits —, nothing awaited inside.

function resolve(c, scope, key) {
    if ((c != null && c.__bp_b_Composable === true)) { return c.compose()(scope, key); }
    return c(scope, key);
}
exports.resolve = resolve;

// Runs a root: `c` resolved over `scope`, or over a root of its own that it

// closes when `c` settles or fails (825 (1)), awaited only when it answered a

// task (822, 823): `val page = await run(App());`.

async function run(c, scope) {
    if ((scope != null)) { const handed = resolve(c, scope, Place.none()); if (handed instanceof Promise) { return await __bp_await(handed); } return handed; }
    const root = Scope.root();
    try {
        const r = resolve(c, root, Place.none());
        if (r instanceof Promise) { return await __bp_await(r); }
        return r;
    } finally {
        root.close();
    }
}
exports.run = run;

// ── what the scope lowering calls (decisions 809 (8), 812, 819) ──────────────

// 

// A program never names these: the compiler imports them under names no

// source can spell. A component body is lowered to `{ scope, key -> … }`

// opening `enter(scope, key)`, its own cell; `use provide(c)` is

// `provideIn(<cell>, <T's identity>, c)` (a context is its value at run time:

// the compiler writes `createContext(v)` as `v`), `use context(ctx)` is

// `find(<the cell's contexts at entry>, <ctx's type's identity>, ctx)`, a

// `use` of a hook or a component calls its value with the cell and

// `Place.none()`, and each `return v` answers `answer(v)`. A context's

// identity is its value's type (379) — the compiler writes it, never a

// program.

// One provided value over the frames it was provided in.

class Frame {
    constructor(key, value, parent) {
        this.key = key;
        this.value = value;
        this.parent = parent;
    }
}
Frame.prototype.__bp = "Frame";
exports.Frame = Frame;

// The cell a body opens: `scope`'s child at `key`.

function enter(scope, key) {
    if (scope instanceof Scope) { if (key instanceof Place) { return scope.childAt(key); } return scope.childAt(Place.none()); }
    (() => { throw Object.defineProperty(new Error("a component is run with a `Scope` (decision 819)"), '__bp_panic', { value: true }) })();
}
exports.enter = enter;

// The contexts `cell` holds now — what a body's `use context` reads.

function received(cell) {
    if (cell instanceof Scope) { return framesAt(cell.storeRef(), cell.ownerRef(), cell.carriedRef(), cell.cellId()); }
    (() => { throw Object.defineProperty(new Error("a component is run with a `Scope` (decision 819)"), '__bp_panic', { value: true }) })();
}
exports.received = received;

// `value` provided for `key` in `cell`: what is resolved under it afterwards

// reads it (809 (8), 812 (3)).

function provideIn(cell, key, value) {
    if (cell instanceof Scope) { provideAt(cell.storeRef(), cell.ownerRef(), cell.carriedRef(), cell.cellId(), key, value); return null; }
    (() => { throw Object.defineProperty(new Error("a component is run with a `Scope` (decision 819)"), '__bp_panic', { value: true }) })();
}
exports.provideIn = provideIn;

// The value provided nearest above for `key` in `frames`, else `fallback` —

// the type's declared default (decision 378 (3): no read is unbound).

// The two `unknown` fields are read through `frameValue` / `frameParent`: wasm boxes a field read as `unknown` only as a function's answer.

function find(frames, key, fallback) {
    let cur = frames;
    while (true) {
    if (cur instanceof Frame) { const f = cur; if ((f.key === key)) { return frameValue(f); } cur = frameParent(f); } else { return frameValue(new Frame(key, fallback, null)); }
    // the default read back as a provided value is;
}
}
exports.find = find;

// A body's answer, as it is (the word wasm moves through it, decision 504).

function answer(value) {
    return value;
}
exports.answer = answer;

// The place a `use` passes (820 (2)).

function nowhere() {
    return Place.none();
}
exports.nowhere = nowhere;

// A fresh root, for a `use` written outside every component body.

function root() {
    return Scope.root();
}
exports.root = root;

function frameValue(f) {
    return f.value;
}

function frameParent(f) {
    return f.parent;
}

// ── the store's host side (decision 824) ─────────────────────────────────────

// storeNew: per-call template (see annotation)

// storeLive: per-call template (see annotation)

// storeGet: per-call template (see annotation)

// storeSet: per-call template (see annotation)

// The closed tree written over the root's: on erlang and beam the entry goes

// instead, so the process keeps no `{bp_scope, _}` (825 (2), (3)).

// storeClose: per-call template (see annotation)

// The process a root is made in: its pid on erlang and beam; elsewhere one

// process holds every root, and a token no test reads stands for it.

// ownerSelf: per-call template (see annotation)

// Whether `owner` is another process than this one: never off the BEAM (an

// owner token there is an empty cell).

// ownerForeign: per-call template (see annotation)

Object.defineProperty(exports, "__bp_priv__", { value: { Context, createContext, provide, context, inject, Place, PlaceItem, PlaceItem$Absent, PlaceItem$Body, PlaceItem$Plain, PlaceItem$Index, PlaceItem$Key, Scope, ScopeTree, Carried, CellEntry, storeOf, treeOf, grow, framesAt, carriedFrames, provideAt, closeStore, framesOf, entryFrames, entryNext, resolve, run, Frame, enter, received, provideIn, find, answer, nowhere, root, frameValue, frameParent } });
```

----- TYPESCRIPT TYPEDEF -- std/context.d.ts
```typescript
export declare class Context<T> {
    readonly contextValue: T;
    constructor(contextValue: T);
}


export declare function createContext<T>(value: T): Context<T>;


export declare function provide<T>(ctx: Context<T>): void;


export declare function context<T>(ctx: Context<T>): T;


export declare function inject(t: any): unknown;


export declare class Place {
    readonly callNo: number;
    readonly item: PlaceItem;
    readonly itemNo: number;
    readonly keyValue: unknown;
    constructor(callNo: number, item: PlaceItem, itemNo: number, keyValue: unknown);
    none(): Place;
    key<K>(k: K): Place;
    index(i: number): Place;
    with(key: Place): Place;
}


export declare class PlaceItem {
    readonly tag: "Absent" | "Body" | "Plain" | "Index" | "Key";
    static readonly Absent: PlaceItem;
    static readonly Body: PlaceItem;
    static readonly Plain: PlaceItem;
    static readonly Index: PlaceItem;
    static readonly Key: PlaceItem;
}


export declare class Scope {
    private constructor(scopeStore: unknown, scopeCell: number, scopeOwner: unknown, scopeCarried: unknown);
    root(): Scope;
    childAt(key: Place): Scope;
    close(): void;
    detach(): Scope;
}


export declare class ScopeTree {
    readonly treeClosed: boolean;
    readonly treeCount: number;
    readonly treeCells: unknown;
    constructor(treeClosed: boolean, treeCount: number, treeCells: unknown);
}


export declare class Carried {
    readonly frames: unknown;
    constructor(frames: unknown);
}


export declare class CellEntry {
    readonly cellNo: number;
    readonly cellFrames: unknown;
    readonly cellNext: unknown;
    constructor(cellNo: number, cellFrames: unknown, cellNext: unknown);
}






















export declare function resolve<T>(c: Promise<T>, scope: Scope, key: Place): T | Promise<T>;


export declare function run<T>(c: Promise<T>, scope: Scope | null): Promise<T>;


export declare class Frame {
    readonly key: string;
    readonly value: unknown;
    readonly parent: unknown;
    constructor(key: string, value: unknown, parent: unknown);
}


export declare function enter(scope: unknown, key: unknown): unknown;


export declare function received(cell: unknown): unknown;


export declare function provideIn(cell: unknown, key: string, value: unknown): unknown;


export declare function find(frames: unknown, key: string, fallback: unknown): unknown;


export declare function answer(value: unknown): unknown;


export declare function nowhere(): unknown;


export declare function root(): unknown;



















```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
val Element = type()
fn cleanup() -> void {
    0;
}
component fn effect(f: fn()) -> Component<i32> {
    return 0;
}
component fn Widget() -> Component<Element> {
    use effect { -> cleanup(); };
    return Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
const { enter: bpScopeEnter__, received: bpScopeReceived__, provideIn: bpScopeProvide__, find: bpScopeFind__, answer: bpScopeAnswer__, nowhere: bpScopeNowhere__, root: bpScopeRoot__ } = require("./std/context.js");

class Element {
}
Element.prototype.__bp = "Element";

function cleanup() {
    0;
}

function effect(f) {
    return (bpScope__, bpKey__) => {
    bpScopeEnter__(bpScope__, bpKey__);
    return bpScopeAnswer__(0);
};
}

function Widget() {
    return (bpScope__, bpKey__) => {
    const bpCell__1 = bpScopeEnter__(bpScope__, bpKey__);
    effect(() => {
    return cleanup();
})(bpCell__1, bpScopeNowhere__());
    return bpScopeAnswer__(new Element());
};
}

Object.defineProperty(exports, "__bp_priv__", { value: { bpScopeEnter__, bpScopeReceived__, bpScopeProvide__, bpScopeFind__, bpScopeAnswer__, bpScopeNowhere__, bpScopeRoot__, Element, cleanup, effect, Widget } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
