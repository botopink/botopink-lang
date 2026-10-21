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

----- ERLANG -- std/context.erl
```erlang
-module(std@context).
-export([createContext/1, provide/1, context/1, inject/1, resolve/3, run/2, enter/2, received/1, provideIn/3, find/3, answer/1, nowhere/0, root/0, storeOf/1, grow/4, closeStore/1, framesAt/4, '__bp_priv__treeOf'/3, '__bp_priv__carriedFrames'/1, '__bp_priv__provideAt'/6, '__bp_priv__framesOf'/2, '__bp_priv__entryFrames'/1, '__bp_priv__entryNext'/1, '__bp_priv__frameValue'/1, '__bp_priv__frameParent'/1]).

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

%% type Context: contextValue

% A context of `value`'s type. At module level it declares that type's

% default (decisions 378, 379); inside a component it makes the context a

% `use provide(…)` gives.

createContext(Value) ->
    {std@context@@Context, Value}.

% Gives `ctx` to every component this component renders below it — never

% to itself or a sibling; the nearest provider of a type wins.

provide(Ctx) ->
    erlang:error({panic, <<"`use provide` / `use context` are lowered where they are written; this body never runs">>}).

% The value of the context of `ctx`'s type provided nearest above this body,

% or `ctx`'s own default: `use context(themeContext)` names a context value

% the module declares or imports, never a bare type (decisions 722, 723).

context(Ctx) ->
    erlang:error({panic, <<"`use provide` / `use context` are lowered where they are written; this body never runs">>}).

% Decision 416 — the record `T` built from the contexts of its fields'

% types: each field the nearest context of its type provided above, else

% that type's declared default, else the field's own default (`use

% inject(Deps)`). `T` is a record; a behavior is read with `use context`.

% `createContext(value, Behavior)` keys a context by the behavior its value

% implements, so a field typed by the behavior reads it.

inject(T) ->
    erlang:error({panic, <<"`use inject` is lowered where it is written; this body never runs">>}).

% ── the place (decisions 819, 820, 884, 891) ─────────────────────────────────

% Where a component stands among its siblings (819 (2)): the number of the

% call that made it, and its item half — absent, a count the call's

% component body or plain function made (821), a list runner's index, or a

% key. A program passes `Place.none()` (the place the value carries), or

% runs one by hand with `Place.key(k)` / `Place.index(i)` (819 (3), 884).

%% type Place: callNo, item, itemNo, keyValue

% A place's item half (891 (1)).

%% type PlaceItem
%%   Absent
%%   Body
%%   Plain
%%   Index
%%   Key

% ── the scope (decisions 809 (8), 817, 824, 825) ─────────────────────────────

% A cell of a render's tree: the contexts provided above it, a persistent map

% keyed by each context's identity. Opaque — made only by `Scope.root()`, a

% cell's `childAt` and `detach`. A root's whole tree is one entry: on erlang

% and beam an entry `{bp_scope, Ref}` of the process dictionary of the

% process that made the root, ended by that process or by `close()`; on

% commonJS a plain object, on wasm a heap cell (824). A scope used after its

% root's `close()` fails `scope-closed` on every target (825 (2)); one read in

% another process than the root's fails `scope-foreign` (824 (3)).

%% type Scope: scopeStore, scopeCell, scopeOwner, scopeCarried

% A root's tree: whether it is closed, the count of its cells, and each

% cell's contexts, the latest entry for an id first. Public as `Frame` is: a

% program never names it.

%% type ScopeTree: treeClosed, treeCount, treeCells

% The contexts a detached root carries across processes (824 (3)).

%% type Carried: frames

% One cell's contexts in a root's tree.

%% type CellEntry: cellNo, cellFrames, cellNext

% A new root's store, its one cell holding `frames`.

storeOf(Frames) ->
    Store = erlang:make_ref(),
    (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, {std@context@@ScopeTree, false, 1, {std@context@@CellEntry, 0, Frames, undefined}}),
    Store.

% The root's tree, live and in its own process; a detached root's starts in

% each process that reads it from the contexts it carries.

treeOf(Store, Owner, Carried) ->
    try
        case ((Owner =/= undefined) andalso (Owner =/= self())) of
            true ->
                erlang:error({panic, <<"scope-foreign: a scope is read in another process than its root's \x{E2}\x{80}\x{94} pass `scope.detach()` to another process (decision 824 (3))">>});
            _ -> ok
        end,
        case (not (erlang:get({bp_scope, Store}) =/= undefined)) of
            true ->
                case ((erlang:is_tuple(Carried) andalso (erlang:tuple_size(Carried) =:= 2)) andalso (erlang:element(1, Carried) =:= std@context@@Carried)) of
                    true ->
                        C = Carried,
                        T = {std@context@@ScopeTree, false, 1, {std@context@@CellEntry, 0, carriedFrames(C), undefined}},
                        (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, T),
                        erlang:throw({'__bp_try', T});
                    _ -> ok
                end;
            _ -> ok
        end,
        case (erlang:get({bp_scope, Store}) =/= undefined) of
            true ->
                Raw = erlang:get({bp_scope, Store}),
                case ((erlang:is_tuple(Raw) andalso (erlang:tuple_size(Raw) =:= 4)) andalso (erlang:element(1, Raw) =:= std@context@@ScopeTree)) of
                    true ->
                        T@1 = Raw,
                        case (not erlang:element(2, T@1)) of
                            true ->
                                erlang:throw({'__bp_try', T@1});
                            _ -> ok
                        end;
                    _ -> ok
                end;
            _ -> ok
        end,
        erlang:error({panic, <<"scope-closed: a scope is used after its root's `close()` (decision 825 (2))">>})
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% A new cell under cell `parent`, starting from its contexts: its id.

grow(Store, Owner, Carried, Parent) ->
    T = treeOf(Store, Owner, Carried),
    Id = erlang:element(3, T),
    (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, {std@context@@ScopeTree, false, '__bp_int'((Id + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/context.bp:232:9">>), {std@context@@CellEntry, Id, framesOf(erlang:element(4, T), Parent), erlang:element(4, T)}}),
    Id.

% The contexts cell `id` holds now.

framesAt(Store, Owner, Carried, Id) ->
    framesOf(erlang:element(4, treeOf(Store, Owner, Carried)), Id).

carriedFrames(C) ->
    erlang:element(2, C).

% `value` provided for `key` in cell `id`.

provideAt(Store, Owner, Carried, Id, Key, Value) ->
    T = treeOf(Store, Owner, Carried),
    Frames = {std@context@@Frame, Key, Value, framesOf(erlang:element(4, T), Id)},
    (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, {std@context@@ScopeTree, false, erlang:element(3, T), {std@context@@CellEntry, Id, Frames, erlang:element(4, T)}}).

% The root's tree closed; a closed one is left as it is.

closeStore(Store) ->
    try
        case (not (erlang:get({bp_scope, Store}) =/= undefined)) of
            true ->
                erlang:throw({'__bp_try', undefined});
            _ -> ok
        end,
        (fun(__S, _) -> erlang:erase({bp_scope, __S}), undefined end)(Store, {std@context@@ScopeTree, true, 0, undefined})
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% The contexts of cell `id` in `cells`.

framesOf(Cells, Id) ->
    try
        Cur = Cells,
        Cur@4 = (fun __BpLoop(Cur@1) ->
            Cur@3 = case ((erlang:is_tuple(Cur@1) andalso (erlang:tuple_size(Cur@1) =:= 4)) andalso (erlang:element(1, Cur@1) =:= std@context@@CellEntry)) of
                true ->
                    E = Cur@1,
                    case (erlang:element(2, E) =:= Id) of
                        true ->
                            erlang:throw({'__bp_try', entryFrames(E)});
                        _ -> ok
                    end,
                    Cur@2 = entryNext(E),
                    Cur@2;
                _ ->
                    erlang:throw({'__bp_try', undefined}),
                    Cur@1
            end,
            __BpLoop(Cur@3)
        end)(Cur)
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

entryFrames(E) ->
    erlang:element(3, E).

entryNext(E) ->
    erlang:element(4, E).

% ── resolving and running (decisions 809 (6), 815 (5), 819, 822, 825) ───────

% Runs `c` over `scope` at `key` and hands back its answer as it came — a

% value, or the task of a component that awaits —, nothing awaited inside.

resolve(C, Scope, Key) ->
    case '__bp_implements'(C, 'Composable') of
        true ->
            ('__bp_method'(compose, C, []))(Scope, Key);
        _ ->
            C(Scope, Key)
    end.

% Runs a root: `c` resolved over `scope`, or over a root of its own that it

% closes when `c` settles or fails (825 (1)), awaited only when it answered a

% task (822, 823): `val page = await run(App());`.

%% @Async — eager lowering
run(C, Scope) ->
    case (Scope =/= undefined) of
        true ->
            Handed = resolve(C, Scope, std@context@@Place:none()),
            case false of
                true ->
                    Handed;
                _ ->
                    Handed
            end;
        _ ->
            Root = std@context@@Scope:root(),
            try
                R = resolve(C, Root, std@context@@Place:none()),
                case false of
                    true ->
                        R;
                    _ ->
                        R
                end
            after
                std@context@@Scope:close(Root)
            end
    end.

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

%% type Frame: key, value, parent

% The cell a body opens: `scope`'s child at `key`.

enter(Scope, Key) ->
    case ((erlang:is_tuple(Scope) andalso (erlang:tuple_size(Scope) =:= 5)) andalso (erlang:element(1, Scope) =:= std@context@@Scope)) of
        true ->
            case ((erlang:is_tuple(Key) andalso (erlang:tuple_size(Key) =:= 5)) andalso (erlang:element(1, Key) =:= std@context@@Place)) of
                true ->
                    std@context@@Scope:childAt(Scope, Key);
                _ ->
                    std@context@@Scope:childAt(Scope, std@context@@Place:none())
            end;
        _ ->
            erlang:error({panic, <<"a component is run with a `Scope` (decision 819)">>})
    end.

% The contexts `cell` holds now — what a body's `use context` reads.

received(Cell) ->
    case ((erlang:is_tuple(Cell) andalso (erlang:tuple_size(Cell) =:= 5)) andalso (erlang:element(1, Cell) =:= std@context@@Scope)) of
        true ->
            framesAt(std@context@@Scope:storeRef(Cell), std@context@@Scope:ownerRef(Cell), std@context@@Scope:carriedRef(Cell), std@context@@Scope:cellId(Cell));
        _ ->
            erlang:error({panic, <<"a component is run with a `Scope` (decision 819)">>})
    end.

% `value` provided for `key` in `cell`: what is resolved under it afterwards

% reads it (809 (8), 812 (3)).

provideIn(Cell, Key, Value) ->
    case ((erlang:is_tuple(Cell) andalso (erlang:tuple_size(Cell) =:= 5)) andalso (erlang:element(1, Cell) =:= std@context@@Scope)) of
        true ->
            provideAt(std@context@@Scope:storeRef(Cell), std@context@@Scope:ownerRef(Cell), std@context@@Scope:carriedRef(Cell), std@context@@Scope:cellId(Cell), Key, Value),
            undefined;
        _ ->
            erlang:error({panic, <<"a component is run with a `Scope` (decision 819)">>})
    end.

% The value provided nearest above for `key` in `frames`, else `fallback` —

% the type's declared default (decision 378 (3): no read is unbound).

% The two `unknown` fields are read through `frameValue` / `frameParent`: wasm boxes a field read as `unknown` only as a function's answer.

find(Frames, Key, Fallback) ->
    try
        Cur = Frames,
        Cur@4 = (fun __BpLoop(Cur@1) ->
            Cur@3 = case ((erlang:is_tuple(Cur@1) andalso (erlang:tuple_size(Cur@1) =:= 4)) andalso (erlang:element(1, Cur@1) =:= std@context@@Frame)) of
                true ->
                    F = Cur@1,
                    case (erlang:element(2, F) =:= Key) of
                        true ->
                            erlang:throw({'__bp_try', frameValue(F)});
                        _ -> ok
                    end,
                    Cur@2 = frameParent(F),
                    Cur@2;
                _ ->
                    erlang:throw({'__bp_try', frameValue({std@context@@Frame, Key, Fallback, undefined})}),
                    Cur@1
            end,
            % the default read back as a provided value is
            __BpLoop(Cur@3)
        end)(Cur)
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% A body's answer, as it is (the word wasm moves through it, decision 504).

answer(Value) ->
    Value.

% The place a `use` passes (820 (2)).

nowhere() ->
    std@context@@Place:none().

% A fresh root, for a `use` written outside every component body.

root() ->
    std@context@@Scope:root().

frameValue(F) ->
    erlang:element(3, F).

frameParent(F) ->
    erlang:element(4, F).

% ── the store's host side (decision 824) ─────────────────────────────────────

%% external fn storeNew -> erlang template

%% external fn storeLive -> erlang template

%% external fn storeGet -> erlang template

%% external fn storeSet -> erlang template

% The closed tree written over the root's: on erlang and beam the entry goes

% instead, so the process keeps no `{bp_scope, _}` (825 (2), (3)).

%% external fn storeClose -> erlang template

% The process a root is made in: its pid on erlang and beam; elsewhere one

% process holds every root, and a token no test reads stands for it.

%% external fn ownerSelf -> erlang template

% Whether `owner` is another process than this one: never off the BEAM (an

% owner token there is an empty cell).

%% external fn ownerForeign -> erlang template

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_method'(M, V, Args) when erlang:is_map(V) -> erlang:apply(maps:get(M, V), [V | Args]);
'__bp_method'(M, V, Args) ->
    T = case erlang:is_tuple(V) of true -> erlang:element(1, V); false -> V end,
    O = case string:split(erlang:atom_to_list(T), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> T end,
    erlang:apply(O, M, [V | Args]).

'__bp_implements'(__BpA0, __BpA1) ->
    T = case erlang:is_tuple(__BpA0) andalso (erlang:tuple_size(__BpA0) > 0) of
true -> erlang:element(1, __BpA0);
false -> __BpA0
end,
case erlang:is_atom(T) andalso (T =/= true) andalso (T =/= false) andalso (T =/= undefined) of
true ->
M = case string:split(erlang:atom_to_list(T), "__v__") of
[P, _] -> erlang:list_to_atom(P);
_ -> T
end,
(code:ensure_loaded(M) =:= {module, M}) andalso erlang:function_exported(M, '__bp_behaviors', 0) andalso lists:member(__BpA1, erlang:apply(M, '__bp_behaviors', []));
false -> false
end.

'__bp_priv__treeOf'(A0, A1, A2) -> treeOf(A0, A1, A2).

'__bp_priv__carriedFrames'(A0) -> carriedFrames(A0).

'__bp_priv__provideAt'(A0, A1, A2, A3, A4, A5) -> provideAt(A0, A1, A2, A3, A4, A5).

'__bp_priv__framesOf'(A0, A1) -> framesOf(A0, A1).

'__bp_priv__entryFrames'(A0) -> entryFrames(A0).

'__bp_priv__entryNext'(A0) -> entryNext(A0).

'__bp_priv__frameValue'(A0) -> frameValue(A0).

'__bp_priv__frameParent'(A0) -> frameParent(A0).
```

----- ERLANG -- std@context@@Context.erl
```erlang
-module(std@context@@Context).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, contextValue) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Context", [{"contextValue", erlang:element(2, V)}]}.
```

----- ERLANG -- std@context@@Place.erl
```erlang
-module(std@context@@Place).
-export([none/0, key/1, index/1, with/2, '__bp_get'/2, '__bp_format'/1]).

none() ->
    {std@context@@Place, 0, std@context@@PlaceItem__v__absent, 0, undefined}.

key(K) ->
    {std@context@@Place, 0, std@context@@PlaceItem__v__key, 0, K}.

index(I) ->
    {std@context@@Place, 0, std@context@@PlaceItem__v__index, I, undefined}.

with(Self, Key) ->
    try
        case (erlang:element(3, Key) =:= std@context@@PlaceItem__v__key) of
            true ->
                {std@context@@Place, erlang:element(2, Self), std@context@@PlaceItem__v__key, 0, erlang:element(5, Key)};
            _ ->
                case (erlang:element(3, Key) =:= std@context@@PlaceItem__v__index) of
                    true ->
                        case ((erlang:element(3, Self) =:= std@context@@PlaceItem__v__absent) orelse (erlang:element(3, Self) =:= std@context@@PlaceItem__v__plain)) of
                            true ->
                                erlang:throw({'__bp_try', {std@context@@Place, erlang:element(2, Self), std@context@@PlaceItem__v__index, erlang:element(4, Key), undefined}});
                            _ -> ok
                        end;
                    _ -> ok
                end,
                Self
        end
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

'__bp_get'(V, callNo) -> erlang:element(2, V);
'__bp_get'(V, item) -> erlang:element(3, V);
'__bp_get'(V, itemNo) -> erlang:element(4, V);
'__bp_get'(V, keyValue) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "Place", [{"callNo", erlang:element(2, V)}, {"item", erlang:element(3, V)}, {"itemNo", erlang:element(4, V)}, {"keyValue", erlang:element(5, V)}]}.
```

----- ERLANG -- std@context@@PlaceItem.erl
```erlang
-module(std@context@@PlaceItem).
-export(['__bp_format'/1]).

'__bp_format'(std@context@@PlaceItem__v__absent) -> {variant, "PlaceItem.Absent", []};
'__bp_format'(std@context@@PlaceItem__v__body) -> {variant, "PlaceItem.Body", []};
'__bp_format'(std@context@@PlaceItem__v__plain) -> {variant, "PlaceItem.Plain", []};
'__bp_format'(std@context@@PlaceItem__v__index) -> {variant, "PlaceItem.Index", []};
'__bp_format'(std@context@@PlaceItem__v__key) -> {variant, "PlaceItem.Key", []}.
```

----- ERLANG -- std@context@@Scope.erl
```erlang
-module(std@context@@Scope).
-export([root/0, childAt/2, close/1, detach/1, storeRef/1, cellId/1, ownerRef/1, carriedRef/1, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

root() ->
    {std@context@@Scope, std@context:storeOf(undefined), 0, self(), undefined}.

childAt(Self, Key) ->
    {std@context@@Scope, erlang:element(2, Self), std@context:grow(erlang:element(2, Self), erlang:element(4, Self), erlang:element(5, Self), erlang:element(3, Self)), erlang:element(4, Self), erlang:element(5, Self)}.

close(Self) ->
    std@context:closeStore(erlang:element(2, Self)).

detach(Self) ->
    Carried = {std@context@@Carried, std@context:framesAt(erlang:element(2, Self), erlang:element(4, Self), erlang:element(5, Self), erlang:element(3, Self))},
    {std@context@@Scope, erlang:make_ref(), 0, undefined, Carried}.

storeRef(Self) ->
    erlang:element(2, Self).

cellId(Self) ->
    erlang:element(3, Self).

ownerRef(Self) ->
    erlang:element(4, Self).

carriedRef(Self) ->
    erlang:element(5, Self).

'__bp_get'(V, scopeStore) -> erlang:element(2, V);
'__bp_get'(V, scopeCell) -> erlang:element(3, V);
'__bp_get'(V, scopeOwner) -> erlang:element(4, V);
'__bp_get'(V, scopeCarried) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "Scope", [{"scopeStore", erlang:element(2, V)}, {"scopeCell", erlang:element(3, V)}, {"scopeOwner", erlang:element(4, V)}, {"scopeCarried", erlang:element(5, V)}]}.

'__bp_behaviors'() -> ['Closeable'].
```

----- ERLANG -- std@context@@ScopeTree.erl
```erlang
-module(std@context@@ScopeTree).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, treeClosed) -> erlang:element(2, V);
'__bp_get'(V, treeCount) -> erlang:element(3, V);
'__bp_get'(V, treeCells) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "ScopeTree", [{"treeClosed", erlang:element(2, V)}, {"treeCount", erlang:element(3, V)}, {"treeCells", erlang:element(4, V)}]}.
```

----- ERLANG -- std@context@@Carried.erl
```erlang
-module(std@context@@Carried).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, frames) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Carried", [{"frames", erlang:element(2, V)}]}.
```

----- ERLANG -- std@context@@CellEntry.erl
```erlang
-module(std@context@@CellEntry).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, cellNo) -> erlang:element(2, V);
'__bp_get'(V, cellFrames) -> erlang:element(3, V);
'__bp_get'(V, cellNext) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "CellEntry", [{"cellNo", erlang:element(2, V)}, {"cellFrames", erlang:element(3, V)}, {"cellNext", erlang:element(4, V)}]}.
```

----- ERLANG -- std@context@@Frame.erl
```erlang
-module(std@context@@Frame).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, key) -> erlang:element(2, V);
'__bp_get'(V, value) -> erlang:element(3, V);
'__bp_get'(V, parent) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Frame", [{"key", erlang:element(2, V)}, {"value", erlang:element(3, V)}, {"parent", erlang:element(4, V)}]}.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
val Element = type()
component fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> Component<#(i32, fn(action: i32) -> i32)> {
    val push: fn(i32) -> i32 = { action -> f(base, action) };
    return #(base, push);
}
component fn LikeWidget() -> Component<Element> {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push(shown);
    return Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__optimistic'/2, '__bp_priv__LikeWidget'/0]).

%% import bpScopeEnter__, bpScopeReceived__, bpScopeProvide__, bpScopeFind__, bpScopeAnswer__, bpScopeNowhere__, bpScopeRoot__

%% type Element: 

optimistic(Base, F) ->
    fun(BpScope__, BpKey__) ->
        std@context:enter(BpScope__, BpKey__),
        Push = fun(Action) ->
            F(Base, Action)
        end,
        std@context:answer({Base, Push})
    end.

'LikeWidget'() ->
    fun(BpScope__, BpKey__) ->
        BpCell__1 = std@context:enter(BpScope__, BpKey__),
        {Shown, Push} = (optimistic(12, fun(C, A) ->
            '__bp_add'(C, A)
        end))(BpCell__1, std@context:nowhere()),
        Push(Shown),
        std@context:answer({test@main@@Element})
    end.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

'__bp_priv__optimistic'(A0, A1) -> optimistic(A0, A1).

'__bp_priv__LikeWidget'() -> 'LikeWidget'().
```

----- ERLANG -- test@main@@Element.erl
```erlang
-module(test@main@@Element).
-export(['__bp_format'/1]).

'__bp_format'(_) -> {record, "Element", []}.
```

----- RUN LOG -----
```logs
```
