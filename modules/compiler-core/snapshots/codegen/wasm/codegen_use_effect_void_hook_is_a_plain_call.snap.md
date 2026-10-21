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

----- WASM TEXT -- std/context.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (tag $__bp_panic (param i32))
  (data (i32.const 256) "\18\00\00\00R\07Context\01\0ccontextValueG")
  (data (i32.const 284) "\01\00\00\00i")
  (data (i32.const 292) "\56\00\00\00`use provide` / `use context` are lowered where they are written; this body never runs")
  (data (i32.const 384) "\41\00\00\00`use inject` is lowered where it is written; this body never runs")
  (data (i32.const 456) "\77\00\00\00R\05Place\04\06callNoi\04itemE\05\10PlaceItem.Absent\0ePlaceItem.Body\0fPlaceItem.Plain\0fPlaceItem.Index\rPlaceItem.Key\06itemNoi\08keyValuei")
  (data (i32.const 580) "\39\00\00\00R\05Scope\04\nscopeStorei\tscopeCelli\nscopeOwneri\0cscopeCarriedi")
  (data (i32.const 644) "\12\00\00\00R\07Carried\01\06framesi")
  (data (i32.const 668) "\2e\00\00\00R\tScopeTree\03\ntreeClosedb\ttreeCounti\ttreeCellsi")
  (data (i32.const 720) "\2a\00\00\00R\tCellEntry\03\06cellNoi\ncellFramesi\08cellNexti")
  (data (i32.const 768) "\81\00\00\00scope-foreign: a scope is read in another process than its root's — pass `scope.detach()` to another process (decision 824 (3))")
  (data (i32.const 904) "\4b\00\00\00scope-closed: a scope is used after its root's `close()` (decision 825 (2))")
  (data (i32.const 984) "\32\00\00\00integer overflow: + on i32 at src/context.bp:232:9")
  (data (i32.const 1040) "\1c\00\00\00R\05Frame\03\03keys\05valuei\06parenti")
  (data (i32.const 1072) "\30\00\00\00a component is run with a `Scope` (decision 819)")
  (global $__heap_ptr (mut i32) (i32.const 1124))
  ;; Contexts (decisions 354, 378, 379) — what a component's body reads from
  ;; above it, React's context in botopink's spelling.
  ;; 
  ;; A context's identity is its value's type. `createContext(value)` at
  ;; module level declares a context value carrying the default of that type
  ;; — one declaration per type in the program:
  ;; 
  ;;     pub val themeContext = comptime createContext(Theme(mode: .Light));
  ;; 
  ;; A component provides a context to everything it renders below it, and a
  ;; body reads through a context value it declares or imports — the nearest
  ;; context of that value's type provided above it, else the value's own
  ;; default (decisions 722, 723):
  ;; 
  ;;     val c = comptime createContext(Theme(mode: .Dark));
  ;;     use provide(c);                                    // the children's
  ;;     val theme = use context(themeContext);             // the nearest above
  ;; 
  ;; Both are hooks, so they are `use`d, never called for a value; `provide`
  ;; only in a `component` body answering `Component<R>`, in the order
  ;; written: what the body resolves after it reads it, what it resolved
  ;; before does not (decision 812 (3)). `use` exists only where there
  ;; is a render tree — a decorator body, a template body and a
  ;; `comptime { … }` have none (`use-outside-render-tree`). A read naming a
  ;; bare type (`use context(Theme)`) is refused at the argument
  ;; (`context-read-by-type`).
  ;; 
  ;; A component at run time is a function over a `Scope` and a `Place`
  ;; (decisions 809, 815, 819): calling `Card(item)` only makes it, and std's
  ;; `resolve(c, scope, key)` runs it — the one way a component runs: `use c`
  ;; in a component body, each child a render library meets, and the root,
  ;; which a program runs with `await run(App())` (decisions 822, 825). Each
  ;; component body opens its own cell, `scope.childAt(key)`, a child of the
  ;; cell it was handed; a `use provide(…)` writes the body's cell, so what
  ;; the body resolves after it — its subtree — reads it, and a `use
  ;; context(…)` reads the contexts the cell held when the body entered
  ;; (decisions 809 (8), 812). The scope travels explicitly: no "current
  ;; context", on any target.
  ;; 
  ;; The work is the compiler's: each `use provide(…)` / `use context(…)` is
  ;; lowered where it is written — `provide` makes the children's scope and
  ;; `context` looks the received one up, the declared default when nothing
  ;; of its type is provided. Neither hook below is ever called: the checker
  ;; refuses every reference to them but a `use`'s operand, and the bodies
  ;; panic.
  ;; A context of `T`: the value a provider gives, or a type's declared default.
  ;; A context of `value`'s type. At module level it declares that type's
  ;; default (decisions 378, 379); inside a component it makes the context a
  ;; `use provide(…)` gives.
  (func $createContext (export "createContext") (param $value i32) (result i32)
    (local $__mem0 i32)
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 288
    i32.store offset=8
    local.get $__mem0
    local.get $value
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  ;; Gives `ctx` to every component this component renders below it — never
  ;; to itself or a sibling; the nearest provider of a type wins.
  (func $provide (export "provide") (param $ctx i32) (result i32)
    i32.const 292
    i32.const 1
    call $__panic_raise
    unreachable
    i32.const 0
  )
  ;; The value of the context of `ctx`'s type provided nearest above this body,
  ;; or `ctx`'s own default: `use context(themeContext)` names a context value
  ;; the module declares or imports, never a bare type (decisions 722, 723).
  (func $context (export "context") (param $ctx i32) (result i32)
    i32.const 292
    i32.const 1
    call $__panic_raise
    unreachable
    i32.const 0
  )
  ;; Decision 416 — the record `T` built from the contexts of its fields'
  ;; types: each field the nearest context of its type provided above, else
  ;; that type's declared default, else the field's own default (`use
  ;; inject(Deps)`). `T` is a record; a behavior is read with `use context`.
  ;; `createContext(value, Behavior)` keys a context by the behavior its value
  ;; implements, so a field typed by the behavior reads it.
  (func $inject (export "inject") (param $t i32) (result i32)
    i32.const 384
    i32.const 1
    call $__panic_raise
    unreachable
    i32.const 0
  )
  ;; ── the place (decisions 819, 820, 884, 891) ─────────────────────────────────
  ;; Where a component stands among its siblings (819 (2)): the number of the
  ;; call that made it, and its item half — absent, a count the call's
  ;; component body or plain function made (821), a list runner's index, or a
  ;; key. A program passes `Place.none()` (the place the value carries), or
  ;; runs one by hand with `Place.key(k)` / `Place.index(i)` (819 (3), 884).
  (func $Place_none (result i32)
    (local $__mem0 i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 460
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 0 ;; PlaceItem.Absent
    i32.store offset=8
    local.get $__mem0
    i32.const 0
    i32.store offset=12
    local.get $__mem0
    i32.const 0
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Place_key (param $k i32) (result i32)
    (local $__mem0 i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 460
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 4 ;; PlaceItem.Key
    i32.store offset=8
    local.get $__mem0
    i32.const 0
    i32.store offset=12
    local.get $__mem0
    unreachable ;; unknown: no static type to box this value by (a type parameter's slot?)
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Place_index (param $i i32) (result i32)
    (local $__mem0 i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 460
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 3 ;; PlaceItem.Index
    i32.store offset=8
    local.get $__mem0
    local.get $i
    i32.store offset=12
    local.get $__mem0
    i32.const 0
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Place_with (param $self i32) (param $key i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $key
    i32.load offset=4 ;; .item
    i32.const 4 ;; PlaceItem.Key
    i32.eq
    (if (result i32)
      (then
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 460
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .callNo
    i32.store offset=4
    local.get $__mem0
    i32.const 4 ;; PlaceItem.Key
    i32.store offset=8
    local.get $__mem0
    i32.const 0
    i32.store offset=12
    local.get $__mem0
    local.get $key
    i32.load offset=12 ;; .keyValue
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $key
    i32.load offset=4 ;; .item
    i32.const 3 ;; PlaceItem.Index
    i32.eq
    (if (result i32)
      (then
    local.get $self
    i32.load offset=4 ;; .item
    i32.const 0 ;; PlaceItem.Absent
    i32.eq
    local.get $self
    i32.load offset=4 ;; .item
    i32.const 2 ;; PlaceItem.Plain
    i32.eq
    i32.or
    (if (result i32)
      (then
    i32.const 20
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 460
    i32.store
    local.get $__mem1
    local.get $self
    i32.load ;; .callNo
    i32.store offset=4
    local.get $__mem1
    i32.const 3 ;; PlaceItem.Index
    i32.store offset=8
    local.get $__mem1
    local.get $key
    i32.load offset=8 ;; .itemNo
    i32.store offset=12
    local.get $__mem1
    i32.const 0
    i32.store offset=16
    local.get $__mem1
    i32.const 4
    i32.add
    return
      )
      (else
        i32.const 0
      )
    )
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $self
    return
  )
  ;; A place's item half (891 (1)).
  ;; ── the scope (decisions 809 (8), 817, 824, 825) ─────────────────────────────
  ;; A cell of a render's tree: the contexts provided above it, a persistent map
  ;; keyed by each context's identity. Opaque — made only by `Scope.root()`, a
  ;; cell's `childAt` and `detach`. A root's whole tree is one entry: on erlang
  ;; and beam an entry `{bp_scope, Ref}` of the process dictionary of the
  ;; process that made the root, ended by that process or by `close()`; on
  ;; commonJS a plain object, on wasm a heap cell (824). A scope used after its
  ;; root's `close()` fails `scope-closed` on every target (825 (2)); one read in
  ;; another process than the root's fails `scope-foreign` (824 (3)).
  (func $Scope_root (result i32)
    (local $__mem0 i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 584
    i32.store
    local.get $__mem0
    i32.const 0
    call $storeOf
    i32.store offset=4
    local.get $__mem0
    i32.const 0
    i32.store offset=8
    local.get $__mem0
    call $ownerSelf
    i32.store offset=12
    local.get $__mem0
    i32.const 0
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Scope_childAt (param $self i32) (param $key i32) (result i32)
    (local $__mem0 i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 584
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .scopeStore
    i32.store offset=4
    local.get $__mem0
    local.get $self
    i32.load ;; .scopeStore
    local.get $self
    i32.load offset=8 ;; .scopeOwner
    local.get $self
    i32.load offset=12 ;; .scopeCarried
    local.get $self
    i32.load offset=4 ;; .scopeCell
    call $grow
    i32.store offset=8
    local.get $__mem0
    local.get $self
    i32.load offset=8 ;; .scopeOwner
    i32.store offset=12
    local.get $__mem0
    local.get $self
    i32.load offset=12 ;; .scopeCarried
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Scope_close (param $self i32) (result i32)
    local.get $self
    i32.load ;; .scopeStore
    call $closeStore
  )
  (func $Scope_detach (param $self i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $carried i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 648
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .scopeStore
    local.get $self
    i32.load offset=8 ;; .scopeOwner
    local.get $self
    i32.load offset=12 ;; .scopeCarried
    local.get $self
    i32.load offset=4 ;; .scopeCell
    call $framesAt
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $carried
    i32.const 20
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 584
    i32.store
    local.get $__mem1
    call $storeNew
    i32.store offset=4
    local.get $__mem1
    i32.const 0
    i32.store offset=8
    local.get $__mem1
    i32.const 0
    i32.store offset=12
    local.get $__mem1
    local.get $carried
    i32.store offset=16
    local.get $__mem1
    i32.const 4
    i32.add
    return
  )
  (func $Scope_storeRef (param $self i32) (result i32)
    local.get $self
    i32.load ;; .scopeStore
    return
  )
  (func $Scope_cellId (param $self i32) (result i32)
    local.get $self
    i32.load offset=4 ;; .scopeCell
    return
  )
  (func $Scope_ownerRef (param $self i32) (result i32)
    local.get $self
    i32.load offset=8 ;; .scopeOwner
    return
  )
  (func $Scope_carriedRef (param $self i32) (result i32)
    local.get $self
    i32.load offset=12 ;; .scopeCarried
    return
  )
  ;; A root's tree: whether it is closed, the count of its cells, and each
  ;; cell's contexts, the latest entry for an id first. Public as `Frame` is: a
  ;; program never names it.
  ;; The contexts a detached root carries across processes (824 (3)).
  ;; One cell's contexts in a root's tree.
  ;; A new root's store, its one cell holding `frames`.
  (func $storeOf (param $frames i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $store i32)
    call $storeNew
    local.set $store
    local.get $store
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 672
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 1
    i32.store offset=8
    local.get $__mem0
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 724
    i32.store
    local.get $__mem1
    i32.const 0
    i32.store offset=4
    local.get $__mem1
    local.get $frames
    i32.store offset=8
    local.get $__mem1
    i32.const 0
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.add
    call $storeSet
    local.get $store
    return
  )
  ;; The root's tree, live and in its own process; a detached root's starts in
  ;; each process that reads it from the contexts it carries.
  (func $treeOf (param $store i32) (param $owner i32) (param $carried i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $c i32)
    (local $t i32)
    (local $raw i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    local.get $owner
    call $ownerForeign
    (if (result i32)
      (then
    i32.const 768
    i32.const 1
    call $__panic_raise
    unreachable
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $store
    call $storeLive
    i32.eqz
    (if (result i32)
      (then
    local.get $carried
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 648
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $carried
    local.set $c
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 672
    i32.store
    local.get $__mem1
    i32.const 0
    i32.store offset=4
    local.get $__mem1
    i32.const 1
    i32.store offset=8
    local.get $__mem1
    i32.const 16
    call $__alloc
    local.set $__mem2
    local.get $__mem2
    i32.const 724
    i32.store
    local.get $__mem2
    i32.const 0
    i32.store offset=4
    local.get $__mem2
    local.get $c
    call $carriedFrames
    i32.store offset=8
    local.get $__mem2
    i32.const 0
    i32.store offset=12
    local.get $__mem2
    i32.const 4
    i32.add
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    local.set $t
    local.get $store
    local.get $t
    call $storeSet
    local.get $t
    return
      )
      (else
        i32.const 0
      )
    )
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $store
    call $storeLive
    (if (result i32)
      (then
    local.get $store
    call $storeGet
    local.set $raw
    local.get $raw
    local.tee $__mem3
    i32.const 256
    i32.ge_u
    local.get $__mem3
    i32.const 4
    i32.sub
    local.get $__mem3
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 672
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $raw
    local.set $t
    local.get $t
    i32.load ;; .treeClosed
    i32.eqz
    (if (result i32)
      (then
    local.get $t
    return
      )
      (else
        i32.const 0
      )
    )
      )
      (else
        i32.const 0
      )
    )
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 904
    i32.const 1
    call $__panic_raise
    unreachable
    i32.const 0
  )
  ;; A new cell under cell `parent`, starting from its contexts: its id.
  (func $grow (param $store i32) (param $owner i32) (param $carried i32) (param $parent i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $t i32)
    (local $id i32)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    local.set $t
    local.get $t
    i32.load offset=4 ;; .treeCount
    local.set $id
    local.get $store
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 672
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    local.get $id
    i32.const 1
    i32.const 984
    call $__i32_add_chk
    i32.store offset=8
    local.get $__mem0
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 724
    i32.store
    local.get $__mem1
    local.get $id
    i32.store offset=4
    local.get $__mem1
    local.get $t
    i32.load offset=8 ;; .treeCells
    local.get $parent
    call $framesOf
    i32.store offset=8
    local.get $__mem1
    local.get $t
    i32.load offset=8 ;; .treeCells
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.add
    call $storeSet
    local.get $id
    return
  )
  ;; The contexts cell `id` holds now.
  (func $framesAt (param $store i32) (param $owner i32) (param $carried i32) (param $id i32) (result i32)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    i32.load offset=8 ;; .treeCells
    local.get $id
    call $framesOf
    return
  )
  (func $carriedFrames (param $c i32) (result i32)
    local.get $c
    i32.load ;; .frames
    return
  )
  ;; `value` provided for `key` in cell `id`.
  (func $provideAt (param $store i32) (param $owner i32) (param $carried i32) (param $id i32) (param $key i32) (param $value i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $t i32)
    (local $frames i32)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    local.set $t
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 1044
    i32.store
    local.get $__mem0
    local.get $key
    i32.store offset=4
    local.get $__mem0
    local.get $value
    i32.store offset=8
    local.get $__mem0
    local.get $t
    i32.load offset=8 ;; .treeCells
    local.get $id
    call $framesOf
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $frames
    local.get $store
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 672
    i32.store
    local.get $__mem1
    i32.const 0
    i32.store offset=4
    local.get $__mem1
    local.get $t
    i32.load offset=4 ;; .treeCount
    i32.store offset=8
    local.get $__mem1
    i32.const 16
    call $__alloc
    local.set $__mem2
    local.get $__mem2
    i32.const 724
    i32.store
    local.get $__mem2
    local.get $id
    i32.store offset=4
    local.get $__mem2
    local.get $frames
    i32.store offset=8
    local.get $__mem2
    local.get $t
    i32.load offset=8 ;; .treeCells
    i32.store offset=12
    local.get $__mem2
    i32.const 4
    i32.add
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    call $storeSet
    i32.const 0
  )
  ;; The root's tree closed; a closed one is left as it is.
  (func $closeStore (param $store i32) (result i32)
    (local $__mem0 i32)
    local.get $store
    call $storeLive
    i32.eqz
    (if (result i32)
      (then
    i32.const 0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $store
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 672
    i32.store
    local.get $__mem0
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 0
    i32.store offset=8
    local.get $__mem0
    i32.const 0
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.add
    call $storeClose
    i32.const 0
  )
  ;; The contexts of cell `id` in `cells`.
  (func $framesOf (param $cells i32) (param $id i32) (result i32)
    (local $cur i32)
    (local $e i32)
    (local $__mem0 i32)
    local.get $cells
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 724
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $cur
    local.set $e
    local.get $e
    i32.load
    local.get $id
    i32.eq
    (if (result i32)
      (then
    local.get $e
    call $entryFrames
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $e
    call $entryNext
    local.set $cur
    i32.const 0
      )
      (else
    i32.const 0
    return
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
  )
  (func $entryFrames (param $e i32) (result i32)
    local.get $e
    i32.load offset=4 ;; .cellFrames
    return
  )
  (func $entryNext (param $e i32) (result i32)
    local.get $e
    i32.load offset=8 ;; .cellNext
    return
  )
  ;; ── resolving and running (decisions 809 (6), 815 (5), 819, 822, 825) ───────
  ;; Runs `c` over `scope` at `key` and hands back its answer as it came — a
  ;; value, or the task of a component that awaits —, nothing awaited inside.
  (func $resolve (export "resolve") (param $c i32) (param $scope i32) (param $key i32) (result i32)
    i32.const 0
    (if (result i32)
      (then
    unreachable ;; unknown: no static type to box this value by (a type parameter's slot?)
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    unreachable ;; unknown: no static type to box this value by (a type parameter's slot?)
    return
  )
  ;; Runs a root: `c` resolved over `scope`, or over a root of its own that it
  ;; closes when `c` settles or fails (825 (1)), awaited only when it answered a
  ;; task (822, 823): `val page = await run(App());`.
  ;; @Async — a state machine (decision 392)
  (func $run (export "run") (param $c i32) (param $scope i32) (result i32)
    (local $__fr i32)
    i32.const 88 ;; the frame: the resume index, then every local
    call $__alloc
    local.set $__fr
    local.get $__fr
    local.get $c
    i32.store offset=8
    local.get $__fr
    local.get $scope
    i32.store offset=16
    i32.const 0 ;; run__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $run__body (param $__task i32) (result i32)
    (local $c i32)
    (local $scope i32)
    (local $handed i32)
    (local $root i32)
    (local $r i32)
    (local $__frame i32)
    (local $__seek i32)
    (local $__state i32)
    (local $__cnd0 i32)
    (local $__cnd1 i32)
    (local $__defer_exc1 i32)
    (local $__defer_ran1 i32)
    (local $__cnd2 i32)
    local.get $__task
    i32.load offset=16
    local.set $__frame
    local.get $__frame
    i32.load offset=8
    local.set $c
    local.get $__frame
    i32.load offset=16
    local.set $scope
    local.get $__frame
    i32.load offset=24
    local.set $handed
    local.get $__frame
    i32.load offset=32
    local.set $root
    local.get $__frame
    i32.load offset=40
    local.set $r
    local.get $__frame
    i32.load offset=48
    local.set $__cnd0
    local.get $__frame
    i32.load offset=56
    local.set $__cnd1
    local.get $__frame
    i32.load offset=64
    local.set $__defer_exc1
    local.get $__frame
    i32.load offset=72
    local.set $__defer_ran1
    local.get $__frame
    i32.load offset=80
    local.set $__cnd2
    local.get $__frame
    i32.load ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd0 ;; the condition, read back
      )
      (else
    local.get $scope
    i32.const 0
    i32.ne
    local.tee $__cnd0
      )
    )
    (if (result i32)
      (then
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $c
    local.get $scope
    call $Place_none
    call $resolve
    local.set $handed
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd1 ;; the condition, read back
      )
      (else
    unreachable ;; `is Async<unknown>`: the wasm backend has no run-time test for this type (no value of it carries a descriptor)
    local.tee $__cnd1
      )
    )
    (if (result i32)
      (then
    local.get $handed
    return
      )
      (else
        i32.const 0
      )
    )
    drop
      )
    )
    local.get $handed
    return
      )
      (else
        i32.const 0
      )
    )
    drop
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    call $Scope_root
    local.set $root
      )
    )
    (block $__defer_done1 (result i32)
    (block $__defer_h1 (result i32)
    i32.const 0
    local.set $__defer_ran1
    (try_table (result i32) (catch $__bp_panic $__defer_h1)
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $c
    local.get $root
    call $Place_none
    call $resolve
    local.set $r
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd2 ;; the condition, read back
      )
      (else
    unreachable ;; `is Async<unknown>`: the wasm backend has no run-time test for this type (no value of it carries a descriptor)
    local.tee $__cnd2
      )
    )
    (if (result i32)
      (then
    local.get $r
    i32.const 1
    local.set $__defer_ran1
    local.get $root
    call $Scope_close
    drop
    return
      )
      (else
        i32.const 0
      )
    )
    drop
      )
    )
    local.get $r
    i32.const 1
    local.set $__defer_ran1
    local.get $root
    call $Scope_close
    drop
    return
    )
    local.get $root
    call $Scope_close
    drop
    br $__defer_done1
    )
    local.set $__defer_exc1
    local.get $__defer_ran1
    i32.eqz
    (if
      (then
    local.get $root
    call $Scope_close
    drop
      )
    )
    local.get $__defer_exc1
    throw $__bp_panic
    )
  )
  (func $run__step (param $__task i32)
    (local $__v i32)
    local.get $__task
    call $run__body
    local.set $__v
    global.get $__task_suspended
    (if
      (then
    i32.const 0
    global.set $__task_suspended
    return
      )
    )
    local.get $__task
    local.get $__v
    call $__task_settle_i32
  )
  ;; ── what the scope lowering calls (decisions 809 (8), 812, 819) ──────────────
  ;; 
  ;; A program never names these: the compiler imports them under names no
  ;; source can spell. A component body is lowered to `{ scope, key -> … }`
  ;; opening `enter(scope, key)`, its own cell; `use provide(c)` is
  ;; `provideIn(<cell>, <T's identity>, c)` (a context is its value at run time:
  ;; the compiler writes `createContext(v)` as `v`), `use context(ctx)` is
  ;; `find(<the cell's contexts at entry>, <ctx's type's identity>, ctx)`, a
  ;; `use` of a hook or a component calls its value with the cell and
  ;; `Place.none()`, and each `return v` answers `answer(v)`. A context's
  ;; identity is its value's type (379) — the compiler writes it, never a
  ;; program.
  ;; One provided value over the frames it was provided in.
  ;; The cell a body opens: `scope`'s child at `key`.
  (func $enter (export "enter") (param $scope i32) (param $key i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $scope
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 584
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $key
    local.tee $__mem1
    i32.const 256
    i32.ge_u
    local.get $__mem1
    i32.const 4
    i32.sub
    local.get $__mem1
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 460
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $scope
    local.get $key
    call $Scope_childAt
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $scope
    call $Place_none
    call $Scope_childAt
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 1072
    i32.const 1
    call $__panic_raise
    unreachable
    i32.const 0
  )
  ;; The contexts `cell` holds now — what a body's `use context` reads.
  (func $received (export "received") (param $cell i32) (result i32)
    (local $__mem0 i32)
    local.get $cell
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 584
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $cell
    call $Scope_storeRef
    local.get $cell
    call $Scope_ownerRef
    local.get $cell
    call $Scope_carriedRef
    local.get $cell
    call $Scope_cellId
    call $framesAt
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 1072
    i32.const 1
    call $__panic_raise
    unreachable
    i32.const 0
  )
  ;; `value` provided for `key` in `cell`: what is resolved under it afterwards
  ;; reads it (809 (8), 812 (3)).
  (func $provideIn (export "provideIn") (param $cell i32) (param $key i32) (param $value i32) (result i32)
    (local $__mem0 i32)
    local.get $cell
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 584
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $cell
    call $Scope_storeRef
    local.get $cell
    call $Scope_ownerRef
    local.get $cell
    call $Scope_carriedRef
    local.get $cell
    call $Scope_cellId
    local.get $key
    local.get $value
    call $provideAt
    drop
    i32.const 0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 1072
    i32.const 1
    call $__panic_raise
    unreachable
    i32.const 0
  )
  ;; The value provided nearest above for `key` in `frames`, else `fallback` —
  ;; the type's declared default (decision 378 (3): no read is unbound).
  ;; The two `unknown` fields are read through `frameValue` / `frameParent`: wasm boxes a field read as `unknown` only as a function's answer.
  (func $find (export "find") (param $frames i32) (param $key i32) (param $fallback i32) (result i32)
    (local $__mem0 i32)
    (local $cur i32)
    (local $f i32)
    (local $__mem1 i32)
    local.get $frames
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 1044
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $cur
    local.set $f
    local.get $f
    i32.load
    local.get $key
    call $__str_eq
    (if (result i32)
      (then
    local.get $f
    call $frameValue
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $f
    call $frameParent
    local.set $cur
    i32.const 0
      )
      (else
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 1044
    i32.store
    local.get $__mem1
    local.get $key
    i32.store offset=4
    local.get $__mem1
    local.get $fallback
    i32.store offset=8
    local.get $__mem1
    i32.const 0
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    call $frameValue
    return
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
  )
  ;; A body's answer, as it is (the word wasm moves through it, decision 504).
  (func $answer (export "answer") (param $value i32) (result i32)
    local.get $value
    return
  )
  ;; The place a `use` passes (820 (2)).
  (func $nowhere (export "nowhere") (result i32)
    call $Place_none
    return
  )
  ;; A fresh root, for a `use` written outside every component body.
  (func $root (export "root") (result i32)
    call $Scope_root
    return
  )
  (func $frameValue (param $f i32) (result i32)
    local.get $f
    i32.load offset=4 ;; .value
    return
  )
  (func $frameParent (param $f i32) (result i32)
    local.get $f
    i32.load offset=8 ;; .parent
    return
  )
  ;; ── the store's host side (decision 824) ─────────────────────────────────────
  ;; storeNew — .Wasm(wasi: .CellNew)
  (func $storeNew (result i32)
    call $__memo_cell_new
  )
  ;; storeLive — .Wasm(wasi: .CellFilled)
  (func $storeLive (param $store i32) (result i32)
    local.get $store
    call $__memo_cell_filled
  )
  ;; storeGet — .Wasm(wasi: .CellGet)
  (func $storeGet (param $store i32) (result i32)
    local.get $store
    call $__memo_cell_get
  )
  ;; storeSet — .Wasm(wasi: .CellSet)
  (func $storeSet (param $store i32) (param $value i32)
    local.get $store
    local.get $value
    call $__memo_cell_set
  )
  ;; The closed tree written over the root's: on erlang and beam the entry goes
  ;; instead, so the process keeps no `{bp_scope, _}` (825 (2), (3)).
  ;; storeClose — .Wasm(wasi: .CellSet)
  (func $storeClose (param $store i32) (param $closed i32)
    local.get $store
    local.get $closed
    call $__memo_cell_set
  )
  ;; The process a root is made in: its pid on erlang and beam; elsewhere one
  ;; process holds every root, and a token no test reads stands for it.
  ;; ownerSelf — .Wasm(wasi: .CellNew)
  (func $ownerSelf (result i32)
    call $__memo_cell_new
  )
  ;; Whether `owner` is another process than this one: never off the BEAM (an
  ;; owner token there is an empty cell).
  ;; ownerForeign — .Wasm(wasi: .CellFilled)
  (func $ownerForeign (param $owner i32) (result i32)
    local.get $owner
    call $__memo_cell_filled
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__str_eq (param $a i32) (param $b i32) (result i32)
    (local $i i32) (local $alen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $alen
    local.get $b
    i32.load
    i32.ne
    (if
      (then i32.const 0 return)
    )
    (block $done
      (loop $cmp
        local.get $i
        local.get $alen
        i32.ge_u
        br_if $done
        local.get $a
        local.get $i
        i32.add
        i32.load8_u offset=4
        local.get $b
        local.get $i
        i32.add
        i32.load8_u offset=4
        i32.ne
        (if
          (then i32.const 0 return)
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cmp
      )
    )
    i32.const 1
  )
  (func $__alloc (param $n i32) (result i32)
    (local $p i32) (local $e i32)
    global.get $__heap_ptr
    local.set $p
    local.get $p
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    local.set $e
    local.get $e
    local.get $p
    i32.lt_u
    (if
      (then
        unreachable
      )
    )
    local.get $e
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    (if
      (then
        local.get $e
        i32.const 65535
        i32.add
        i32.const 16
        i32.shr_u
        memory.size
        i32.sub
        memory.grow
        i32.const -1
        i32.eq
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $e
    global.set $__heap_ptr
    local.get $p
  )
  (func $__write_err (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 2
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__assert_fail (param $where i32) (param $msg i32)
    local.get $where
    i32.const 4
    i32.add
    local.get $where
    i32.load
    call $__write_err
    i32.const 188
    i64.const 8390880602276044858
    i64.store
    i32.const 196
    i64.const 7811882119909502825
    i64.store
    i32.const 204
    i32.const 101
    i32.store8
    i32.const 205
    i32.const 100
    i32.store8
    i32.const 188
    i32.const 18
    call $__write_err
    local.get $msg
    (if
      (then
        i32.const 188
        i32.const 8250
        i32.store
        i32.const 188
        i32.const 2
        call $__write_err
        local.get $msg
        i32.const 4
        i32.add
        local.get $msg
        i32.load
        call $__write_err
      )
    )
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__panic_fail (param $msg i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    i32.const 4
    i32.add
    local.get $msg
    i32.load
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site i32) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site i32) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site i32) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            local.get $site
            call $__chk_fail
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (global $__task_head (mut i32) (i32.const 0))
  (global $__task_tail (mut i32) (i32.const 0))
  (global $__task_suspended (mut i32) (i32.const 0))
  (func $__task_new (param $kind i32) (param $frame i32) (result i32)
    (local $t i32)
    i32.const 40
    call $__alloc
    local.set $t
    local.get $t
    local.get $kind
    i32.store offset=20
    local.get $t
    local.get $frame
    i32.store offset=16
    local.get $t
  )
  (func $__task_start (param $kind i32) (param $frame i32) (result i32)
    (local $t i32)
    local.get $kind
    local.get $frame
    call $__task_new
    local.tee $t
    call $__task_resume
    local.get $t
  )
  (func $__task_pending (param $t i32) (result i32)
    local.get $t
    i32.load
    i32.eqz
  )
  (func $__task_listen (param $t i32) (param $kind i32) (param $target i32) (param $index i32)
    (local $n i32)
    i32.const 16
    call $__alloc
    local.set $n
    local.get $n
    local.get $t
    i32.load offset=4
    i32.store
    local.get $n
    local.get $kind
    i32.store offset=4
    local.get $n
    local.get $target
    i32.store offset=8
    local.get $n
    local.get $index
    i32.store offset=12
    local.get $t
    local.get $n
    i32.store offset=4
  )
  (func $__task_wait (param $t i32) (param $w i32)
    local.get $t
    i32.const 0
    local.get $w
    i32.const 0
    call $__task_listen
  )
  (func $__task_settle_i32 (param $t i32) (param $v i32)
    local.get $t
    local.get $v
    i32.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_settle_i64 (param $t i32) (param $v i64)
    local.get $t
    local.get $v
    i64.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_settle_f64 (param $t i32) (param $v f64)
    local.get $t
    local.get $v
    f64.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_wake (param $t i32)
    (local $n i32) (local $m i32) (local $r i32) (local $k i32) (local $w i32)
    local.get $t
    i32.load
    (if
      (then
        return
      )
    )
    local.get $t
    i32.const 1
    i32.store
    local.get $t
    i32.load offset=4
    local.set $n
    local.get $t
    i32.const 0
    i32.store offset=4
    (block $brk
      (loop $cont
        local.get $n
        i32.eqz
        br_if $brk
        local.get $n
        i32.load
        local.set $m
        local.get $n
        local.get $r
        i32.store
        local.get $n
        local.set $r
        local.get $m
        local.set $n
        br $cont
      )
    )
    (block $brk
      (loop $cont
        local.get $r
        i32.eqz
        br_if $brk
        local.get $r
        i32.load offset=4
        local.set $k
        local.get $r
        i32.load offset=8
        local.set $w
        local.get $k
        i32.eqz
        (if
          (then
            local.get $w
            call $__task_enqueue
          )
        )
        local.get $k
        i32.const 1
        i32.eq
        (if
          (then
            local.get $w
            i32.load
            i32.eqz
            (if
              (then
                local.get $w
                local.get $t
                i64.load offset=8
                i64.store offset=8
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $k
        i32.const 2
        i32.eq
        (if
          (then
            local.get $w
            i32.load offset=28
            i32.const 4
            i32.add
            local.get $r
            i32.load offset=12
            i32.const 4
            i32.mul
            i32.add
            local.get $t
            i32.load offset=8
            i32.store
            local.get $w
            local.get $w
            i32.load offset=32
            i32.const 1
            i32.sub
            i32.store offset=32
            local.get $w
            i32.load offset=32
            i32.eqz
            (if
              (then
                local.get $w
                local.get $w
                i32.load offset=28
                i32.store offset=8
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $r
        i32.load
        local.set $r
        br $cont
      )
    )
  )
  (func $__task_enqueue (param $t i32)
    local.get $t
    i32.const 0
    i32.store offset=24
    global.get $__task_tail
    (if
      (then
        global.get $__task_tail
        local.get $t
        i32.store offset=24
      )
      (else
        local.get $t
        global.set $__task_head
      )
    )
    local.get $t
    global.set $__task_tail
  )
  (func $__task_drain
    (local $t i32)
    (block $brk
      (loop $cont
        global.get $__task_head
        local.tee $t
        i32.eqz
        br_if $brk
        local.get $t
        i32.load offset=24
        global.set $__task_head
        global.get $__task_head
        i32.eqz
        (if
          (then
            i32.const 0
            global.set $__task_tail
          )
        )
        local.get $t
        call $__task_resume
        br $cont
      )
    )
  )
  (func $__task_block_on (param $t i32) (result i32)
    (local $r i32)
    (block $brk
      (loop $cont
        local.get $t
        i32.load
        br_if $brk
        global.get $__task_head
        local.tee $r
        i32.eqz
        (if
          (then
            unreachable
          )
        )
        local.get $r
        i32.load offset=24
        global.set $__task_head
        global.get $__task_head
        i32.eqz
        (if
          (then
            i32.const 0
            global.set $__task_tail
          )
        )
        local.get $r
        call $__task_resume
        br $cont
      )
    )
    local.get $t
  )
  (func $__task_finish
    (block $brk
      (loop $cont
        call $__task_drain
        call $__task_host_poll
        i32.eqz
        br_if $brk
        br $cont
      )
    )
  )
  (func $__task_resume (param $t i32)
    (local $k i32)
    local.get $t
    i32.load offset=20 ;; kind
    local.set $k
    local.get $k
    i32.const 0
    i32.eq
    (if
      (then
    local.get $t
    call $run__step
    return
      )
    )
    unreachable
  )
  (func $__task_host_poll (result i32)
    i32.const 0
  )
  (func $__panic_raise (param $msg i32) (param $print i32)
    (local $c i32)
    i32.const 8
    call $__alloc
    local.set $c
    local.get $c
    local.get $msg
    i32.store
    local.get $c
    local.get $print
    i32.store offset=4
    local.get $c
    throw $__bp_panic
  )
  (func $__chk_fail (param $site i32)
    local.get $site
    i32.const 1
    call $__panic_raise
    unreachable
  )
  (func $__memo_cell_new (result i32)
    (local $p i32)
    i32.const 8
    call $__alloc
    local.set $p
    local.get $p
    i32.const 0
    i32.store
    local.get $p
    i32.const 0
    i32.store offset=4
    local.get $p
  )
  (func $__memo_cell_filled (param $c i32) (result i32)
    local.get $c
    i32.load
  )
  (func $__memo_cell_get (param $c i32) (result i32)
    local.get $c
    i32.load offset=4
  )
  (func $__memo_cell_set (param $c i32) (param $v i32)
    local.get $c
    local.get $v
    i32.store offset=4
    local.get $c
    i32.const 1
    i32.store
  )
  (@custom "botopink.needs" "exceptions\0a")
)
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

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0 $__lambda1))
  (data (i32.const 256) "\18\00\00\00R\07Context\01\0ccontextValueG")
  (data (i32.const 284) "\01\00\00\00i")
  (data (i32.const 292) "\56\00\00\00`use provide` / `use context` are lowered where they are written; this body never runs")
  (data (i32.const 384) "\41\00\00\00`use inject` is lowered where it is written; this body never runs")
  (data (i32.const 456) "\77\00\00\00R\05Place\04\06callNoi\04itemE\05\10PlaceItem.Absent\0ePlaceItem.Body\0fPlaceItem.Plain\0fPlaceItem.Index\rPlaceItem.Key\06itemNoi\08keyValuei")
  (data (i32.const 580) "\39\00\00\00R\05Scope\04\nscopeStorei\tscopeCelli\nscopeOwneri\0cscopeCarriedi")
  (data (i32.const 644) "\12\00\00\00R\07Carried\01\06framesi")
  (data (i32.const 668) "\2e\00\00\00R\tScopeTree\03\ntreeClosedb\ttreeCounti\ttreeCellsi")
  (data (i32.const 720) "\2a\00\00\00R\tCellEntry\03\06cellNoi\ncellFramesi\08cellNexti")
  (data (i32.const 768) "\81\00\00\00scope-foreign: a scope is read in another process than its root's — pass `scope.detach()` to another process (decision 824 (3))")
  (data (i32.const 904) "\4b\00\00\00scope-closed: a scope is used after its root's `close()` (decision 825 (2))")
  (data (i32.const 984) "\2b\00\00\00integer overflow: + on i32 at main.bp:232:9")
  (data (i32.const 1032) "\1c\00\00\00R\05Frame\03\03keys\05valuei\06parenti")
  (data (i32.const 1064) "\30\00\00\00a component is run with a `Scope` (decision 819)")
  (data (i32.const 1116) "\0a\00\00\00R\07Element\00")
  (global $__heap_ptr (mut i32) (i32.const 1132))
  (func $createContext (param $value i32) (result i32)
    (local $__mem0 i32)
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 288
    i32.store offset=8
    local.get $__mem0
    local.get $value
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $provide (param $ctx i32) (result i32)
    i32.const 292
    call $__panic_fail
    unreachable
    i32.const 0
  )
  (func $context (param $ctx i32) (result i32)
    i32.const 292
    call $__panic_fail
    unreachable
    i32.const 0
  )
  (func $inject (param $t i32) (result i32)
    i32.const 384
    call $__panic_fail
    unreachable
    i32.const 0
  )
  (func $Place_none (result i32)
    (local $__mem0 i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 460
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 0 ;; PlaceItem.Absent
    i32.store offset=8
    local.get $__mem0
    i32.const 0
    i32.store offset=12
    local.get $__mem0
    i32.const 0
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Place_key (param $k i32) (result i32)
    (local $__mem0 i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 460
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 4 ;; PlaceItem.Key
    i32.store offset=8
    local.get $__mem0
    i32.const 0
    i32.store offset=12
    local.get $__mem0
    unreachable ;; unknown: no static type to box this value by (a type parameter's slot?)
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Place_index (param $i i32) (result i32)
    (local $__mem0 i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 460
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 3 ;; PlaceItem.Index
    i32.store offset=8
    local.get $__mem0
    local.get $i
    i32.store offset=12
    local.get $__mem0
    i32.const 0
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Place_with (param $self i32) (param $key i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $key
    i32.load offset=4 ;; .item
    i32.const 4 ;; PlaceItem.Key
    i32.eq
    (if (result i32)
      (then
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 460
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .callNo
    i32.store offset=4
    local.get $__mem0
    i32.const 4 ;; PlaceItem.Key
    i32.store offset=8
    local.get $__mem0
    i32.const 0
    i32.store offset=12
    local.get $__mem0
    local.get $key
    i32.load offset=12 ;; .keyValue
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $key
    i32.load offset=4 ;; .item
    i32.const 3 ;; PlaceItem.Index
    i32.eq
    (if (result i32)
      (then
    local.get $self
    i32.load offset=4 ;; .item
    i32.const 0 ;; PlaceItem.Absent
    i32.eq
    local.get $self
    i32.load offset=4 ;; .item
    i32.const 2 ;; PlaceItem.Plain
    i32.eq
    i32.or
    (if (result i32)
      (then
    i32.const 20
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 460
    i32.store
    local.get $__mem1
    local.get $self
    i32.load ;; .callNo
    i32.store offset=4
    local.get $__mem1
    i32.const 3 ;; PlaceItem.Index
    i32.store offset=8
    local.get $__mem1
    local.get $key
    i32.load offset=8 ;; .itemNo
    i32.store offset=12
    local.get $__mem1
    i32.const 0
    i32.store offset=16
    local.get $__mem1
    i32.const 4
    i32.add
    return
      )
      (else
        i32.const 0
      )
    )
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $self
    return
  )
  (func $Scope_root (result i32)
    (local $__mem0 i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 584
    i32.store
    local.get $__mem0
    i32.const 0
    call $storeOf
    i32.store offset=4
    local.get $__mem0
    i32.const 0
    i32.store offset=8
    local.get $__mem0
    call $ownerSelf
    i32.store offset=12
    local.get $__mem0
    i32.const 0
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Scope_childAt (param $self i32) (param $key i32) (result i32)
    (local $__mem0 i32)
    i32.const 20
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 584
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .scopeStore
    i32.store offset=4
    local.get $__mem0
    local.get $self
    i32.load ;; .scopeStore
    local.get $self
    i32.load offset=8 ;; .scopeOwner
    local.get $self
    i32.load offset=12 ;; .scopeCarried
    local.get $self
    i32.load offset=4 ;; .scopeCell
    call $grow
    i32.store offset=8
    local.get $__mem0
    local.get $self
    i32.load offset=8 ;; .scopeOwner
    i32.store offset=12
    local.get $__mem0
    local.get $self
    i32.load offset=12 ;; .scopeCarried
    i32.store offset=16
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $Scope_close (param $self i32) (result i32)
    local.get $self
    i32.load ;; .scopeStore
    call $closeStore
  )
  (func $Scope_detach (param $self i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $carried i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 648
    i32.store
    local.get $__mem0
    local.get $self
    i32.load ;; .scopeStore
    local.get $self
    i32.load offset=8 ;; .scopeOwner
    local.get $self
    i32.load offset=12 ;; .scopeCarried
    local.get $self
    i32.load offset=4 ;; .scopeCell
    call $framesAt
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $carried
    i32.const 20
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 584
    i32.store
    local.get $__mem1
    call $storeNew
    i32.store offset=4
    local.get $__mem1
    i32.const 0
    i32.store offset=8
    local.get $__mem1
    i32.const 0
    i32.store offset=12
    local.get $__mem1
    local.get $carried
    i32.store offset=16
    local.get $__mem1
    i32.const 4
    i32.add
    return
  )
  (func $Scope_storeRef (param $self i32) (result i32)
    local.get $self
    i32.load ;; .scopeStore
    return
  )
  (func $Scope_cellId (param $self i32) (result i32)
    local.get $self
    i32.load offset=4 ;; .scopeCell
    return
  )
  (func $Scope_ownerRef (param $self i32) (result i32)
    local.get $self
    i32.load offset=8 ;; .scopeOwner
    return
  )
  (func $Scope_carriedRef (param $self i32) (result i32)
    local.get $self
    i32.load offset=12 ;; .scopeCarried
    return
  )
  (func $storeOf (param $frames i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $store i32)
    call $storeNew
    local.set $store
    local.get $store
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 672
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 1
    i32.store offset=8
    local.get $__mem0
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 724
    i32.store
    local.get $__mem1
    i32.const 0
    i32.store offset=4
    local.get $__mem1
    local.get $frames
    i32.store offset=8
    local.get $__mem1
    i32.const 0
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.add
    call $storeSet
    local.get $store
    return
  )
  (func $treeOf (param $store i32) (param $owner i32) (param $carried i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $c i32)
    (local $t i32)
    (local $raw i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    local.get $owner
    call $ownerForeign
    (if (result i32)
      (then
    i32.const 768
    call $__panic_fail
    unreachable
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $store
    call $storeLive
    i32.eqz
    (if (result i32)
      (then
    local.get $carried
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 648
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $carried
    local.set $c
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 672
    i32.store
    local.get $__mem1
    i32.const 0
    i32.store offset=4
    local.get $__mem1
    i32.const 1
    i32.store offset=8
    local.get $__mem1
    i32.const 16
    call $__alloc
    local.set $__mem2
    local.get $__mem2
    i32.const 724
    i32.store
    local.get $__mem2
    i32.const 0
    i32.store offset=4
    local.get $__mem2
    local.get $c
    call $carriedFrames
    i32.store offset=8
    local.get $__mem2
    i32.const 0
    i32.store offset=12
    local.get $__mem2
    i32.const 4
    i32.add
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    local.set $t
    local.get $store
    local.get $t
    call $storeSet
    local.get $t
    return
      )
      (else
        i32.const 0
      )
    )
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $store
    call $storeLive
    (if (result i32)
      (then
    local.get $store
    call $storeGet
    local.set $raw
    local.get $raw
    local.tee $__mem3
    i32.const 256
    i32.ge_u
    local.get $__mem3
    i32.const 4
    i32.sub
    local.get $__mem3
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 672
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $raw
    local.set $t
    local.get $t
    i32.load ;; .treeClosed
    i32.eqz
    (if (result i32)
      (then
    local.get $t
    return
      )
      (else
        i32.const 0
      )
    )
      )
      (else
        i32.const 0
      )
    )
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 904
    call $__panic_fail
    unreachable
    i32.const 0
  )
  (func $grow (param $store i32) (param $owner i32) (param $carried i32) (param $parent i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $t i32)
    (local $id i32)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    local.set $t
    local.get $t
    i32.load offset=4 ;; .treeCount
    local.set $id
    local.get $store
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 672
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    local.get $id
    i32.const 1
    i32.const 984
    call $__i32_add_chk
    i32.store offset=8
    local.get $__mem0
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 724
    i32.store
    local.get $__mem1
    local.get $id
    i32.store offset=4
    local.get $__mem1
    local.get $t
    i32.load offset=8 ;; .treeCells
    local.get $parent
    call $framesOf
    i32.store offset=8
    local.get $__mem1
    local.get $t
    i32.load offset=8 ;; .treeCells
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.add
    call $storeSet
    local.get $id
    return
  )
  (func $framesAt (param $store i32) (param $owner i32) (param $carried i32) (param $id i32) (result i32)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    i32.load offset=8 ;; .treeCells
    local.get $id
    call $framesOf
    return
  )
  (func $carriedFrames (param $c i32) (result i32)
    local.get $c
    i32.load ;; .frames
    return
  )
  (func $provideAt (param $store i32) (param $owner i32) (param $carried i32) (param $id i32) (param $key i32) (param $value i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $t i32)
    (local $frames i32)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    local.set $t
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 1036
    i32.store
    local.get $__mem0
    local.get $key
    i32.store offset=4
    local.get $__mem0
    local.get $value
    i32.store offset=8
    local.get $__mem0
    local.get $t
    i32.load offset=8 ;; .treeCells
    local.get $id
    call $framesOf
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.add
    local.set $frames
    local.get $store
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 672
    i32.store
    local.get $__mem1
    i32.const 0
    i32.store offset=4
    local.get $__mem1
    local.get $t
    i32.load offset=4 ;; .treeCount
    i32.store offset=8
    local.get $__mem1
    i32.const 16
    call $__alloc
    local.set $__mem2
    local.get $__mem2
    i32.const 724
    i32.store
    local.get $__mem2
    local.get $id
    i32.store offset=4
    local.get $__mem2
    local.get $frames
    i32.store offset=8
    local.get $__mem2
    local.get $t
    i32.load offset=8 ;; .treeCells
    i32.store offset=12
    local.get $__mem2
    i32.const 4
    i32.add
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    call $storeSet
    i32.const 0
  )
  (func $closeStore (param $store i32) (result i32)
    (local $__mem0 i32)
    local.get $store
    call $storeLive
    i32.eqz
    (if (result i32)
      (then
    i32.const 0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $store
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 672
    i32.store
    local.get $__mem0
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 0
    i32.store offset=8
    local.get $__mem0
    i32.const 0
    i32.store offset=12
    local.get $__mem0
    i32.const 4
    i32.add
    call $storeClose
    i32.const 0
  )
  (func $framesOf (param $cells i32) (param $id i32) (result i32)
    (local $cur i32)
    (local $e i32)
    (local $__mem0 i32)
    local.get $cells
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 724
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $cur
    local.set $e
    local.get $e
    i32.load
    local.get $id
    i32.eq
    (if (result i32)
      (then
    local.get $e
    call $entryFrames
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $e
    call $entryNext
    local.set $cur
    i32.const 0
      )
      (else
    i32.const 0
    return
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
  )
  (func $entryFrames (param $e i32) (result i32)
    local.get $e
    i32.load offset=4 ;; .cellFrames
    return
  )
  (func $entryNext (param $e i32) (result i32)
    local.get $e
    i32.load offset=8 ;; .cellNext
    return
  )
  (func $resolve (param $c i32) (param $scope i32) (param $key i32) (result i32)
    i32.const 0
    (if (result i32)
      (then
    unreachable ;; unknown: no static type to box this value by (a type parameter's slot?)
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    unreachable ;; unknown: no static type to box this value by (a type parameter's slot?)
    return
  )
  ;; @Async — a state machine (decision 392)
  (func $run (param $c i32) (param $scope i32) (result i32)
    (local $__fr i32)
    i32.const 72 ;; the frame: the resume index, then every local
    call $__alloc
    local.set $__fr
    local.get $__fr
    local.get $c
    i32.store offset=8
    local.get $__fr
    local.get $scope
    i32.store offset=16
    i32.const 0 ;; run__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $run__body (param $__task i32) (result i32)
    (local $c i32)
    (local $scope i32)
    (local $handed i32)
    (local $root i32)
    (local $r i32)
    (local $__frame i32)
    (local $__seek i32)
    (local $__state i32)
    (local $__cnd0 i32)
    (local $__cnd1 i32)
    (local $__cnd2 i32)
    local.get $__task
    i32.load offset=16
    local.set $__frame
    local.get $__frame
    i32.load offset=8
    local.set $c
    local.get $__frame
    i32.load offset=16
    local.set $scope
    local.get $__frame
    i32.load offset=24
    local.set $handed
    local.get $__frame
    i32.load offset=32
    local.set $root
    local.get $__frame
    i32.load offset=40
    local.set $r
    local.get $__frame
    i32.load offset=48
    local.set $__cnd0
    local.get $__frame
    i32.load offset=56
    local.set $__cnd1
    local.get $__frame
    i32.load offset=64
    local.set $__cnd2
    local.get $__frame
    i32.load ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd0 ;; the condition, read back
      )
      (else
    local.get $scope
    i32.const 0
    i32.ne
    local.tee $__cnd0
      )
    )
    (if (result i32)
      (then
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $c
    local.get $scope
    call $Place_none
    call $resolve
    local.set $handed
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd1 ;; the condition, read back
      )
      (else
    unreachable ;; `is Async<unknown>`: the wasm backend has no run-time test for this type (no value of it carries a descriptor)
    local.tee $__cnd1
      )
    )
    (if (result i32)
      (then
    local.get $handed
    return
      )
      (else
        i32.const 0
      )
    )
    drop
      )
    )
    local.get $handed
    return
      )
      (else
        i32.const 0
      )
    )
    drop
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    call $Scope_root
    local.set $root
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $c
    local.get $root
    call $Place_none
    call $resolve
    local.set $r
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd2 ;; the condition, read back
      )
      (else
    unreachable ;; `is Async<unknown>`: the wasm backend has no run-time test for this type (no value of it carries a descriptor)
    local.tee $__cnd2
      )
    )
    (if (result i32)
      (then
    local.get $r
    local.get $root
    call $Scope_close
    drop
    return
      )
      (else
        i32.const 0
      )
    )
    drop
      )
    )
    local.get $r
    local.get $root
    call $Scope_close
    drop
    return
  )
  (func $run__step (param $__task i32)
    (local $__v i32)
    local.get $__task
    call $run__body
    local.set $__v
    global.get $__task_suspended
    (if
      (then
    i32.const 0
    global.set $__task_suspended
    return
      )
    )
    local.get $__task
    local.get $__v
    call $__task_settle_i32
  )
  (func $enter (param $scope i32) (param $key i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $scope
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 584
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $key
    local.tee $__mem1
    i32.const 256
    i32.ge_u
    local.get $__mem1
    i32.const 4
    i32.sub
    local.get $__mem1
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 460
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $scope
    local.get $key
    call $Scope_childAt
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $scope
    call $Place_none
    call $Scope_childAt
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 1064
    call $__panic_fail
    unreachable
    i32.const 0
  )
  (func $received (param $cell i32) (result i32)
    (local $__mem0 i32)
    local.get $cell
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 584
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $cell
    call $Scope_storeRef
    local.get $cell
    call $Scope_ownerRef
    local.get $cell
    call $Scope_carriedRef
    local.get $cell
    call $Scope_cellId
    call $framesAt
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 1064
    call $__panic_fail
    unreachable
    i32.const 0
  )
  (func $provideIn (param $cell i32) (param $key i32) (param $value i32) (result i32)
    (local $__mem0 i32)
    local.get $cell
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 584
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $cell
    call $Scope_storeRef
    local.get $cell
    call $Scope_ownerRef
    local.get $cell
    call $Scope_carriedRef
    local.get $cell
    call $Scope_cellId
    local.get $key
    local.get $value
    call $provideAt
    drop
    i32.const 0
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 1064
    call $__panic_fail
    unreachable
    i32.const 0
  )
  (func $find (param $frames i32) (param $key i32) (param $fallback i32) (result i32)
    (local $__mem0 i32)
    (local $cur i32)
    (local $f i32)
    (local $__mem1 i32)
    local.get $frames
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.tee $__mem0
    i32.const 256
    i32.ge_u
    local.get $__mem0
    i32.const 4
    i32.sub
    local.get $__mem0
    i32.const 256
    i32.ge_u
    i32.mul
    i32.load
    i32.const 1036
    i32.eq
    i32.and
    (if (result i32)
      (then
    local.get $cur
    local.set $f
    local.get $f
    i32.load
    local.get $key
    call $__str_eq
    (if (result i32)
      (then
    local.get $f
    call $frameValue
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $f
    call $frameParent
    local.set $cur
    i32.const 0
      )
      (else
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 1036
    i32.store
    local.get $__mem1
    local.get $key
    i32.store offset=4
    local.get $__mem1
    local.get $fallback
    i32.store offset=8
    local.get $__mem1
    i32.const 0
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    call $frameValue
    return
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
  )
  (func $answer (param $value i32) (result i32)
    local.get $value
    return
  )
  (func $nowhere (result i32)
    call $Place_none
    return
  )
  (func $root (result i32)
    call $Scope_root
    return
  )
  (func $frameValue (param $f i32) (result i32)
    local.get $f
    i32.load offset=4 ;; .value
    return
  )
  (func $frameParent (param $f i32) (result i32)
    local.get $f
    i32.load offset=8 ;; .parent
    return
  )
  ;; storeNew — .Wasm(wasi: .CellNew)
  (func $storeNew (result i32)
    call $__memo_cell_new
  )
  ;; storeLive — .Wasm(wasi: .CellFilled)
  (func $storeLive (param $store i32) (result i32)
    local.get $store
    call $__memo_cell_filled
  )
  ;; storeGet — .Wasm(wasi: .CellGet)
  (func $storeGet (param $store i32) (result i32)
    local.get $store
    call $__memo_cell_get
  )
  ;; storeSet — .Wasm(wasi: .CellSet)
  (func $storeSet (param $store i32) (param $value i32)
    local.get $store
    local.get $value
    call $__memo_cell_set
  )
  ;; storeClose — .Wasm(wasi: .CellSet)
  (func $storeClose (param $store i32) (param $closed i32)
    local.get $store
    local.get $closed
    call $__memo_cell_set
  )
  ;; ownerSelf — .Wasm(wasi: .CellNew)
  (func $ownerSelf (result i32)
    call $__memo_cell_new
  )
  ;; ownerForeign — .Wasm(wasi: .CellFilled)
  (func $ownerForeign (param $owner i32) (result i32)
    local.get $owner
    call $__memo_cell_filled
  )
  (func $cleanup (result i32)
    i32.const 0
  )
  (func $effect (param $f i32) (result i32)
    (local $__mem0 i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add ;; a component's lambda: past its mark
    return
  )
  (func $Widget (result i32)
    (local $__mem0 i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add ;; a component's lambda: past its mark
    return
  )
  (func $bpScopeRaw__enter (param $s i32) (param $k i32) (result i32)
    local.get $s
    local.get $k
    call $enter
    return
  )
  (func $bpScopeRaw__answer (param $v i32) (result i32)
    local.get $v
    call $answer
    return
  )
  (func $bpScopeRaw__run0 (param $c i32) (param $s i32) (param $k i32) (result i32)
    (local $__fnv0 i32)
    local.get $c
    local.set $__fnv0
    local.get $__fnv0
    local.get $s
    local.get $k
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32 i32 i32) (result i32)
    return
  )
  (func $__lambda0 (param $__env i32) (param $bpScope__ i32) (param $bpKey__ i32) (result i32)
    local.get $bpScope__
    local.get $bpKey__
    call $bpScopeRaw__enter
    drop
    i32.const 0
    call $bpScopeRaw__answer
    return
  )
  (func $__lambda1 (param $__env i32) (param $bpScope__ i32) (param $bpKey__ i32) (result i32)
    (local $__mem0 i32)
    (local $bpCell__1 i32)
    (local $__runc0 i32)
    (local $__runm0 i32)
    (local $__runw0 i32)
    local.get $bpScope__
    local.get $bpKey__
    call $bpScopeRaw__enter
    local.set $bpCell__1
    i32.const 0 ;; missing argument
    call $effect
    local.tee $__runc0
    i32.const 4
    i32.sub
    i32.load ;; the lambda's mark: a state machine?
    local.set $__runm0
    local.get $__runc0
    local.get $bpCell__1
    call $nowhere
    local.get $__runc0
    i32.load ;; table index
    call_indirect (param i32 i32 i32) (result i32)
    local.set $__runw0
    local.get $__runm0
    (if (result i32)
      (then
    local.get $__runw0
    call $__task_block_on
    i32.load offset=8 ;; the settled value
      )
      (else
    local.get $__runw0
      )
    )
    drop
    i32.const 4
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 1120
    i32.store
    local.get $__mem0
    i32.const 4
    i32.add
    call $bpScopeRaw__answer
    return
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__print_nl
    i32.const 8
    i32.const 10
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  ;; separator between the arguments of a multi-argument `@print`
  (func $__print_sp
    i32.const 8
    i32.const 32
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i32 (param $n i32)
    local.get $n
    call $__print_i32_raw
    call $__print_nl
  )
  (func $__print_i32_raw (param $n i32)
    (local $buf i32) (local $len i32) (local $neg i32) (local $d i32)
    (local $i i32) (local $j i32) (local $tmp i32)
    i32.const 64
    local.set $buf
    local.get $n
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 1
        local.set $neg
        i32.const 0
        local.get $n
        i32.sub
        local.set $n
      )
    )
    (block $done
      (loop $digits
        local.get $n
        i32.const 10
        i32.rem_u
        i32.const 48
        i32.add
        local.set $d
        local.get $buf
        local.get $len
        i32.add
        local.get $d
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
        local.get $n
        i32.const 10
        i32.div_u
        local.set $n
        local.get $n
        i32.const 0
        i32.gt_u
        br_if $digits
      )
    )
    ;; reverse
    i32.const 0
    local.set $i
    local.get $len
    i32.const 1
    i32.sub
    local.set $j
    (block $rdone
      (loop $rev
        local.get $i
        local.get $j
        i32.ge_u
        br_if $rdone
        local.get $buf
        local.get $i
        i32.add
        i32.load8_u
        local.set $tmp
        local.get $buf
        local.get $i
        i32.add
        local.get $buf
        local.get $j
        i32.add
        i32.load8_u
        i32.store8
        local.get $buf
        local.get $j
        i32.add
        local.get $tmp
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $j
        i32.const 1
        i32.sub
        local.set $j
        br $rev
      )
    )
    ;; add neg sign + newline
    ;; shift the digits one byte right to make room for '-'
    ;; (dst = buf+1, NOT buf+len: the latter moved them `len`
    ;;  bytes and printed -12 as -21)
    local.get $neg
    (if
      (then
        local.get $buf
        i32.const 1
        i32.add
        local.get $buf
        local.get $len
        call $__memmove
        local.get $buf
        i32.const 45
        i32.store8
        local.get $len
        i32.const 1
        i32.add
        local.set $len
      )
    )
    local.get $buf
    local.get $len
    call $__write_bytes
  )
  (func $__memmove (param $dst i32) (param $src i32) (param $len i32)
    (local $i i32)
    local.get $len
    i32.const 1
    i32.sub
    local.set $i
    (block $done
      (loop $loop
        local.get $i
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $dst
        local.get $i
        i32.add
        local.get $src
        local.get $i
        i32.add
        i32.load8_u
        i32.store8
        local.get $i
        i32.const 1
        i32.sub
        local.set $i
        br $loop
      )
    )
  )
  (func $__str_eq (param $a i32) (param $b i32) (result i32)
    (local $i i32) (local $alen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $alen
    local.get $b
    i32.load
    i32.ne
    (if
      (then i32.const 0 return)
    )
    (block $done
      (loop $cmp
        local.get $i
        local.get $alen
        i32.ge_u
        br_if $done
        local.get $a
        local.get $i
        i32.add
        i32.load8_u offset=4
        local.get $b
        local.get $i
        i32.add
        i32.load8_u offset=4
        i32.ne
        (if
          (then i32.const 0 return)
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cmp
      )
    )
    i32.const 1
  )
  (func $__alloc (param $n i32) (result i32)
    (local $p i32) (local $e i32)
    global.get $__heap_ptr
    local.set $p
    local.get $p
    local.get $n
    i32.add
    i32.const 3
    i32.add
    i32.const -4
    i32.and
    local.set $e
    local.get $e
    local.get $p
    i32.lt_u
    (if
      (then
        unreachable
      )
    )
    local.get $e
    memory.size
    i32.const 16
    i32.shl
    i32.gt_u
    (if
      (then
        local.get $e
        i32.const 65535
        i32.add
        i32.const 16
        i32.shr_u
        memory.size
        i32.sub
        memory.grow
        i32.const -1
        i32.eq
        (if
          (then
            unreachable
          )
        )
      )
    )
    local.get $e
    global.set $__heap_ptr
    local.get $p
  )
  (func $__write_err (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 2
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
  (func $__assert_fail (param $where i32) (param $msg i32)
    local.get $where
    i32.const 4
    i32.add
    local.get $where
    i32.load
    call $__write_err
    i32.const 188
    i64.const 8390880602276044858
    i64.store
    i32.const 196
    i64.const 7811882119909502825
    i64.store
    i32.const 204
    i32.const 101
    i32.store8
    i32.const 205
    i32.const 100
    i32.store8
    i32.const 188
    i32.const 18
    call $__write_err
    local.get $msg
    (if
      (then
        i32.const 188
        i32.const 8250
        i32.store
        i32.const 188
        i32.const 2
        call $__write_err
        local.get $msg
        i32.const 4
        i32.add
        local.get $msg
        i32.load
        call $__write_err
      )
    )
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__panic_fail (param $msg i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    i32.const 4
    i32.add
    local.get $msg
    i32.load
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.add
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.sub
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site i32) (result i32)
    (local $r i64)
    local.get $a
    i64.extend_i32_s
    local.get $b
    i64.extend_i32_s
    i64.mul
    local.set $r
    local.get $r
    i32.wrap_i64
    i64.extend_i32_s
    local.get $r
    i64.ne
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
    i32.wrap_i64
  )
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site i32) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.add
    local.set $r
    local.get $a
    local.get $r
    i64.xor
    local.get $b
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site i32) (result i64)
    (local $r i64)
    local.get $a
    local.get $b
    i64.sub
    local.set $r
    local.get $a
    local.get $b
    i64.xor
    local.get $a
    local.get $r
    i64.xor
    i64.and
    i64.const 0
    i64.lt_s
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $r
  )
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site i32) (result i64)
    (local $r i64)
    local.get $a
    i64.const -1
    i64.eq
    local.get $b
    i64.const -9223372036854775808
    i64.eq
    i32.and
    (if
      (then
        local.get $site
        call $__chk_fail
        unreachable
      )
    )
    local.get $a
    local.get $b
    i64.mul
    local.set $r
    local.get $a
    i64.eqz
    i32.eqz
    (if
      (then
        local.get $r
        local.get $a
        i64.div_s
        local.get $b
        i64.ne
        (if
          (then
            local.get $site
            call $__chk_fail
            unreachable
          )
        )
      )
    )
    local.get $r
  )
  (global $__task_head (mut i32) (i32.const 0))
  (global $__task_tail (mut i32) (i32.const 0))
  (global $__task_suspended (mut i32) (i32.const 0))
  (func $__task_new (param $kind i32) (param $frame i32) (result i32)
    (local $t i32)
    i32.const 40
    call $__alloc
    local.set $t
    local.get $t
    local.get $kind
    i32.store offset=20
    local.get $t
    local.get $frame
    i32.store offset=16
    local.get $t
  )
  (func $__task_start (param $kind i32) (param $frame i32) (result i32)
    (local $t i32)
    local.get $kind
    local.get $frame
    call $__task_new
    local.tee $t
    call $__task_resume
    local.get $t
  )
  (func $__task_pending (param $t i32) (result i32)
    local.get $t
    i32.load
    i32.eqz
  )
  (func $__task_listen (param $t i32) (param $kind i32) (param $target i32) (param $index i32)
    (local $n i32)
    i32.const 16
    call $__alloc
    local.set $n
    local.get $n
    local.get $t
    i32.load offset=4
    i32.store
    local.get $n
    local.get $kind
    i32.store offset=4
    local.get $n
    local.get $target
    i32.store offset=8
    local.get $n
    local.get $index
    i32.store offset=12
    local.get $t
    local.get $n
    i32.store offset=4
  )
  (func $__task_wait (param $t i32) (param $w i32)
    local.get $t
    i32.const 0
    local.get $w
    i32.const 0
    call $__task_listen
  )
  (func $__task_settle_i32 (param $t i32) (param $v i32)
    local.get $t
    local.get $v
    i32.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_settle_i64 (param $t i32) (param $v i64)
    local.get $t
    local.get $v
    i64.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_settle_f64 (param $t i32) (param $v f64)
    local.get $t
    local.get $v
    f64.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_wake (param $t i32)
    (local $n i32) (local $m i32) (local $r i32) (local $k i32) (local $w i32)
    local.get $t
    i32.load
    (if
      (then
        return
      )
    )
    local.get $t
    i32.const 1
    i32.store
    local.get $t
    i32.load offset=4
    local.set $n
    local.get $t
    i32.const 0
    i32.store offset=4
    (block $brk
      (loop $cont
        local.get $n
        i32.eqz
        br_if $brk
        local.get $n
        i32.load
        local.set $m
        local.get $n
        local.get $r
        i32.store
        local.get $n
        local.set $r
        local.get $m
        local.set $n
        br $cont
      )
    )
    (block $brk
      (loop $cont
        local.get $r
        i32.eqz
        br_if $brk
        local.get $r
        i32.load offset=4
        local.set $k
        local.get $r
        i32.load offset=8
        local.set $w
        local.get $k
        i32.eqz
        (if
          (then
            local.get $w
            call $__task_enqueue
          )
        )
        local.get $k
        i32.const 1
        i32.eq
        (if
          (then
            local.get $w
            i32.load
            i32.eqz
            (if
              (then
                local.get $w
                local.get $t
                i64.load offset=8
                i64.store offset=8
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $k
        i32.const 2
        i32.eq
        (if
          (then
            local.get $w
            i32.load offset=28
            i32.const 4
            i32.add
            local.get $r
            i32.load offset=12
            i32.const 4
            i32.mul
            i32.add
            local.get $t
            i32.load offset=8
            i32.store
            local.get $w
            local.get $w
            i32.load offset=32
            i32.const 1
            i32.sub
            i32.store offset=32
            local.get $w
            i32.load offset=32
            i32.eqz
            (if
              (then
                local.get $w
                local.get $w
                i32.load offset=28
                i32.store offset=8
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $r
        i32.load
        local.set $r
        br $cont
      )
    )
  )
  (func $__task_enqueue (param $t i32)
    local.get $t
    i32.const 0
    i32.store offset=24
    global.get $__task_tail
    (if
      (then
        global.get $__task_tail
        local.get $t
        i32.store offset=24
      )
      (else
        local.get $t
        global.set $__task_head
      )
    )
    local.get $t
    global.set $__task_tail
  )
  (func $__task_drain
    (local $t i32)
    (block $brk
      (loop $cont
        global.get $__task_head
        local.tee $t
        i32.eqz
        br_if $brk
        local.get $t
        i32.load offset=24
        global.set $__task_head
        global.get $__task_head
        i32.eqz
        (if
          (then
            i32.const 0
            global.set $__task_tail
          )
        )
        local.get $t
        call $__task_resume
        br $cont
      )
    )
  )
  (func $__task_block_on (param $t i32) (result i32)
    (local $r i32)
    (block $brk
      (loop $cont
        local.get $t
        i32.load
        br_if $brk
        global.get $__task_head
        local.tee $r
        i32.eqz
        (if
          (then
            unreachable
          )
        )
        local.get $r
        i32.load offset=24
        global.set $__task_head
        global.get $__task_head
        i32.eqz
        (if
          (then
            i32.const 0
            global.set $__task_tail
          )
        )
        local.get $r
        call $__task_resume
        br $cont
      )
    )
    local.get $t
  )
  (func $__task_finish
    (block $brk
      (loop $cont
        call $__task_drain
        call $__task_host_poll
        i32.eqz
        br_if $brk
        br $cont
      )
    )
  )
  (func $__task_resume (param $t i32)
    (local $k i32)
    local.get $t
    i32.load offset=20 ;; kind
    local.set $k
    local.get $k
    i32.const 0
    i32.eq
    (if
      (then
    local.get $t
    call $run__step
    return
      )
    )
    unreachable
  )
  (func $__task_host_poll (result i32)
    i32.const 0
  )
  (func $__chk_fail (param $site i32)
    local.get $site
    call $__panic_fail
    unreachable
  )
  (func $__memo_cell_new (result i32)
    (local $p i32)
    i32.const 8
    call $__alloc
    local.set $p
    local.get $p
    i32.const 0
    i32.store
    local.get $p
    i32.const 0
    i32.store offset=4
    local.get $p
  )
  (func $__memo_cell_filled (param $c i32) (result i32)
    local.get $c
    i32.load
  )
  (func $__memo_cell_get (param $c i32) (result i32)
    local.get $c
    i32.load offset=4
  )
  (func $__memo_cell_set (param $c i32) (param $v i32)
    local.get $c
    local.get $v
    i32.store offset=4
    local.get $c
    i32.const 1
    i32.store
  )
)
```

----- RUN LOG -----
```logs
```
