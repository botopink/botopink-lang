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

// Decision 827 — the components `cs` resolved in order under one `use`:
// `val items = use all(self.entries.map({ e -> e.view }));`. `all`'s cell
// stands at the `use`'s place and entry `i` runs under it at
// `Place.index(i)` (884), so a keyed entry keeps its key, one a component
// body counted its count, and any other entry its position. It answers
// `T[]`, or the task of it when an entry answered a task; the `use` awaits
// it. Lowered where it is `use`d; this body never runs.
pub component fn all<T>(cs: Component<T>[]) -> Component<T[]> {
    panic("`use all` is lowered where it is written; this body never runs");
}

// ── the place (decisions 819, 820, 821, 884, 891) ────────────────────────────

// Where a component stands among its siblings (819 (2)): the number of the
// call that made it, and its item half — absent, a count the call's
// component body or plain function made (821), a list runner's index, or a
// key. A program passes `Place.none()` (the place the value carries), or
// runs one by hand with `Place.key(k)` / `Place.index(i)` (819 (3), 884).
// `stamped` marks a place a making call wrote (820 (1)): a runner's never is.
pub type Place(callNo: i32, item: PlaceItem, itemNo: i32, keyValue: unknown, stamped: bool) {
    // The place the component's value carries (820 (2)): what `use c` and a
    // root pass.
    pub fn none() -> Place {
        return Place(callNo: 0, item: PlaceItem.Absent, itemNo: 0, keyValue: null, stamped: false);
    }

    // `k` in the item's stead, the call's number kept (819 (3)).
    pub fn key<K>(k: K) -> Place {
        return Place(callNo: 0, item: PlaceItem.Key, itemNo: 0, keyValue: k, stamped: false);
    }

    // Position `i` in a list run — `all`'s entries and a render library's
    // children (884, 891).
    pub fn index(i: i32) -> Place {
        return Place(callNo: 0, item: PlaceItem.Index, itemNo: i, keyValue: null, stamped: false);
    }

    // This place as `key` says it is run (820 (2), 884 (1), 891 (1)): a key
    // replaces the item half; an index fills an absent one or a plain
    // function's count and keeps a body's count and a key; `Place.none()`
    // keeps it whole.
    pub fn with(self: Self, key: Place) -> Place {
        if (key.item == PlaceItem.Key)
            return Place(callNo: self.callNo, item: PlaceItem.Key, itemNo: 0, keyValue: key.keyValue, stamped: self.stamped);
        if (key.item == PlaceItem.Index)
            if (self.item == PlaceItem.Absent || self.item == PlaceItem.Plain)
                return Place(callNo: self.callNo, item: PlaceItem.Index, itemNo: key.itemNo, keyValue: null, stamped: self.stamped);
        return self;
    }
}

// A place's item half (891 (1)).
pub type PlaceItem { Absent, Body, Plain, Index, Key }

// Whether two places name one child: the call's number and the item half,
// a key compared by value (818 (3)).
fn samePlace(a: Place, b: Place) -> bool {
    if (a.callNo != b.callNo || a.item != b.item || a.itemNo != b.itemNo)
        return false;
    if (a.item == PlaceItem.Key) return sameKey(placeKey(a), placeKey(b));
    return true;
}

fn placeKey(p: Place) -> unknown {
    return p.keyValue;
}

// ── the scope (decisions 809 (8), 816, 817, 824, 825) ────────────────────────

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

    // The child cell of this one at `key`, entered for a render (816, 817):
    // the cell its place named in this cell's previous render, or in this
    // one, reused with its hooks' state; any other place a fresh cell. It
    // takes this cell's contexts as they stand (817 (5)). Each component body
    // opens its own with it; two siblings with one key fail `key-duplicate`
    // (819 (5)).
    pub fn childAt(self: Self, key: Place) -> Scope {
        return Scope(scopeStore: self.scopeStore, scopeCell: openChild(self.scopeStore, self.scopeOwner, self.scopeCarried, self.scopeCell, key), scopeOwner: self.scopeOwner, scopeCarried: self.scopeCarried);
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

// A root's tree: whether it is closed, the count of its cells, each cell's
// state and each `place → cell` link, the latest entry for an id or a place
// first. Public as `Frame` is: a program never names it.
pub type ScopeTree(treeClosed: bool, treeCount: i32, treeCells: unknown, treeLinks: unknown)

// The contexts a detached root carries across processes (824 (3)).
pub type Carried(frames: unknown)

// One cell of a root's tree: its contexts, the number of its renders, its
// hook's slot (816, 818 (1)) and the count of the values each call of its
// body made in the current render (821 (1)).
pub type CellEntry(cellNo: i32, cellFrames: unknown, cellGen: i32, cellSlot: unknown, cellFilled: bool, cellCounts: unknown, cellNext: unknown)

// A child cell at a place of its parent, and the parent's render that last
// met it (817 (1)).
pub type PlaceLink(linkParent: i32, linkPlace: Place, linkChild: i32, linkSeen: i32, linkNext: unknown)

// The count of the values call `countCall` made in one render or one entry.
pub type PlaceCount(countCall: i32, countValue: i32, countNext: unknown)

// A new root's store, its one cell holding `frames`.
fn storeOf(frames: unknown) -> unknown {
    val store = storeNew();
    storeSet(store, ScopeTree(treeClosed: false, treeCount: 1, treeCells: CellEntry(cellNo: 0, cellFrames: frames, cellGen: 0, cellSlot: null, cellFilled: false, cellCounts: null, cellNext: null), treeLinks: null));
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
            val t = ScopeTree(treeClosed: false, treeCount: 1, treeCells: CellEntry(cellNo: 0, cellFrames: carriedFrames(c), cellGen: 0, cellSlot: null, cellFilled: false, cellCounts: null, cellNext: null), treeLinks: null);
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

fn treeCells(t: ScopeTree) -> unknown {
    return t.treeCells;
}

fn treeLinks(t: ScopeTree) -> unknown {
    return t.treeLinks;
}

// `t` with `e` as cell `e.cellNo`'s state.
fn withCell(t: ScopeTree, e: CellEntry) -> ScopeTree {
    return ScopeTree(treeClosed: false, treeCount: t.treeCount, treeCells: CellEntry(cellNo: e.cellNo, cellFrames: entryFrames(e), cellGen: e.cellGen, cellSlot: entrySlot(e), cellFilled: e.cellFilled, cellCounts: entryCounts(e), cellNext: treeCells(t)), treeLinks: treeLinks(t));
}

// Cell `id`'s state in `cells`.
fn cellOf(cells: unknown, id: i32) -> CellEntry {
    var cur = cells;
    loop {
        if (cur is CellEntry) {
            val e: CellEntry = cur;
            if (e.cellNo == id) return e;
            cur = entryNext(e);
        } else panic("a scope names a cell its tree does not hold (decision 817)");
    }
}

// The child of cell `parent` at `key`, entered for a render: its id.
fn openChild(store: unknown, owner: unknown, carried: unknown, parent: i32, key: Place) -> i32 {
    val t = treeOf(store, owner, carried);
    val p = cellOf(treeCells(t), parent);
    val frames = entryFrames(p);
    val found = linkAt(treeLinks(t), parent, key);
    if (found is PlaceLink) {
        val l: PlaceLink = found;
        // Two siblings with one key in one render (819 (5)); the root's
        // children are each run's own.
        if (parent != 0 && l.linkSeen == p.cellGen && key.item == PlaceItem.Key)
            panic("key-duplicate: two siblings carry the key "
                + keyText(placeKey(key))
                + " (decision 819 (5))");
        // Met in the parent's previous render or in this one: the same cell,
        // its contexts taken anew and its counts reset (816 (2), 817 (5)).
        if (parent == 0 || l.linkSeen >= p.cellGen - 1) {
            val c = cellOf(treeCells(t), l.linkChild);
            val kept = withCell(t, CellEntry(cellNo: c.cellNo, cellFrames: frames, cellGen: c.cellGen
                + 1, cellSlot: entrySlot(c), cellFilled: c.cellFilled, cellCounts: null, cellNext: null));
            storeSet(store, ScopeTree(treeClosed: false, treeCount: kept.treeCount, treeCells: treeCells(kept), treeLinks: PlaceLink(linkParent: parent, linkPlace: key, linkChild: l.linkChild, linkSeen: p.cellGen, linkNext: treeLinks(kept))));
            return l.linkChild;
        }
    }
    // A place not met in the parent's previous render: a fresh cell.
    val id = t.treeCount;
    storeSet(store, ScopeTree(treeClosed: false, treeCount: id
        + 1, treeCells: CellEntry(cellNo: id, cellFrames: frames, cellGen: 1, cellSlot: null, cellFilled: false, cellCounts: null, cellNext: treeCells(t)), treeLinks: PlaceLink(linkParent: parent, linkPlace: key, linkChild: id, linkSeen: p.cellGen, linkNext: treeLinks(t))));
    return id;
}

// The latest link of cell `parent` at `key`, or null.
fn linkAt(links: unknown, parent: i32, key: Place) -> unknown {
    var cur = links;
    loop {
        if (cur is PlaceLink) {
            val l: PlaceLink = cur;
            if (l.linkParent == parent && samePlace(l.linkPlace, key))
                return linkSelf(l);
            cur = linkNext(l);
        } else return null;
    }
}

fn linkSelf(l: PlaceLink) -> unknown {
    return l;
}

fn linkNext(l: PlaceLink) -> unknown {
    return l.linkNext;
}

// A key as a failure names it.
fn keyText(k: unknown) -> string {
    if (k is string) return "\"" + k + "\"";
    if (k is i32) return k.toString();
    return "of another type";
}

// The contexts cell `id` holds now.
fn framesAt(store: unknown, owner: unknown, carried: unknown, id: i32) -> unknown {
    return entryFrames(cellOf(treeCells(treeOf(store, owner, carried)), id));
}

fn carriedFrames(c: Carried) -> unknown {
    return c.frames;
}

// `value` provided for `key` in cell `id`.
fn provideAt(store: unknown, owner: unknown, carried: unknown, id: i32, key: string, value: unknown) -> void {
    val t = treeOf(store, owner, carried);
    val c = cellOf(treeCells(t), id);
    val frames = Frame(key: key, value: value, parent: entryFrames(c));
    storeSet(store, withCell(t, CellEntry(cellNo: id, cellFrames: frames, cellGen: c.cellGen, cellSlot: entrySlot(c), cellFilled: c.cellFilled, cellCounts: entryCounts(c), cellNext: null)));
}

// The count of the values call `callNo` made before this one in cell `id`'s
// current render; the cell counts this one (821 (1)).
fn countAt(store: unknown, owner: unknown, carried: unknown, id: i32, callNo: i32) -> i32 {
    val t = treeOf(store, owner, carried);
    val c = cellOf(treeCells(t), id);
    val n = countIn(entryCounts(c), callNo);
    storeSet(store, withCell(t, CellEntry(cellNo: id, cellFrames: entryFrames(c), cellGen: c.cellGen, cellSlot: entrySlot(c), cellFilled: c.cellFilled, cellCounts: PlaceCount(countCall: callNo, countValue: n
        + 1, countNext: entryCounts(c)), cellNext: null)));
    return n;
}

// The latest count of call `callNo` in `counts`, else 0.
fn countIn(counts: unknown, callNo: i32) -> i32 {
    var cur = counts;
    loop {
        if (cur is PlaceCount) {
            val k: PlaceCount = cur;
            if (k.countCall == callNo) return k.countValue;
            cur = countRest(k);
        } else return 0;
    }
}

fn countRest(k: PlaceCount) -> unknown {
    return k.countNext;
}

// Cell `id`'s slot: what `make` answered on the cell's first render, kept
// while the cell stands (816 (1), 818 (1)).
fn slotAt(store: unknown, owner: unknown, carried: unknown, id: i32, make: fn() -> unknown) -> unknown {
    val c = cellOf(treeCells(treeOf(store, owner, carried)), id);
    if (c.cellFilled) return entrySlot(c);
    val value = make();
    val t = treeOf(store, owner, carried);
    val now = cellOf(treeCells(t), id);
    storeSet(store, withCell(t, CellEntry(cellNo: id, cellFrames: entryFrames(now), cellGen: now.cellGen, cellSlot: value, cellFilled: true, cellCounts: entryCounts(now), cellNext: null)));
    return value;
}

// The root's tree closed; a closed one is left as it is.
fn closeStore(store: unknown) -> void {
    if (!storeLive(store)) return;
    storeClose(store, ScopeTree(treeClosed: true, treeCount: 0, treeCells: null, treeLinks: null));
}

fn entryFrames(e: CellEntry) -> unknown {
    return e.cellFrames;
}

fn entrySlot(e: CellEntry) -> unknown {
    return e.cellSlot;
}

fn entryCounts(e: CellEntry) -> unknown {
    return e.cellCounts;
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

// ── the stamp (decisions 820, 821, 818 (3)) ──────────────────────────────────
//
// Each written call answering a component answers its value carrying its
// place: `stamp(c, <the body's cell>, n)` in a component body, the item the
// count of the values call `n` made in the body's current render;
// `stampPlain(c, <the entry's counter>, n)` in a plain function, counted in
// that entry (`countNew` at its entry, `countEnd` deferred); `stampKeyed(c,
// n, k)` for `#[key(k)]`. The place travels in the value: run with a
// runner's place it is `mine.with(key)`; a place another stamp already wrote
// passes through, so the stamp written last — the outer call's — wins
// (821 (2)).

pub fn stamp(c: Component<unknown>, cell: unknown, callNo: i32) -> Composition<unknown> {
    if (cell is Scope)
        return placed(c, Place(callNo: callNo, item: PlaceItem.Body, itemNo: countAt(cell.storeRef(), cell.ownerRef(), cell.carriedRef(), cell.cellId(), callNo), keyValue: null, stamped: true));
    panic("a component is run with a `Scope` (decision 819)");
}

pub fn stampPlain(c: Component<unknown>, counter: unknown, callNo: i32) -> Composition<unknown> {
    return placed(c, Place(callNo: callNo, item: PlaceItem.Plain, itemNo: countNext(counter, callNo), keyValue: null, stamped: true));
}

pub fn stampKeyed(c: Component<unknown>, callNo: i32, k: unknown) -> Composition<unknown> {
    return placed(c, Place(callNo: callNo, item: PlaceItem.Key, itemNo: 0, keyValue: k, stamped: true));
}

// `c` carrying `mine`.
fn placed(c: Component<unknown>, mine: Place) -> Composition<unknown> {
    return { scope, key -> resolve(c, scope, if (key.stamped) key else mine.with(key)) };
}

// `use memo(make)` written as call `callNo` of a body: the slot of its own
// child cell (818 (1)), filled on that cell's first render.
pub fn memoIn(cell: unknown, callNo: i32, make: fn() -> unknown) -> unknown {
    if (cell is Scope) {
        val child = cell.childAt(Place(callNo: callNo, item: PlaceItem.Body, itemNo: countAt(cell.storeRef(), cell.ownerRef(), cell.carriedRef(), cell.cellId(), callNo), keyValue: null, stamped: true));
        return slotAt(child.storeRef(), child.ownerRef(), child.carriedRef(), child.cellId(), make);
    }
    panic("a component is run with a `Scope` (decision 819)");
}

// `use all(cs)` written as call `callNo` of a body (827, 884): entry `i` run
// under `all`'s own child cell at `Place.index(i)`, in order; the answers as
// a list, or the task of the list once each settled in order when an entry
// answered a task.
pub fn allIn(cell: unknown, callNo: i32, cs: Component<unknown>[]) -> unknown {
    if (cell is Scope) {
        val child = cell.childAt(Place(callNo: callNo, item: PlaceItem.Body, itemNo: countAt(cell.storeRef(), cell.ownerRef(), cell.carriedRef(), cell.cellId(), callNo), keyValue: null, stamped: true));
        var answers: unknown[] = [];
        var waits = false;
        for (0..cs.length) { i ->
            val r = resolve(cs[i]!, child, Place.index(i));
            if (r is Async<unknown>) waits = true;
            answers = answers.append([r]);
        }
        if (waits) return settled(answers);
        return answers;
    }
    panic("a component is run with a `Scope` (decision 819)");
}

// Each of `answers` awaited in order where it is a task.
async fn settled(answers: unknown[]) -> Async<unknown[]> {
    var out: unknown[] = [];
    for (answers) { r ->
        if (r is Async<unknown>) {
            val v = await r;
            out = out.append([v]);
        } else out = out.append([r]);
    }
    return out;
}

// A plain function entry's counter of the values each of its calls made
// (821 (2)).
pub fn countNew() -> unknown {
    return countCellNew();
}

// The entry's counter gone: on erlang and beam its process-dictionary entry.
pub fn countEnd(counter: unknown) -> void {
    countCellEnd(counter, null);
}

// The count of the values call `callNo` made before this one in the entry.
fn countNext(counter: unknown, callNo: i32) -> i32 {
    val counts = if (countCellFilled(counter)) countCellGet(counter) else null;
    val n = countIn(counts, callNo);
    countCellSet(counter, PlaceCount(countCall: callNo, countValue: n
        + 1, countNext: counts));
    return n;
}

fn frameValue(f: Frame) -> unknown {
    return f.value;
}

fn frameParent(f: Frame) -> unknown {
    return f.parent;
}

// ── the store's host side (decision 824) ─────────────────────────────────────

// Two keys compared by value (818 (3)).
fn sameKey(a: unknown, b: unknown) -> bool {
    return a == b;
}

#[compiler.external(
    .JavaScript("""({ v: undefined })"""),
    .Erlang("""erlang:make_ref()"""),
    .Wasm(wasi: .CellNew),
)]
declare fn countCellNew() -> unknown;

#[compiler.external(
    .JavaScript("""($0.v !== undefined)"""),
    .Erlang("""(erlang:get({bp_count, $0}) =/= undefined)"""),
    .Wasm(wasi: .CellFilled),
)]
declare fn countCellFilled(counter: unknown) -> bool;

#[compiler.external(
    .JavaScript("""$0.v"""),
    .Erlang("""erlang:get({bp_count, $0})"""),
    .Wasm(wasi: .CellGet),
)]
declare fn countCellGet(counter: unknown) -> unknown;

#[compiler.external(
    .JavaScript("""((__s, __v) => { __s.v = __v; return undefined; })($0, $1)"""),
    .Erlang("""(fun(__S, __V) -> erlang:put({bp_count, __S}, __V), undefined end)($0, $1)"""),
    .Wasm(wasi: .CellSet),
)]
declare fn countCellSet(counter: unknown, value: unknown) -> void;

#[compiler.external(
    .JavaScript("""((__s, __v) => { __s.v = __v; return undefined; })($0, $1)"""),
    .Erlang("""(fun(__S, _) -> erlang:erase({bp_count, __S}), undefined end)($0, $1)"""),
    .Wasm(wasi: .CellSet),
)]
declare fn countCellEnd(counter: unknown, gone: unknown) -> void;

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
{exports, [{createContext, 1}, {provide, 1}, {context, 1}, {inject, 1}, {all, 1}, {resolve, 3}, {run, 2}, {enter, 2}, {received, 1}, {provideIn, 3}, {find, 3}, {answer, 1}, {nowhere, 0}, {root, 0}, {stamp, 3}, {stampPlain, 3}, {stampKeyed, 3}, {memoIn, 3}, {allIn, 3}, {countNew, 0}, {countEnd, 1}, {storeOf, 1}, {openChild, 5}, {closeStore, 1}, {framesAt, 4}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__carriedFrames', 1}, {'__bp_priv__cellOf', 2}, {'__bp_priv__countAt', 5}, {'__bp_priv__countIn', 2}, {'__bp_priv__countNext', 2}, {'__bp_priv__countRest', 1}, {'__bp_priv__entryCounts', 1}, {'__bp_priv__entryFrames', 1}, {'__bp_priv__entryNext', 1}, {'__bp_priv__entrySlot', 1}, {'__bp_priv__frameParent', 1}, {'__bp_priv__frameValue', 1}, {'__bp_priv__keyText', 1}, {'__bp_priv__linkAt', 3}, {'__bp_priv__linkNext', 1}, {'__bp_priv__linkSelf', 1}, {'__bp_priv__placeKey', 1}, {'__bp_priv__placed', 2}, {'__bp_priv__provideAt', 6}, {'__bp_priv__sameKey', 2}, {'__bp_priv__samePlace', 2}, {'__bp_priv__settled', 1}, {'__bp_priv__slotAt', 5}, {'__bp_priv__treeCells', 1}, {'__bp_priv__treeLinks', 1}, {'__bp_priv__treeOf', 3}, {'__bp_priv__withCell', 2}]}.
{attributes, []}.
{labels, 510}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context.erl", 1}]}.
    {func_info, {atom, std@context}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 110}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 111}}.
  {label, 110}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 112}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 113}}.
  {label, 112}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 115}}.
  {label, 113}.
  {label, 111}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "std@context.erl", 2}]}.
    {func_info, {atom, std@context}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 116}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 117}}.
  {label, 116}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 115}}.
    {jump, {f, 119}}.
  {label, 118}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 115}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 115}}.
  {label, 119}.
  {label, 117}.
    {deallocate, 6}.
    return.
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

{function, createContext, 1, 7}.
  {label, 6}.
    {line, [{location, "std@context.erl", 3}]}.
    {func_info, {atom, std@context}, {atom, createContext}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Context}, {y, 0}]}}.
    {deallocate, 1}.
    return.
% Gives `ctx` to every component this component renders below it — never
% to itself or a sibling; the nearest provider of a type wins.

{function, provide, 1, 9}.
  {label, 8}.
    {line, [{location, "std@context.erl", 4}]}.
    {func_info, {atom, std@context}, {atom, provide}, 1}.
  {label, 9}.
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

{function, context, 1, 11}.
  {label, 10}.
    {line, [{location, "std@context.erl", 5}]}.
    {func_info, {atom, std@context}, {atom, context}, 1}.
  {label, 11}.
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

{function, inject, 1, 13}.
  {label, 12}.
    {line, [{location, "std@context.erl", 6}]}.
    {func_info, {atom, std@context}, {atom, inject}, 1}.
  {label, 13}.
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
% Decision 827 — the components `cs` resolved in order under one `use`:
% `val items = use all(self.entries.map({ e -> e.view }));`. `all`'s cell
% stands at the `use`'s place and entry `i` runs under it at
% `Place.index(i)` (884), so a keyed entry keeps its key, one a component
% body counted its count, and any other entry its position. It answers
% `T[]`, or the task of it when an entry answered a task; the `use` awaits
% it. Lowered where it is `use`d; this body never runs.

{function, all, 1, 15}.
  {label, 14}.
    {line, [{location, "std@context.erl", 7}]}.
    {func_info, {atom, std@context}, {atom, all}, 1}.
  {label, 15}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"`use all` is lowered where it is written; this body never runs">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
% ── the place (decisions 819, 820, 821, 884, 891) ────────────────────────────
% Where a component stands among its siblings (819 (2)): the number of the
% call that made it, and its item half — absent, a count the call's
% component body or plain function made (821), a list runner's index, or a
% key. A program passes `Place.none()` (the place the value carries), or
% runs one by hand with `Place.key(k)` / `Place.index(i)` (819 (3), 884).
% `stamped` marks a place a making call wrote (820 (1)): a runner's never is.
% A place's item half (891 (1)).
% Whether two places name one child: the call's number and the item half,
% a key compared by value (818 (3)).

{function, samePlace, 2, 17}.
  {label, 16}.
    {line, [{location, "std@context.erl", 12}]}.
    {func_info, {atom, std@context}, {atom, samePlace}, 2}.
  {label, 17}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 121}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 121}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 122}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 122}.
    {test, is_ne_exact, {f, 123}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 124}}.
  {label, 123}.
    {move, {atom, false}, {x, 0}}.
  {label, 124}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 125}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 127}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 127}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 128}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 128}.
    {test, is_ne_exact, {f, 129}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 130}}.
  {label, 129}.
    {move, {atom, false}, {x, 0}}.
  {label, 130}.
    {jump, {f, 126}}.
  {label, 125}.
    {move, {atom, true}, {x, 0}}.
  {label, 126}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 131}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 133}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 133}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 134}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 134}.
    {test, is_ne_exact, {f, 135}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 136}}.
  {label, 135}.
    {move, {atom, false}, {x, 0}}.
  {label, 136}.
    {jump, {f, 132}}.
  {label, 131}.
    {move, {atom, true}, {x, 0}}.
  {label, 132}.
    {test, is_eq, {f, 120}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 120}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 138}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 138}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__key}, {x, 0}}.
    {test, is_eq_exact, {f, 137}, [{x, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_last, 2, {f, 109}, 4}.
  {label, 137}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, placeKey, 1, 19}.
  {label, 18}.
    {line, [{location, "std@context.erl", 13}]}.
    {func_info, {atom, std@context}, {atom, placeKey}, 1}.
  {label, 19}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 139}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 139}.
    {deallocate, 1}.
    return.
% ── the scope (decisions 809 (8), 816, 817, 824, 825) ────────────────────────
% A cell of a render's tree: the contexts provided above it, a persistent map
% keyed by each context's identity. Opaque — made only by `Scope.root()`, a
% cell's `childAt` and `detach`. A root's whole tree is one entry: on erlang
% and beam an entry `{bp_scope, Ref}` of the process dictionary of the
% process that made the root, ended by that process or by `close()`; on
% commonJS a plain object, on wasm a heap cell (824). A scope used after its
% root's `close()` fails `scope-closed` on every target (825 (2)); one read in
% another process than the root's fails `scope-foreign` (824 (3)).
% A root's tree: whether it is closed, the count of its cells, each cell's
% state and each `place → cell` link, the latest entry for an id or a place
% first. Public as `Frame` is: a program never names it.
% The contexts a detached root carries across processes (824 (3)).
% One cell of a root's tree: its contexts, the number of its renders, its
% hook's slot (816, 818 (1)) and the count of the values each call of its
% body made in the current render (821 (1)).
% A child cell at a place of its parent, and the parent's render that last
% met it (817 (1)).
% The count of the values call `countCall` made in one render or one entry.
% A new root's store, its one cell holding `frames`.

{function, storeOf, 1, 21}.
  {label, 20}.
    {line, [{location, "std@context.erl", 22}]}.
    {func_info, {atom, std@context}, {atom, storeOf}, 1}.
  {label, 21}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, erlang, make_ref, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 9, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {integer, 0}, {y, 0}, {integer, 0}, {atom, undefined}, {x, 0}, {atom, undefined}, {atom, undefined}]}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {y, 2}, {integer, 1}, {x, 0}, {atom, undefined}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 141}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 8}.
    return.
% The root's tree, live and in its own process; a detached root's starts in
% each process that reads it from the contexts it carries.

{function, treeOf, 3, 23}.
  {label, 22}.
    {line, [{location, "std@context.erl", 23}]}.
    {func_info, {atom, std@context}, {atom, treeOf}, 3}.
  {label, 23}.
    {allocate, 18, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 148}}.
    {test, is_eq, {f, 146}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"scope-foreign: a scope is read in another process than its root's \x{E2}\x{80}\x{94} pass `scope.detach()` to another process (decision 824 (3))">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {jump, {f, 154}}.
  {label, 146}.
  {label, 154}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 157}}.
    {test, is_eq, {f, 158}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 159}}.
  {label, 158}.
    {move, {atom, true}, {x, 0}}.
  {label, 159}.
    {test, is_eq, {f, 155}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 161}, [{x, 0}, 2, {atom, std@context@@Carried}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 162}}.
  {label, 161}.
    {move, {atom, false}, {x, 0}}.
  {label, 162}.
    {test, is_eq, {f, 160}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 9, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {integer, 0}, {x, 1}, {integer, 0}, {atom, undefined}, {x, 0}, {atom, undefined}, {atom, undefined}]}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {y, 4}, {integer, 1}, {x, 0}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 141}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 18}.
    return.
  {label, 160}.
    {jump, {f, 163}}.
  {label, 155}.
  {label, 163}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 157}}.
    {test, is_eq, {f, 164}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 166}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 168}, [{x, 0}, 5, {atom, std@context@@ScopeTree}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 169}}.
  {label, 168}.
    {move, {atom, false}, {x, 0}}.
  {label, 169}.
    {test, is_eq, {f, 167}, [{x, 0}, {atom, true}]}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 171}, [{x, 0}, 5, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 171}.
    {test, is_eq, {f, 172}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 173}}.
  {label, 172}.
    {move, {atom, true}, {x, 0}}.
  {label, 173}.
    {test, is_eq, {f, 170}, [{x, 0}, {atom, true}]}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 18}.
    return.
  {label, 170}.
    {jump, {f, 174}}.
  {label, 167}.
  {label, 174}.
    {jump, {f, 175}}.
  {label, 164}.
  {label, 175}.
    {move, {literal, <<"scope-closed: a scope is used after its root's `close()` (decision 825 (2))">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 18}.
    return.

{function, treeCells, 1, 25}.
  {label, 24}.
    {line, [{location, "std@context.erl", 24}]}.
    {func_info, {atom, std@context}, {atom, treeCells}, 1}.
  {label, 25}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 176}, [{x, 0}, 5, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 176}.
    {deallocate, 1}.
    return.

{function, treeLinks, 1, 27}.
  {label, 26}.
    {line, [{location, "std@context.erl", 25}]}.
    {func_info, {atom, std@context}, {atom, treeLinks}, 1}.
  {label, 27}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 177}, [{x, 0}, 5, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 177}.
    {deallocate, 1}.
    return.
% `t` with `e` as cell `e.cellNo`'s state.

{function, withCell, 2, 29}.
  {label, 28}.
    {line, [{location, "std@context.erl", 26}]}.
    {func_info, {atom, std@context}, {atom, withCell}, 2}.
  {label, 29}.
    {allocate, 13, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 178}, [{x, 0}, 5, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 178}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 179}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 179}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 59}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 180}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 180}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 61}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 181}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 181}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 25}}.
    {test_heap, 9, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {x, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 27}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {y, 2}, {y, 3}, {y, 10}, {x, 0}]}}.
    {deallocate, 13}.
    return.
% Cell `id`'s state in `cells`.

{function, cellOf, 2, 31}.
  {label, 30}.
    {line, [{location, "std@context.erl", 27}]}.
    {func_info, {atom, std@context}, {atom, cellOf}, 2}.
  {label, 31}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@context.erl", 28}]}.
  {label, 182}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 183}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 185}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 186}}.
  {label, 185}.
    {move, {atom, false}, {x, 0}}.
  {label, 186}.
    {test, is_eq, {f, 184}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 188}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 188}.
    {test, is_eq_exact, {f, 187}, [{x, 0}, {y, 1}]}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 187}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 65}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 189}}.
  {label, 184}.
    {move, {literal, <<"a scope names a cell its tree does not hold (decision 817)">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 189}.
    {jump, {f, 182}}.
  {label, 183}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.
% The child of cell `parent` at `key`, entered for a render: its id.

{function, openChild, 5, 33}.
  {label, 32}.
    {line, [{location, "std@context.erl", 28}]}.
    {func_info, {atom, std@context}, {atom, openChild}, 5}.
  {label, 33}.
    {allocate, 52, 5}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}, {y, 41}, {y, 42}, {y, 43}, {y, 44}, {y, 45}, {y, 46}, {y, 47}, {y, 48}, {y, 49}, {y, 50}, {y, 51}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 23}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 59}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 27}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call, 3, {f, 35}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 191}, [{x, 0}, 6, {atom, std@context@@PlaceLink}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 192}}.
  {label, 191}.
    {move, {atom, false}, {x, 0}}.
  {label, 192}.
    {test, is_eq, {f, 190}, [{x, 0}, {atom, true}]}.
    {move, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {test, is_ne_exact, {f, 194}, [{y, 3}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 195}}.
  {label, 194}.
    {move, {atom, false}, {x, 0}}.
  {label, 195}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 196}, [{x, 1}, {atom, true}]}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 198}, [{x, 0}, 6, {atom, std@context@@PlaceLink}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 198}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 199}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 199}.
    {test, is_eq_exact, {f, 200}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 201}}.
  {label, 200}.
    {move, {atom, false}, {x, 0}}.
  {label, 201}.
    {jump, {f, 197}}.
  {label, 196}.
    {move, {atom, false}, {x, 0}}.
  {label, 197}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 202}, [{x, 1}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 204}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 204}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__key}, {x, 0}}.
    {test, is_eq_exact, {f, 205}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 206}}.
  {label, 205}.
    {move, {atom, false}, {x, 0}}.
  {label, 206}.
    {jump, {f, 203}}.
  {label, 202}.
    {move, {atom, false}, {x, 0}}.
  {label, 203}.
    {test, is_eq, {f, 193}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<" (decision 819 (5))">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 19}}.
    {call, 1, {f, 41}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"key-duplicate: two siblings carry the key ">>}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 236}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {jump, {f, 239}}.
  {label, 193}.
  {label, 239}.
    {test, is_eq_exact, {f, 241}, [{y, 3}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 242}}.
  {label, 241}.
    {move, {atom, false}, {x, 0}}.
  {label, 242}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 243}, [{x, 1}, {atom, true}]}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 245}, [{x, 0}, 6, {atom, std@context@@PlaceLink}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 245}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 246}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 246}.
    {gc_bif, '-', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 247}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 247}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 248}}.
  {label, 247}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/context.bp:306:52">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 248}.
    {test, is_ge, {f, 249}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 250}}.
  {label, 249}.
    {move, {atom, false}, {x, 0}}.
  {label, 250}.
    {jump, {f, 244}}.
  {label, 243}.
    {move, {atom, true}, {x, 0}}.
  {label, 244}.
    {test, is_eq, {f, 240}, [{x, 0}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 251}, [{x, 0}, 6, {atom, std@context@@PlaceLink}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 251}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_tagged_tuple, {f, 252}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 252}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_tagged_tuple, {f, 253}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 253}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 254}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 254}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 255}}.
  {label, 254}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/context.bp:309:17">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 255}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 11}, {x, 0}}.
    {call, 1, {f, 61}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_tagged_tuple, {f, 256}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 256}.
    {test_heap, 9, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {y, 12}, {y, 7}, {y, 13}, {y, 14}, {x, 0}, {atom, undefined}, {atom, undefined}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call, 2, {f, 29}}.
    {move, {x, 0}, {y, 15}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 15}, {x, 0}}.
    {test, is_tagged_tuple, {f, 257}, [{x, 0}, 5, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 257}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 15}, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 258}, [{x, 0}, 6, {atom, std@context@@PlaceLink}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 258}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 259}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 259}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 15}, {x, 0}}.
    {call, 1, {f, 27}}.
    {test_heap, 7, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@PlaceLink}, {y, 3}, {y, 4}, {y, 19}, {y, 20}, {x, 0}]}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {y, 16}, {y, 17}, {y, 18}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 141}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_tagged_tuple, {f, 260}, [{x, 0}, 6, {atom, std@context@@PlaceLink}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 260}.
    {deallocate, 52}.
    return.
  {label, 240}.
    {jump, {f, 261}}.
  {label, 190}.
  {label, 261}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 262}, [{x, 0}, 5, {atom, std@context@@ScopeTree}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 262}.
    {move, {x, 0}, {y, 21}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 21}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 263}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 263}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 264}}.
  {label, 263}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/context.bp:317:9">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 264}.
    {move, {x, 0}, {y, 23}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 25}}.
    {test_heap, 9, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {y, 21}, {y, 7}, {integer, 1}, {atom, undefined}, {y, 24}, {atom, undefined}, {x, 0}]}}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 265}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 265}.
    {move, {x, 0}, {y, 26}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 27}}.
    {test_heap, 7, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@PlaceLink}, {y, 3}, {y, 4}, {y, 21}, {y, 26}, {x, 0}]}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {y, 22}, {y, 23}, {y, 25}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 141}}.
    {move, {y, 21}, {x, 0}}.
    {deallocate, 52}.
    return.
% The latest link of cell `parent` at `key`, or null.

{function, linkAt, 3, 35}.
  {label, 34}.
    {line, [{location, "std@context.erl", 29}]}.
    {func_info, {atom, std@context}, {atom, linkAt}, 3}.
  {label, 35}.
    {allocate, 7, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@context.erl", 30}]}.
  {label, 266}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 267}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 269}, [{x, 0}, 6, {atom, std@context@@PlaceLink}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 270}}.
  {label, 269}.
    {move, {atom, false}, {x, 0}}.
  {label, 270}.
    {test, is_eq, {f, 268}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 272}, [{x, 0}, 6, {atom, std@context@@PlaceLink}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 272}.
    {test, is_eq_exact, {f, 273}, [{x, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 274}}.
  {label, 273}.
    {move, {atom, false}, {x, 0}}.
  {label, 274}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 275}, [{x, 1}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 277}, [{x, 0}, 6, {atom, std@context@@PlaceLink}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 277}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 17}}.
    {jump, {f, 276}}.
  {label, 275}.
    {move, {atom, false}, {x, 0}}.
  {label, 276}.
    {test, is_eq, {f, 271}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 1, {f, 37}, 7}.
  {label, 271}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 278}}.
  {label, 268}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 278}.
    {jump, {f, 266}}.
  {label, 267}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, linkSelf, 1, 37}.
  {label, 36}.
    {line, [{location, "std@context.erl", 30}]}.
    {func_info, {atom, std@context}, {atom, linkSelf}, 1}.
  {label, 37}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, linkNext, 1, 39}.
  {label, 38}.
    {line, [{location, "std@context.erl", 31}]}.
    {func_info, {atom, std@context}, {atom, linkNext}, 1}.
  {label, 39}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 279}, [{x, 0}, 6, {atom, std@context@@PlaceLink}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 279}.
    {deallocate, 1}.
    return.
% A key as a failure names it.

{function, keyText, 1, 41}.
  {label, 40}.
    {line, [{location, "std@context.erl", 32}]}.
    {func_info, {atom, std@context}, {atom, keyText}, 1}.
  {label, 41}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 281}, [{x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 282}}.
  {label, 281}.
    {move, {atom, false}, {x, 0}}.
  {label, 282}.
    {test, is_eq, {f, 280}, [{x, 0}, {atom, true}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"\"">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 236}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.
  {label, 280}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 287}, [{x, 0}]}.
    {jump, {f, 286}}.
  {label, 287}.
    {test, is_float, {f, 284}, [{x, 0}]}.
    {gc_bif, trunc, {f, 0}, 1, [{x, 0}], {x, 1}}.
    {test, is_eq, {f, 284}, [{x, 0}, {x, 1}]}.
  {label, 286}.
    {test, is_ge, {f, 284}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 284}, [{integer, 2147483647}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 285}}.
  {label, 284}.
    {move, {atom, false}, {x, 0}}.
  {label, 285}.
    {test, is_eq, {f, 283}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, trunc, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 3}.
  {label, 283}.
    {move, {literal, <<"of another type">>}, {x, 0}}.
    {deallocate, 3}.
    return.
% The contexts cell `id` holds now.

{function, framesAt, 4, 43}.
  {label, 42}.
    {line, [{location, "std@context.erl", 33}]}.
    {func_info, {atom, std@context}, {atom, framesAt}, 4}.
  {label, 43}.
    {allocate, 4, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 23}}.
    {call, 1, {f, 25}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 31}}.
    {call_last, 1, {f, 59}, 4}.

{function, carriedFrames, 1, 45}.
  {label, 44}.
    {line, [{location, "std@context.erl", 34}]}.
    {func_info, {atom, std@context}, {atom, carriedFrames}, 1}.
  {label, 45}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 288}, [{x, 0}, 2, {atom, std@context@@Carried}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 288}.
    {deallocate, 1}.
    return.
% `value` provided for `key` in cell `id`.

{function, provideAt, 6, 47}.
  {label, 46}.
    {line, [{location, "std@context.erl", 35}]}.
    {func_info, {atom, std@context}, {atom, provideAt}, 6}.
  {label, 47}.
    {allocate, 23, 6}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, {x, 5}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 23}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 59}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Frame}, {y, 4}, {y, 5}, {x, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 289}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 289}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 61}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 290}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 290}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 63}}.
    {test_heap, 9, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {y, 3}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {x, 0}, {atom, undefined}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 6}, {x, 0}}.
    {call, 2, {f, 29}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 141}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 23}.
    return.
% The count of the values call `callNo` made before this one in cell `id`'s
% current render; the cell counts this one (821 (1)).

{function, countAt, 5, 49}.
  {label, 48}.
    {line, [{location, "std@context.erl", 36}]}.
    {func_info, {atom, std@context}, {atom, countAt}, 5}.
  {label, 49}.
    {allocate, 22, 5}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 23}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 63}}.
    {move, {y, 4}, {x, 1}}.
    {call, 2, {f, 51}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 59}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 291}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 291}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 61}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 292}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 292}.
    {move, {x, 0}, {y, 11}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 7}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 293}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 293}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 294}}.
  {label, 293}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/context.bp:373:9">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 294}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 63}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@PlaceCount}, {y, 4}, {y, 12}, {x, 0}]}}.
    {test_heap, 9, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {y, 3}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {x, 0}, {atom, undefined}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call, 2, {f, 29}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 141}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 22}.
    return.
% The latest count of call `callNo` in `counts`, else 0.

{function, countIn, 2, 51}.
  {label, 50}.
    {line, [{location, "std@context.erl", 37}]}.
    {func_info, {atom, std@context}, {atom, countIn}, 2}.
  {label, 51}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "std@context.erl", 38}]}.
  {label, 295}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 296}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 298}, [{x, 0}, 4, {atom, std@context@@PlaceCount}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 299}}.
  {label, 298}.
    {move, {atom, false}, {x, 0}}.
  {label, 299}.
    {test, is_eq, {f, 297}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 301}, [{x, 0}, 4, {atom, std@context@@PlaceCount}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 301}.
    {test, is_eq_exact, {f, 300}, [{x, 0}, {y, 1}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 302}, [{x, 0}, 4, {atom, std@context@@PlaceCount}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 302}.
    {deallocate, 4}.
    return.
  {label, 300}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 53}}.
    {move, {x, 0}, {y, 2}}.
    {jump, {f, 303}}.
  {label, 297}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 303}.
    {jump, {f, 295}}.
  {label, 296}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, countRest, 1, 53}.
  {label, 52}.
    {line, [{location, "std@context.erl", 38}]}.
    {func_info, {atom, std@context}, {atom, countRest}, 1}.
  {label, 53}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 304}, [{x, 0}, 4, {atom, std@context@@PlaceCount}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 304}.
    {deallocate, 1}.
    return.
% Cell `id`'s slot: what `make` answered on the cell's first render, kept
% while the cell stands (816 (1), 818 (1)).

{function, slotAt, 5, 55}.
  {label, 54}.
    {line, [{location, "std@context.erl", 39}]}.
    {func_info, {atom, std@context}, {atom, slotAt}, 5}.
  {label, 55}.
    {allocate, 20, 5}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {x, 4}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 23}}.
    {call, 1, {f, 25}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 306}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 306}.
    {test, is_eq, {f, 305}, [{x, 0}, {atom, true}]}.
    {move, {y, 5}, {x, 0}}.
    {call_last, 1, {f, 61}, 20}.
  {label, 305}.
    {move, {y, 4}, {x, 0}}.
    {call_fun, 0}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call, 3, {f, 23}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {y, 3}, {x, 1}}.
    {call, 2, {f, 31}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 59}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 307}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 307}.
    {move, {x, 0}, {y, 10}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 63}}.
    {test_heap, 9, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@CellEntry}, {y, 3}, {y, 9}, {y, 10}, {y, 6}, {y, 11}, {x, 0}, {atom, undefined}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 7}, {x, 0}}.
    {call, 2, {f, 29}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 141}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 20}.
    return.
% The root's tree closed; a closed one is left as it is.

{function, closeStore, 1, 57}.
  {label, 56}.
    {line, [{location, "std@context.erl", 40}]}.
    {func_info, {atom, std@context}, {atom, closeStore}, 1}.
  {label, 57}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 157}}.
    {test, is_eq, {f, 309}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 310}}.
  {label, 309}.
    {move, {atom, true}, {x, 0}}.
  {label, 310}.
    {test, is_eq, {f, 308}, [{x, 0}, {atom, true}]}.
    {deallocate, 3}.
    return.
  {label, 308}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 6, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@ScopeTree}, {x, 0}, {integer, 0}, {atom, undefined}, {atom, undefined}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 312}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, entryFrames, 1, 59}.
  {label, 58}.
    {line, [{location, "std@context.erl", 41}]}.
    {func_info, {atom, std@context}, {atom, entryFrames}, 1}.
  {label, 59}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 317}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 317}.
    {deallocate, 1}.
    return.

{function, entrySlot, 1, 61}.
  {label, 60}.
    {line, [{location, "std@context.erl", 42}]}.
    {func_info, {atom, std@context}, {atom, entrySlot}, 1}.
  {label, 61}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 318}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 318}.
    {deallocate, 1}.
    return.

{function, entryCounts, 1, 63}.
  {label, 62}.
    {line, [{location, "std@context.erl", 43}]}.
    {func_info, {atom, std@context}, {atom, entryCounts}, 1}.
  {label, 63}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 319}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 319}.
    {deallocate, 1}.
    return.

{function, entryNext, 1, 65}.
  {label, 64}.
    {line, [{location, "std@context.erl", 44}]}.
    {func_info, {atom, std@context}, {atom, entryNext}, 1}.
  {label, 65}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 320}, [{x, 0}, 8, {atom, std@context@@CellEntry}]}.
    {get_tuple_element, {x, 0}, 7, {x, 0}}.
  {label, 320}.
    {deallocate, 1}.
    return.
% ── resolving and running (decisions 809 (6), 815 (5), 819, 822, 825) ───────
% Runs `c` over `scope` at `key` and hands back its answer as it came — a
% value, or the task of a component that awaits —, nothing awaited inside.

{function, resolve, 3, 67}.
  {label, 66}.
    {line, [{location, "std@context.erl", 45}]}.
    {func_info, {atom, std@context}, {atom, resolve}, 3}.
  {label, 67}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, 'Composable'}, {x, 1}}.
    {call, 2, {f, 323}}.
    {test, is_eq, {f, 321}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, compose}, {x, 0}}.
    {call, 3, {f, 358}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 4}.
    return.
  {label, 321}.
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
{function, run, 2, 69}.
  {label, 68}.
    {line, [{location, "std@context.erl", 46}]}.
    {func_info, {atom, std@context}, {atom, run}, 2}.
  {label, 69}.
    {allocate, 15, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ne_exact, {f, 365}, [{y, 1}, {atom, undefined}]}.
    {call_ext, 0, {extfunc, std@context@@Place, none, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 367}}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 368}}.
  {label, 367}.
    {move, {atom, false}, {x, 0}}.
  {label, 368}.
    {test, is_eq, {f, 366}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 366}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 365}.
    {call_ext, 0, {extfunc, std@context@@Scope, root, 0}}.
    {move, {x, 0}, {y, 3}}.
    {'try', {y, 14}, {f, 369}}.
    {call_ext, 0, {extfunc, std@context@@Place, none, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 371}}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 372}}.
  {label, 371}.
    {move, {atom, false}, {x, 0}}.
  {label, 372}.
    {test, is_eq, {f, 370}, [{x, 0}, {atom, true}]}.
    {move, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {try_end, {y, 14}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, close, 1}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 370}.
    {move, {y, 7}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {try_end, {y, 14}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, close, 1}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 15}.
    return.
  {label, 369}.
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

{function, enter, 2, 71}.
  {label, 70}.
    {line, [{location, "std@context.erl", 47}]}.
    {func_info, {atom, std@context}, {atom, enter}, 2}.
  {label, 71}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 375}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 376}}.
  {label, 375}.
    {move, {atom, false}, {x, 0}}.
  {label, 376}.
    {test, is_eq, {f, 374}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 378}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 379}}.
  {label, 378}.
    {move, {atom, false}, {x, 0}}.
  {label, 379}.
    {test, is_eq, {f, 377}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@context@@Scope, childAt, 2}, 4}.
  {label, 377}.
    {call_ext, 0, {extfunc, std@context@@Place, none, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 2, {extfunc, std@context@@Scope, childAt, 2}, 4}.
  {label, 374}.
    {move, {literal, <<"a component is run with a `Scope` (decision 819)">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.
% The contexts `cell` holds now — what a body's `use context` reads.

{function, received, 1, 73}.
  {label, 72}.
    {line, [{location, "std@context.erl", 48}]}.
    {func_info, {atom, std@context}, {atom, received}, 1}.
  {label, 73}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 381}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 382}}.
  {label, 381}.
    {move, {atom, false}, {x, 0}}.
  {label, 382}.
    {test, is_eq, {f, 380}, [{x, 0}, {atom, true}]}.
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
    {call_last, 4, {f, 43}, 5}.
  {label, 380}.
    {move, {literal, <<"a component is run with a `Scope` (decision 819)">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
% `value` provided for `key` in `cell`: what is resolved under it afterwards
% reads it (809 (8), 812 (3)).

{function, provideIn, 3, 75}.
  {label, 74}.
    {line, [{location, "std@context.erl", 49}]}.
    {func_info, {atom, std@context}, {atom, provideIn}, 3}.
  {label, 75}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 384}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 385}}.
  {label, 384}.
    {move, {atom, false}, {x, 0}}.
  {label, 385}.
    {test, is_eq, {f, 383}, [{x, 0}, {atom, true}]}.
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
    {call, 6, {f, 47}}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 383}.
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

{function, find, 3, 77}.
  {label, 76}.
    {line, [{location, "std@context.erl", 50}]}.
    {func_info, {atom, std@context}, {atom, find}, 3}.
  {label, 77}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@context.erl", 51}]}.
  {label, 386}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 387}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 389}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 390}}.
  {label, 389}.
    {move, {atom, false}, {x, 0}}.
  {label, 390}.
    {test, is_eq, {f, 388}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 392}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 392}.
    {test, is_eq_exact, {f, 391}, [{x, 0}, {y, 1}]}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 1, {f, 105}, 5}.
  {label, 391}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 107}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 393}}.
  {label, 388}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Frame}, {y, 1}, {y, 2}, {atom, undefined}]}}.
    {call_last, 1, {f, 105}, 5}.
  {label, 393}.
    {jump, {f, 386}}.
  {label, 387}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
% A body's answer, as it is (the word wasm moves through it, decision 504).

{function, answer, 1, 79}.
  {label, 78}.
    {line, [{location, "std@context.erl", 51}]}.
    {func_info, {atom, std@context}, {atom, answer}, 1}.
  {label, 79}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
% The place a `use` passes (820 (2)).

{function, nowhere, 0, 81}.
  {label, 80}.
    {line, [{location, "std@context.erl", 52}]}.
    {func_info, {atom, std@context}, {atom, nowhere}, 0}.
  {label, 81}.
    {allocate, 0, 0}.
    {call_ext_last, 0, {extfunc, std@context@@Place, none, 0}, 0}.
% A fresh root, for a `use` written outside every component body.

{function, root, 0, 83}.
  {label, 82}.
    {line, [{location, "std@context.erl", 53}]}.
    {func_info, {atom, std@context}, {atom, root}, 0}.
  {label, 83}.
    {allocate, 0, 0}.
    {call_ext_last, 0, {extfunc, std@context@@Scope, root, 0}, 0}.
% ── the stamp (decisions 820, 821, 818 (3)) ──────────────────────────────────
% 
% Each written call answering a component answers its value carrying its
% place: `stamp(c, <the body's cell>, n)` in a component body, the item the
% count of the values call `n` made in the body's current render;
% `stampPlain(c, <the entry's counter>, n)` in a plain function, counted in
% that entry (`countNew` at its entry, `countEnd` deferred); `stampKeyed(c,
% n, k)` for `#[key(k)]`. The place travels in the value: run with a
% runner's place it is `mine.with(key)`; a place another stamp already wrote
% passes through, so the stamp written last — the outer call's — wins
% (821 (2)).

{function, stamp, 3, 85}.
  {label, 84}.
    {line, [{location, "std@context.erl", 54}]}.
    {func_info, {atom, std@context}, {atom, stamp}, 3}.
  {label, 85}.
    {allocate, 15, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 395}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 396}}.
  {label, 395}.
    {move, {atom, false}, {x, 0}}.
  {label, 396}.
    {test, is_eq, {f, 394}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@context@@PlaceItem__v__body}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, storeRef, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, ownerRef, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, carriedRef, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, cellId, 1}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 2}, {x, 4}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 4}, {x, 0}}.
    {call, 5, {f, 49}}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 7, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {y, 2}, {y, 3}, {y, 7}, {atom, undefined}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 2, {f, 91}, 15}.
  {label, 394}.
    {move, {literal, <<"a component is run with a `Scope` (decision 819)">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 15}.
    return.

{function, stampPlain, 3, 87}.
  {label, 86}.
    {line, [{location, "std@context.erl", 55}]}.
    {func_info, {atom, std@context}, {atom, stampPlain}, 3}.
  {label, 87}.
    {allocate, 10, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {atom, std@context@@PlaceItem__v__plain}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 103}}.
    {move, {x, 0}, {y, 4}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 7, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {y, 2}, {y, 3}, {y, 4}, {atom, undefined}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 2, {f, 91}, 10}.

{function, stampKeyed, 3, 89}.
  {label, 88}.
    {line, [{location, "std@context.erl", 56}]}.
    {func_info, {atom, std@context}, {atom, stampKeyed}, 3}.
  {label, 89}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {atom, std@context@@PlaceItem__v__key}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 7, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {y, 1}, {x, 1}, {integer, 0}, {y, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 2, {f, 91}, 5}.
% `c` carrying `mine`.

{function, placed, 2, 91}.
  {label, 90}.
    {line, [{location, "std@context.erl", 57}]}.
    {func_info, {atom, std@context}, {atom, placed}, 2}.
  {label, 91}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 398}, 0, 0, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {deallocate, 2}.
    return.
% `use memo(make)` written as call `callNo` of a body: the slot of its own
% child cell (818 (1)), filled on that cell's first render.

{function, memoIn, 3, 93}.
  {label, 92}.
    {line, [{location, "std@context.erl", 58}]}.
    {func_info, {atom, std@context}, {atom, memoIn}, 3}.
  {label, 93}.
    {allocate, 21, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 403}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 404}}.
  {label, 403}.
    {move, {atom, false}, {x, 0}}.
  {label, 404}.
    {test, is_eq, {f, 402}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@context@@PlaceItem__v__body}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, storeRef, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, ownerRef, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, carriedRef, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, cellId, 1}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 1}, {x, 4}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 4}, {x, 0}}.
    {call, 5, {f, 49}}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 7, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {y, 1}, {y, 3}, {y, 7}, {atom, undefined}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, std@context@@Scope, childAt, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, storeRef, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, ownerRef, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, carriedRef, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, cellId, 1}}.
    {move, {y, 10}, {x, 1}}.
    {move, {y, 2}, {x, 4}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 11}, {x, 2}}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 5, {f, 55}, 21}.
  {label, 402}.
    {move, {literal, <<"a component is run with a `Scope` (decision 819)">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 21}.
    return.
% `use all(cs)` written as call `callNo` of a body (827, 884): entry `i` run
% under `all`'s own child cell at `Place.index(i)`, in order; the answers as
% a list, or the task of the list once each settled in order when an entry
% answered a task.

{function, allIn, 3, 95}.
  {label, 94}.
    {line, [{location, "std@context.erl", 59}]}.
    {func_info, {atom, std@context}, {atom, allIn}, 3}.
  {label, 95}.
    {allocate, 18, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 406}, [{x, 0}, 5, {atom, std@context@@Scope}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 407}}.
  {label, 406}.
    {move, {atom, false}, {x, 0}}.
  {label, 407}.
    {test, is_eq, {f, 405}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@context@@PlaceItem__v__body}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, storeRef, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, ownerRef, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, carriedRef, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Scope, cellId, 1}}.
    {move, {y, 5}, {x, 1}}.
    {move, {y, 1}, {x, 4}}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 6}, {x, 2}}.
    {move, {y, 4}, {x, 0}}.
    {call, 5, {f, 49}}.
    {move, {x, 0}, {y, 7}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 7, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {y, 1}, {y, 3}, {y, 7}, {atom, undefined}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, std@context@@Scope, childAt, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 2}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, seq, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{y, 10}, {y, 9}]}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 409}, 0, 0, {x, 0}, {list, [{y, 2}, {y, 8}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {bif, element, {f, 0}, [{integer, 1}, {x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 10}}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 1}}.
    {move, {x, 1}, {y, 9}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq, {f, 420}, [{x, 0}, {atom, true}]}.
    {move, {y, 9}, {x, 0}}.
    {call_last, 1, {f, 97}, 18}.
  {label, 420}.
    {move, {y, 9}, {x, 0}}.
    {deallocate, 18}.
    return.
  {label, 405}.
    {move, {literal, <<"a component is run with a `Scope` (decision 819)">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 18}.
    return.
% Each of `answers` awaited in order where it is a task.

%% @Async — eager lowering
{function, settled, 1, 97}.
  {label, 96}.
    {line, [{location, "std@context.erl", 60}]}.
    {func_info, {atom, std@context}, {atom, settled}, 1}.
  {label, 97}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 422}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
% A plain function entry's counter of the values each of its calls made
% (821 (2)).

{function, countNew, 0, 99}.
  {label, 98}.
    {line, [{location, "std@context.erl", 61}]}.
    {func_info, {atom, std@context}, {atom, countNew}, 0}.
  {label, 99}.
    {allocate, 0, 0}.
    {call_ext_last, 0, {extfunc, erlang, make_ref, 0}, 0}.
% The entry's counter gone: on erlang and beam its process-dictionary entry.

{function, countEnd, 1, 101}.
  {label, 100}.
    {line, [{location, "std@context.erl", 62}]}.
    {func_info, {atom, std@context}, {atom, countEnd}, 1}.
  {label, 101}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call, 2, {f, 428}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
% The count of the values call `callNo` made before this one in the entry.

{function, countNext, 2, 103}.
  {label, 102}.
    {line, [{location, "std@context.erl", 63}]}.
    {func_info, {atom, std@context}, {atom, countNext}, 2}.
  {label, 103}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 435}}.
    {test, is_eq, {f, 433}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 438}}.
    {jump, {f, 436}}.
  {label, 433}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 436}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 51}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 3}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 445}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 445}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 446}}.
  {label, 445}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/context.bp:612:9">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 446}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@PlaceCount}, {y, 1}, {x, 0}, {y, 2}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 440}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, frameValue, 1, 105}.
  {label, 104}.
    {line, [{location, "std@context.erl", 64}]}.
    {func_info, {atom, std@context}, {atom, frameValue}, 1}.
  {label, 105}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 447}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 447}.
    {deallocate, 1}.
    return.

{function, frameParent, 1, 107}.
  {label, 106}.
    {line, [{location, "std@context.erl", 65}]}.
    {func_info, {atom, std@context}, {atom, frameParent}, 1}.
  {label, 107}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 448}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 448}.
    {deallocate, 1}.
    return.
% ── the store's host side (decision 824) ─────────────────────────────────────
% Two keys compared by value (818 (3)).

{function, sameKey, 2, 109}.
  {label, 108}.
    {line, [{location, "std@context.erl", 66}]}.
    {func_info, {atom, std@context}, {atom, sameKey}, 2}.
  {label, 109}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_eq, {f, 449}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 450}}.
  {label, 449}.
    {move, {atom, false}, {x, 0}}.
  {label, 450}.
    {deallocate, 2}.
    return.
% The closed tree written over the root's: on erlang and beam the entry goes
% instead, so the process keeps no `{bp_scope, _}` (825 (2), (3)).
% The process a root is made in: its pid on erlang and beam; elsewhere one
% process holds every root, and a token no test reads stands for it.
% Whether `owner` is another process than this one: never off the BEAM (an
% owner token there is an empty cell).

{function, '__bp_priv__array_range', 2, 453}.
  {label, 452}.
    {line, [{location, "std@context.erl", 68}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 453}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 455}.
  {label, 454}.
    {line, [{location, "std@context.erl", 69}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 455}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__carriedFrames', 1, 457}.
  {label, 456}.
    {line, [{location, "std@context.erl", 70}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__carriedFrames'}, 1}.
  {label, 457}.
    {call_only, 1, {f, 45}}.

{function, '__bp_priv__cellOf', 2, 459}.
  {label, 458}.
    {line, [{location, "std@context.erl", 71}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__cellOf'}, 2}.
  {label, 459}.
    {call_only, 2, {f, 31}}.

{function, '__bp_priv__countAt', 5, 461}.
  {label, 460}.
    {line, [{location, "std@context.erl", 72}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__countAt'}, 5}.
  {label, 461}.
    {call_only, 5, {f, 49}}.

{function, '__bp_priv__countIn', 2, 463}.
  {label, 462}.
    {line, [{location, "std@context.erl", 73}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__countIn'}, 2}.
  {label, 463}.
    {call_only, 2, {f, 51}}.

{function, '__bp_priv__countNext', 2, 465}.
  {label, 464}.
    {line, [{location, "std@context.erl", 74}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__countNext'}, 2}.
  {label, 465}.
    {call_only, 2, {f, 103}}.

{function, '__bp_priv__countRest', 1, 467}.
  {label, 466}.
    {line, [{location, "std@context.erl", 75}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__countRest'}, 1}.
  {label, 467}.
    {call_only, 1, {f, 53}}.

{function, '__bp_priv__entryCounts', 1, 469}.
  {label, 468}.
    {line, [{location, "std@context.erl", 76}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__entryCounts'}, 1}.
  {label, 469}.
    {call_only, 1, {f, 63}}.

{function, '__bp_priv__entryFrames', 1, 471}.
  {label, 470}.
    {line, [{location, "std@context.erl", 77}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__entryFrames'}, 1}.
  {label, 471}.
    {call_only, 1, {f, 59}}.

{function, '__bp_priv__entryNext', 1, 473}.
  {label, 472}.
    {line, [{location, "std@context.erl", 78}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__entryNext'}, 1}.
  {label, 473}.
    {call_only, 1, {f, 65}}.

{function, '__bp_priv__entrySlot', 1, 475}.
  {label, 474}.
    {line, [{location, "std@context.erl", 79}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__entrySlot'}, 1}.
  {label, 475}.
    {call_only, 1, {f, 61}}.

{function, '__bp_priv__frameParent', 1, 477}.
  {label, 476}.
    {line, [{location, "std@context.erl", 80}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__frameParent'}, 1}.
  {label, 477}.
    {call_only, 1, {f, 107}}.

{function, '__bp_priv__frameValue', 1, 479}.
  {label, 478}.
    {line, [{location, "std@context.erl", 81}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__frameValue'}, 1}.
  {label, 479}.
    {call_only, 1, {f, 105}}.

{function, '__bp_priv__keyText', 1, 481}.
  {label, 480}.
    {line, [{location, "std@context.erl", 82}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__keyText'}, 1}.
  {label, 481}.
    {call_only, 1, {f, 41}}.

{function, '__bp_priv__linkAt', 3, 483}.
  {label, 482}.
    {line, [{location, "std@context.erl", 83}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__linkAt'}, 3}.
  {label, 483}.
    {call_only, 3, {f, 35}}.

{function, '__bp_priv__linkNext', 1, 485}.
  {label, 484}.
    {line, [{location, "std@context.erl", 84}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__linkNext'}, 1}.
  {label, 485}.
    {call_only, 1, {f, 39}}.

{function, '__bp_priv__linkSelf', 1, 487}.
  {label, 486}.
    {line, [{location, "std@context.erl", 85}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__linkSelf'}, 1}.
  {label, 487}.
    {call_only, 1, {f, 37}}.

{function, '__bp_priv__placeKey', 1, 489}.
  {label, 488}.
    {line, [{location, "std@context.erl", 86}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__placeKey'}, 1}.
  {label, 489}.
    {call_only, 1, {f, 19}}.

{function, '__bp_priv__placed', 2, 491}.
  {label, 490}.
    {line, [{location, "std@context.erl", 87}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__placed'}, 2}.
  {label, 491}.
    {call_only, 2, {f, 91}}.

{function, '__bp_priv__provideAt', 6, 493}.
  {label, 492}.
    {line, [{location, "std@context.erl", 88}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__provideAt'}, 6}.
  {label, 493}.
    {call_only, 6, {f, 47}}.

{function, '__bp_priv__sameKey', 2, 495}.
  {label, 494}.
    {line, [{location, "std@context.erl", 89}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__sameKey'}, 2}.
  {label, 495}.
    {call_only, 2, {f, 109}}.

{function, '__bp_priv__samePlace', 2, 497}.
  {label, 496}.
    {line, [{location, "std@context.erl", 90}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__samePlace'}, 2}.
  {label, 497}.
    {call_only, 2, {f, 17}}.

{function, '__bp_priv__settled', 1, 499}.
  {label, 498}.
    {line, [{location, "std@context.erl", 91}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__settled'}, 1}.
  {label, 499}.
    {call_only, 1, {f, 97}}.

{function, '__bp_priv__slotAt', 5, 501}.
  {label, 500}.
    {line, [{location, "std@context.erl", 92}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__slotAt'}, 5}.
  {label, 501}.
    {call_only, 5, {f, 55}}.

{function, '__bp_priv__treeCells', 1, 503}.
  {label, 502}.
    {line, [{location, "std@context.erl", 93}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__treeCells'}, 1}.
  {label, 503}.
    {call_only, 1, {f, 25}}.

{function, '__bp_priv__treeLinks', 1, 505}.
  {label, 504}.
    {line, [{location, "std@context.erl", 94}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__treeLinks'}, 1}.
  {label, 505}.
    {call_only, 1, {f, 27}}.

{function, '__bp_priv__treeOf', 3, 507}.
  {label, 506}.
    {line, [{location, "std@context.erl", 95}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__treeOf'}, 3}.
  {label, 507}.
    {call_only, 3, {f, 23}}.

{function, '__bp_priv__withCell', 2, 509}.
  {label, 508}.
    {line, [{location, "std@context.erl", 96}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__withCell'}, 2}.
  {label, 509}.
    {call_only, 2, {f, 29}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 145}.
  {label, 144}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 145}.
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

{function, '__bp_tpl_0', 2, 141}.
  {label, 140}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_0'}, 2}.
  {label, 141}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 145}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1', 1, 148}.
  {label, 147}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_1'}, 1}.
  {label, 148}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 151}, [{x, 0}, {atom, true}]}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 153}}.
  {label, 151}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 152}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 1}}.
    {jump, {f, 153}}.
  {label, 152}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 153}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_2', 1, 157}.
  {label, 156}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_2'}, 1}.
  {label, 157}.
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

{function, '__bp_tpl_3', 1, 166}.
  {label, 165}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_3'}, 1}.
  {label, 166}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_scope}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, get, 1}, 2}.

{function, '__bp_print', 1, 208}.
  {label, 207}.
    {line, [{location, "std@context.erl", 29}]}.
    {func_info, {atom, std@context}, {atom, '__bp_print'}, 1}.
  {label, 208}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 212}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 212}.
  {label, 211}.
    {line, [{location, "std@context.erl", 29}]}.
    {func_info, {atom, std@context}, {atom, '-bp_show_top-'}, 1}.
  {label, 212}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 210}}.

{function, '-bp_show_elem-', 1, 214}.
  {label, 213}.
    {line, [{location, "std@context.erl", 29}]}.
    {func_info, {atom, std@context}, {atom, '-bp_show_elem-'}, 1}.
  {label, 214}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 210}}.

{function, '__bp_show', 2, 210}.
  {label, 209}.
    {line, [{location, "std@context.erl", 29}]}.
    {func_info, {atom, std@context}, {atom, '__bp_show'}, 2}.
  {label, 210}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 222}, [{x, 0}]}.
    {test, is_eq, {f, 221}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 221}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 222}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 223}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 214}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 223}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 225}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 224}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 224}, [{x, 0}]}.
    {test, is_ne_exact, {f, 224}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 224}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 224}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 229}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 230}}.
  {label, 229}.
    {test, is_eq_exact, {f, 226}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 230}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 210}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 224}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 214}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 225}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 227}, [{x, 0}]}.
    {test, is_ne_exact, {f, 227}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 227}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 228}, [{x, 0}, {atom, undefined}]}.
  {label, 226}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 216}, 2}.
  {label, 227}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 228}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 216}.
  {label, 215}.
    {line, [{location, "std@context.erl", 29}]}.
    {func_info, {atom, std@context}, {atom, '__bp_tagged'}, 2}.
  {label, 216}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 231}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 231}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 231}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 232}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 218}, 3}.
  {label, 232}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 218}.
  {label, 217}.
    {line, [{location, "std@context.erl", 29}]}.
    {func_info, {atom, std@context}, {atom, '__bp_render'}, 1}.
  {label, 218}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 233}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 233}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 234}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 234}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 220}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 220}.
  {label, 219}.
    {line, [{location, "std@context.erl", 29}]}.
    {func_info, {atom, std@context}, {atom, '-bp_render_pair-'}, 1}.
  {label, 220}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 210}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 236}.
  {label, 235}.
    {line, [{location, "std@context.erl", 29}]}.
    {func_info, {atom, std@context}, {atom, '-bp_stringify-'}, 1}.
  {label, 236}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 237}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 237}.
    {test, is_integer, {f, 238}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 238}.
    {call, 1, {f, 212}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_4-t/2-fun-0-', 2, 316}.
  {label, 315}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_4-t/2-fun-0-'}, 2}.
  {label, 316}.
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

{function, '__bp_tpl_4', 2, 312}.
  {label, 311}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_4'}, 2}.
  {label, 312}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 316}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_5', 2, 323}.
  {label, 322}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_5'}, 2}.
  {label, 323}.
    {allocate, 12, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_tuple, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 326}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 328}}.
  {label, 326}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 327}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 328}}.
  {label, 327}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 328}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 330}, [{x, 0}, {atom, true}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 329}}.
  {label, 330}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 331}, [{x, 0}, {atom, false}]}.
    {move, {y, 2}, {y, 5}}.
    {jump, {f, 329}}.
  {label, 331}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 329}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 333}}.
  {label, 333}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_atom, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 334}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, true}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 337}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, false}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 340}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 8}}.
    {jump, {f, 342}}.
  {label, 340}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 341}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 8}}.
    {jump, {f, 342}}.
  {label, 341}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 9}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 342}.
    {move, {y, 8}, {y, 6}}.
    {jump, {f, 339}}.
  {label, 337}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 338}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 6}}.
    {jump, {f, 339}}.
  {label, 338}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 7}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 339}.
    {move, {y, 6}, {y, 4}}.
    {jump, {f, 336}}.
  {label, 334}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 335}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 4}}.
    {jump, {f, 336}}.
  {label, 335}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 5}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 336}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 344}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {literal, [95, 95, 118, 95, 95]}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 346}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 7}, {y, 8}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_nonempty_list, {f, 346}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 9}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_nil, {f, 346}, [{x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {y, 6}}.
    {jump, {f, 345}}.
  {label, 346}.
    {move, {y, 0}, {y, 6}}.
    {jump, {f, 345}}.
  {label, 345}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 349}}.
  {label, 349}.
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
    {test, is_eq_exact, {f, 350}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_behaviors'}, {x, 1}}.
    {move, {integer, 0}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 353}, [{x, 0}, {atom, true}]}.
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
    {jump, {f, 355}}.
  {label, 353}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 354}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 7}}.
    {jump, {f, 355}}.
  {label, 354}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 8}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 355}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 352}}.
  {label, 350}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 351}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 352}}.
  {label, 351}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 352}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 344}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 356}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 12}.
    return.
  {label, 356}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '-bp_method-', 3, 358}.
  {label, 357}.
    {line, [{location, "std@context.erl", 46}]}.
    {func_info, {atom, std@context}, {atom, '-bp_method-'}, 3}.
  {label, 358}.
    {test, is_map, {f, 359}, [{x, 1}]}.
    {bif, map_get, {f, 0}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call_ext_only, 2, {extfunc, erlang, apply, 2}}.
  {label, 359}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {test, is_tuple, {f, 360}, [{x, 1}]}.
    {bif, element, {f, 0}, [{integer, 1}, {x, 1}], {x, 0}}.
    {jump, {f, 361}}.
  {label, 360}.
    {move, {x, 1}, {x, 0}}.
  {label, 361}.
    {move, {x, 0}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, split, 2}}.
    {test, is_nonempty_list, {f, 362}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {test, is_nil, {f, 363}, [{x, 2}]}.
    {jump, {f, 362}}.
  {label, 363}.
    {move, {x, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_atom, 1}}.
    {jump, {f, 364}}.
  {label, 362}.
    {move, {y, 2}, {x, 0}}.
  {label, 364}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, erlang, apply, 3}, 3}.

{function, '-placed/2-fun-0-', 4, 398}.
  {label, 397}.
    {line, [{location, "std@context.erl", 58}]}.
    {func_info, {atom, std@context}, {atom, '-placed/2-fun-0-'}, 4}.
  {label, 398}.
    {allocate, 7, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 400}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 400}.
    {test, is_eq, {f, 399}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 401}}.
  {label, 399}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, std@context@@Place, with, 2}}.
  {label, 401}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 3, {f, 67}}.
    {deallocate, 7}.
    return.

{function, '-bp_at-', 2, 412}.
  {label, 411}.
    {line, [{location, "std@context.erl", 60}]}.
    {func_info, {atom, std@context}, {atom, '-bp_at-'}, 2}.
  {label, 412}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 414}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 413}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 414}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 413}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 413}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-allIn/3-fun-1-', 4, 409}.
  {label, 408}.
    {line, [{location, "std@context.erl", 60}]}.
    {func_info, {atom, std@context}, {atom, '-allIn/3-fun-1-'}, 4}.
  {label, 409}.
    {allocate, 12, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {bif, element, {f, 0}, [{integer, 1}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {bif, element, {f, 0}, [{integer, 2}, {y, 1}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 412}}.
    {test, is_ne_exact, {f, 410}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 415}}.
  {label, 410}.
    {move, {literal, <<"value is null \x{E2}\x{80}\x{94} cs[i]! at src/context.bp:574:29">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 415}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@context@@Place, index, 1}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 7}, {x, 0}}.
    {call, 3, {f, 67}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 417}}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 418}}.
  {label, 417}.
    {move, {atom, false}, {x, 0}}.
  {label, 418}.
    {test, is_eq, {f, 416}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {jump, {f, 419}}.
  {label, 416}.
  {label, 419}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 4}, {y, 5}]}}.
    {deallocate, 12}.
    return.

{function, '-settled/1-fun-2-', 2, 422}.
  {label, 421}.
    {line, [{location, "std@context.erl", 61}]}.
    {func_info, {atom, std@context}, {atom, '-settled/1-fun-2-'}, 2}.
  {label, 422}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 424}}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 425}}.
  {label, 424}.
    {move, {atom, false}, {x, 0}}.
  {label, 425}.
    {test, is_eq, {f, 423}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 426}}.
  {label, 423}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
  {label, 426}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_6-t/2-fun-0-', 2, 432}.
  {label, 431}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_6-t/2-fun-0-'}, 2}.
  {label, 432}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_count}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, erase, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_6', 2, 428}.
  {label, 427}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_6'}, 2}.
  {label, 428}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 432}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_7', 1, 435}.
  {label, 434}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_7'}, 1}.
  {label, 435}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_count}, {y, 0}]}}.
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

{function, '__bp_tpl_8', 1, 438}.
  {label, 437}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_8'}, 1}.
  {label, 438}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_count}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, get, 1}, 2}.

{function, '__bp_tpl_9-t/2-fun-0-', 2, 444}.
  {label, 443}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_9-t/2-fun-0-'}, 2}.
  {label, 444}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_count}, {y, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_9', 2, 440}.
  {label, 439}.
    {func_info, {atom, std@context}, {atom, '__bp_tpl_9'}, 2}.
  {label, 440}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 444}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 115}.
  {label, 114}.
    {line, [{location, "std@context.erl", 67}]}.
    {func_info, {atom, std@context}, {atom, '__bp_prim_append'}, 2}.
  {label, 115}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 451}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 451}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@context@@Context.S
```erlang
{module, std@context@@Context}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 7}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@Context.erl", 3}]}.
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
    {line, [{location, "std@context@@Context.erl", 3}]}.
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
{labels, 39}.

{function, none, 0, 3}.
  {label, 2}.
    {line, [{location, "std@context@@Place.erl", 8}]}.
    {func_info, {atom, std@context@@Place}, {atom, none}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, std@context@@PlaceItem__v__absent}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 7, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {integer, 0}, {x, 1}, {integer, 0}, {atom, undefined}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, key, 1, 5}.
  {label, 4}.
    {line, [{location, "std@context@@Place.erl", 9}]}.
    {func_info, {atom, std@context@@Place}, {atom, key}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, std@context@@PlaceItem__v__key}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 7, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {integer, 0}, {x, 1}, {integer, 0}, {y, 0}, {x, 0}]}}.
    {deallocate, 1}.
    return.

{function, index, 1, 7}.
  {label, 6}.
    {line, [{location, "std@context@@Place.erl", 10}]}.
    {func_info, {atom, std@context@@Place}, {atom, index}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, std@context@@PlaceItem__v__index}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 7, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {integer, 0}, {x, 1}, {y, 0}, {atom, undefined}, {x, 0}]}}.
    {deallocate, 1}.
    return.

{function, with, 2, 9}.
  {label, 8}.
    {line, [{location, "std@context@@Place.erl", 11}]}.
    {func_info, {atom, std@context@@Place}, {atom, with}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 11}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 11}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__key}, {x, 0}}.
    {test, is_eq_exact, {f, 10}, [{x, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 12}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__key}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 13}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 13}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 14}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 14}.
    {test_heap, 7, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {x, 1}, {x, 2}, {integer, 0}, {x, 3}, {x, 0}]}}.
    {deallocate, 2}.
    return.
  {label, 10}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 16}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 16}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__index}, {x, 0}}.
    {test, is_eq_exact, {f, 15}, [{x, 1}, {x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 18}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 18}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__absent}, {x, 0}}.
    {test, is_eq_exact, {f, 19}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 20}}.
  {label, 19}.
    {move, {atom, false}, {x, 0}}.
  {label, 20}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 21}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 23}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 23}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__plain}, {x, 0}}.
    {test, is_eq_exact, {f, 24}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {atom, false}, {x, 0}}.
  {label, 25}.
    {jump, {f, 22}}.
  {label, 21}.
    {move, {atom, true}, {x, 0}}.
  {label, 22}.
    {test, is_eq, {f, 17}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 26}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 26}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, std@context@@PlaceItem__v__index}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 27}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 27}.
    {move, {x, 0}, {x, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 6, {atom, std@context@@Place}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 28}.
    {test_heap, 7, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Place}, {x, 1}, {x, 2}, {x, 3}, {atom, undefined}, {x, 0}]}}.
    {deallocate, 2}.
    return.
  {label, 17}.
    {jump, {f, 29}}.
  {label, 15}.
  {label, 29}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 31}.
  {label, 30}.
    {line, [{location, "std@context@@Place.erl", 12}]}.
    {func_info, {atom, std@context@@Place}, {atom, '__bp_get'}, 2}.
  {label, 31}.
    {test, is_eq_exact, {f, 32}, [{x, 1}, {atom, callNo}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 32}.
    {test, is_eq_exact, {f, 33}, [{x, 1}, {atom, item}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 33}.
    {test, is_eq_exact, {f, 34}, [{x, 1}, {atom, itemNo}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 34}.
    {test, is_eq_exact, {f, 35}, [{x, 1}, {atom, keyValue}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 35}.
    {test, is_eq_exact, {f, 36}, [{x, 1}, {atom, stamped}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 6}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 36}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 38}.
  {label, 37}.
    {line, [{location, "std@context@@Place.erl", 12}]}.
    {func_info, {atom, std@context@@Place}, {atom, '__bp_format'}, 1}.
  {label, 38}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"stamped">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
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
    {line, [{location, "std@context@@PlaceItem.erl", 12}]}.
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
    {line, [{location, "std@context@@Scope.erl", 14}]}.
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
    {line, [{location, "std@context@@Scope.erl", 15}]}.
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
    {move, {y, 1}, {x, 4}}.
    {move, {x, 1}, {x, 5}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {move, {x, 0}, {x, 3}}.
    {move, {x, 5}, {x, 0}}.
    {call_ext, 5, {extfunc, std@context, openChild, 5}}.
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
    {line, [{location, "std@context@@Scope.erl", 16}]}.
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
    {line, [{location, "std@context@@Scope.erl", 17}]}.
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
    {line, [{location, "std@context@@Scope.erl", 18}]}.
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
    {line, [{location, "std@context@@Scope.erl", 19}]}.
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
    {line, [{location, "std@context@@Scope.erl", 20}]}.
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
    {line, [{location, "std@context@@Scope.erl", 21}]}.
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
    {line, [{location, "std@context@@Scope.erl", 22}]}.
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
    {line, [{location, "std@context@@Scope.erl", 22}]}.
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
    {line, [{location, "std@context@@Scope.erl", 22}]}.
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
{labels, 10}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@ScopeTree.erl", 22}]}.
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
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, treeLinks}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "std@context@@ScopeTree.erl", 22}]}.
    {func_info, {atom, std@context@@ScopeTree}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"treeLinks">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
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
    {line, [{location, "std@context@@Carried.erl", 22}]}.
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
    {line, [{location, "std@context@@Carried.erl", 22}]}.
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
{labels, 13}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@CellEntry.erl", 22}]}.
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
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, cellGen}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, cellSlot}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {test, is_eq_exact, {f, 8}, [{x, 1}, {atom, cellFilled}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 6}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 8}.
    {test, is_eq_exact, {f, 9}, [{x, 1}, {atom, cellCounts}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 7}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 9}.
    {test, is_eq_exact, {f, 10}, [{x, 1}, {atom, cellNext}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 8}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 10}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 12}.
  {label, 11}.
    {line, [{location, "std@context@@CellEntry.erl", 22}]}.
    {func_info, {atom, std@context@@CellEntry}, {atom, '__bp_format'}, 1}.
  {label, 12}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 8}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"cellNext">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 7}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"cellCounts">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"cellFilled">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"cellSlot">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"cellGen">>}, {x, 0}]}}.
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

----- BEAM ASSEMBLY -- std@context@@PlaceLink.S
```erlang
{module, std@context@@PlaceLink}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 11}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@PlaceLink.erl", 22}]}.
    {func_info, {atom, std@context@@PlaceLink}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, linkParent}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, linkPlace}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, linkChild}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, linkSeen}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {test, is_eq_exact, {f, 8}, [{x, 1}, {atom, linkNext}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 6}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 8}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 10}.
  {label, 9}.
    {line, [{location, "std@context@@PlaceLink.erl", 22}]}.
    {func_info, {atom, std@context@@PlaceLink}, {atom, '__bp_format'}, 1}.
  {label, 10}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"linkNext">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"linkSeen">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"linkChild">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"linkPlace">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"linkParent">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"PlaceLink">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@context@@PlaceCount.S
```erlang
{module, std@context@@PlaceCount}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@PlaceCount.erl", 22}]}.
    {func_info, {atom, std@context@@PlaceCount}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, countCall}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, countValue}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, countNext}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "std@context@@PlaceCount.erl", 22}]}.
    {func_info, {atom, std@context@@PlaceCount}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"countNext">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"countValue">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"countCall">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"PlaceCount">>}, {y, 1}]}}.
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
    {line, [{location, "std@context@@Frame.erl", 47}]}.
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
    {line, [{location, "std@context@@Frame.erl", 47}]}.
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
    {move, {y, 2}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, std@context, stamp, 3}}.
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
