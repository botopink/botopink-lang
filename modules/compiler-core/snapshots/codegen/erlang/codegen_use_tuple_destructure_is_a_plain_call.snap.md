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

----- ERLANG -- std/context.erl
```erlang
-module(std@context).
-export([createContext/1, provide/1, context/1, inject/1, all/1, resolve/3, run/2, enter/2, received/1, provideIn/3, find/3, answer/1, nowhere/0, root/0, stamp/3, stampPlain/3, stampKeyed/3, memoIn/3, allIn/3, countNew/0, countEnd/1, storeOf/1, openChild/5, closeStore/1, framesAt/4, '__bp_priv__array_range'/2, '__bp_priv__array_repeat'/2, '__bp_priv__samePlace'/2, '__bp_priv__placeKey'/1, '__bp_priv__treeOf'/3, '__bp_priv__treeCells'/1, '__bp_priv__treeLinks'/1, '__bp_priv__withCell'/2, '__bp_priv__cellOf'/2, '__bp_priv__linkAt'/3, '__bp_priv__linkSelf'/1, '__bp_priv__linkNext'/1, '__bp_priv__keyText'/1, '__bp_priv__carriedFrames'/1, '__bp_priv__provideAt'/6, '__bp_priv__countAt'/5, '__bp_priv__countIn'/2, '__bp_priv__countRest'/1, '__bp_priv__slotAt'/5, '__bp_priv__entryFrames'/1, '__bp_priv__entrySlot'/1, '__bp_priv__entryCounts'/1, '__bp_priv__entryNext'/1, '__bp_priv__placed'/2, '__bp_priv__settled'/1, '__bp_priv__countNext'/2, '__bp_priv__frameValue'/1, '__bp_priv__frameParent'/1, '__bp_priv__sameKey'/2]).

%% behavior array

array_range(Start, Stop) ->
    case ((Stop - Start) =< 0) of
        true ->
            [];
        false ->
            case ((Stop - Start) =:= 1) of
                true ->
                    [Start];
                false ->
                    Count = (Stop - Start),
                    Low = array_range(Start, (Start + (Count div 2))),
                    High = array_range((Start + (Count div 2)), Stop),
                    '__bp_prim_append'(Low, High)
            end
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Half = array_repeat(Value, (Times div 2)),
            case ((Times rem 2) =:= 0) of
                true ->
                    '__bp_prim_append'(Half, Half);
                false ->
                    '__bp_prim_append'('__bp_prim_append'(Half, Half), [Value])
            end
    end.

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

% Decision 827 — the components `cs` resolved in order under one `use`:

% `val items = use all(self.entries.map({ e -> e.view }));`. `all`'s cell

% stands at the `use`'s place and entry `i` runs under it at

% `Place.index(i)` (884), so a keyed entry keeps its key, one a component

% body counted its count, and any other entry its position. It answers

% `T[]`, or the task of it when an entry answered a task; the `use` awaits

% it. Lowered where it is `use`d; this body never runs.

all(Cs) ->
    erlang:error({panic, <<"`use all` is lowered where it is written; this body never runs">>}).

% ── the place (decisions 819, 820, 821, 884, 891) ────────────────────────────

% Where a component stands among its siblings (819 (2)): the number of the

% call that made it, and its item half — absent, a count the call's

% component body or plain function made (821), a list runner's index, or a

% key. A program passes `Place.none()` (the place the value carries), or

% runs one by hand with `Place.key(k)` / `Place.index(i)` (819 (3), 884).

% `stamped` marks a place a making call wrote (820 (1)): a runner's never is.

%% type Place: callNo, item, itemNo, keyValue, stamped

% A place's item half (891 (1)).

%% type PlaceItem
%%   Absent
%%   Body
%%   Plain
%%   Index
%%   Key

% Whether two places name one child: the call's number and the item half,

% a key compared by value (818 (3)).

samePlace(A, B) ->
    case (((erlang:element(2, A) =/= erlang:element(2, B)) orelse (erlang:element(3, A) =/= erlang:element(3, B))) orelse (erlang:element(4, A) =/= erlang:element(4, B))) of
        true ->
            false;
        _ ->
            case (erlang:element(3, A) =:= std@context@@PlaceItem__v__key) of
                true ->
                    sameKey(placeKey(A), placeKey(B));
                _ ->
                    true
            end
    end.

placeKey(P) ->
    erlang:element(5, P).

% ── the scope (decisions 809 (8), 816, 817, 824, 825) ────────────────────────

% A cell of a render's tree: the contexts provided above it, a persistent map

% keyed by each context's identity. Opaque — made only by `Scope.root()`, a

% cell's `childAt` and `detach`. A root's whole tree is one entry: on erlang

% and beam an entry `{bp_scope, Ref}` of the process dictionary of the

% process that made the root, ended by that process or by `close()`; on

% commonJS a plain object, on wasm a heap cell (824). A scope used after its

% root's `close()` fails `scope-closed` on every target (825 (2)); one read in

% another process than the root's fails `scope-foreign` (824 (3)).

%% type Scope: scopeStore, scopeCell, scopeOwner, scopeCarried

% A root's tree: whether it is closed, the count of its cells, each cell's

% state and each `place → cell` link, the latest entry for an id or a place

% first. Public as `Frame` is: a program never names it.

%% type ScopeTree: treeClosed, treeCount, treeCells, treeLinks

% The contexts a detached root carries across processes (824 (3)).

%% type Carried: frames

% One cell of a root's tree: its contexts, the number of its renders, its

% hook's slot (816, 818 (1)) and the count of the values each call of its

% body made in the current render (821 (1)).

%% type CellEntry: cellNo, cellFrames, cellGen, cellSlot, cellFilled, cellCounts, cellNext

% A child cell at a place of its parent, and the parent's render that last

% met it (817 (1)).

%% type PlaceLink: linkParent, linkPlace, linkChild, linkSeen, linkNext

% The count of the values call `countCall` made in one render or one entry.

%% type PlaceCount: countCall, countValue, countNext

% A new root's store, its one cell holding `frames`.

storeOf(Frames) ->
    Store = erlang:make_ref(),
    (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, {std@context@@ScopeTree, false, 1, {std@context@@CellEntry, 0, Frames, 0, undefined, false, undefined, undefined}, undefined}),
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
                        T = {std@context@@ScopeTree, false, 1, {std@context@@CellEntry, 0, carriedFrames(C), 0, undefined, false, undefined, undefined}, undefined},
                        (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, T),
                        erlang:throw({'__bp_try', T});
                    _ -> ok
                end;
            _ -> ok
        end,
        case (erlang:get({bp_scope, Store}) =/= undefined) of
            true ->
                Raw = erlang:get({bp_scope, Store}),
                case ((erlang:is_tuple(Raw) andalso (erlang:tuple_size(Raw) =:= 5)) andalso (erlang:element(1, Raw) =:= std@context@@ScopeTree)) of
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

treeCells(T) ->
    erlang:element(4, T).

treeLinks(T) ->
    erlang:element(5, T).

% `t` with `e` as cell `e.cellNo`'s state.

withCell(T, E) ->
    {std@context@@ScopeTree, false, erlang:element(3, T), {std@context@@CellEntry, erlang:element(2, E), entryFrames(E), erlang:element(4, E), entrySlot(E), erlang:element(6, E), entryCounts(E), treeCells(T)}, treeLinks(T)}.

% Cell `id`'s state in `cells`.

cellOf(Cells, Id) ->
    try
        Cur = Cells,
        Cur@4 = (fun __BpLoop(Cur@1) ->
            Cur@3 = case ((erlang:is_tuple(Cur@1) andalso (erlang:tuple_size(Cur@1) =:= 8)) andalso (erlang:element(1, Cur@1) =:= std@context@@CellEntry)) of
                true ->
                    E = Cur@1,
                    case (erlang:element(2, E) =:= Id) of
                        true ->
                            erlang:throw({'__bp_try', E});
                        _ -> ok
                    end,
                    Cur@2 = entryNext(E),
                    Cur@2;
                _ ->
                    erlang:error({panic, <<"a scope names a cell its tree does not hold (decision 817)">>}),
                    Cur@1
            end,
            __BpLoop(Cur@3)
        end)(Cur)
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% The child of cell `parent` at `key`, entered for a render: its id.

openChild(Store, Owner, Carried, Parent, Key) ->
    try
        T = treeOf(Store, Owner, Carried),
        P = cellOf(treeCells(T), Parent),
        Frames = entryFrames(P),
        Found = linkAt(treeLinks(T), Parent, Key),
        case ((erlang:is_tuple(Found) andalso (erlang:tuple_size(Found) =:= 6)) andalso (erlang:element(1, Found) =:= std@context@@PlaceLink)) of
            true ->
                L = Found,
                % Two siblings with one key in one render (819 (5)); the root's
                % children are each run's own.
                case (((Parent =/= 0) andalso (erlang:element(5, L) =:= erlang:element(4, P))) andalso (erlang:element(3, Key) =:= std@context@@PlaceItem__v__key)) of
                    true ->
                        erlang:error({panic, <<"key-duplicate: two siblings carry the key ", (keyText(placeKey(Key)))/binary, " (decision 819 (5))">>});
                    _ -> ok
                end,
                % Met in the parent's previous render or in this one: the same cell,
                % its contexts taken anew and its counts reset (816 (2), 817 (5)).
                case ((Parent =:= 0) orelse (erlang:element(5, L) >= '__bp_int'((erlang:element(4, P) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/context.bp:306:52">>))) of
                    true ->
                        C = cellOf(treeCells(T), erlang:element(4, L)),
                        Kept = withCell(T, {std@context@@CellEntry, erlang:element(2, C), Frames, '__bp_int'((erlang:element(4, C) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/context.bp:309:17">>), entrySlot(C), erlang:element(6, C), undefined, undefined}),
                        (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, {std@context@@ScopeTree, false, erlang:element(3, Kept), treeCells(Kept), {std@context@@PlaceLink, Parent, Key, erlang:element(4, L), erlang:element(4, P), treeLinks(Kept)}}),
                        erlang:throw({'__bp_try', erlang:element(4, L)});
                    _ -> ok
                end;
            _ -> ok
        end,
        % A place not met in the parent's previous render: a fresh cell.
        Id = erlang:element(3, T),
        (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, {std@context@@ScopeTree, false, '__bp_int'((Id + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/context.bp:317:9">>), {std@context@@CellEntry, Id, Frames, 1, undefined, false, undefined, treeCells(T)}, {std@context@@PlaceLink, Parent, Key, Id, erlang:element(4, P), treeLinks(T)}}),
        Id
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% The latest link of cell `parent` at `key`, or null.

linkAt(Links, Parent, Key) ->
    try
        Cur = Links,
        Cur@4 = (fun __BpLoop(Cur@1) ->
            Cur@3 = case ((erlang:is_tuple(Cur@1) andalso (erlang:tuple_size(Cur@1) =:= 6)) andalso (erlang:element(1, Cur@1) =:= std@context@@PlaceLink)) of
                true ->
                    L = Cur@1,
                    case ((erlang:element(2, L) =:= Parent) andalso samePlace(erlang:element(3, L), Key)) of
                        true ->
                            erlang:throw({'__bp_try', linkSelf(L)});
                        _ -> ok
                    end,
                    Cur@2 = linkNext(L),
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

linkSelf(L) ->
    L.

linkNext(L) ->
    erlang:element(6, L).

% A key as a failure names it.

keyText(K) ->
    case erlang:is_binary(K) of
        true ->
            <<"\"", ('__bp_text'(K))/binary, "\"">>;
        _ ->
            case (((erlang:is_number(K) andalso (K == erlang:trunc(K))) andalso (K >= -2147483648)) andalso (K =< 2147483647)) of
                true ->
                    K@1 = erlang:trunc(K),
                    erlang:integer_to_binary(K@1);
                _ ->
                    <<"of another type">>
            end
    end.

% The contexts cell `id` holds now.

framesAt(Store, Owner, Carried, Id) ->
    entryFrames(cellOf(treeCells(treeOf(Store, Owner, Carried)), Id)).

carriedFrames(C) ->
    erlang:element(2, C).

% `value` provided for `key` in cell `id`.

provideAt(Store, Owner, Carried, Id, Key, Value) ->
    T = treeOf(Store, Owner, Carried),
    C = cellOf(treeCells(T), Id),
    Frames = {std@context@@Frame, Key, Value, entryFrames(C)},
    (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, withCell(T, {std@context@@CellEntry, Id, Frames, erlang:element(4, C), entrySlot(C), erlang:element(6, C), entryCounts(C), undefined})).

% The count of the values call `callNo` made before this one in cell `id`'s

% current render; the cell counts this one (821 (1)).

countAt(Store, Owner, Carried, Id, CallNo) ->
    T = treeOf(Store, Owner, Carried),
    C = cellOf(treeCells(T), Id),
    N = countIn(entryCounts(C), CallNo),
    (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, withCell(T, {std@context@@CellEntry, Id, entryFrames(C), erlang:element(4, C), entrySlot(C), erlang:element(6, C), {std@context@@PlaceCount, CallNo, '__bp_int'((N + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/context.bp:373:9">>), entryCounts(C)}, undefined})),
    N.

% The latest count of call `callNo` in `counts`, else 0.

countIn(Counts, CallNo) ->
    try
        Cur = Counts,
        Cur@4 = (fun __BpLoop(Cur@1) ->
            Cur@3 = case ((erlang:is_tuple(Cur@1) andalso (erlang:tuple_size(Cur@1) =:= 4)) andalso (erlang:element(1, Cur@1) =:= std@context@@PlaceCount)) of
                true ->
                    K = Cur@1,
                    case (erlang:element(2, K) =:= CallNo) of
                        true ->
                            erlang:throw({'__bp_try', erlang:element(3, K)});
                        _ -> ok
                    end,
                    Cur@2 = countRest(K),
                    Cur@2;
                _ ->
                    erlang:throw({'__bp_try', 0}),
                    Cur@1
            end,
            __BpLoop(Cur@3)
        end)(Cur)
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

countRest(K) ->
    erlang:element(4, K).

% Cell `id`'s slot: what `make` answered on the cell's first render, kept

% while the cell stands (816 (1), 818 (1)).

slotAt(Store, Owner, Carried, Id, Make) ->
    C = cellOf(treeCells(treeOf(Store, Owner, Carried)), Id),
    case erlang:element(6, C) of
        true ->
            entrySlot(C);
        _ ->
            Value = Make(),
            T = treeOf(Store, Owner, Carried),
            Now = cellOf(treeCells(T), Id),
            (fun(__S, __V) -> erlang:put({bp_scope, __S}, __V), undefined end)(Store, withCell(T, {std@context@@CellEntry, Id, entryFrames(Now), erlang:element(4, Now), Value, true, entryCounts(Now), undefined})),
            Value
    end.

% The root's tree closed; a closed one is left as it is.

closeStore(Store) ->
    try
        case (not (erlang:get({bp_scope, Store}) =/= undefined)) of
            true ->
                erlang:throw({'__bp_try', undefined});
            _ -> ok
        end,
        (fun(__S, _) -> erlang:erase({bp_scope, __S}), undefined end)(Store, {std@context@@ScopeTree, true, 0, undefined, undefined})
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

entryFrames(E) ->
    erlang:element(3, E).

entrySlot(E) ->
    erlang:element(5, E).

entryCounts(E) ->
    erlang:element(7, E).

entryNext(E) ->
    erlang:element(8, E).

% ── resolving and running (decisions 809 (6), 815 (5), 819, 822, 825) ───────

% Runs `c` over `scope` at `key` and hands back its answer as it came — a

% value, or the task of a component that awaits —, nothing awaited inside.

resolve(C, Scope, Key) ->
    case '__bp_implements'(C, std@primitives@@Composable) of
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
            case ((erlang:is_tuple(Key) andalso (erlang:tuple_size(Key) =:= 6)) andalso (erlang:element(1, Key) =:= std@context@@Place)) of
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

stamp(C, Cell, CallNo) ->
    case ((erlang:is_tuple(Cell) andalso (erlang:tuple_size(Cell) =:= 5)) andalso (erlang:element(1, Cell) =:= std@context@@Scope)) of
        true ->
            placed(C, {std@context@@Place, CallNo, std@context@@PlaceItem__v__body, countAt(std@context@@Scope:storeRef(Cell), std@context@@Scope:ownerRef(Cell), std@context@@Scope:carriedRef(Cell), std@context@@Scope:cellId(Cell), CallNo), undefined, true});
        _ ->
            erlang:error({panic, <<"a component is run with a `Scope` (decision 819)">>})
    end.

stampPlain(C, Counter, CallNo) ->
    placed(C, {std@context@@Place, CallNo, std@context@@PlaceItem__v__plain, countNext(Counter, CallNo), undefined, true}).

stampKeyed(C, CallNo, K) ->
    placed(C, {std@context@@Place, CallNo, std@context@@PlaceItem__v__key, 0, K, true}).

% `c` carrying `mine`.

placed(C, Mine) ->
    fun(Scope, Key) ->
        resolve(C, Scope, case erlang:element(6, Key) of
            true ->
                Key;
            false ->
                std@context@@Place:with(Mine, Key)
        end)
    end.

% `use memo(make)` written as call `callNo` of a body: the slot of its own

% child cell (818 (1)), filled on that cell's first render.

memoIn(Cell, CallNo, Make) ->
    case ((erlang:is_tuple(Cell) andalso (erlang:tuple_size(Cell) =:= 5)) andalso (erlang:element(1, Cell) =:= std@context@@Scope)) of
        true ->
            Child = std@context@@Scope:childAt(Cell, {std@context@@Place, CallNo, std@context@@PlaceItem__v__body, countAt(std@context@@Scope:storeRef(Cell), std@context@@Scope:ownerRef(Cell), std@context@@Scope:carriedRef(Cell), std@context@@Scope:cellId(Cell), CallNo), undefined, true}),
            slotAt(std@context@@Scope:storeRef(Child), std@context@@Scope:ownerRef(Child), std@context@@Scope:carriedRef(Child), std@context@@Scope:cellId(Child), Make);
        _ ->
            erlang:error({panic, <<"a component is run with a `Scope` (decision 819)">>})
    end.

% `use all(cs)` written as call `callNo` of a body (827, 884): entry `i` run

% under `all`'s own child cell at `Place.index(i)`, in order; the answers as

% a list, or the task of the list once each settled in order when an entry

% answered a task.

allIn(Cell, CallNo, Cs) ->
    case ((erlang:is_tuple(Cell) andalso (erlang:tuple_size(Cell) =:= 5)) andalso (erlang:element(1, Cell) =:= std@context@@Scope)) of
        true ->
            Child = std@context@@Scope:childAt(Cell, {std@context@@Place, CallNo, std@context@@PlaceItem__v__body, countAt(std@context@@Scope:storeRef(Cell), std@context@@Scope:ownerRef(Cell), std@context@@Scope:carriedRef(Cell), std@context@@Scope:cellId(Cell), CallNo), undefined, true}),
            Answers = [],
            Waits = false,
            {Waits@4, Answers@3} = lists:foldl(fun(I, {Waits@1, Answers@1}) ->
                R = resolve(case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Cs, I) of
                    undefined ->
                        erlang:error({panic, <<"value is null \x{E2}\x{80}\x{94} cs[i]! at src/context.bp:574:29">>});
                    __bp_opt_574_34 ->
                        __bp_opt_574_34
                end, Child, std@context@@Place:index(I)),
                Waits@3 = case false of
                    true ->
                        Waits@2 = true,
                        Waits@2;
                    _ ->
                        Waits@1
                end,
                Answers@2 = (Answers@1 ++ [R]),
                {Waits@3, Answers@2}
            end, {Waits, Answers}, lists:seq(0, (erlang:length(Cs)) - 1)),
            case Waits@4 of
                true ->
                    settled(Answers@3);
                _ ->
                    Answers@3
            end;
        _ ->
            erlang:error({panic, <<"a component is run with a `Scope` (decision 819)">>})
    end.

% Each of `answers` awaited in order where it is a task.

%% @Async — eager lowering
settled(Answers) ->
    Out = [],
    Out@5 = lists:foldl(fun(R, Out@1) ->
        Out@4 = case false of
            true ->
                V = R,
                Out@2 = (Out@1 ++ [V]),
                Out@2;
            _ ->
                Out@3 = (Out@1 ++ [R]),
                Out@3
        end,
        Out@4
    end, Out, Answers),
    Out@5.

% A plain function entry's counter of the values each of its calls made

% (821 (2)).

countNew() ->
    erlang:make_ref().

% The entry's counter gone: on erlang and beam its process-dictionary entry.

countEnd(Counter) ->
    (fun(__S, _) -> erlang:erase({bp_count, __S}), undefined end)(Counter, undefined).

% The count of the values call `callNo` made before this one in the entry.

countNext(Counter, CallNo) ->
    Counts = case (erlang:get({bp_count, Counter}) =/= undefined) of
        true ->
            erlang:get({bp_count, Counter});
        false ->
            undefined
    end,
    N = countIn(Counts, CallNo),
    (fun(__S, __V) -> erlang:put({bp_count, __S}, __V), undefined end)(Counter, {std@context@@PlaceCount, CallNo, '__bp_int'((N + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/context.bp:612:9">>), Counts}),
    N.

frameValue(F) ->
    erlang:element(3, F).

frameParent(F) ->
    erlang:element(4, F).

% ── the store's host side (decision 824) ─────────────────────────────────────

% Two keys compared by value (818 (3)).

sameKey(A, B) ->
    (A == B).

%% external fn countCellNew -> erlang template

%% external fn countCellFilled -> erlang template

%% external fn countCellGet -> erlang template

%% external fn countCellSet -> erlang template

%% external fn countCellEnd -> erlang template

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

'__bp_prim_append'(Recv, Arg0) when erlang:is_list(Recv) ->
    (Recv ++ Arg0);
'__bp_prim_append'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"append">>, 1, Recv}).

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_method'(M, V, Args) when erlang:is_map(V) -> erlang:apply(maps:get(M, V), [V | Args]);
'__bp_method'(M, V, Args) ->
    T = case erlang:is_tuple(V) of true -> erlang:element(1, V); false -> V end,
    O = case string:split(erlang:atom_to_list(T), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> T end,
    erlang:apply(O, M, [V | Args]).

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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

'__bp_priv__array_range'(A0, A1) -> array_range(A0, A1).

'__bp_priv__array_repeat'(A0, A1) -> array_repeat(A0, A1).

'__bp_priv__samePlace'(A0, A1) -> samePlace(A0, A1).

'__bp_priv__placeKey'(A0) -> placeKey(A0).

'__bp_priv__treeOf'(A0, A1, A2) -> treeOf(A0, A1, A2).

'__bp_priv__treeCells'(A0) -> treeCells(A0).

'__bp_priv__treeLinks'(A0) -> treeLinks(A0).

'__bp_priv__withCell'(A0, A1) -> withCell(A0, A1).

'__bp_priv__cellOf'(A0, A1) -> cellOf(A0, A1).

'__bp_priv__linkAt'(A0, A1, A2) -> linkAt(A0, A1, A2).

'__bp_priv__linkSelf'(A0) -> linkSelf(A0).

'__bp_priv__linkNext'(A0) -> linkNext(A0).

'__bp_priv__keyText'(A0) -> keyText(A0).

'__bp_priv__carriedFrames'(A0) -> carriedFrames(A0).

'__bp_priv__provideAt'(A0, A1, A2, A3, A4, A5) -> provideAt(A0, A1, A2, A3, A4, A5).

'__bp_priv__countAt'(A0, A1, A2, A3, A4) -> countAt(A0, A1, A2, A3, A4).

'__bp_priv__countIn'(A0, A1) -> countIn(A0, A1).

'__bp_priv__countRest'(A0) -> countRest(A0).

'__bp_priv__slotAt'(A0, A1, A2, A3, A4) -> slotAt(A0, A1, A2, A3, A4).

'__bp_priv__entryFrames'(A0) -> entryFrames(A0).

'__bp_priv__entrySlot'(A0) -> entrySlot(A0).

'__bp_priv__entryCounts'(A0) -> entryCounts(A0).

'__bp_priv__entryNext'(A0) -> entryNext(A0).

'__bp_priv__placed'(A0, A1) -> placed(A0, A1).

'__bp_priv__settled'(A0) -> settled(A0).

'__bp_priv__countNext'(A0, A1) -> countNext(A0, A1).

'__bp_priv__frameValue'(A0) -> frameValue(A0).

'__bp_priv__frameParent'(A0) -> frameParent(A0).

'__bp_priv__sameKey'(A0, A1) -> sameKey(A0, A1).
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
    {std@context@@Place, 0, std@context@@PlaceItem__v__absent, 0, undefined, false}.

key(K) ->
    {std@context@@Place, 0, std@context@@PlaceItem__v__key, 0, K, false}.

index(I) ->
    {std@context@@Place, 0, std@context@@PlaceItem__v__index, I, undefined, false}.

with(Self, Key) ->
    try
        case (erlang:element(3, Key) =:= std@context@@PlaceItem__v__key) of
            true ->
                {std@context@@Place, erlang:element(2, Self), std@context@@PlaceItem__v__key, 0, erlang:element(5, Key), erlang:element(6, Self)};
            _ ->
                case (erlang:element(3, Key) =:= std@context@@PlaceItem__v__index) of
                    true ->
                        case ((erlang:element(3, Self) =:= std@context@@PlaceItem__v__absent) orelse (erlang:element(3, Self) =:= std@context@@PlaceItem__v__plain)) of
                            true ->
                                erlang:throw({'__bp_try', {std@context@@Place, erlang:element(2, Self), std@context@@PlaceItem__v__index, erlang:element(4, Key), undefined, erlang:element(6, Self)}});
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
'__bp_get'(V, keyValue) -> erlang:element(5, V);
'__bp_get'(V, stamped) -> erlang:element(6, V).

'__bp_format'(V) -> {record, "Place", [{"callNo", erlang:element(2, V)}, {"item", erlang:element(3, V)}, {"itemNo", erlang:element(4, V)}, {"keyValue", erlang:element(5, V)}, {"stamped", erlang:element(6, V)}]}.
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
    {std@context@@Scope, erlang:element(2, Self), std@context:openChild(erlang:element(2, Self), erlang:element(4, Self), erlang:element(5, Self), erlang:element(3, Self), Key), erlang:element(4, Self), erlang:element(5, Self)}.

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

'__bp_behaviors'() -> [std@primitives@@Closeable].
```

----- ERLANG -- std@context@@ScopeTree.erl
```erlang
-module(std@context@@ScopeTree).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, treeClosed) -> erlang:element(2, V);
'__bp_get'(V, treeCount) -> erlang:element(3, V);
'__bp_get'(V, treeCells) -> erlang:element(4, V);
'__bp_get'(V, treeLinks) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "ScopeTree", [{"treeClosed", erlang:element(2, V)}, {"treeCount", erlang:element(3, V)}, {"treeCells", erlang:element(4, V)}, {"treeLinks", erlang:element(5, V)}]}.
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
'__bp_get'(V, cellGen) -> erlang:element(4, V);
'__bp_get'(V, cellSlot) -> erlang:element(5, V);
'__bp_get'(V, cellFilled) -> erlang:element(6, V);
'__bp_get'(V, cellCounts) -> erlang:element(7, V);
'__bp_get'(V, cellNext) -> erlang:element(8, V).

'__bp_format'(V) -> {record, "CellEntry", [{"cellNo", erlang:element(2, V)}, {"cellFrames", erlang:element(3, V)}, {"cellGen", erlang:element(4, V)}, {"cellSlot", erlang:element(5, V)}, {"cellFilled", erlang:element(6, V)}, {"cellCounts", erlang:element(7, V)}, {"cellNext", erlang:element(8, V)}]}.
```

----- ERLANG -- std@context@@PlaceLink.erl
```erlang
-module(std@context@@PlaceLink).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, linkParent) -> erlang:element(2, V);
'__bp_get'(V, linkPlace) -> erlang:element(3, V);
'__bp_get'(V, linkChild) -> erlang:element(4, V);
'__bp_get'(V, linkSeen) -> erlang:element(5, V);
'__bp_get'(V, linkNext) -> erlang:element(6, V).

'__bp_format'(V) -> {record, "PlaceLink", [{"linkParent", erlang:element(2, V)}, {"linkPlace", erlang:element(3, V)}, {"linkChild", erlang:element(4, V)}, {"linkSeen", erlang:element(5, V)}, {"linkNext", erlang:element(6, V)}]}.
```

----- ERLANG -- std@context@@PlaceCount.erl
```erlang
-module(std@context@@PlaceCount).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, countCall) -> erlang:element(2, V);
'__bp_get'(V, countValue) -> erlang:element(3, V);
'__bp_get'(V, countNext) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "PlaceCount", [{"countCall", erlang:element(2, V)}, {"countValue", erlang:element(3, V)}, {"countNext", erlang:element(4, V)}]}.
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

%% import bpScopeEnter__, bpScopeAnswer__, bpScopeNowhere__, bpStamp__

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
        {Shown, Push} = (std@context:stamp(optimistic(12, fun(C, A) ->
            '__bp_add'(C, A)
        end), BpCell__1, 1))(BpCell__1, std@context:nowhere()),
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
