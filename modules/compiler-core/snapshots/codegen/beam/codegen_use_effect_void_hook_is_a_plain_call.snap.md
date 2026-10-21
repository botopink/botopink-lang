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

----- BEAM ASSEMBLY -- std/context.S
```erlang
{module, std@context}.
{exports, [{createContext, 1}, {provide, 1}, {context, 1}, {inject, 1}, {resolve, 3}, {run, 2}, {enter, 2}, {received, 1}, {provideIn, 3}, {find, 3}, {answer, 1}, {nowhere, 0}, {root, 0}, {storeOf, 1}, {grow, 4}, {closeStore, 1}, {framesAt, 4}, {'__bp_priv__carriedFrames', 1}, {'__bp_priv__entryFrames', 1}, {'__bp_priv__entryNext', 1}, {'__bp_priv__frameParent', 1}, {'__bp_priv__frameValue', 1}, {'__bp_priv__framesOf', 2}, {'__bp_priv__provideAt', 6}, {'__bp_priv__treeOf', 3}]}.
{attributes, []}.
{labels, 208}.
%%% Contexts (decisions 354, 378, 379) — what a component's body reads from
%%% above it, React's context in botopink's spelling.
%%% 
%%% A context's identity is its value's type. `createContext(value)` at
%%% module level declares a context value carrying the default of that type
%%% — one declaration per type in the program:
%%% 
%%%     pub val themeContext = comptime createContext(Theme(mode: .Light));
%%% 
%%% A component provides a context to everything it renders below it, and a
%%% body reads through a context value it declares or imports — the nearest
%%% context of that value's type provided above it, else the value's own
%%% default (decisions 722, 723):
%%% 
%%%     val c = comptime createContext(Theme(mode: .Dark));
%%%     use provide(c);                                    // the children's
%%%     val theme = use context(themeContext);             // the nearest above
%%% 
%%% Both are hooks, so they are `use`d, never called for a value; `provide`
%%% only in a `component` body answering `Component<R>`, in the order
%%% written: what the body resolves after it reads it, what it resolved
%%% before does not (decision 812 (3)). `use` exists only where there
%%% is a render tree — a decorator body, a template body and a
%%% `comptime { … }` have none (`use-outside-render-tree`). A read naming a
%%% bare type (`use context(Theme)`) is refused at the argument
%%% (`context-read-by-type`).
%%% 
%%% A component at run time is a function over a `Scope` and a `Place`
%%% (decisions 809, 815, 819): calling `Card(item)` only makes it, and std's
%%% `resolve(c, scope, key)` runs it — the one way a component runs: `use c`
%%% in a component body, each child a render library meets, and the root,
%%% which a program runs with `await run(App())` (decisions 822, 825). Each
%%% component body opens its own cell, `scope.childAt(key)`, a child of the
%%% cell it was handed; a `use provide(…)` writes the body's cell, so what
%%% the body resolves after it — its subtree — reads it, and a `use
%%% context(…)` reads the contexts the cell held when the body entered
%%% (decisions 809 (8), 812). The scope travels explicitly: no "current
%%% context", on any target.
%%% 
%%% The work is the compiler's: each `use provide(…)` / `use context(…)` is
%%% lowered where it is written — `provide` makes the children's scope and
%%% `context` looks the received one up, the declared default when nothing
%%% of its type is provided. Neither hook below is ever called: the checker
%%% refuses every reference to them but a `use`'s operand, and the bodies
%%% panic.
% A context of `T`: the value a provider gives, or a type's declared default.
% A context of `value`'s type. At module level it declares that type's
% default (decisions 378, 379); inside a component it makes the context a
% `use provide(…)` gives.

{function, createContext, 1, 3}.
  {label, 2}.
    {line, [{location, "std@context.erl", 1}]}.
    {func_info, {atom, std@context}, {atom, createContext}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Context}, {y, 0}]}}.
    {deallocate, 1}.
    return.
% Gives `ctx` to every component this component renders below it — never
% to itself or a sibling; the nearest provider of a type wins.

{function, provide, 1, 5}.
  {label, 4}.
    {line, [{location, "std@context.erl", 2}]}.
    {func_info, {atom, std@context}, {atom, provide}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"`use provide` / `use context` are lowered where they are written; this body never runs">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
% The value of the context of `ctx`'s type provided nearest above this body,
% or `ctx`'s own default: `use context(themeContext)` names a context value
% the module declares or imports, never a bare type (decisions 722, 723).

{function, context, 1, 7}.
  {label, 6}.
    {line, [{location, "std@context.erl", 3}]}.
    {func_info, {atom, std@context}, {atom, context}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"`use provide` / `use context` are lowered where they are written; this body never runs">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
% Decision 416 — the record `T` built from the contexts of its fields'
% types: each field the nearest context of its type provided above, else
% that type's declared default, else the field's own default (`use
% inject(Deps)`). `T` is a record; a behavior is read with `use context`.
% `createContext(value, Behavior)` keys a context by the behavior its value
% implements, so a field typed by the behavior reads it.

{function, inject, 1, 9}.
  {label, 8}.
    {line, [{location, "std@context.erl", 4}]}.
    {func_info, {atom, std@context}, {atom, inject}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"`use inject` is lowered where it is written; this body never runs">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
% ── the place (decisions 819, 820, 884, 891) ─────────────────────────────────
% Where a component stands among its siblings (819 (2)): the number of the
% call that made it, and its item half — absent, a count the call's
% component body or plain function made (821), a list runner's index, or a
% key. A program passes `Place.none()` (the place the value carries), or
% runs one by hand with `Place.key(k)` / `Place.index(i)` (819 (3), 884).
% A place's item half (891 (1)).
% ── the scope (decisions 809 (8), 817, 824, 825) ─────────────────────────────
% A cell of a render's tree: the contexts provided above it, a persistent map
% keyed by each context's identity. Opaque — made only by `Scope.root()`, a
% cell's `childAt` and `detach`. A root's whole tree is one entry: on erlang
% and beam an entry `{bp_scope, Ref}` of the process dictionary of the
% process that made the root, ended by that process or by `close()`; on
% commonJS a plain object, on wasm a heap cell (824). A scope used after its
% root's `close()` fails `scope-closed` on every target (825 (2)); one read in
% another process than the root's fails `scope-foreign` (824 (3)).
% A root's tree: whether it is closed, the count of its cells, and each
% cell's contexts, the latest entry for an id first. Public as `Frame` is: a
% program never names it.
% The contexts a detached root carries across processes (824 (3)).
% One cell's contexts in a root's tree.
% A new root's store, its one cell holding `frames`.

{function, storeOf, 1, 11}.
  {label, 10}.
    {line, [{location, "std@context.erl", 17}]}.
    {func_info, {atom, std@context}, {atom, storeOf}, 1}.
  {label, 11}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, make_ref, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {integer, 0}, {y, 0}, {atom, undefined}]}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {y, 2}, {integer, 1}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 53}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 7}.
    return.
% The root's tree, live and in its own process; a detached root's starts in
% each process that reads it from the contexts it carries.

{function, treeOf, 3, 13}.
  {label, 12}.
    {line, [{location, "std@context.erl", 18}]}.
    {func_info, {atom, std@context}, {atom, treeOf}, 3}.
  {label, 13}.
    {allocate, 13, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 60}}.
    {test, is_eq, {f, 58}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"scope-foreign: a scope is read in another process than its root's \x{E2}\x{80}\x{94} pass `scope.detach()` to another process (decision 824 (3))">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {jump, {f, 66}}.
  {label, 58}.
  {label, 66}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {test, is_eq, {f, 70}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {atom, true}, {x, 0}}.
  {label, 71}.
    {test, is_eq, {f, 67}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 73}, [{x, 0}, 2, {atom, std@context@@Carried}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {atom, false}, {x, 0}}.
  {label, 74}.
    {test, is_eq, {f, 72}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 19}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {integer, 0}, {x, 0}, {atom, undefined}]}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {y, 4}, {integer, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 53}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 72}.
    {jump, {f, 75}}.
  {label, 67}.
  {label, 75}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {test, is_eq, {f, 76}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 78}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 80}, [{x, 0}, 4, {atom, std@context@@ScopeTree}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 81}}.
  {label, 80}.
    {move, {atom, false}, {x, 0}}.
  {label, 81}.
    {test, is_eq, {f, 79}, [{x, 0}, {atom, true}]}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 83}, [{x, 0}, 4, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 83}.
    {test, is_eq, {f, 84}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 85}}.
  {label, 84}.
    {move, {atom, true}, {x, 0}}.
  {label, 85}.
    {test, is_eq, {f, 82}, [{x, 0}, {atom, true}]}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 82}.
    {jump, {f, 86}}.
  {label, 79}.
  {label, 86}.
    {jump, {f, 87}}.
  {label, 76}.
  {label, 87}.
    {move, {literal, <<"scope-closed: a scope is used after its root's `close()` (decision 825 (2))">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 13}.
    return.
% A new cell under cell `parent`, starting from its contexts: its id.

{function, grow, 4, 15}.
  {label, 14}.
    {line, [{location, "std@context.erl", 19}]}.
    {func_info, {atom, std@context}, {atom, grow}, 4}.
  {label, 15}.
    {allocate, 14, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 13}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 88}, [{x, 0}, 4, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 88}.
    {move, {x, 0}, {y, 5}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 5}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 89}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 89}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/context.bp:232:9">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 90}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 91}, [{x, 0}, 4, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 91}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 25}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 92}, [{x, 0}, 4, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 92}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {y, 5}, {x, 1}, {x, 0}]}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {y, 6}, {y, 7}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 53}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 14}.
    return.
% The contexts cell `id` holds now.

{function, framesAt, 4, 17}.
  {label, 16}.
    {line, [{location, "std@context.erl", 20}]}.
    {func_info, {atom, std@context}, {atom, framesAt}, 4}.
  {label, 17}.
    {allocate, 4, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 13}}.
    {test, is_tagged_tuple, {f, 93}, [{x, 0}, 4, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 93}.
    {move, {y, 3}, {x, 1}}.
    {call_last, 2, {f, 25}, 4}.

{function, carriedFrames, 1, 19}.
  {label, 18}.
    {line, [{location, "std@context.erl", 21}]}.
    {func_info, {atom, std@context}, {atom, carriedFrames}, 1}.
  {label, 19}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 94}, [{x, 0}, 2, {atom, std@context@@Carried}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 94}.
    {deallocate, 1}.
    return.
% `value` provided for `key` in cell `id`.

{function, provideAt, 6, 21}.
  {label, 20}.
    {line, [{location, "std@context.erl", 22}]}.
    {func_info, {atom, std@context}, {atom, provideAt}, 6}.
  {label, 21}.
    {allocate, 16, 6}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, {x, 5}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 13}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 95}, [{x, 0}, 4, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 95}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 25}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Frame}, {y, 4}, {y, 5}, {x, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 96}, [{x, 0}, 4, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 96}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 97}, [{x, 0}, 4, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 97}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {y, 3}, {y, 7}, {x, 0}]}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {y, 8}, {y, 9}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 53}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.
% The root's tree closed; a closed one is left as it is.

{function, closeStore, 1, 23}.
  {label, 22}.
    {line, [{location, "std@context.erl", 23}]}.
    {func_info, {atom, std@context}, {atom, closeStore}, 1}.
  {label, 23}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 69}}.
    {test, is_eq, {f, 99}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {atom, true}, {x, 0}}.
  {label, 100}.
    {test, is_eq, {f, 98}, [{x, 0}, {atom, true}]}.
    {deallocate, 3}.
    return.
  {label, 98}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {x, 0}, {integer, 0}, {atom, undefined}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 102}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
% The contexts of cell `id` in `cells`.

{function, framesOf, 2, 25}.
  {label, 24}.
    {line, [{location, "std@context.erl", 24}]}.
    {func_info, {atom, std@context}, {atom, framesOf}, 2}.
  {label, 25}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@context.erl", 25}]}.
  {label, 107}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 108}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 110}, [{x, 0}, 4, {atom, std@context@@CellEntry}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 111}}.
  {label, 110}.
    {move, {atom, false}, {x, 0}}.
  {label, 111}.
    {test, is_eq, {f, 109}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 113}, [{x, 0}, 4, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 113}.
    {test, is_eq_exact, {f, 112}, [{x, 0}, {y, 1}]}.
    {move, {y, 3}, {x, 0}}.
    {call_last, 1, {f, 27}, 4}.
  {label, 112}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 114}}.
  {label, 109}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 114}.
    {jump, {f, 107}}.
  {label, 108}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, entryFrames, 1, 27}.
  {label, 26}.
    {line, [{location, "std@context.erl", 25}]}.
    {func_info, {atom, std@context}, {atom, entryFrames}, 1}.
  {label, 27}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 115}, [{x, 0}, 4, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 115}.
    {deallocate, 1}.
    return.

{function, entryNext, 1, 29}.
  {label, 28}.
    {line, [{location, "std@context.erl", 26}]}.
    {func_info, {atom, std@context}, {atom, entryNext}, 1}.
  {label, 29}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 116}, [{x, 0}, 4, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 116}.
    {deallocate, 1}.
    return.
% ── resolving and running (decisions 809 (6), 815 (5), 819, 822, 825) ───────
% Runs `c` over `scope` at `key` and hands back its answer as it came — a
% value, or the task of a component that awaits —, nothing awaited inside.

{function, resolve, 3, 31}.
  {label, 30}.
    {line, [{location, "std@context.erl", 27}]}.
    {func_info, {atom, std@context}, {atom, resolve}, 3}.
  {label, 31}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, 'Composable'}, {x, 1}}.
    {call, 2, {f, 119}}.
    {test, is_eq, {f, 117}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, compose}, {x, 0}}.
    {call, 3, {f, 154}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 4}.
    return.
  {label, 117}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 4}.
    return.
% Runs a root: `c` resolved over `scope`, or over a root of its own that it
% closes when `c` settles or fails (825 (1)), awaited only when it answered a
% task (822, 823): `val page = await run(App());`.

%% @Async — eager lowering
{function, run, 2, 33}.
  {label, 32}.
    {line, [{location, "std@context.erl", 28}]}.
    {func_info, {atom, std@context}, {atom, run}, 2}.
  {label, 33}.
    {allocate, 15, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ne_exact, {f, 161}, [{y, 1}, {atom, undefined}]}.
    {call_ext, 0, {extfunc, std@context@@Place, none, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 31}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 163}}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 164}}.
  {label, 163}.
    {move, {atom, false}, {x, 0}}.
  {label, 164}.
    {test, is_eq, {f, 162}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 162}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 161}.
    {call_ext, 0, {extfunc, std@context@@Scope, root, 0}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 14}, {f, 165}}.
    {call_ext, 0, {extfunc, std@context@@Place, none, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 31}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 167}}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 168}}.
  {label, 167}.
    {move, {atom, false}, {x, 0}}.
  {label, 168}.
    {test, is_eq, {f, 166}, [{x, 0}, {atom, true}]}.
    {move, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {try_end, {y, 14}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, close, 1}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 166}.
    {move, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {try_end, {y, 14}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, close, 1}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 165}.
    {try_case, {y, 14}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 2}, {y, 6}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, close, 1}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
% ── what the scope lowering calls (decisions 809 (8), 812, 819) ──────────────
% 
% A program never names these: the compiler imports them under names no
% source can spell. A component body is lowered to `{ scope, key -> … }`
% opening `enter(scope, key)`, its own cell; `use provide(c)` is
% `provideIn(<cell>, <T's identity>, c)` (a context is its value at run time:
% the compiler writes `createContext(v)` as `v`), `use context(ctx)` is
% `find(<the cell's contexts at entry>, <ctx's type's identity>, ctx)`, a
% `use` of a hook or a component calls its value with the cell and
% `Place.none()`, and each `return v` answers `answer(v)`. A context's
% identity is its value's type (379) — the compiler writes it, never a
% program.
% One provided value over the frames it was provided in.
% The cell a body opens: `scope`'s child at `key`.

{function, enter, 2, 35}.
  {label, 34}.
    {line, [{location, "std@context.erl", 29}]}.
    {func_info, {atom, std@context}, {atom, enter}, 2}.
  {label, 35}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 171}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 172}}.
  {label, 171}.
    {move, {atom, false}, {x, 0}}.
  {label, 172}.
    {test, is_eq, {f, 170}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 174}, [{x, 0}, 5, {atom, std@context@@Place}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 175}}.
  {label, 174}.
    {move, {atom, false}, {x, 0}}.
  {label, 175}.
    {test, is_eq, {f, 173}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@context@@Scope, childAt, 2}, 4}.
  {label, 173}.
    {call_ext, 0, {extfunc, std@context@@Place, none, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 2, {extfunc, std@context@@Scope, childAt, 2}, 4}.
  {label, 170}.
    {move, {literal, <<"a component is run with a `Scope` (decision 819)">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.
% The contexts `cell` holds now — what a body's `use context` reads.

{function, received, 1, 37}.
  {label, 36}.
    {line, [{location, "std@context.erl", 30}]}.
    {func_info, {atom, std@context}, {atom, received}, 1}.
  {label, 37}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 177}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 178}}.
  {label, 177}.
    {move, {atom, false}, {x, 0}}.
  {label, 178}.
    {test, is_eq, {f, 176}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, storeRef, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, ownerRef, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, carriedRef, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, cellId, 1}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 3}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_last, 4, {f, 17}, 5}.
  {label, 176}.
    {move, {literal, <<"a component is run with a `Scope` (decision 819)">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
% `value` provided for `key` in `cell`: what is resolved under it afterwards
% reads it (809 (8), 812 (3)).

{function, provideIn, 3, 39}.
  {label, 38}.
    {line, [{location, "std@context.erl", 31}]}.
    {func_info, {atom, std@context}, {atom, provideIn}, 3}.
  {label, 39}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 180}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 181}}.
  {label, 180}.
    {move, {atom, false}, {x, 0}}.
  {label, 181}.
    {test, is_eq, {f, 179}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, storeRef, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, ownerRef, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, carriedRef, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, cellId, 1}}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 2}, {x, 5}}.
    {move, {y, 1}, {x, 4}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 5}, {x, 2}}.
    {move, {y, 3}, {x, 0}}.
    {call, 6, {f, 21}}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 179}.
    {move, {literal, <<"a component is run with a `Scope` (decision 819)">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 9}.
    return.
% The value provided nearest above for `key` in `frames`, else `fallback` —
% the type's declared default (decision 378 (3): no read is unbound).
% The two `unknown` fields are read through `frameValue` / `frameParent`: wasm boxes a field read as `unknown` only as a function's answer.

{function, find, 3, 41}.
  {label, 40}.
    {line, [{location, "std@context.erl", 32}]}.
    {func_info, {atom, std@context}, {atom, find}, 3}.
  {label, 41}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@context.erl", 33}]}.
  {label, 182}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 183}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 185}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 186}}.
  {label, 185}.
    {move, {atom, false}, {x, 0}}.
  {label, 186}.
    {test, is_eq, {f, 184}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 188}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 188}.
    {test, is_eq_exact, {f, 187}, [{x, 0}, {y, 1}]}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 1, {f, 49}, 5}.
  {label, 187}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 51}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 189}}.
  {label, 184}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Frame}, {y, 1}, {y, 2}, {atom, undefined}]}}.
    {call_last, 1, {f, 49}, 5}.
  {label, 189}.
    {jump, {f, 182}}.
  {label, 183}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
% A body's answer, as it is (the word wasm moves through it, decision 504).

{function, answer, 1, 43}.
  {label, 42}.
    {line, [{location, "std@context.erl", 33}]}.
    {func_info, {atom, std@context}, {atom, answer}, 1}.
  {label, 43}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% The place a `use` passes (820 (2)).

{function, nowhere, 0, 45}.
  {label, 44}.
    {line, [{location, "std@context.erl", 34}]}.
    {func_info, {atom, std@context}, {atom, nowhere}, 0}.
  {label, 45}.
    {allocate, 0, 0}.
    {call_ext_last, 0, {extfunc, std@context@@Place, none, 0}, 0}.
% A fresh root, for a `use` written outside every component body.

{function, root, 0, 47}.
  {label, 46}.
    {line, [{location, "std@context.erl", 35}]}.
    {func_info, {atom, std@context}, {atom, root}, 0}.
  {label, 47}.
    {allocate, 0, 0}.
    {call_ext_last, 0, {extfunc, std@context@@Scope, root, 0}, 0}.

{function, frameValue, 1, 49}.
  {label, 48}.
    {line, [{location, "std@context.erl", 36}]}.
    {func_info, {atom, std@context}, {atom, frameValue}, 1}.
  {label, 49}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 190}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 190}.
    {deallocate, 1}.
    return.

{function, frameParent, 1, 51}.
  {label, 50}.
    {line, [{location, "std@context.erl", 37}]}.
    {func_info, {atom, std@context}, {atom, frameParent}, 1}.
  {label, 51}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 191}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 191}.
    {deallocate, 1}.
    return.
% ── the store's host side (decision 824) ─────────────────────────────────────
% The closed tree written over the root's: on erlang and beam the entry goes
% instead, so the process keeps no `{bp_scope, _}` (825 (2), (3)).
% The process a root is made in: its pid on erlang and beam; elsewhere one
% process holds every root, and a token no test reads stands for it.
% Whether `owner` is another process than this one: never off the BEAM (an
% owner token there is an empty cell).

{function, '__bp_priv__carriedFrames', 1, 193}.
  {label, 192}.
    {line, [{location, "std@context.erl", 38}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__carriedFrames'}, 1}.
  {label, 193}.
    {call_only, 1, {f, 19}}.

{function, '__bp_priv__entryFrames', 1, 195}.
  {label, 194}.
    {line, [{location, "std@context.erl", 39}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__entryFrames'}, 1}.
  {label, 195}.
    {call_only, 1, {f, 27}}.

{function, '__bp_priv__entryNext', 1, 197}.
  {label, 196}.
    {line, [{location, "std@context.erl", 40}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__entryNext'}, 1}.
  {label, 197}.
    {call_only, 1, {f, 29}}.

{function, '__bp_priv__frameParent', 1, 199}.
  {label, 198}.
    {line, [{location, "std@context.erl", 41}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__frameParent'}, 1}.
  {label, 199}.
    {call_only, 1, {f, 51}}.

{function, '__bp_priv__frameValue', 1, 201}.
  {label, 200}.
    {line, [{location, "std@context.erl", 42}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__frameValue'}, 1}.
  {label, 201}.
    {call_only, 1, {f, 49}}.

{function, '__bp_priv__framesOf', 2, 203}.
  {label, 202}.
    {line, [{location, "std@context.erl", 43}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__framesOf'}, 2}.
  {label, 203}.
    {call_only, 2, {f, 25}}.

{function, '__bp_priv__provideAt', 6, 205}.
  {label, 204}.
    {line, [{location, "std@context.erl", 44}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__provideAt'}, 6}.
  {label, 205}.
    {call_only, 6, {f, 21}}.

{function, '__bp_priv__treeOf', 3, 207}.
  {label, 206}.
    {line, [{location, "std@context.erl", 45}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__treeOf'}, 3}.
  {label, 207}.
    {call_only, 3, {f, 13}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 57}.
  {label, 56}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 57}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_scope}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_0', 2, 53}.
  {label, 52}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_0'}, 2}.
  {label, 53}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 57}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1', 1, 60}.
  {label, 59}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_1'}, 1}.
  {label, 60}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, {atom, true}]}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 65}}.
  {label, 63}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 1}}.
    {jump, {f, 65}}.
  {label, 64}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 65}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_2', 1, 69}.
  {label, 68}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_2'}, 1}.
  {label, 69}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_scope}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_3', 1, 78}.
  {label, 77}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_3'}, 1}.
  {label, 78}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_scope}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, get, 1}, 2}.

{function, '__bp_tpl_4-t/2-fun-0-', 2, 106}.
  {label, 105}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_4-t/2-fun-0-'}, 2}.
  {label, 106}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_scope}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_4', 2, 102}.
  {label, 101}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_4'}, 2}.
  {label, 102}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 106}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_5', 2, 119}.
  {label, 118}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_5'}, 2}.
  {label, 119}.
    {allocate, 12, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_tuple, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 122}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 124}}.
  {label, 122}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 123}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 124}}.
  {label, 123}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 124}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 126}, [{x, 0}, {atom, true}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 125}}.
  {label, 126}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 127}, [{x, 0}, {atom, false}]}.
    {move, {y, 2}, {y, 5}}.
    {jump, {f, 125}}.
  {label, 127}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 125}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 129}}.
  {label, 129}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_atom, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 130}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, true}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 133}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, false}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 136}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 8}}.
    {jump, {f, 138}}.
  {label, 136}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 137}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 8}}.
    {jump, {f, 138}}.
  {label, 137}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 9}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 138}.
    {move, {y, 8}, {y, 6}}.
    {jump, {f, 135}}.
  {label, 133}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 134}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 6}}.
    {jump, {f, 135}}.
  {label, 134}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 7}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 135}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 132}}.
  {label, 130}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 131}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 132}}.
  {label, 131}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 132}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 140}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {literal, [95, 95, 118, 95, 95]}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 142}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 8}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_nonempty_list, {f, 142}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 9}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nil, {f, 142}, [{x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 6}}.
    {jump, {f, 141}}.
  {label, 142}.
    {move, {y, 0}, {y, 6}}.
    {jump, {f, 141}}.
  {label, 141}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 145}}.
  {label, 145}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, module}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 146}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_behaviors'}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 149}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_behaviors'}, {x, 1}}.
    {move, nil, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 7}}.
    {jump, {f, 151}}.
  {label, 149}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 150}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 7}}.
    {jump, {f, 151}}.
  {label, 150}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 8}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 151}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 148}}.
  {label, 146}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 147}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 148}}.
  {label, 147}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 148}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 140}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 152}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 152}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '-bp_method-', 3, 154}.
  {label, 153}.
    {line, [{location, "std@context.erl", 28}]}.
    {func_info, {atom, std@context}, {atom, '-bp_method-'}, 3}.
  {label, 154}.
    {test, is_map, {f, 155}, [{x, 1}]}.
    {bif, map_get, {f, 0}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call_ext_only, 2, {extfunc, erlang, apply, 2}}.
  {label, 155}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {test, is_tuple, {f, 156}, [{x, 1}]}.
    {bif, element, {f, 0}, [{integer, 1}, {x, 1}], {x, 0}}.
    {jump, {f, 157}}.
  {label, 156}.
    {move, {x, 1}, {x, 0}}.
  {label, 157}.
    {move, {x, 0}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, split, 2}}.
    {test, is_nonempty_list, {f, 158}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {test, is_nil, {f, 159}, [{x, 2}]}.
    {jump, {f, 158}}.
  {label, 159}.
    {move, {x, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_atom, 1}}.
    {jump, {f, 160}}.
  {label, 158}.
    {move, {y, 2}, {x, 0}}.
  {label, 160}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, erlang, apply, 3}, 3}.
```

----- BEAM ASSEMBLY -- std@context@@Context.S
```erlang
{module, std@context@@Context}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@Context.erl", 1}]}.
    {func_info, {atom, std@context@@Context}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, contextValue}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 6}.
  {label, 5}.
    {line, [{location, "std@context@@Context.erl", 1}]}.
    {func_info, {atom, std@context@@Context}, {atom, '__bp_format'}, 1}.
  {label, 6}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"contextValue">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Context">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@context@@Place.S
```erlang
{module, std@context@@Place}.
{exports, [{none, 0}, {key, 1}, {index, 1}, {with, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 36}.

{function, none, 0, 3}.
  {label, 2}.
    {line, [{location, "std@context@@Place.erl", 5}]}.
    {func_info, {atom, std@context@@Place}, {atom, none}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, std@context@@PlaceItem__v__absent}, {x, 0}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {integer, 0}, {x, 0}, {integer, 0}, {atom, undefined}]}}.
    {deallocate, 0}.
    return.

{function, key, 1, 5}.
  {label, 4}.
    {line, [{location, "std@context@@Place.erl", 6}]}.
    {func_info, {atom, std@context@@Place}, {atom, key}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, std@context@@PlaceItem__v__key}, {x, 0}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {integer, 0}, {x, 0}, {integer, 0}, {y, 0}]}}.
    {deallocate, 1}.
    return.

{function, index, 1, 7}.
  {label, 6}.
    {line, [{location, "std@context@@Place.erl", 7}]}.
    {func_info, {atom, std@context@@Place}, {atom, index}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, std@context@@PlaceItem__v__index}, {x, 0}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {integer, 0}, {x, 0}, {y, 0}, {atom, undefined}]}}.
    {deallocate, 1}.
    return.

{function, with, 2, 9}.
  {label, 8}.
    {line, [{location, "std@context@@Place.erl", 8}]}.
    {func_info, {atom, std@context@@Place}, {atom, with}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 11}, [{x, 0}, 5, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 11}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__key}, {x, 0}}.
    {test, is_eq_exact, {f, 10}, [{x, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 5, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 12}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__key}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 13}, [{x, 0}, 5, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 13}.
    {test_heap, 6, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {x, 1}, {x, 2}, {integer, 0}, {x, 0}]}}.
    {deallocate, 2}.
    return.
  {label, 10}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 15}, [{x, 0}, 5, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 15}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__index}, {x, 0}}.
    {test, is_eq_exact, {f, 14}, [{x, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 17}, [{x, 0}, 5, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 17}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__absent}, {x, 0}}.
    {test, is_eq_exact, {f, 18}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {atom, false}, {x, 0}}.
  {label, 19}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 20}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 22}, [{x, 0}, 5, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 22}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__plain}, {x, 0}}.
    {test, is_eq_exact, {f, 23}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 24}}.
  {label, 23}.
    {move, {atom, false}, {x, 0}}.
  {label, 24}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {atom, true}, {x, 0}}.
  {label, 21}.
    {test, is_eq, {f, 16}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 25}, [{x, 0}, 5, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 25}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__index}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 26}, [{x, 0}, 5, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 26}.
    {test_heap, 6, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {x, 1}, {x, 2}, {x, 0}, {atom, undefined}]}}.
    {deallocate, 2}.
    return.
  {label, 16}.
    {jump, {f, 27}}.
  {label, 14}.
  {label, 27}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 29}.
  {label, 28}.
    {line, [{location, "std@context@@Place.erl", 9}]}.
    {func_info, {atom, std@context@@Place}, {atom, '__bp_get'}, 2}.
  {label, 29}.
    {test, is_eq_exact, {f, 30}, [{x, 1}, {atom, callNo}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 30}.
    {test, is_eq_exact, {f, 31}, [{x, 1}, {atom, item}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 31}.
    {test, is_eq_exact, {f, 32}, [{x, 1}, {atom, itemNo}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 32}.
    {test, is_eq_exact, {f, 33}, [{x, 1}, {atom, keyValue}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 33}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 35}.
  {label, 34}.
    {line, [{location, "std@context@@Place.erl", 9}]}.
    {func_info, {atom, std@context@@Place}, {atom, '__bp_format'}, 1}.
  {label, 35}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"keyValue">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"itemNo">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"item">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"callNo">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Place">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@context@@PlaceItem.S
```erlang
{module, std@context@@PlaceItem}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "std@context@@PlaceItem.erl", 9}]}.
    {func_info, {atom, std@context@@PlaceItem}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, std@context@@PlaceItem__v__absent}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"PlaceItem.Absent">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, std@context@@PlaceItem__v__body}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"PlaceItem.Body">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, std@context@@PlaceItem__v__plain}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"PlaceItem.Plain">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 7}, [{x, 0}, {atom, std@context@@PlaceItem__v__index}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"PlaceItem.Index">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 7}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 8}, [{x, 0}, {atom, std@context@@PlaceItem__v__key}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"PlaceItem.Key">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 8}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"PlaceItem">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@context@@Scope.S
```erlang
{module, std@context@@Scope}.
{exports, [{root, 0}, {childAt, 2}, {close, 1}, {detach, 1}, {storeRef, 1}, {cellId, 1}, {ownerRef, 1}, {carriedRef, 1}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 46}.

{function, root, 0, 3}.
  {label, 2}.
    {line, [{location, "std@context@@Scope.erl", 9}]}.
    {func_info, {atom, std@context@@Scope}, {atom, root}, 0}.
  {label, 3}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {atom, undefined}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context, storeOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 19}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Scope}, {y, 0}, {integer, 0}, {x, 0}, {atom, undefined}]}}.
    {deallocate, 4}.
    return.

{function, childAt, 2, 5}.
  {label, 4}.
    {line, [{location, "std@context@@Scope.erl", 10}]}.
    {func_info, {atom, std@context@@Scope}, {atom, childAt}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 20}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 20}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 21}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 21}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 22}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 22}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 23}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 23}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 24}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 24}.
    {move, {x, 1}, {x, 4}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 4}, {x, 0}}.
    {call_ext, 4, {extfunc, std@context, grow, 4}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 25}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 25}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 26}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 26}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Scope}, {y, 2}, {y, 3}, {y, 4}, {x, 0}]}}.
    {deallocate, 6}.
    return.

{function, close, 1, 7}.
  {label, 6}.
    {line, [{location, "std@context@@Scope.erl", 11}]}.
    {func_info, {atom, std@context@@Scope}, {atom, close}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 27}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 27}.
    {call_ext, 1, {extfunc, std@context, closeStore, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, detach, 1, 9}.
  {label, 8}.
    {line, [{location, "std@context@@Scope.erl", 12}]}.
    {func_info, {atom, std@context@@Scope}, {atom, detach}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 28}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 29}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 29}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 30}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 30}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 31}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 31}.
    {move, {x, 1}, {x, 4}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 4}, {x, 0}}.
    {call_ext, 4, {extfunc, std@context, framesAt, 4}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Carried}, {x, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {call_ext, 0, {extfunc, erlang, make_ref, 0}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Scope}, {x, 0}, {integer, 0}, {atom, undefined}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, storeRef, 1, 11}.
  {label, 10}.
    {line, [{location, "std@context@@Scope.erl", 13}]}.
    {func_info, {atom, std@context@@Scope}, {atom, storeRef}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 32}.
    {deallocate, 1}.
    return.

{function, cellId, 1, 13}.
  {label, 12}.
    {line, [{location, "std@context@@Scope.erl", 14}]}.
    {func_info, {atom, std@context@@Scope}, {atom, cellId}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 33}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 33}.
    {deallocate, 1}.
    return.

{function, ownerRef, 1, 15}.
  {label, 14}.
    {line, [{location, "std@context@@Scope.erl", 15}]}.
    {func_info, {atom, std@context@@Scope}, {atom, ownerRef}, 1}.
  {label, 15}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 34}.
    {deallocate, 1}.
    return.

{function, carriedRef, 1, 17}.
  {label, 16}.
    {line, [{location, "std@context@@Scope.erl", 16}]}.
    {func_info, {atom, std@context@@Scope}, {atom, carriedRef}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 35}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 37}.
  {label, 36}.
    {line, [{location, "std@context@@Scope.erl", 17}]}.
    {func_info, {atom, std@context@@Scope}, {atom, '__bp_get'}, 2}.
  {label, 37}.
    {test, is_eq_exact, {f, 38}, [{x, 1}, {atom, scopeStore}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 38}.
    {test, is_eq_exact, {f, 39}, [{x, 1}, {atom, scopeCell}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 39}.
    {test, is_eq_exact, {f, 40}, [{x, 1}, {atom, scopeOwner}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 40}.
    {test, is_eq_exact, {f, 41}, [{x, 1}, {atom, scopeCarried}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 41}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 43}.
  {label, 42}.
    {line, [{location, "std@context@@Scope.erl", 17}]}.
    {func_info, {atom, std@context@@Scope}, {atom, '__bp_format'}, 1}.
  {label, 43}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"scopeCarried">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"scopeOwner">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"scopeCell">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"scopeStore">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Scope">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 45}.
  {label, 44}.
    {line, [{location, "std@context@@Scope.erl", 17}]}.
    {func_info, {atom, std@context@@Scope}, {atom, '__bp_behaviors'}, 0}.
  {label, 45}.
    {move, {literal, ['Closeable']}, {x, 0}}.
    return.

{function, '__bp_tpl_0', 0, 19}.
  {label, 18}.
    {func_info, {atom, std@context@@Scope}, {atom, '__bp_tpl_0'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {call_ext_last, 0, {extfunc, erlang, self, 0}, 0}.
```

----- BEAM ASSEMBLY -- std@context@@ScopeTree.S
```erlang
{module, std@context@@ScopeTree}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@ScopeTree.erl", 17}]}.
    {func_info, {atom, std@context@@ScopeTree}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, treeClosed}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, treeCount}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, treeCells}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "std@context@@ScopeTree.erl", 17}]}.
    {func_info, {atom, std@context@@ScopeTree}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"treeCells">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"treeCount">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"treeClosed">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"ScopeTree">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@context@@Carried.S
```erlang
{module, std@context@@Carried}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@Carried.erl", 17}]}.
    {func_info, {atom, std@context@@Carried}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, frames}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 6}.
  {label, 5}.
    {line, [{location, "std@context@@Carried.erl", 17}]}.
    {func_info, {atom, std@context@@Carried}, {atom, '__bp_format'}, 1}.
  {label, 6}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"frames">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Carried">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@context@@CellEntry.S
```erlang
{module, std@context@@CellEntry}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@CellEntry.erl", 17}]}.
    {func_info, {atom, std@context@@CellEntry}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, cellNo}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, cellFrames}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, cellNext}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "std@context@@CellEntry.erl", 17}]}.
    {func_info, {atom, std@context@@CellEntry}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"cellNext">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"cellFrames">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"cellNo">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"CellEntry">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@context@@Frame.S
```erlang
{module, std@context@@Frame}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@Frame.erl", 29}]}.
    {func_info, {atom, std@context@@Frame}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, key}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, value}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, parent}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "std@context@@Frame.erl", 29}]}.
    {func_info, {atom, std@context@@Frame}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"parent">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"value">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"key">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Frame">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__Widget', 0}, {'__bp_priv__cleanup', 0}, {'__bp_priv__effect', 1}]}.
{attributes, []}.
{labels, 20}.

{function, cleanup, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, cleanup}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, effect, 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, effect}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
    {deallocate, 1}.
    return.

{function, 'Widget', 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, 'Widget'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {deallocate, 0}.
    return.

{function, '__bp_priv__Widget', 0, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Widget'}, 0}.
  {label, 15}.
    {call_only, 0, {f, 7}}.

{function, '__bp_priv__cleanup', 0, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__cleanup'}, 0}.
  {label, 17}.
    {call_only, 0, {f, 3}}.

{function, '__bp_priv__effect', 1, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__effect'}, 1}.
  {label, 19}.
    {call_only, 1, {f, 5}}.

{function, '-effect/1-fun-0-', 2, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-effect/1-fun-0-'}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, std@context, enter, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, std@context, answer, 1}, 2}.

{function, '-Widget/2-fun-2-', 0, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-Widget/2-fun-2-'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {deallocate, 0}.
    return.

{function, '-Widget/0-fun-1-', 2, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-Widget/0-fun-1-'}, 2}.
  {label, 11}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, std@context, enter, 2}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    {call, 1, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {call_ext, 0, {extfunc, std@context, nowhere, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {call_fun, 2}.
    {test_heap, 2, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Element}]}}.
    {call_ext_last, 1, {extfunc, std@context, answer, 1}, 6}.
```

----- BEAM ASSEMBLY -- test@main@@Element.S
```erlang
{module, test@main@@Element}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 4}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Element.erl", 1}]}.
    {func_info, {atom, test@main@@Element}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Element">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
