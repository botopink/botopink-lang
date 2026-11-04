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

pub fn stamp<T>(c: Component<T>, cell: unknown, callNo: i32) -> Composition<T> {
    if (cell is Scope)
        return placed(c, Place(callNo: callNo, item: PlaceItem.Body, itemNo: countAt(cell.storeRef(), cell.ownerRef(), cell.carriedRef(), cell.cellId(), callNo), keyValue: null, stamped: true));
    panic("a component is run with a `Scope` (decision 819)");
}

pub fn stampPlain<T>(c: Component<T>, counter: unknown, callNo: i32) -> Composition<T> {
    return placed(c, Place(callNo: callNo, item: PlaceItem.Plain, itemNo: countNext(counter, callNo), keyValue: null, stamped: true));
}

pub fn stampKeyed<T>(c: Component<T>, callNo: i32, k: unknown) -> Composition<T> {
    return placed(c, Place(callNo: callNo, item: PlaceItem.Key, itemNo: 0, keyValue: k, stamped: true));
}

// `c` carrying `mine`.
fn placed<T>(c: Component<T>, mine: Place) -> Composition<T> {
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

----- WASM TEXT -- std/context.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (sub (array (mut i32))))
    (type $arr_bool (sub final $arr_i32 (array (mut i32))))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (sub (struct (field $v i64))))
    (type $box_u64 (sub final $box_i64 (struct (field $v i64))))
    (type $box_f64 (struct (field $v f64)))
    (type $box_bool (sub final $box_i32 (struct (field $v i32))))
    (type $box_big (struct (field $v (ref null $str))))
    (type $closure (sub (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $hostn (struct (field $next (mut (ref null $hostn))) (field $h i32) (field $t (ref null $task))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $cell (struct (field $filled (mut i32)) (field $value (mut anyref))))
    (type $__decl (sub (struct (field $ti (ref null $__tinfo)))))
    (type $__tinfo (struct (field $name (ref null $str)) (field $print funcref) (field $eq funcref) (field $display funcref) (field $kind i32)))
    (type $__print_sig (func (param anyref)))
    (type $__eq_sig (func (param anyref anyref) (result i32)))
  )
  (rec
    (type $sig_0 (func (param (ref null $closure)) (result anyref)))
  )
  (rec
    (type $sig_2 (func (param (ref null $closure) anyref anyref) (result anyref)))
  )
  (rec
    (type $rec_Carried (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut anyref)))))
    (type $brand_rec_Carried (struct (field i32) (field f64) (field i64) (field f32) (field i32) (field f32) (field f32) (field i32) (field i32) (field f32) (field i32) (field i64) (field f32) (field i64) (field f64) (field f32) (field i32) (field i64) (field i32) (field i32) (field i64) (field f32) (field i64) (field f64) (field i32) (field f64) (field f64) (field i32) (field f32) (field i64) (field i32) (field f64)))
  )
  (rec
    (type $rec_CellEntry (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut anyref)) (field $f2 (mut i32)) (field $f3 (mut anyref)) (field $f4 (mut i32)) (field $f5 (mut anyref)) (field $f6 (mut anyref)))))
    (type $brand_rec_CellEntry (struct (field f64) (field f64) (field i32) (field i32) (field i32) (field i32) (field f32) (field f64) (field i32) (field i32) (field i32) (field i32) (field f64) (field i32) (field f32) (field i64) (field i32) (field i64) (field i64) (field f64) (field f64) (field f32) (field i64) (field f64) (field i32) (field i64) (field i32) (field f32) (field f32) (field i32) (field f64) (field i32)))
  )
  (rec
    (type $rec_Context (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut anyref)))))
    (type $brand_rec_Context (struct (field f64) (field f64) (field i64) (field f64) (field f32) (field f32) (field i64) (field i64) (field i64) (field f32) (field i64) (field i32) (field i64) (field f32) (field i64) (field f64) (field i64) (field i64) (field i64) (field i64) (field f32) (field i32) (field i32) (field f64) (field i64) (field i64) (field f64) (field f64) (field i32) (field i32) (field i64) (field i32)))
  )
  (rec
    (type $rec_Frame (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $str))) (field $f1 (mut anyref)) (field $f2 (mut anyref)))))
    (type $brand_rec_Frame (struct (field i64) (field f32) (field i64) (field i64) (field i64) (field i32) (field f32) (field f32) (field f64) (field f32) (field f32) (field f64) (field i64) (field f32) (field i32) (field i64) (field i64) (field i32) (field f32) (field i32) (field f32) (field f64) (field i32) (field f64) (field i64) (field f32) (field i64) (field i32) (field f64) (field i64) (field f64) (field i64)))
  )
  (rec
    (type $rec_Place (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut i32)) (field $f2 (mut i32)) (field $f3 (mut anyref)) (field $f4 (mut i32)))))
    (type $brand_rec_Place (struct (field i64) (field f32) (field i32) (field i32) (field i64) (field i64) (field f64) (field f64) (field i64) (field f32) (field i32) (field i64) (field f32) (field i64) (field f64) (field i32) (field f32) (field i32) (field f32) (field f32) (field i32) (field i64) (field i64) (field f32) (field f64) (field i64) (field f32) (field f64) (field i32) (field f32) (field i64) (field f32)))
  )
  (rec
    (type $rec_PlaceCount (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut i32)) (field $f2 (mut anyref)))))
    (type $brand_rec_PlaceCount (struct (field f64) (field f32) (field i64) (field f64) (field i64) (field i32) (field f32) (field i32) (field i32) (field i32) (field f64) (field f64) (field f32) (field i64) (field f32) (field i32) (field i64) (field f32) (field f32) (field i32) (field i32) (field i32) (field f64) (field f64) (field i64) (field i64) (field f32) (field i32) (field f32) (field f64) (field f64) (field f32)))
  )
  (rec
    (type $rec_PlaceLink (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut (ref null $rec_Place))) (field $f2 (mut i32)) (field $f3 (mut i32)) (field $f4 (mut anyref)))))
    (type $brand_rec_PlaceLink (struct (field i64) (field i32) (field f64) (field i64) (field f64) (field i32) (field f32) (field i64) (field i32) (field f32) (field i64) (field f32) (field f64) (field i32) (field i64) (field i64) (field i32) (field i32) (field i32) (field f32) (field f32) (field f64) (field f64) (field i32) (field f64) (field f64) (field i32) (field i32) (field i64) (field i32) (field f32) (field i32)))
  )
  (rec
    (type $rec_Scope (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut anyref)) (field $f1 (mut i32)) (field $f2 (mut anyref)) (field $f3 (mut anyref)))))
    (type $brand_rec_Scope (struct (field f32) (field i64) (field i64) (field f32) (field f64) (field i32) (field i32) (field f64) (field f64) (field i32) (field i32) (field f32) (field f32) (field f64) (field i32) (field f64) (field f32) (field f32) (field i32) (field i64) (field f64) (field i32) (field i32) (field f32) (field i32) (field i64) (field f64) (field f64) (field f32) (field f32) (field f32) (field i32)))
  )
  (rec
    (type $rec_ScopeTree (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut i32)) (field $f2 (mut anyref)) (field $f3 (mut anyref)))))
    (type $brand_rec_ScopeTree (struct (field i64) (field i32) (field i64) (field f64) (field i32) (field f32) (field f64) (field i32) (field i64) (field f32) (field f32) (field i64) (field i64) (field f64) (field f64) (field f32) (field f32) (field f32) (field i32) (field i32) (field i64) (field i64) (field f64) (field i64) (field f64) (field i32) (field i64) (field i32) (field f32) (field f32) (field f32) (field f32)))
  )
  (rec
    (type $frame0 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $closure))) (field $s1 (mut (ref null $rec_Scope))) (field $s2 (mut anyref)) (field $s3 (mut (ref null $rec_Scope))) (field $s4 (mut anyref)) (field $s5 (mut i32)) (field $s6 (mut i32)) (field $s7 (mut anyref)) (field $s8 (mut anyref)) (field $s9 (mut i32)) (field $s10 (mut anyref)) (field $s11 (mut anyref)) (field $s12 (mut i32)) (field $s13 (mut i32)) (field $s14 (mut anyref)) (field $s15 (mut anyref)) (field $s16 (mut i32)) (field $s17 (mut anyref))))
    (type $env0 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))) (field $c1 (mut (ref null $rec_Place))))))
    (type $frame1 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $arr_any))) (field $s1 (mut i32)) (field $s2 (mut i32)) (field $s3 (mut i32)) (field $s4 (mut (ref null $arr_any))) (field $s5 (mut i32)) (field $s6 (mut anyref)) (field $s7 (mut (ref null $arr_any))) (field $s8 (mut i32)) (field $s9 (mut i32)) (field $s10 (mut anyref)) (field $s11 (mut i32)) (field $s12 (mut anyref)) (field $s13 (mut anyref)) (field $s14 (mut i32)) (field $s15 (mut anyref))))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__print_decl" (func $__print_decl (param anyref)))
  (import "std@__rt" "__eq_decl" (func $__eq_decl (param anyref anyref) (result i32)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i32ToString" (func $__abi___std_number_i32ToString (param i32) (result arrayref)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (tag $__bp_panic (param anyref))
  (elem declare func $__lambda0)
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
  (func $createContext (export "createContext") (param $value anyref) (result (ref null $rec_Context))
    (local $__mem0 i32)
    local.get $value
    call $__new_30
    return
  )
  ;; Gives `ctx` to every component this component renders below it — never
  ;; to itself or a sibling; the nearest provider of a type wins.
  (func $provide (export "provide") (param $ctx (ref null $rec_Context)) (result (ref null $closure))
    global.get $__s0
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null $closure
  )
  ;; The value of the context of `ctx`'s type provided nearest above this body,
  ;; or `ctx`'s own default: `use context(themeContext)` names a context value
  ;; the module declares or imports, never a bare type (decisions 722, 723).
  (func $context (export "context") (param $ctx (ref null $rec_Context)) (result (ref null $closure))
    global.get $__s0
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null $closure
  )
  ;; Decision 416 — the record `T` built from the contexts of its fields'
  ;; types: each field the nearest context of its type provided above, else
  ;; that type's declared default, else the field's own default (`use
  ;; inject(Deps)`). `T` is a record; a behavior is read with `use context`.
  ;; `createContext(value, Behavior)` keys a context by the behavior its value
  ;; implements, so a field typed by the behavior reads it.
  (func $inject (export "inject") (param $t i32) (result (ref null $closure))
    global.get $__s1
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null $closure
  )
  ;; Decision 827 — the components `cs` resolved in order under one `use`:
  ;; `val items = use all(self.entries.map({ e -> e.view }));`. `all`'s cell
  ;; stands at the `use`'s place and entry `i` runs under it at
  ;; `Place.index(i)` (884), so a keyed entry keeps its key, one a component
  ;; body counted its count, and any other entry its position. It answers
  ;; `T[]`, or the task of it when an entry answered a task; the `use` awaits
  ;; it. Lowered where it is `use`d; this body never runs.
  (func $all (export "all") (param $cs (ref null $arr_any)) (result (ref null $closure))
    global.get $__s2
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null $closure
  )
  ;; ── the place (decisions 819, 820, 821, 884, 891) ────────────────────────────
  ;; Where a component stands among its siblings (819 (2)): the number of the
  ;; call that made it, and its item half — absent, a count the call's
  ;; component body or plain function made (821), a list runner's index, or a
  ;; key. A program passes `Place.none()` (the place the value carries), or
  ;; runs one by hand with `Place.key(k)` / `Place.index(i)` (819 (3), 884).
  ;; `stamped` marks a place a making call wrote (820 (1)): a runner's never is.
  (func $Place_none (result (ref null $rec_Place))
    (local $__mem0 i32)
    i32.const 0
    i32.const 0 ;; PlaceItem.Absent
    i32.const 0
    ref.null any
    i32.const 0
    call $__new_34
    return
  )
  (func $Place_key (param $k anyref) (result (ref null $rec_Place))
    (local $__mem0 i32)
    i32.const 0
    i32.const 4 ;; PlaceItem.Key
    i32.const 0
    local.get $k
    i32.const 0
    call $__new_34
    return
  )
  (func $Place_index (param $i i32) (result (ref null $rec_Place))
    (local $__mem0 i32)
    i32.const 0
    i32.const 3 ;; PlaceItem.Index
    local.get $i
    ref.null any
    i32.const 0
    call $__new_34
    return
  )
  (func $Place_with (param $self (ref null $rec_Place)) (param $key (ref null $rec_Place)) (result (ref null $rec_Place))
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $key
    struct.get $rec_Place $f1
    i32.const 4 ;; PlaceItem.Key
    i32.eq
    (if (result (ref null $rec_Place))
      (then
    local.get $self
    struct.get $rec_Place $f0
    i32.const 4 ;; PlaceItem.Key
    i32.const 0
    local.get $key
    struct.get $rec_Place $f3
    local.get $self
    struct.get $rec_Place $f4
    call $__new_34
    return
      )
      (else
        ref.null $rec_Place
      )
    )
    drop
    local.get $key
    struct.get $rec_Place $f1
    i32.const 3 ;; PlaceItem.Index
    i32.eq
    (if (result (ref null $rec_Place))
      (then
    local.get $self
    struct.get $rec_Place $f1
    i32.const 0 ;; PlaceItem.Absent
    i32.eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $self
    struct.get $rec_Place $f1
    i32.const 2 ;; PlaceItem.Plain
    i32.eq
      )
    )
    (if (result (ref null $rec_Place))
      (then
    local.get $self
    struct.get $rec_Place $f0
    i32.const 3 ;; PlaceItem.Index
    local.get $key
    struct.get $rec_Place $f2
    ref.null any
    local.get $self
    struct.get $rec_Place $f4
    call $__new_34
    return
      )
      (else
        ref.null $rec_Place
      )
    )
      )
      (else
        ref.null $rec_Place
      )
    )
    drop
    local.get $self
    return
  )
  ;; A place's item half (891 (1)).
  ;; Whether two places name one child: the call's number and the item half,
  ;; a key compared by value (818 (3)).
  (func $samePlace (param $a (ref null $rec_Place)) (param $b (ref null $rec_Place)) (result i32)
    local.get $a
    struct.get $rec_Place $f0
    local.get $b
    struct.get $rec_Place $f0
    i32.ne
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $a
    struct.get $rec_Place $f1
    local.get $b
    struct.get $rec_Place $f1
    i32.ne
      )
    )
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $a
    struct.get $rec_Place $f2
    local.get $b
    struct.get $rec_Place $f2
    i32.ne
      )
    )
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
    local.get $a
    struct.get $rec_Place $f1
    i32.const 4 ;; PlaceItem.Key
    i32.eq
    (if (result i32)
      (then
    local.get $a
    call $placeKey
    local.get $b
    call $placeKey
    call $sameKey
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 1
    return
  )
  (func $placeKey (param $p (ref null $rec_Place)) (result anyref)
    local.get $p
    struct.get $rec_Place $f3
    return
  )
  ;; ── the scope (decisions 809 (8), 816, 817, 824, 825) ────────────────────────
  ;; A cell of a render's tree: the contexts provided above it, a persistent map
  ;; keyed by each context's identity. Opaque — made only by `Scope.root()`, a
  ;; cell's `childAt` and `detach`. A root's whole tree is one entry: on erlang
  ;; and beam an entry `{bp_scope, Ref}` of the process dictionary of the
  ;; process that made the root, ended by that process or by `close()`; on
  ;; commonJS a plain object, on wasm a heap cell (824). A scope used after its
  ;; root's `close()` fails `scope-closed` on every target (825 (2)); one read in
  ;; another process than the root's fails `scope-foreign` (824 (3)).
  (func $Scope_root (result (ref null $rec_Scope))
    (local $__mem0 i32)
    ref.null any
    call $storeOf
    i32.const 0
    call $ownerSelf
    ref.null any
    call $__new_40
    return
  )
  (func $Scope_childAt (param $self (ref null $rec_Scope)) (param $key (ref null $rec_Place)) (result (ref null $rec_Scope))
    (local $__mem0 i32)
    local.get $self
    struct.get $rec_Scope $f0
    local.get $self
    struct.get $rec_Scope $f0
    local.get $self
    struct.get $rec_Scope $f2
    local.get $self
    struct.get $rec_Scope $f3
    local.get $self
    struct.get $rec_Scope $f1
    local.get $key
    call $openChild
    local.get $self
    struct.get $rec_Scope $f2
    local.get $self
    struct.get $rec_Scope $f3
    call $__new_40
    return
  )
  (func $Scope_close (param $self (ref null $rec_Scope)) (result i32)
    local.get $self
    struct.get $rec_Scope $f0
    call $closeStore
  )
  (func $Scope_detach (param $self (ref null $rec_Scope)) (result (ref null $rec_Scope))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $carried (ref null $rec_Carried))
    local.get $self
    struct.get $rec_Scope $f0
    local.get $self
    struct.get $rec_Scope $f2
    local.get $self
    struct.get $rec_Scope $f3
    local.get $self
    struct.get $rec_Scope $f1
    call $framesAt
    call $__new_26
    local.set $carried
    call $storeNew
    i32.const 0
    ref.null any
    local.get $carried
    call $__new_40
    return
  )
  (func $Scope_storeRef (param $self (ref null $rec_Scope)) (result anyref)
    local.get $self
    struct.get $rec_Scope $f0
    return
  )
  (func $Scope_cellId (param $self (ref null $rec_Scope)) (result i32)
    local.get $self
    struct.get $rec_Scope $f1
    return
  )
  (func $Scope_ownerRef (param $self (ref null $rec_Scope)) (result anyref)
    local.get $self
    struct.get $rec_Scope $f2
    return
  )
  (func $Scope_carriedRef (param $self (ref null $rec_Scope)) (result anyref)
    local.get $self
    struct.get $rec_Scope $f3
    return
  )
  ;; A root's tree: whether it is closed, the count of its cells, each cell's
  ;; state and each `place → cell` link, the latest entry for an id or a place
  ;; first. Public as `Frame` is: a program never names it.
  ;; The contexts a detached root carries across processes (824 (3)).
  ;; One cell of a root's tree: its contexts, the number of its renders, its
  ;; hook's slot (816, 818 (1)) and the count of the values each call of its
  ;; body made in the current render (821 (1)).
  ;; A child cell at a place of its parent, and the parent's render that last
  ;; met it (817 (1)).
  ;; The count of the values call `countCall` made in one render or one entry.
  ;; A new root's store, its one cell holding `frames`.
  (func $storeOf (param $frames anyref) (result anyref)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $store anyref)
    call $storeNew
    local.set $store
    local.get $store
    i32.const 0
    i32.const 1
    i32.const 0
    local.get $frames
    i32.const 0
    ref.null any
    i32.const 0
    ref.null any
    ref.null any
    call $__new_28
    ref.null any
    call $__new_42
    call $storeSet
    local.get $store
    return
  )
  ;; The root's tree, live and in its own process; a detached root's starts in
  ;; each process that reads it from the contexts it carries.
  (func $treeOf (param $store anyref) (param $owner anyref) (param $carried anyref) (result (ref null $rec_ScopeTree))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $c (ref null $rec_Carried))
    (local $t (ref null $rec_ScopeTree))
    (local $raw anyref)
    (local $__gc0 anyref)
    (local $__gc1 anyref)
    local.get $owner
    call $ownerForeign
    (if (result (ref null $rec_ScopeTree))
      (then
    global.get $__s3
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null $rec_ScopeTree
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
    drop
    local.get $store
    call $storeLive
    i32.eqz
    (if (result (ref null $rec_ScopeTree))
      (then
    local.get $carried
    local.set $__gc0
    local.get $__gc0
    ref.test (ref null $rec_Carried)
    local.get $__gc0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $rec_ScopeTree))
      (then
    local.get $carried
    ref.cast (ref null $rec_Carried)
    local.set $c
    i32.const 0
    i32.const 1
    i32.const 0
    local.get $c
    call $carriedFrames
    i32.const 0
    ref.null any
    i32.const 0
    ref.null any
    ref.null any
    call $__new_28
    ref.null any
    call $__new_42
    local.set $t
    local.get $store
    local.get $t
    call $storeSet
    local.get $t
    return
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
    drop
    local.get $store
    call $storeLive
    (if (result (ref null $rec_ScopeTree))
      (then
    local.get $store
    call $storeGet
    local.set $raw
    local.get $raw
    local.set $__gc1
    local.get $__gc1
    ref.test (ref null $rec_ScopeTree)
    local.get $__gc1
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $rec_ScopeTree))
      (then
    local.get $raw
    ref.cast (ref null $rec_ScopeTree)
    local.set $t
    local.get $t
    struct.get $rec_ScopeTree $f0
    i32.eqz
    (if (result (ref null $rec_ScopeTree))
      (then
    local.get $t
    return
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
    drop
    global.get $__s4
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null $rec_ScopeTree
  )
  (func $treeCells (param $t (ref null $rec_ScopeTree)) (result anyref)
    local.get $t
    struct.get $rec_ScopeTree $f2
    return
  )
  (func $treeLinks (param $t (ref null $rec_ScopeTree)) (result anyref)
    local.get $t
    struct.get $rec_ScopeTree $f3
    return
  )
  ;; `t` with `e` as cell `e.cellNo`'s state.
  (func $withCell (param $t (ref null $rec_ScopeTree)) (param $e (ref null $rec_CellEntry)) (result (ref null $rec_ScopeTree))
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 0
    local.get $t
    struct.get $rec_ScopeTree $f1
    local.get $e
    struct.get $rec_CellEntry $f0
    local.get $e
    call $entryFrames
    local.get $e
    struct.get $rec_CellEntry $f2
    local.get $e
    call $entrySlot
    local.get $e
    struct.get $rec_CellEntry $f4
    local.get $e
    call $entryCounts
    local.get $t
    call $treeCells
    call $__new_28
    local.get $t
    call $treeLinks
    call $__new_42
    return
  )
  ;; Cell `id`'s state in `cells`.
  (func $cellOf (param $cells anyref) (param $id i32) (result (ref null $rec_CellEntry))
    (local $cur anyref)
    (local $e (ref null $rec_CellEntry))
    (local $__gc2 anyref)
    local.get $cells
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.set $__gc2
    local.get $__gc2
    ref.test (ref null $rec_CellEntry)
    local.get $__gc2
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $cur
    ref.cast (ref null $rec_CellEntry)
    local.set $e
    local.get $e
    struct.get $rec_CellEntry $f0
    local.get $id
    i32.eq
    (if (result (ref null $rec_CellEntry))
      (then
    local.get $e
    return
      )
      (else
        ref.null $rec_CellEntry
      )
    )
    drop
    local.get $e
    call $entryNext
    local.set $cur
      )
      (else
    global.get $__s5
    i32.const 1
    call $__panic_raise
    unreachable
      )
    )
        br $__continue
      )
    )
    unreachable ;; a loop with no break never ends
  )
  ;; The child of cell `parent` at `key`, entered for a render: its id.
  (func $openChild (param $store anyref) (param $owner anyref) (param $carried anyref) (param $parent i32) (param $key (ref null $rec_Place)) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $t (ref null $rec_ScopeTree))
    (local $p (ref null $rec_CellEntry))
    (local $frames anyref)
    (local $found anyref)
    (local $l (ref null $rec_PlaceLink))
    (local $c (ref null $rec_CellEntry))
    (local $kept (ref null $rec_ScopeTree))
    (local $id i32)
    (local $__gc3 anyref)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    local.set $t
    local.get $t
    call $treeCells
    local.get $parent
    call $cellOf
    local.set $p
    local.get $p
    call $entryFrames
    local.set $frames
    local.get $t
    call $treeLinks
    local.get $parent
    local.get $key
    call $linkAt
    local.set $found
    local.get $found
    local.set $__gc3
    local.get $__gc3
    ref.test (ref null $rec_PlaceLink)
    local.get $__gc3
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    local.get $found
    ref.cast (ref null $rec_PlaceLink)
    local.set $l
    local.get $parent
    i32.const 0
    i32.ne
    (if (result i32)
      (then
    local.get $l
    struct.get $rec_PlaceLink $f3
    local.get $p
    struct.get $rec_CellEntry $f2
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $key
    struct.get $rec_Place $f1
    i32.const 4 ;; PlaceItem.Key
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    global.get $__s6
    local.get $key
    call $placeKey
    call $keyText
    call $__str_concat
    global.get $__s7
    call $__str_concat
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
    local.get $parent
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $l
    struct.get $rec_PlaceLink $f3
    local.get $p
    struct.get $rec_CellEntry $f2
    i32.const 1
    global.get $__s8
    call $__i32_sub_chk
    i32.ge_s
      )
    )
    (if (result i32)
      (then
    local.get $t
    call $treeCells
    local.get $l
    struct.get $rec_PlaceLink $f2
    call $cellOf
    local.set $c
    local.get $t
    local.get $c
    struct.get $rec_CellEntry $f0
    local.get $frames
    local.get $c
    struct.get $rec_CellEntry $f2
    i32.const 1
    global.get $__s9
    call $__i32_add_chk
    local.get $c
    call $entrySlot
    local.get $c
    struct.get $rec_CellEntry $f4
    ref.null any
    ref.null any
    call $__new_28
    call $withCell
    local.set $kept
    local.get $store
    i32.const 0
    local.get $kept
    struct.get $rec_ScopeTree $f1
    local.get $kept
    call $treeCells
    local.get $parent
    local.get $key
    local.get $l
    struct.get $rec_PlaceLink $f2
    local.get $p
    struct.get $rec_CellEntry $f2
    local.get $kept
    call $treeLinks
    call $__new_38
    call $__new_42
    call $storeSet
    local.get $l
    struct.get $rec_PlaceLink $f2
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
    local.get $t
    struct.get $rec_ScopeTree $f1
    local.set $id
    local.get $store
    i32.const 0
    local.get $id
    i32.const 1
    global.get $__s10
    call $__i32_add_chk
    local.get $id
    local.get $frames
    i32.const 1
    ref.null any
    i32.const 0
    ref.null any
    local.get $t
    call $treeCells
    call $__new_28
    local.get $parent
    local.get $key
    local.get $id
    local.get $p
    struct.get $rec_CellEntry $f2
    local.get $t
    call $treeLinks
    call $__new_38
    call $__new_42
    call $storeSet
    local.get $id
    return
  )
  ;; The latest link of cell `parent` at `key`, or null.
  (func $linkAt (param $links anyref) (param $parent i32) (param $key (ref null $rec_Place)) (result anyref)
    (local $cur anyref)
    (local $l (ref null $rec_PlaceLink))
    (local $__gc4 anyref)
    local.get $links
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.set $__gc4
    local.get $__gc4
    ref.test (ref null $rec_PlaceLink)
    local.get $__gc4
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    local.get $cur
    ref.cast (ref null $rec_PlaceLink)
    local.set $l
    local.get $l
    struct.get $rec_PlaceLink $f0
    local.get $parent
    i32.eq
    (if (result i32)
      (then
    local.get $l
    struct.get $rec_PlaceLink $f1
    local.get $key
    call $samePlace
      )
      (else
    i32.const 0
      )
    )
    (if (result anyref)
      (then
    local.get $l
    call $linkSelf
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $l
    call $linkNext
    local.set $cur
    i32.const 0
      )
      (else
    ref.null any
    return
      )
    )
    drop
        br $__continue
      )
    )
    unreachable ;; a loop with no break never ends
  )
  (func $linkSelf (param $l (ref null $rec_PlaceLink)) (result anyref)
    local.get $l
    return
  )
  (func $linkNext (param $l (ref null $rec_PlaceLink)) (result anyref)
    local.get $l
    struct.get $rec_PlaceLink $f4
    return
  )
  ;; A key as a failure names it.
  (func $keyText (param $k anyref) (result (ref null $str))
    (local $__gc5 anyref)
    (local $k__is0 (ref null $str))
    (local $k__is1 i32)
    local.get $k
    local.tee $__gc5
    ref.test (ref null $str)
    local.get $__gc5
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $k
    ref.cast (ref null $str)
    local.set $k__is0
    global.get $__s11
    local.get $k__is0
    call $__str_concat
    global.get $__s11
    call $__str_concat
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $k
    i32.const -2147483648
    i32.const 2147483647
    call $__unk_int_in
    (if (result (ref null $str))
      (then
    local.get $k
    call $__unk_as_i32
    local.set $k__is1
    local.get $k__is1
    call $__std_number_i32ToString
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    global.get $__s12
    return
  )
  ;; The contexts cell `id` holds now.
  (func $framesAt (param $store anyref) (param $owner anyref) (param $carried anyref) (param $id i32) (result anyref)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    call $treeCells
    local.get $id
    call $cellOf
    call $entryFrames
    return
  )
  (func $carriedFrames (param $c (ref null $rec_Carried)) (result anyref)
    local.get $c
    struct.get $rec_Carried $f0
    return
  )
  ;; `value` provided for `key` in cell `id`.
  (func $provideAt (param $store anyref) (param $owner anyref) (param $carried anyref) (param $id i32) (param $key (ref null $str)) (param $value anyref) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $t (ref null $rec_ScopeTree))
    (local $c (ref null $rec_CellEntry))
    (local $frames (ref null $rec_Frame))
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    local.set $t
    local.get $t
    call $treeCells
    local.get $id
    call $cellOf
    local.set $c
    local.get $key
    local.get $value
    local.get $c
    call $entryFrames
    call $__new_32
    local.set $frames
    local.get $store
    local.get $t
    local.get $id
    local.get $frames
    local.get $c
    struct.get $rec_CellEntry $f2
    local.get $c
    call $entrySlot
    local.get $c
    struct.get $rec_CellEntry $f4
    local.get $c
    call $entryCounts
    ref.null any
    call $__new_28
    call $withCell
    call $storeSet
    i32.const 0
  )
  ;; The count of the values call `callNo` made before this one in cell `id`'s
  ;; current render; the cell counts this one (821 (1)).
  (func $countAt (param $store anyref) (param $owner anyref) (param $carried anyref) (param $id i32) (param $callNo i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $t (ref null $rec_ScopeTree))
    (local $c (ref null $rec_CellEntry))
    (local $n i32)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    local.set $t
    local.get $t
    call $treeCells
    local.get $id
    call $cellOf
    local.set $c
    local.get $c
    call $entryCounts
    local.get $callNo
    call $countIn
    local.set $n
    local.get $store
    local.get $t
    local.get $id
    local.get $c
    call $entryFrames
    local.get $c
    struct.get $rec_CellEntry $f2
    local.get $c
    call $entrySlot
    local.get $c
    struct.get $rec_CellEntry $f4
    local.get $callNo
    local.get $n
    i32.const 1
    global.get $__s13
    call $__i32_add_chk
    local.get $c
    call $entryCounts
    call $__new_36
    ref.null any
    call $__new_28
    call $withCell
    call $storeSet
    local.get $n
    return
  )
  ;; The latest count of call `callNo` in `counts`, else 0.
  (func $countIn (param $counts anyref) (param $callNo i32) (result i32)
    (local $cur anyref)
    (local $k (ref null $rec_PlaceCount))
    (local $__gc6 anyref)
    local.get $counts
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.set $__gc6
    local.get $__gc6
    ref.test (ref null $rec_PlaceCount)
    local.get $__gc6
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    local.get $cur
    ref.cast (ref null $rec_PlaceCount)
    local.set $k
    local.get $k
    struct.get $rec_PlaceCount $f0
    local.get $callNo
    i32.eq
    (if (result i32)
      (then
    local.get $k
    struct.get $rec_PlaceCount $f1
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $k
    call $countRest
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
    unreachable ;; a loop with no break never ends
  )
  (func $countRest (param $k (ref null $rec_PlaceCount)) (result anyref)
    local.get $k
    struct.get $rec_PlaceCount $f2
    return
  )
  ;; Cell `id`'s slot: what `make` answered on the cell's first render, kept
  ;; while the cell stands (816 (1), 818 (1)).
  (func $slotAt (param $store anyref) (param $owner anyref) (param $carried anyref) (param $id i32) (param $make (ref null $closure)) (result anyref)
    (local $__mem0 i32)
    (local $c (ref null $rec_CellEntry))
    (local $value anyref)
    (local $t (ref null $rec_ScopeTree))
    (local $now (ref null $rec_CellEntry))
    (local $__fnv0 (ref null $closure))
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    call $treeCells
    local.get $id
    call $cellOf
    local.set $c
    local.get $c
    struct.get $rec_CellEntry $f4
    (if (result anyref)
      (then
    local.get $c
    call $entrySlot
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $make
    local.set $__fnv0
    local.get $__fnv0
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_0)
    call_ref $sig_0
    local.set $value
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    local.set $t
    local.get $t
    call $treeCells
    local.get $id
    call $cellOf
    local.set $now
    local.get $store
    local.get $t
    local.get $id
    local.get $now
    call $entryFrames
    local.get $now
    struct.get $rec_CellEntry $f2
    local.get $value
    i32.const 1
    local.get $now
    call $entryCounts
    ref.null any
    call $__new_28
    call $withCell
    call $storeSet
    local.get $value
    return
  )
  ;; The root's tree closed; a closed one is left as it is.
  (func $closeStore (param $store anyref) (result i32)
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
    i32.const 1
    i32.const 0
    ref.null any
    ref.null any
    call $__new_42
    call $storeClose
    i32.const 0
  )
  (func $entryFrames (param $e (ref null $rec_CellEntry)) (result anyref)
    local.get $e
    struct.get $rec_CellEntry $f1
    return
  )
  (func $entrySlot (param $e (ref null $rec_CellEntry)) (result anyref)
    local.get $e
    struct.get $rec_CellEntry $f3
    return
  )
  (func $entryCounts (param $e (ref null $rec_CellEntry)) (result anyref)
    local.get $e
    struct.get $rec_CellEntry $f5
    return
  )
  (func $entryNext (param $e (ref null $rec_CellEntry)) (result anyref)
    local.get $e
    struct.get $rec_CellEntry $f6
    return
  )
  ;; ── resolving and running (decisions 809 (6), 815 (5), 819, 822, 825) ───────
  ;; Runs `c` over `scope` at `key` and hands back its answer as it came — a
  ;; value, or the task of a component that awaits —, nothing awaited inside.
  (func $resolve (export "resolve") (param $c (ref null $closure)) (param $scope (ref null $rec_Scope)) (param $key (ref null $rec_Place)) (result anyref)
    (local $__fnv0 (ref null $closure))
    i32.const 0
    (if (result anyref)
      (then
    unreachable ;; an arm under a behavior test no value passes (decision 810 (1))
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $c
    local.set $__fnv0
    local.get $__fnv0
    local.get $scope
    local.get $key
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_2)
    call_ref $sig_2
    return
  )
  ;; Runs a root: `c` resolved over `scope`, or over a root of its own that it
  ;; closes when `c` settles or fails (825 (1)), awaited only when it answered a
  ;; task (822, 823): `val page = await run(App());`.
  ;; @Async — a state machine (decision 392)
  (func $run (export "run") (param $c (ref null $closure)) (param $scope (ref null $rec_Scope)) (result (ref null $task))
    (local $__fr (ref null $frame0))
    struct.new_default $frame0 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $c
    struct.set $frame0 $s0
    local.get $__fr
    local.get $scope
    struct.set $frame0 $s1
    i32.const 0 ;; run__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $run__body (param $__task (ref null $task)) (result anyref)
    (local $c (ref null $closure))
    (local $scope (ref null $rec_Scope))
    (local $handed anyref)
    (local $root (ref null $rec_Scope))
    (local $r anyref)
    (local $__frame (ref null $frame0))
    (local $__seek i32)
    (local $__state i32)
    (local $__cnd0 i32)
    (local $__cnd1 i32)
    (local $__gc7 anyref)
    (local $__mtv2 anyref)
    (local $__mtm2 i32)
    (local $__aw1 anyref)
    (local $__defer_exc1 anyref)
    (local $__defer_ran1 i32)
    (local $__cnd3 i32)
    (local $__gc8 anyref)
    (local $__mtv4 anyref)
    (local $__mtm4 i32)
    (local $__aw2 anyref)
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame0)
    local.set $__frame
    local.get $__frame
    struct.get $frame0 $s0
    local.set $c
    local.get $__frame
    struct.get $frame0 $s1
    local.set $scope
    local.get $__frame
    struct.get $frame0 $s2
    local.set $handed
    local.get $__frame
    struct.get $frame0 $s3
    local.set $root
    local.get $__frame
    struct.get $frame0 $s4
    local.set $r
    local.get $__frame
    struct.get $frame0 $s5
    local.set $__cnd0
    local.get $__frame
    struct.get $frame0 $s6
    local.set $__cnd1
    local.get $__frame
    struct.get $frame0 $s7
    local.set $__gc7
    local.get $__frame
    struct.get $frame0 $s8
    local.set $__mtv2
    local.get $__frame
    struct.get $frame0 $s9
    local.set $__mtm2
    local.get $__frame
    struct.get $frame0 $s10
    local.set $__aw1
    local.get $__frame
    struct.get $frame0 $s11
    local.set $__defer_exc1
    local.get $__frame
    struct.get $frame0 $s12
    local.set $__defer_ran1
    local.get $__frame
    struct.get $frame0 $s13
    local.set $__cnd3
    local.get $__frame
    struct.get $frame0 $s14
    local.set $__gc8
    local.get $__frame
    struct.get $frame0 $s15
    local.set $__mtv4
    local.get $__frame
    struct.get $frame0 $s16
    local.set $__mtm4
    local.get $__frame
    struct.get $frame0 $s17
    local.set $__aw2
    local.get $__frame
    struct.get $frame0 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd0 ;; the condition, read back
      )
      (else
    local.get $scope
    ref.is_null
    i32.eqz
    local.tee $__cnd0
      )
    )
    (if (result anyref)
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
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd1 ;; the condition, read back
      )
      (else
    local.get $handed
    local.set $__gc7
    local.get $__gc7
    ref.test (ref null $task)
    local.get $__gc7
    ref.is_null
    i32.eqz
    i32.and
    local.tee $__cnd1
      )
    )
    (if (result anyref)
      (then
    (block $__aw1
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 1
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
    br $__aw1 ;; resumed here
      )
    )
    br $__aw1 ;; resuming past this await
      )
    )
    local.get $handed
    local.tee $__mtv2
    ref.test (ref null $task)
    local.set $__mtm2
    local.get $__mtv2
    local.set $__aw1
    local.get $__mtm2
    (if (result i32)
      (then
    local.get $__aw1
    ref.cast (ref null $task)
    call $__task_pending
      )
      (else
    i32.const 0
      )
    )
    (if
      (then
    local.get $__aw1
    ref.cast (ref null $task)
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $c
    struct.set $frame0 $s0
    local.get $__frame
    local.get $scope
    struct.set $frame0 $s1
    local.get $__frame
    local.get $handed
    struct.set $frame0 $s2
    local.get $__frame
    local.get $root
    struct.set $frame0 $s3
    local.get $__frame
    local.get $r
    struct.set $frame0 $s4
    local.get $__frame
    local.get $__cnd0
    struct.set $frame0 $s5
    local.get $__frame
    local.get $__cnd1
    struct.set $frame0 $s6
    local.get $__frame
    local.get $__gc7
    struct.set $frame0 $s7
    local.get $__frame
    local.get $__mtv2
    struct.set $frame0 $s8
    local.get $__frame
    local.get $__mtm2
    struct.set $frame0 $s9
    local.get $__frame
    local.get $__aw1
    struct.set $frame0 $s10
    local.get $__frame
    local.get $__defer_exc1
    struct.set $frame0 $s11
    local.get $__frame
    local.get $__defer_ran1
    struct.set $frame0 $s12
    local.get $__frame
    local.get $__cnd3
    struct.set $frame0 $s13
    local.get $__frame
    local.get $__gc8
    struct.set $frame0 $s14
    local.get $__frame
    local.get $__mtv4
    struct.set $frame0 $s15
    local.get $__frame
    local.get $__mtm4
    struct.set $frame0 $s16
    local.get $__frame
    local.get $__aw2
    struct.set $frame0 $s17
    local.get $__frame
    i32.const 1
    struct.set $frame0 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null any
    return ;; suspended
      )
    )
    )
    local.get $__mtm2
    (if (result anyref)
      (then
    local.get $__aw1
    ref.cast (ref null $task)
    struct.get $task $value ;; the settled value
      )
      (else
    local.get $__aw1
      )
    )
    return
      )
      (else
        ref.null any
      )
    )
    drop
      )
    )
    local.get $handed
    return
      )
      (else
        ref.null any
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
    (block $__defer_done1 (result anyref)
    (block $__defer_h1 (result anyref)
    i32.const 0
    local.set $__defer_ran1
    (try_table (result anyref) (catch $__bp_panic $__defer_h1)
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
    local.get $__state
    i32.const 2
    i32.ge_u
    local.get $__state
    i32.const 2
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd3 ;; the condition, read back
      )
      (else
    local.get $r
    local.set $__gc8
    local.get $__gc8
    ref.test (ref null $task)
    local.get $__gc8
    ref.is_null
    i32.eqz
    i32.and
    local.tee $__cnd3
      )
    )
    (if (result anyref)
      (then
    (block $__aw2
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 2
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
    br $__aw2 ;; resumed here
      )
    )
    br $__aw2 ;; resuming past this await
      )
    )
    local.get $r
    local.tee $__mtv4
    ref.test (ref null $task)
    local.set $__mtm4
    local.get $__mtv4
    local.set $__aw2
    local.get $__mtm4
    (if (result i32)
      (then
    local.get $__aw2
    ref.cast (ref null $task)
    call $__task_pending
      )
      (else
    i32.const 0
      )
    )
    (if
      (then
    local.get $__aw2
    ref.cast (ref null $task)
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $c
    struct.set $frame0 $s0
    local.get $__frame
    local.get $scope
    struct.set $frame0 $s1
    local.get $__frame
    local.get $handed
    struct.set $frame0 $s2
    local.get $__frame
    local.get $root
    struct.set $frame0 $s3
    local.get $__frame
    local.get $r
    struct.set $frame0 $s4
    local.get $__frame
    local.get $__cnd0
    struct.set $frame0 $s5
    local.get $__frame
    local.get $__cnd1
    struct.set $frame0 $s6
    local.get $__frame
    local.get $__gc7
    struct.set $frame0 $s7
    local.get $__frame
    local.get $__mtv2
    struct.set $frame0 $s8
    local.get $__frame
    local.get $__mtm2
    struct.set $frame0 $s9
    local.get $__frame
    local.get $__aw1
    struct.set $frame0 $s10
    local.get $__frame
    local.get $__defer_exc1
    struct.set $frame0 $s11
    local.get $__frame
    local.get $__defer_ran1
    struct.set $frame0 $s12
    local.get $__frame
    local.get $__cnd3
    struct.set $frame0 $s13
    local.get $__frame
    local.get $__gc8
    struct.set $frame0 $s14
    local.get $__frame
    local.get $__mtv4
    struct.set $frame0 $s15
    local.get $__frame
    local.get $__mtm4
    struct.set $frame0 $s16
    local.get $__frame
    local.get $__aw2
    struct.set $frame0 $s17
    local.get $__frame
    i32.const 2
    struct.set $frame0 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null any
    return ;; suspended
      )
    )
    )
    local.get $__mtm4
    (if (result anyref)
      (then
    local.get $__aw2
    ref.cast (ref null $task)
    struct.get $task $value ;; the settled value
      )
      (else
    local.get $__aw2
      )
    )
    i32.const 1
    local.set $__defer_ran1
    local.get $root
    call $Scope_close
    drop
    return
      )
      (else
        ref.null any
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
  (func $run__step (param $__task (ref null $task))
    (local $__v anyref)
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
    call $__task_settle
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
  (func $enter (export "enter") (param $scope anyref) (param $key anyref) (result anyref)
    (local $__gc9 anyref)
    (local $__gc10 anyref)
    local.get $scope
    local.set $__gc9
    local.get $__gc9
    ref.test (ref null $rec_Scope)
    local.get $__gc9
    ref.is_null
    i32.eqz
    i32.and
    (if (result anyref)
      (then
    local.get $key
    local.set $__gc10
    local.get $__gc10
    ref.test (ref null $rec_Place)
    local.get $__gc10
    ref.is_null
    i32.eqz
    i32.and
    (if (result anyref)
      (then
    local.get $scope
    ref.cast (ref null $rec_Scope)
    local.get $key
    ref.cast (ref null $rec_Place)
    call $Scope_childAt
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $scope
    ref.cast (ref null $rec_Scope)
    call $Place_none
    call $Scope_childAt
    return
      )
      (else
        ref.null any
      )
    )
    drop
    global.get $__s14
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null any
  )
  ;; The contexts `cell` holds now — what a body's `use context` reads.
  (func $received (export "received") (param $cell anyref) (result anyref)
    (local $__gc11 anyref)
    local.get $cell
    local.set $__gc11
    local.get $__gc11
    ref.test (ref null $rec_Scope)
    local.get $__gc11
    ref.is_null
    i32.eqz
    i32.and
    (if (result anyref)
      (then
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_storeRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_ownerRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_carriedRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_cellId
    call $framesAt
    return
      )
      (else
        ref.null any
      )
    )
    drop
    global.get $__s14
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null any
  )
  ;; `value` provided for `key` in `cell`: what is resolved under it afterwards
  ;; reads it (809 (8), 812 (3)).
  (func $provideIn (export "provideIn") (param $cell anyref) (param $key (ref null $str)) (param $value anyref) (result anyref)
    (local $__gc12 anyref)
    local.get $cell
    local.set $__gc12
    local.get $__gc12
    ref.test (ref null $rec_Scope)
    local.get $__gc12
    ref.is_null
    i32.eqz
    i32.and
    (if (result anyref)
      (then
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_storeRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_ownerRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_carriedRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_cellId
    local.get $key
    local.get $value
    call $provideAt
    drop
    ref.null any
    return
      )
      (else
        ref.null any
      )
    )
    drop
    global.get $__s14
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null any
  )
  ;; The value provided nearest above for `key` in `frames`, else `fallback` —
  ;; the type's declared default (decision 378 (3): no read is unbound).
  ;; The two `unknown` fields are read through `frameValue` / `frameParent`: wasm boxes a field read as `unknown` only as a function's answer.
  (func $find (export "find") (param $frames anyref) (param $key (ref null $str)) (param $fallback anyref) (result anyref)
    (local $__mem0 i32)
    (local $cur anyref)
    (local $f (ref null $rec_Frame))
    (local $__gc13 anyref)
    local.get $frames
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.set $__gc13
    local.get $__gc13
    ref.test (ref null $rec_Frame)
    local.get $__gc13
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    local.get $cur
    ref.cast (ref null $rec_Frame)
    local.set $f
    local.get $f
    struct.get $rec_Frame $f0
    local.get $key
    call $__str_eq
    (if (result anyref)
      (then
    local.get $f
    call $frameValue
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $f
    call $frameParent
    local.set $cur
    i32.const 0
      )
      (else
    local.get $key
    local.get $fallback
    ref.null any
    call $__new_32
    call $frameValue
    return
      )
    )
    drop
        br $__continue
      )
    )
    unreachable ;; a loop with no break never ends
  )
  ;; A body's answer, as it is (the word wasm moves through it, decision 504).
  (func $answer (export "answer") (param $value anyref) (result anyref)
    local.get $value
    return
  )
  ;; The place a `use` passes (820 (2)).
  (func $nowhere (export "nowhere") (result anyref)
    call $Place_none
    return
  )
  ;; A fresh root, for a `use` written outside every component body.
  (func $root (export "root") (result anyref)
    call $Scope_root
    return
  )
  ;; ── the stamp (decisions 820, 821, 818 (3)) ──────────────────────────────────
  ;; 
  ;; Each written call answering a component answers its value carrying its
  ;; place: `stamp(c, <the body's cell>, n)` in a component body, the item the
  ;; count of the values call `n` made in the body's current render;
  ;; `stampPlain(c, <the entry's counter>, n)` in a plain function, counted in
  ;; that entry (`countNew` at its entry, `countEnd` deferred); `stampKeyed(c,
  ;; n, k)` for `#[key(k)]`. The place travels in the value: run with a
  ;; runner's place it is `mine.with(key)`; a place another stamp already wrote
  ;; passes through, so the stamp written last — the outer call's — wins
  ;; (821 (2)).
  (func $stamp (export "stamp") (param $c (ref null $closure)) (param $cell anyref) (param $callNo i32) (result (ref null $closure))
    (local $__mem0 i32)
    (local $__gc14 anyref)
    local.get $cell
    local.set $__gc14
    local.get $__gc14
    ref.test (ref null $rec_Scope)
    local.get $__gc14
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $closure))
      (then
    local.get $c
    local.get $callNo
    i32.const 1 ;; PlaceItem.Body
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_storeRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_ownerRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_carriedRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_cellId
    local.get $callNo
    call $countAt
    ref.null any
    i32.const 1
    call $__new_34
    call $placed
    return
      )
      (else
        ref.null $closure
      )
    )
    drop
    global.get $__s14
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null $closure
  )
  (func $stampPlain (export "stampPlain") (param $c (ref null $closure)) (param $counter anyref) (param $callNo i32) (result (ref null $closure))
    (local $__mem0 i32)
    local.get $c
    local.get $callNo
    i32.const 2 ;; PlaceItem.Plain
    local.get $counter
    local.get $callNo
    call $countNext
    ref.null any
    i32.const 1
    call $__new_34
    call $placed
    return
  )
  (func $stampKeyed (export "stampKeyed") (param $c (ref null $closure)) (param $callNo i32) (param $k anyref) (result (ref null $closure))
    (local $__mem0 i32)
    local.get $c
    local.get $callNo
    i32.const 4 ;; PlaceItem.Key
    i32.const 0
    local.get $k
    i32.const 1
    call $__new_34
    call $placed
    return
  )
  ;; `c` carrying `mine`.
  (func $placed (param $c (ref null $closure)) (param $mine (ref null $rec_Place)) (result (ref null $closure))
    ref.func $__lambda0
    i32.const 2 ;; arity
    i32.const 0
    local.get $c ;; capture c
    local.get $mine ;; capture mine
    struct.new $env0
    return
  )
  ;; `use memo(make)` written as call `callNo` of a body: the slot of its own
  ;; child cell (818 (1)), filled on that cell's first render.
  (func $memoIn (export "memoIn") (param $cell anyref) (param $callNo i32) (param $make (ref null $closure)) (result anyref)
    (local $__mem0 i32)
    (local $child (ref null $rec_Scope))
    (local $__gc15 anyref)
    local.get $cell
    local.set $__gc15
    local.get $__gc15
    ref.test (ref null $rec_Scope)
    local.get $__gc15
    ref.is_null
    i32.eqz
    i32.and
    (if (result anyref)
      (then
    local.get $cell
    ref.cast (ref null $rec_Scope)
    local.get $callNo
    i32.const 1 ;; PlaceItem.Body
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_storeRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_ownerRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_carriedRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_cellId
    local.get $callNo
    call $countAt
    ref.null any
    i32.const 1
    call $__new_34
    call $Scope_childAt
    local.set $child
    local.get $child
    call $Scope_storeRef
    local.get $child
    call $Scope_ownerRef
    local.get $child
    call $Scope_carriedRef
    local.get $child
    call $Scope_cellId
    local.get $make
    call $slotAt
    return
      )
      (else
        ref.null any
      )
    )
    drop
    global.get $__s14
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null any
  )
  ;; `use all(cs)` written as call `callNo` of a body (827, 884): entry `i` run
  ;; under `all`'s own child cell at `Place.index(i)`, in order; the answers as
  ;; a list, or the task of the list once each settled in order when an entry
  ;; answered a task.
  (func $allIn (export "allIn") (param $cell anyref) (param $callNo i32) (param $cs (ref null $arr_any)) (result anyref)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $child (ref null $rec_Scope))
    (local $answers (ref null $arr_any))
    (local $waits i32)
    (local $i i32)
    (local $r anyref)
    (local $__bp_opt_574_34 i32)
    (local $__gc16 anyref)
    (local $__opt0 (ref null $closure))
    (local $__bp_opt_574_34__2 (ref null $closure))
    (local $__gc17 anyref)
    local.get $cell
    local.set $__gc16
    local.get $__gc16
    ref.test (ref null $rec_Scope)
    local.get $__gc16
    ref.is_null
    i32.eqz
    i32.and
    (if (result anyref)
      (then
    local.get $cell
    ref.cast (ref null $rec_Scope)
    local.get $callNo
    i32.const 1 ;; PlaceItem.Body
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_storeRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_ownerRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_carriedRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_cellId
    local.get $callNo
    call $countAt
    ref.null any
    i32.const 1
    call $__new_34
    call $Scope_childAt
    local.set $child
    array.new_fixed $arr_any 0
    local.set $answers
    i32.const 0
    local.set $waits
    i32.const 0
    local.set $i
    (block $__break
      (loop $__continue
        local.get $i
    local.get $cs
    array.len
        i32.ge_s
        br_if $__break
    local.get $cs
    local.get $i
    call $__arr_at_opt_any
    ref.cast (ref null $closure)
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $closure))
      (then
    local.get $__opt0
    local.set $__bp_opt_574_34__2
    local.get $__bp_opt_574_34__2
      )
      (else
    global.get $__s15
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null $closure
      )
    )
    local.get $child
    local.get $i
    call $Place_index
    call $resolve__T_unknown
    local.set $r
    local.get $r
    local.set $__gc17
    local.get $__gc17
    ref.test (ref null $task)
    local.get $__gc17
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    i32.const 1
    local.set $waits
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $answers
    local.get $r
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $answers
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $waits
    (if (result anyref)
      (then
    local.get $answers
    call $settled
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $answers
    return
      )
      (else
        ref.null any
      )
    )
    drop
    global.get $__s14
    i32.const 1
    call $__panic_raise
    unreachable
    ref.null any
  )
  ;; Each of `answers` awaited in order where it is a task.
  ;; @Async — a state machine (decision 392)
  (func $settled (param $answers (ref null $arr_any)) (result (ref null $task))
    (local $__fr (ref null $frame1))
    struct.new_default $frame1 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $answers
    struct.set $frame1 $s0
    i32.const 1 ;; settled__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $settled__body (param $__task (ref null $task)) (result (ref null $arr_any))
    (local $answers (ref null $arr_any))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $out (ref null $arr_any))
    (local $r i32)
    (local $v anyref)
    (local $__frame (ref null $frame1))
    (local $__seek i32)
    (local $__state i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $r__sh0 anyref)
    (local $__cnd1 i32)
    (local $__gc18 anyref)
    (local $__mtv2 anyref)
    (local $__mtm2 i32)
    (local $__aw1 anyref)
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame1)
    local.set $__frame
    local.get $__frame
    struct.get $frame1 $s0
    local.set $answers
    local.get $__frame
    struct.get $frame1 $s1
    local.set $__mem0
    local.get $__frame
    struct.get $frame1 $s2
    local.set $__mem1
    local.get $__frame
    struct.get $frame1 $s3
    local.set $__mem2
    local.get $__frame
    struct.get $frame1 $s4
    local.set $out
    local.get $__frame
    struct.get $frame1 $s5
    local.set $r
    local.get $__frame
    struct.get $frame1 $s6
    local.set $v
    local.get $__frame
    struct.get $frame1 $s7
    local.set $__iter0
    local.get $__frame
    struct.get $frame1 $s8
    local.set $__idx0
    local.get $__frame
    struct.get $frame1 $s9
    local.set $__len0
    local.get $__frame
    struct.get $frame1 $s10
    local.set $r__sh0
    local.get $__frame
    struct.get $frame1 $s11
    local.set $__cnd1
    local.get $__frame
    struct.get $frame1 $s12
    local.set $__gc18
    local.get $__frame
    struct.get $frame1 $s13
    local.set $__mtv2
    local.get $__frame
    struct.get $frame1 $s14
    local.set $__mtm2
    local.get $__frame
    struct.get $frame1 $s15
    local.set $__aw1
    local.get $__frame
    struct.get $frame1 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    array.new_fixed $arr_any 0
    local.set $out
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $answers
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
      )
    )
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
        local.set $r__sh0
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd1 ;; the condition, read back
      )
      (else
    local.get $r__sh0
    local.set $__gc18
    local.get $__gc18
    ref.test (ref null $task)
    local.get $__gc18
    ref.is_null
    i32.eqz
    i32.and
    local.tee $__cnd1
      )
    )
    (if
      (then
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    (block $__aw1
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 1
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
    br $__aw1 ;; resumed here
      )
    )
    br $__aw1 ;; resuming past this await
      )
    )
    local.get $r__sh0
    local.tee $__mtv2
    ref.test (ref null $task)
    local.set $__mtm2
    local.get $__mtv2
    local.set $__aw1
    local.get $__mtm2
    (if (result i32)
      (then
    local.get $__aw1
    ref.cast (ref null $task)
    call $__task_pending
      )
      (else
    i32.const 0
      )
    )
    (if
      (then
    local.get $__aw1
    ref.cast (ref null $task)
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $answers
    struct.set $frame1 $s0
    local.get $__frame
    local.get $__mem0
    struct.set $frame1 $s1
    local.get $__frame
    local.get $__mem1
    struct.set $frame1 $s2
    local.get $__frame
    local.get $__mem2
    struct.set $frame1 $s3
    local.get $__frame
    local.get $out
    struct.set $frame1 $s4
    local.get $__frame
    local.get $r
    struct.set $frame1 $s5
    local.get $__frame
    local.get $v
    struct.set $frame1 $s6
    local.get $__frame
    local.get $__iter0
    struct.set $frame1 $s7
    local.get $__frame
    local.get $__idx0
    struct.set $frame1 $s8
    local.get $__frame
    local.get $__len0
    struct.set $frame1 $s9
    local.get $__frame
    local.get $r__sh0
    struct.set $frame1 $s10
    local.get $__frame
    local.get $__cnd1
    struct.set $frame1 $s11
    local.get $__frame
    local.get $__gc18
    struct.set $frame1 $s12
    local.get $__frame
    local.get $__mtv2
    struct.set $frame1 $s13
    local.get $__frame
    local.get $__mtm2
    struct.set $frame1 $s14
    local.get $__frame
    local.get $__aw1
    struct.set $frame1 $s15
    local.get $__frame
    i32.const 1
    struct.set $frame1 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $arr_any
    return ;; suspended
      )
    )
    )
    local.get $__mtm2
    (if (result anyref)
      (then
    local.get $__aw1
    ref.cast (ref null $task)
    struct.get $task $value ;; the settled value
      )
      (else
    local.get $__aw1
      )
    )
    local.set $v
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $out
    local.get $v
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $out
      )
    )
      )
      (else
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $out
    local.get $r__sh0
    array.new_fixed $arr_any 1
    call $__arr_concat_any
    local.set $out
      )
    )
      )
    )
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
      )
    )
    local.get $out
    return
  )
  (func $settled__step (param $__task (ref null $task))
    (local $__v (ref null $arr_any))
    local.get $__task
    call $settled__body
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
    call $__task_settle
  )
  ;; A plain function entry's counter of the values each of its calls made
  ;; (821 (2)).
  (func $countNew (export "countNew") (result anyref)
    call $countCellNew
    return
  )
  ;; The entry's counter gone: on erlang and beam its process-dictionary entry.
  (func $countEnd (export "countEnd") (param $counter anyref) (result i32)
    local.get $counter
    ref.null any
    call $countCellEnd
    i32.const 0
  )
  ;; The count of the values call `callNo` made before this one in the entry.
  (func $countNext (param $counter anyref) (param $callNo i32) (result i32)
    (local $__mem0 i32)
    (local $counts anyref)
    (local $n i32)
    local.get $counter
    call $countCellFilled
    (if (result anyref)
      (then
    local.get $counter
    call $countCellGet
      )
      (else
    ref.null any
      )
    )
    local.set $counts
    local.get $counts
    local.get $callNo
    call $countIn
    local.set $n
    local.get $counter
    local.get $callNo
    local.get $n
    i32.const 1
    global.get $__s16
    call $__i32_add_chk
    local.get $counts
    call $__new_36
    call $countCellSet
    local.get $n
    return
  )
  (func $frameValue (param $f (ref null $rec_Frame)) (result anyref)
    local.get $f
    struct.get $rec_Frame $f1
    return
  )
  (func $frameParent (param $f (ref null $rec_Frame)) (result anyref)
    local.get $f
    struct.get $rec_Frame $f2
    return
  )
  ;; ── the store's host side (decision 824) ─────────────────────────────────────
  ;; Two keys compared by value (818 (3)).
  (func $sameKey (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    local.get $b
    call $__unk_eq
    return
  )
  ;; countCellNew — .Wasm(wasi: .CellNew)
  (func $countCellNew (result anyref)
    call $__memo_cell_new
  )
  ;; countCellFilled — .Wasm(wasi: .CellFilled)
  (func $countCellFilled (param $counter anyref) (result i32)
    local.get $counter
    call $__memo_cell_filled
  )
  ;; countCellGet — .Wasm(wasi: .CellGet)
  (func $countCellGet (param $counter anyref) (result anyref)
    local.get $counter
    call $__memo_cell_get
  )
  ;; countCellSet — .Wasm(wasi: .CellSet)
  (func $countCellSet (param $counter anyref) (param $value anyref)
    local.get $counter
    local.get $value
    call $__memo_cell_set
  )
  ;; countCellEnd — .Wasm(wasi: .CellSet)
  (func $countCellEnd (param $counter anyref) (param $gone anyref)
    local.get $counter
    local.get $gone
    call $__memo_cell_set
  )
  ;; storeNew — .Wasm(wasi: .CellNew)
  (func $storeNew (result anyref)
    call $__memo_cell_new
  )
  ;; storeLive — .Wasm(wasi: .CellFilled)
  (func $storeLive (param $store anyref) (result i32)
    local.get $store
    call $__memo_cell_filled
  )
  ;; storeGet — .Wasm(wasi: .CellGet)
  (func $storeGet (param $store anyref) (result anyref)
    local.get $store
    call $__memo_cell_get
  )
  ;; storeSet — .Wasm(wasi: .CellSet)
  (func $storeSet (param $store anyref) (param $value anyref)
    local.get $store
    local.get $value
    call $__memo_cell_set
  )
  ;; The closed tree written over the root's: on erlang and beam the entry goes
  ;; instead, so the process keeps no `{bp_scope, _}` (825 (2), (3)).
  ;; storeClose — .Wasm(wasi: .CellSet)
  (func $storeClose (param $store anyref) (param $closed anyref)
    local.get $store
    local.get $closed
    call $__memo_cell_set
  )
  ;; The process a root is made in: its pid on erlang and beam; elsewhere one
  ;; process holds every root, and a token no test reads stands for it.
  ;; ownerSelf — .Wasm(wasi: .CellNew)
  (func $ownerSelf (result anyref)
    call $__memo_cell_new
  )
  ;; Whether `owner` is another process than this one: never off the BEAM (an
  ;; owner token there is an empty cell).
  ;; ownerForeign — .Wasm(wasi: .CellFilled)
  (func $ownerForeign (param $owner anyref) (result i32)
    local.get $owner
    call $__memo_cell_filled
  )
  (func $resolve__T_unknown (param $c (ref null $closure)) (param $scope (ref null $rec_Scope)) (param $key (ref null $rec_Place)) (result anyref)
    (local $__fnv0 (ref null $closure))
    i32.const 0
    (if (result anyref)
      (then
    unreachable ;; an arm under a behavior test no value passes (decision 810 (1))
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $c
    local.set $__fnv0
    local.get $__fnv0
    local.get $scope
    local.get $key
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_2)
    call_ref $sig_2
    return
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (param $scope (ref null $rec_Scope)) (param $key (ref null $rec_Place)) (result anyref)
    (local $c (ref null $closure))
    (local $mine (ref null $rec_Place))
    local.get $__env
    struct.get $env0 $c0
    local.set $c
    local.get $__env
    struct.get $env0 $c1
    local.set $mine
    local.get $c
    local.get $scope
    local.get $key
    struct.get $rec_Place $f4
    (if (result (ref null $rec_Place))
      (then
    local.get $key
      )
      (else
    local.get $mine
    local.get $key
    call $Place_with
      )
    )
    call $resolve
  )
  (func $__lambda0 (type $sig_2) (param $__env (ref null $closure)) (param $__a0 anyref) (param $__a1 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    local.get $__a0
    ref.cast (ref null $rec_Scope)
    local.get $__a1
    ref.cast (ref null $rec_Place)
    call $__lambda0__b
  )
  (func $__unk_int_in (param $v anyref) (param $lo i32) (param $hi i32) (result i32)
    (local $k i32)
    (local $x f64)
    local.get $v
    ref.is_null
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_bool)
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.tee $k
    local.get $lo
    i32.ge_s
    local.get $k
    local.get $hi
    i32.le_s
    i32.and
    return
      )
    )
    local.get $v
    ref.test (ref null $box_f64)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    local.tee $x
    f64.floor
    local.get $x
    f64.ne
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $x
    local.get $lo
    f64.convert_i32_s
    f64.ge
    local.get $x
    local.get $hi
    f64.convert_i32_s
    f64.le
    i32.and
  )
  (func $__unk_as_i32 (param $v anyref) (result i32)
    local.get $v
    ref.test (ref null $box_f64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    i32.trunc_f64_s
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
  )
  (func $__arr_at_opt_any (param $xs (ref null $arr_any)) (param $i i32) (result anyref)
    local.get $i
    i32.const 0
    i32.lt_s
    (if
      (then
    local.get $i
    local.get $xs
    array.len
    i32.add
    local.set $i
      )
    )
    local.get $i
    i32.const 0
    i32.lt_s
    local.get $i
    local.get $xs
    array.len
    i32.ge_s
    i32.or
    (if (result anyref)
      (then
    ref.null any
      )
      (else
    local.get $xs
    local.get $i
    array.get $arr_any
      )
    )
  )
  (func $__arr_concat_any (param $xs (ref null $arr_any)) (param $ys (ref null $arr_any)) (result (ref null $arr_any))
    (local $la i32)
    (local $lb i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $la
    local.get $ys
    array.len
    local.set $lb
    local.get $la
    local.get $lb
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $la
    array.copy $arr_any $arr_any
    local.get $r
    local.get $la
    local.get $ys
    i32.const 0
    local.get $lb
    array.copy $arr_any $arr_any
    local.get $r
  )
  (func $__unk_is_num (param $v anyref) (result i32)
    local.get $v
    ref.is_null
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    local.get $v
    ref.test (ref null $box_bool)
    i32.eqz
    i32.and
    local.get $v
    ref.test (ref null $box_f64)
    i32.or
  )
  (func $__unk_as_f64 (param $v anyref) (result f64)
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    f64.convert_i32_s
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
  )
  (func $__unk_eq (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    call $__unk_is_num
    local.get $b
    call $__unk_is_num
    i32.and
    (if
      (then
    local.get $a
    call $__unk_as_f64
    local.get $b
    call $__unk_as_f64
    f64.eq
    return
      )
    )
    local.get $a
    ref.test (ref null $str)
    local.get $a
    ref.is_null
    i32.eqz
    i32.and
    local.get $b
    ref.test (ref null $str)
    i32.and
    local.get $b
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $a
    ref.cast (ref null $str)
    local.get $b
    ref.cast (ref null $str)
    call $__str_eq
    return
      )
    )
    local.get $a
    ref.test (ref null $box_bool)
    local.get $a
    ref.is_null
    i32.eqz
    i32.and
    local.get $b
    ref.test (ref null $box_bool)
    i32.and
    local.get $b
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $a
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $b
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    i32.eq
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__unk_print_q (param $v anyref)
    local.get $v
    ref.is_null
    (if
      (then
    global.get $__s20
    call $__print_str_raw
    return
      )
    )
    local.get $v
    call $__print_ebox
    (if
      (then
    return
      )
    )
    local.get $v
    call $__print_arrs
    (if
      (then
    return
      )
    )
    local.get $v
    ref.test (ref null $box_bool)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_bool)
    struct.get $box_bool $v
    call $__print_bool_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_f64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    call $__print_f64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_u64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_u64)
    struct.get $box_u64 $v
    call $__print_u64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    call $__print_i64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $str)
    (if
      (then
    local.get $v
    ref.cast (ref null $str)
    call $__print_quoted_raw
    return
      )
    )
    local.get $v
    call $__print_tagged_raw
  )
  (func $__pr1 (param $v anyref)
    local.get $v
    call $__unk_print_q
  )
  (func $__pr0 (param $v (ref null $rec_Context))
    global.get $__s17
    call $__print_str_raw
    global.get $__s18
    call $__print_str_raw
    global.get $__s19
    call $__print_str_raw
    local.get $v
    struct.get $rec_Context $f0
    call $__pr1
    global.get $__s21
    call $__print_str_raw
  )
  (func $__tip1 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Context)
    call $__pr0
  )
  (func $__tie1 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Context)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr3 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr4 (param $v i32)
    local.get $v
    i32.const 0
    i32.eq
    (if
      (then
    global.get $__s26
    call $__print_str_raw
    return
      )
    )
    local.get $v
    i32.const 1
    i32.eq
    (if
      (then
    global.get $__s27
    call $__print_str_raw
    return
      )
    )
    local.get $v
    i32.const 2
    i32.eq
    (if
      (then
    global.get $__s28
    call $__print_str_raw
    return
      )
    )
    local.get $v
    i32.const 3
    i32.eq
    (if
      (then
    global.get $__s29
    call $__print_str_raw
    return
      )
    )
    local.get $v
    i32.const 4
    i32.eq
    (if
      (then
    global.get $__s30
    call $__print_str_raw
    return
      )
    )
  )
  (func $__pr5 (param $v i32)
    local.get $v
    call $__print_bool_raw
  )
  (func $__pr2 (param $v (ref null $rec_Place))
    global.get $__s23
    call $__print_str_raw
    global.get $__s18
    call $__print_str_raw
    global.get $__s24
    call $__print_str_raw
    local.get $v
    struct.get $rec_Place $f0
    call $__pr3
    global.get $__s25
    call $__print_str_raw
    local.get $v
    struct.get $rec_Place $f1
    call $__pr4
    global.get $__s31
    call $__print_str_raw
    local.get $v
    struct.get $rec_Place $f2
    call $__pr3
    global.get $__s32
    call $__print_str_raw
    local.get $v
    struct.get $rec_Place $f3
    call $__pr1
    global.get $__s33
    call $__print_str_raw
    local.get $v
    struct.get $rec_Place $f4
    call $__pr5
    global.get $__s21
    call $__print_str_raw
  )
  (func $__tip4 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Place)
    call $__pr2
  )
  (func $__tie4 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Place)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr6 (param $v (ref null $rec_Scope))
    global.get $__s35
    call $__print_str_raw
    global.get $__s18
    call $__print_str_raw
    global.get $__s36
    call $__print_str_raw
    local.get $v
    struct.get $rec_Scope $f0
    call $__pr1
    global.get $__s37
    call $__print_str_raw
    local.get $v
    struct.get $rec_Scope $f1
    call $__pr3
    global.get $__s38
    call $__print_str_raw
    local.get $v
    struct.get $rec_Scope $f2
    call $__pr1
    global.get $__s39
    call $__print_str_raw
    local.get $v
    struct.get $rec_Scope $f3
    call $__pr1
    global.get $__s21
    call $__print_str_raw
  )
  (func $__tip5 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Scope)
    call $__pr6
  )
  (func $__tie5 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Scope)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr7 (param $v (ref null $rec_Carried))
    global.get $__s41
    call $__print_str_raw
    global.get $__s18
    call $__print_str_raw
    global.get $__s42
    call $__print_str_raw
    local.get $v
    struct.get $rec_Carried $f0
    call $__pr1
    global.get $__s21
    call $__print_str_raw
  )
  (func $__tip6 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Carried)
    call $__pr7
  )
  (func $__tie6 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Carried)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr8 (param $v (ref null $rec_CellEntry))
    global.get $__s44
    call $__print_str_raw
    global.get $__s18
    call $__print_str_raw
    global.get $__s45
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f0
    call $__pr3
    global.get $__s46
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f1
    call $__pr1
    global.get $__s47
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f2
    call $__pr3
    global.get $__s48
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f3
    call $__pr1
    global.get $__s49
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f4
    call $__pr5
    global.get $__s50
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f5
    call $__pr1
    global.get $__s51
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f6
    call $__pr1
    global.get $__s21
    call $__print_str_raw
  )
  (func $__tip7 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_CellEntry)
    call $__pr8
  )
  (func $__tie7 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_CellEntry)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr9 (param $v (ref null $rec_ScopeTree))
    global.get $__s53
    call $__print_str_raw
    global.get $__s18
    call $__print_str_raw
    global.get $__s54
    call $__print_str_raw
    local.get $v
    struct.get $rec_ScopeTree $f0
    call $__pr5
    global.get $__s55
    call $__print_str_raw
    local.get $v
    struct.get $rec_ScopeTree $f1
    call $__pr3
    global.get $__s56
    call $__print_str_raw
    local.get $v
    struct.get $rec_ScopeTree $f2
    call $__pr1
    global.get $__s57
    call $__print_str_raw
    local.get $v
    struct.get $rec_ScopeTree $f3
    call $__pr1
    global.get $__s21
    call $__print_str_raw
  )
  (func $__tip8 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_ScopeTree)
    call $__pr9
  )
  (func $__tie8 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_ScopeTree)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr11 (param $v anyref)
    local.get $v
    call $__print_tagged_raw
  )
  (func $__pr10 (param $v (ref null $rec_PlaceLink))
    global.get $__s59
    call $__print_str_raw
    global.get $__s18
    call $__print_str_raw
    global.get $__s60
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceLink $f0
    call $__pr3
    global.get $__s61
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceLink $f1
    call $__pr11
    global.get $__s62
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceLink $f2
    call $__pr3
    global.get $__s63
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceLink $f3
    call $__pr3
    global.get $__s64
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceLink $f4
    call $__pr1
    global.get $__s21
    call $__print_str_raw
  )
  (func $__tip9 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_PlaceLink)
    call $__pr10
  )
  (func $__tie9 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_PlaceLink)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr13 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr12 (param $v (ref null $rec_Frame))
    global.get $__s66
    call $__print_str_raw
    global.get $__s18
    call $__print_str_raw
    global.get $__s67
    call $__print_str_raw
    local.get $v
    struct.get $rec_Frame $f0
    call $__pr13
    global.get $__s68
    call $__print_str_raw
    local.get $v
    struct.get $rec_Frame $f1
    call $__pr1
    global.get $__s69
    call $__print_str_raw
    local.get $v
    struct.get $rec_Frame $f2
    call $__pr1
    global.get $__s21
    call $__print_str_raw
  )
  (func $__tip13 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Frame)
    call $__pr12
  )
  (func $__tie13 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Frame)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr14 (param $v (ref null $rec_PlaceCount))
    global.get $__s71
    call $__print_str_raw
    global.get $__s18
    call $__print_str_raw
    global.get $__s72
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceCount $f0
    call $__pr3
    global.get $__s73
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceCount $f1
    call $__pr3
    global.get $__s74
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceCount $f2
    call $__pr1
    global.get $__s21
    call $__print_str_raw
  )
  (func $__tip14 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_PlaceCount)
    call $__pr14
  )
  (func $__tie14 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_PlaceCount)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__unk_eq_s1 (param $a (ref null $rec_Context)) (param $b (ref null $rec_Context)) (result i32)
    local.get $a
    struct.get $rec_Context $f0
    local.get $b
    struct.get $rec_Context $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_arr_any (param $a (ref null $arr_any)) (param $b (ref null $arr_any)) (result i32)
    (local $i i32)
    local.get $a
    array.len
    local.get $b
    array.len
    i32.ne
    (if
      (then
    i32.const 0
    return
      )
    )
    (block $brk
    (loop $cont
    local.get $i
    local.get $a
    array.len
    i32.ge_u
    br_if $brk
    local.get $a
    local.get $i
    array.get $arr_any
    local.get $b
    local.get $i
    array.get $arr_any
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    i32.const 1
  )
  (func $__unk_eq_s4 (param $a (ref null $rec_Place)) (param $b (ref null $rec_Place)) (result i32)
    local.get $a
    struct.get $rec_Place $f0
    local.get $b
    struct.get $rec_Place $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Place $f1
    local.get $b
    struct.get $rec_Place $f1
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Place $f2
    local.get $b
    struct.get $rec_Place $f2
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Place $f3
    local.get $b
    struct.get $rec_Place $f3
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Place $f4
    local.get $b
    struct.get $rec_Place $f4
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s5 (param $a (ref null $rec_Scope)) (param $b (ref null $rec_Scope)) (result i32)
    local.get $a
    struct.get $rec_Scope $f0
    local.get $b
    struct.get $rec_Scope $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Scope $f1
    local.get $b
    struct.get $rec_Scope $f1
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Scope $f2
    local.get $b
    struct.get $rec_Scope $f2
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Scope $f3
    local.get $b
    struct.get $rec_Scope $f3
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s6 (param $a (ref null $rec_Carried)) (param $b (ref null $rec_Carried)) (result i32)
    local.get $a
    struct.get $rec_Carried $f0
    local.get $b
    struct.get $rec_Carried $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s7 (param $a (ref null $rec_CellEntry)) (param $b (ref null $rec_CellEntry)) (result i32)
    local.get $a
    struct.get $rec_CellEntry $f0
    local.get $b
    struct.get $rec_CellEntry $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f1
    local.get $b
    struct.get $rec_CellEntry $f1
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f2
    local.get $b
    struct.get $rec_CellEntry $f2
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f3
    local.get $b
    struct.get $rec_CellEntry $f3
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f4
    local.get $b
    struct.get $rec_CellEntry $f4
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f5
    local.get $b
    struct.get $rec_CellEntry $f5
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f6
    local.get $b
    struct.get $rec_CellEntry $f6
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s8 (param $a (ref null $rec_ScopeTree)) (param $b (ref null $rec_ScopeTree)) (result i32)
    local.get $a
    struct.get $rec_ScopeTree $f0
    local.get $b
    struct.get $rec_ScopeTree $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_ScopeTree $f1
    local.get $b
    struct.get $rec_ScopeTree $f1
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_ScopeTree $f2
    local.get $b
    struct.get $rec_ScopeTree $f2
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_ScopeTree $f3
    local.get $b
    struct.get $rec_ScopeTree $f3
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s9 (param $a (ref null $rec_PlaceLink)) (param $b (ref null $rec_PlaceLink)) (result i32)
    local.get $a
    struct.get $rec_PlaceLink $f0
    local.get $b
    struct.get $rec_PlaceLink $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceLink $f1
    local.get $b
    struct.get $rec_PlaceLink $f1
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceLink $f2
    local.get $b
    struct.get $rec_PlaceLink $f2
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceLink $f3
    local.get $b
    struct.get $rec_PlaceLink $f3
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceLink $f4
    local.get $b
    struct.get $rec_PlaceLink $f4
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s13 (param $a (ref null $rec_Frame)) (param $b (ref null $rec_Frame)) (result i32)
    local.get $a
    struct.get $rec_Frame $f0
    local.get $b
    struct.get $rec_Frame $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Frame $f1
    local.get $b
    struct.get $rec_Frame $f1
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Frame $f2
    local.get $b
    struct.get $rec_Frame $f2
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s14 (param $a (ref null $rec_PlaceCount)) (param $b (ref null $rec_PlaceCount)) (result i32)
    local.get $a
    struct.get $rec_PlaceCount $f0
    local.get $b
    struct.get $rec_PlaceCount $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceCount $f1
    local.get $b
    struct.get $rec_PlaceCount $f1
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceCount $f2
    local.get $b
    struct.get $rec_PlaceCount $f2
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s21 (param $a (ref null $box_i64)) (param $b (ref null $box_i64)) (result i32)
    local.get $a
    struct.get $box_i64 $v
    local.get $b
    struct.get $box_i64 $v
    i64.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_ref (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    ref.is_null
    local.get $b
    ref.is_null
    i32.or
    (if
      (then
    local.get $a
    ref.is_null
    local.get $b
    ref.is_null
    i32.and
    return
      )
    )
    local.get $a
    ref.cast (ref null eq)
    local.get $b
    ref.cast (ref null eq)
    ref.eq
    (if
      (then
    i32.const 1
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Context)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Context)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Context)
    local.get $b
    ref.cast (ref null $rec_Context)
    call $__unk_eq_s1
    return
      )
    )
    local.get $a
    ref.test (ref null $arr_any)
    (if
      (then
    local.get $b
    ref.test (ref null $arr_any)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $arr_any)
    local.get $b
    ref.cast (ref null $arr_any)
    call $__unk_eq_arr_any
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Place)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Place)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Place)
    local.get $b
    ref.cast (ref null $rec_Place)
    call $__unk_eq_s4
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Scope)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Scope)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Scope)
    local.get $b
    ref.cast (ref null $rec_Scope)
    call $__unk_eq_s5
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Carried)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Carried)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Carried)
    local.get $b
    ref.cast (ref null $rec_Carried)
    call $__unk_eq_s6
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_CellEntry)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_CellEntry)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_CellEntry)
    local.get $b
    ref.cast (ref null $rec_CellEntry)
    call $__unk_eq_s7
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_ScopeTree)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_ScopeTree)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_ScopeTree)
    local.get $b
    ref.cast (ref null $rec_ScopeTree)
    call $__unk_eq_s8
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_PlaceLink)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_PlaceLink)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_PlaceLink)
    local.get $b
    ref.cast (ref null $rec_PlaceLink)
    call $__unk_eq_s9
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Frame)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Frame)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Frame)
    local.get $b
    ref.cast (ref null $rec_Frame)
    call $__unk_eq_s13
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_PlaceCount)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_PlaceCount)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_PlaceCount)
    local.get $b
    ref.cast (ref null $rec_PlaceCount)
    call $__unk_eq_s14
    return
      )
    )
    local.get $a
    ref.test (ref null $box_i64)
    (if
      (then
    local.get $b
    ref.test (ref null $box_i64)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $box_i64)
    local.get $b
    ref.cast (ref null $box_i64)
    call $__unk_eq_s21
    return
      )
    )
    local.get $a
    ref.test (ref null $__decl)
    local.get $b
    ref.test (ref null $__decl)
    i32.and
    (if
      (then
    local.get $a
    local.get $b
    call $__eq_decl
    return
      )
    )
    i32.const 0
  )
  (func $__print_tagged_raw (param $v anyref)
    local.get $v
    ref.test (ref null $rec_Context)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Context)
    call $__pr0
    return
      )
    )
    local.get $v
    ref.test (ref null $closure)
    (if
      (then
    global.get $__s76
    call $__print_str_raw
    local.get $v
    ref.cast (ref null $closure)
    struct.get $closure $arity
    call $__print_i32_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Place)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Place)
    call $__pr2
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Scope)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Scope)
    call $__pr6
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Carried)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Carried)
    call $__pr7
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_CellEntry)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_CellEntry)
    call $__pr8
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_ScopeTree)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_ScopeTree)
    call $__pr9
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_PlaceLink)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_PlaceLink)
    call $__pr10
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Frame)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Frame)
    call $__pr12
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_PlaceCount)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_PlaceCount)
    call $__pr14
    return
      )
    )
    local.get $v
    ref.test (ref null $task)
    (if
      (then
    global.get $__s77
    i32.const 1
    call $__panic_raise
    unreachable
      )
    )
    local.get $v
    ref.test (ref null $__decl)
    (if
      (then
    local.get $v
    call $__print_decl
    return
      )
    )
    unreachable
  )
  (func $__print_ebox (param $v anyref) (result i32)
    i32.const 0
  )
  (func $__pr15 (param $v (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    global.get $__s78
    call $__print_str_raw
    local.get $v
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    global.get $__s79
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_any
    call $__pr1
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s80
    call $__print_str_raw
  )
  (func $__print_arrs (param $v anyref) (result i32)
    local.get $v
    ref.test (ref null $arr_any)
    (if
      (then
    local.get $v
    ref.cast (ref null $arr_any)
    call $__pr15
    i32.const 1
    return
      )
    )
    i32.const 0
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
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
  (func $__print_str_raw (param $s (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    local.get $s
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $s
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
  )
  (func $__print_str (param $s (ref null $str))
    local.get $s
    call $__print_str_raw
    call $__print_nl
  )
  (func $__print_bool (param $b i32)
    local.get $b
    call $__print_bool_raw
    call $__print_nl
  )
  (func $__print_bool_raw (param $b i32)
    local.get $b
    (if
      (then
        ;; "true" as a little-endian i32
        i32.const 16
        i32.const 1702195828
        i32.store
        i32.const 16
        i32.const 4
        call $__write_bytes
      )
      (else
        ;; "fals" + 'e'
        i32.const 16
        i32.const 1936482662
        i32.store
        i32.const 16
        i32.const 101
        i32.store8 offset=4
        i32.const 16
        i32.const 5
        call $__write_bytes
      )
    )
  )
  (func $__print_f64 (param $x f64)
    local.get $x
    call $__print_f64_raw
    call $__print_nl
  )
  (func $__print_f64_raw (param $x f64)
    (local $s i32) (local $top i32)
    global.get $__heap_ptr
    local.set $top
    local.get $x
    call $__std_number_floatToString
    local.set $s
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
  )
  (func $__str_concat (param $a (ref null $str)) (param $b (ref null $str)) (result (ref null $str))
    (local $r (ref null $str)) (local $alen i32) (local $blen i32)
    local.get $a
    array.len
    local.set $alen
    local.get $b
    array.len
    local.set $blen
    local.get $alen
    local.get $blen
    i32.add
    array.new_default $str
    local.set $r
    local.get $r
    i32.const 0
    local.get $a
    i32.const 0
    local.get $alen
    array.copy $str $str
    local.get $r
    local.get $alen
    local.get $b
    i32.const 0
    local.get $blen
    array.copy $str $str
    local.get $r
  )
  (func $__str_eq (param $a (ref null $str)) (param $b (ref null $str)) (result i32)
    (local $i i32) (local $n i32) (local $an i32) (local $bn i32)
    local.get $a
    ref.is_null
    local.set $an
    local.get $b
    ref.is_null
    local.set $bn
    local.get $an
    local.get $bn
    i32.or
    (if
      (then
        local.get $an
        local.get $bn
        i32.and
        return
      )
    )
    local.get $a
    array.len
    local.set $n
    local.get $n
    local.get $b
    array.len
    i32.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        array.get_u $str
        local.get $b
        local.get $i
        array.get_u $str
        i32.ne
        (if
          (then
            i32.const 0
            return
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 1
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
  (func $__panic_fail (param $msg (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $msg
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
    local.get $top
    global.set $__heap_ptr
  )
  (func $__print_quoted_raw (param $s (ref null $str))
    (local $n i32) (local $i i32) (local $ch i32) (local $e i32)
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
    local.get $s
    array.len
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $s
        local.get $i
        array.get_u $str
        local.set $ch
        i32.const 0
        local.set $e
        local.get $ch
        i32.const 34
        i32.eq
        local.get $ch
        i32.const 92
        i32.eq
        i32.or
        (if
          (then
            local.get $ch
            local.set $e
          )
        )
        local.get $ch
        i32.const 10
        i32.eq
        (if
          (then
            i32.const 110
            local.set $e
          )
        )
        local.get $ch
        i32.const 13
        i32.eq
        (if
          (then
            i32.const 114
            local.set $e
          )
        )
        local.get $ch
        i32.const 9
        i32.eq
        (if
          (then
            i32.const 116
            local.set $e
          )
        )
        local.get $e
        (if
          (then
            i32.const 8
            i32.const 92
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
            i32.const 8
            local.get $e
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
          (else
            i32.const 8
            local.get $ch
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i64_raw (param $v i64)
    local.get $v
    call $__std_number_i64ToString
    call $__print_str_raw
  )
  (func $__print_i64 (param $v i64)
    local.get $v
    call $__print_i64_raw
    call $__print_nl
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
  (func $__print_u64_raw (param $v i64)
    local.get $v
    call $__std_number_u64ToString
    call $__print_str_raw
  )
  (func $__print_u64 (param $v i64)
    local.get $v
    call $__print_u64_raw
    call $__print_nl
  )
  (global $__task_head (mut (ref null $task)) (ref.null $task))
  (global $__task_tail (mut (ref null $task)) (ref.null $task))
  (global $__task_suspended (mut i32) (i32.const 0))
  (func $__task_new (param $kind i32) (param $frame structref) (result (ref null $task))
    i32.const 0
    ref.null $waiter
    ref.null any
    local.get $frame
    local.get $kind
    ref.null $task
    ref.null any
    i32.const 0
    struct.new $task
  )
  (func $__task_start (param $kind i32) (param $frame structref) (result (ref null $task))
    (local $t (ref null $task))
    local.get $kind
    local.get $frame
    call $__task_new
    local.tee $t
    call $__task_resume
    local.get $t
  )
  (func $__task_pending (param $t (ref null $task)) (result i32)
    local.get $t
    struct.get $task $state
    i32.eqz
  )
  (func $__task_listen (param $t (ref null $task)) (param $kind i32) (param $target (ref null $task)) (param $index i32)
    (local $n (ref null $waiter))
    local.get $t
    struct.get $task $waiters
    local.get $kind
    local.get $target
    local.get $index
    struct.new $waiter
    local.set $n
    local.get $t
    local.get $n
    struct.set $task $waiters
  )
  (func $__task_wait (param $t (ref null $task)) (param $w (ref null $task))
    local.get $t
    i32.const 0
    local.get $w
    i32.const 0
    call $__task_listen
  )
  (func $__task_settle (param $t (ref null $task)) (param $v anyref)
    local.get $t
    local.get $v
    struct.set $task $value
    local.get $t
    call $__task_wake
  )
  (func $__task_wake (param $t (ref null $task))
    (local $n (ref null $waiter)) (local $m (ref null $waiter)) (local $r (ref null $waiter)) (local $k i32) (local $w (ref null $task))
    local.get $t
    struct.get $task $state
    (if
      (then
        return
      )
    )
    local.get $t
    i32.const 1
    struct.set $task $state
    local.get $t
    struct.get $task $waiters
    local.set $n
    local.get $t
    ref.null $waiter
    struct.set $task $waiters
    local.get $t
    ref.null struct
    struct.set $task $frame
    (block $brk
      (loop $cont
        local.get $n
        ref.is_null
        br_if $brk
        local.get $n
        struct.get $waiter $next
        local.set $m
        local.get $n
        local.get $r
        struct.set $waiter $next
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
        ref.is_null
        br_if $brk
        local.get $r
        struct.get $waiter $kind
        local.set $k
        local.get $r
        struct.get $waiter $target
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
            struct.get $task $state
            i32.eqz
            (if
              (then
                local.get $w
                local.get $t
                struct.get $task $value
                struct.set $task $value
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
            struct.get $task $aux
            ref.cast (ref null $arr_any)
            local.get $r
            struct.get $waiter $slot
            local.get $t
            struct.get $task $value
            array.set $arr_any
            local.get $w
            local.get $w
            struct.get $task $left
            i32.const 1
            i32.sub
            struct.set $task $left
            local.get $w
            struct.get $task $left
            i32.eqz
            (if
              (then
                local.get $w
                local.get $w
                struct.get $task $aux
                struct.set $task $value
                local.get $w
                ref.null any
                struct.set $task $aux
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $r
        struct.get $waiter $next
        local.set $r
        br $cont
      )
    )
  )
  (func $__task_enqueue (param $t (ref null $task))
    local.get $t
    ref.null $task
    struct.set $task $next
    global.get $__task_tail
    ref.is_null
    (if
      (then
        local.get $t
        global.set $__task_head
      )
      (else
        global.get $__task_tail
        local.get $t
        struct.set $task $next
      )
    )
    local.get $t
    global.set $__task_tail
  )
  (func $__task_drain
    (local $t (ref null $task))
    (block $brk
      (loop $cont
        global.get $__task_head
        local.tee $t
        ref.is_null
        br_if $brk
        local.get $t
        struct.get $task $next
        global.set $__task_head
        global.get $__task_head
        ref.is_null
        (if
          (then
            ref.null $task
            global.set $__task_tail
          )
        )
        local.get $t
        call $__task_resume
        br $cont
      )
    )
  )
  (func $__task_block_on (param $t (ref null $task)) (result (ref null $task))
    (local $r (ref null $task))
    (block $brk
      (loop $cont
        local.get $t
        struct.get $task $state
        br_if $brk
        global.get $__task_head
        local.tee $r
        ref.is_null
        (if
          (then
            unreachable
          )
        )
        local.get $r
        struct.get $task $next
        global.set $__task_head
        global.get $__task_head
        ref.is_null
        (if
          (then
            ref.null $task
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
  (func $__task_resume (param $t (ref null $task))
    (local $k i32)
    local.get $t
    struct.get $task $kind ;; kind
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
    local.get $k
    i32.const 1
    i32.eq
    (if
      (then
    local.get $t
    call $settled__step
    return
      )
    )
    unreachable
  )
  (func $__task_host_poll (result i32)
    i32.const 0
  )
  (func $__panic_raise (param $msg (ref null $str)) (param $print i32)
    local.get $msg
    local.get $print
    struct.new $exn
    throw $__bp_panic
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    i32.const 1
    call $__panic_raise
    unreachable
  )
  (func $__memo_cell_new (result (ref null $cell))
    i32.const 0
    ref.null any
    struct.new $cell
  )
  (func $__memo_cell_filled (param $c anyref) (result i32)
    local.get $c
    ref.cast (ref null $cell)
    struct.get $cell $filled
  )
  (func $__memo_cell_get (param $c anyref) (result anyref)
    local.get $c
    ref.cast (ref null $cell)
    struct.get $cell $value
  )
  (func $__memo_cell_set (param $c anyref) (param $v anyref)
    local.get $c
    ref.cast (ref null $cell)
    local.get $v
    struct.set $cell $value
    local.get $c
    ref.cast (ref null $cell)
    i32.const 1
    struct.set $cell $filled
  )
  (func $__std_number_i32ToString (param $p0 i32) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_i32ToString
    ref.cast (ref null $str)
  )
  (func $__std_number_i64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_i64ToString
    ref.cast (ref null $str)
  )
  (func $__std_number_u64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_u64ToString
    ref.cast (ref null $str)
  )
  (data $__d0 "`use provide` / `use context` are lowered where they are written; this body never runs")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "`use inject` is lowered where it is written; this body never runs")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "`use all` is lowered where it is written; this body never runs")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "scope-foreign: a scope is read in another process than its root's — pass `scope.detach()` to another process (decision 824 (3))")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "scope-closed: a scope is used after its root's `close()` (decision 825 (2))")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "a scope names a cell its tree does not hold (decision 817)")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "key-duplicate: two siblings carry the key ")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 " (decision 819 (5))")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "integer overflow: - on i32 at src/context.bp:306:52")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "integer overflow: + on i32 at src/context.bp:309:17")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "integer overflow: + on i32 at src/context.bp:317:9")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "\"")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "of another type")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "integer overflow: + on i32 at src/context.bp:373:9")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (data $__d14 "a component is run with a `Scope` (decision 819)")
  (global $__s14 (mut (ref null $str)) (ref.null $str))
  (data $__d15 "value is null — cs[i]! at src/context.bp:574:29")
  (global $__s15 (mut (ref null $str)) (ref.null $str))
  (data $__d16 "integer overflow: + on i32 at src/context.bp:612:9")
  (global $__s16 (mut (ref null $str)) (ref.null $str))
  (data $__d17 "Context")
  (global $__s17 (mut (ref null $str)) (ref.null $str))
  (data $__d18 "(")
  (global $__s18 (mut (ref null $str)) (ref.null $str))
  (data $__d19 "contextValue: ")
  (global $__s19 (mut (ref null $str)) (ref.null $str))
  (data $__d20 "null")
  (global $__s20 (mut (ref null $str)) (ref.null $str))
  (data $__d21 ")")
  (global $__s21 (mut (ref null $str)) (ref.null $str))
  (data $__d22 "std@context.Context")
  (global $__s22 (mut (ref null $str)) (ref.null $str))
  (data $__d23 "Place")
  (global $__s23 (mut (ref null $str)) (ref.null $str))
  (data $__d24 "callNo: ")
  (global $__s24 (mut (ref null $str)) (ref.null $str))
  (data $__d25 ", item: ")
  (global $__s25 (mut (ref null $str)) (ref.null $str))
  (data $__d26 "PlaceItem.Absent")
  (global $__s26 (mut (ref null $str)) (ref.null $str))
  (data $__d27 "PlaceItem.Body")
  (global $__s27 (mut (ref null $str)) (ref.null $str))
  (data $__d28 "PlaceItem.Plain")
  (global $__s28 (mut (ref null $str)) (ref.null $str))
  (data $__d29 "PlaceItem.Index")
  (global $__s29 (mut (ref null $str)) (ref.null $str))
  (data $__d30 "PlaceItem.Key")
  (global $__s30 (mut (ref null $str)) (ref.null $str))
  (data $__d31 ", itemNo: ")
  (global $__s31 (mut (ref null $str)) (ref.null $str))
  (data $__d32 ", keyValue: ")
  (global $__s32 (mut (ref null $str)) (ref.null $str))
  (data $__d33 ", stamped: ")
  (global $__s33 (mut (ref null $str)) (ref.null $str))
  (data $__d34 "std@context.Place")
  (global $__s34 (mut (ref null $str)) (ref.null $str))
  (data $__d35 "Scope")
  (global $__s35 (mut (ref null $str)) (ref.null $str))
  (data $__d36 "scopeStore: ")
  (global $__s36 (mut (ref null $str)) (ref.null $str))
  (data $__d37 ", scopeCell: ")
  (global $__s37 (mut (ref null $str)) (ref.null $str))
  (data $__d38 ", scopeOwner: ")
  (global $__s38 (mut (ref null $str)) (ref.null $str))
  (data $__d39 ", scopeCarried: ")
  (global $__s39 (mut (ref null $str)) (ref.null $str))
  (data $__d40 "std@context.Scope")
  (global $__s40 (mut (ref null $str)) (ref.null $str))
  (data $__d41 "Carried")
  (global $__s41 (mut (ref null $str)) (ref.null $str))
  (data $__d42 "frames: ")
  (global $__s42 (mut (ref null $str)) (ref.null $str))
  (data $__d43 "std@context.Carried")
  (global $__s43 (mut (ref null $str)) (ref.null $str))
  (data $__d44 "CellEntry")
  (global $__s44 (mut (ref null $str)) (ref.null $str))
  (data $__d45 "cellNo: ")
  (global $__s45 (mut (ref null $str)) (ref.null $str))
  (data $__d46 ", cellFrames: ")
  (global $__s46 (mut (ref null $str)) (ref.null $str))
  (data $__d47 ", cellGen: ")
  (global $__s47 (mut (ref null $str)) (ref.null $str))
  (data $__d48 ", cellSlot: ")
  (global $__s48 (mut (ref null $str)) (ref.null $str))
  (data $__d49 ", cellFilled: ")
  (global $__s49 (mut (ref null $str)) (ref.null $str))
  (data $__d50 ", cellCounts: ")
  (global $__s50 (mut (ref null $str)) (ref.null $str))
  (data $__d51 ", cellNext: ")
  (global $__s51 (mut (ref null $str)) (ref.null $str))
  (data $__d52 "std@context.CellEntry")
  (global $__s52 (mut (ref null $str)) (ref.null $str))
  (data $__d53 "ScopeTree")
  (global $__s53 (mut (ref null $str)) (ref.null $str))
  (data $__d54 "treeClosed: ")
  (global $__s54 (mut (ref null $str)) (ref.null $str))
  (data $__d55 ", treeCount: ")
  (global $__s55 (mut (ref null $str)) (ref.null $str))
  (data $__d56 ", treeCells: ")
  (global $__s56 (mut (ref null $str)) (ref.null $str))
  (data $__d57 ", treeLinks: ")
  (global $__s57 (mut (ref null $str)) (ref.null $str))
  (data $__d58 "std@context.ScopeTree")
  (global $__s58 (mut (ref null $str)) (ref.null $str))
  (data $__d59 "PlaceLink")
  (global $__s59 (mut (ref null $str)) (ref.null $str))
  (data $__d60 "linkParent: ")
  (global $__s60 (mut (ref null $str)) (ref.null $str))
  (data $__d61 ", linkPlace: ")
  (global $__s61 (mut (ref null $str)) (ref.null $str))
  (data $__d62 ", linkChild: ")
  (global $__s62 (mut (ref null $str)) (ref.null $str))
  (data $__d63 ", linkSeen: ")
  (global $__s63 (mut (ref null $str)) (ref.null $str))
  (data $__d64 ", linkNext: ")
  (global $__s64 (mut (ref null $str)) (ref.null $str))
  (data $__d65 "std@context.PlaceLink")
  (global $__s65 (mut (ref null $str)) (ref.null $str))
  (data $__d66 "Frame")
  (global $__s66 (mut (ref null $str)) (ref.null $str))
  (data $__d67 "key: ")
  (global $__s67 (mut (ref null $str)) (ref.null $str))
  (data $__d68 ", value: ")
  (global $__s68 (mut (ref null $str)) (ref.null $str))
  (data $__d69 ", parent: ")
  (global $__s69 (mut (ref null $str)) (ref.null $str))
  (data $__d70 "std@context.Frame")
  (global $__s70 (mut (ref null $str)) (ref.null $str))
  (data $__d71 "PlaceCount")
  (global $__s71 (mut (ref null $str)) (ref.null $str))
  (data $__d72 "countCall: ")
  (global $__s72 (mut (ref null $str)) (ref.null $str))
  (data $__d73 ", countValue: ")
  (global $__s73 (mut (ref null $str)) (ref.null $str))
  (data $__d74 ", countNext: ")
  (global $__s74 (mut (ref null $str)) (ref.null $str))
  (data $__d75 "std@context.PlaceCount")
  (global $__s75 (mut (ref null $str)) (ref.null $str))
  (data $__d76 "fn/")
  (global $__s76 (mut (ref null $str)) (ref.null $str))
  (data $__d77 "wasm cannot print a Task value dynamically yet")
  (global $__s77 (mut (ref null $str)) (ref.null $str))
  (data $__d78 "[")
  (global $__s78 (mut (ref null $str)) (ref.null $str))
  (data $__d79 ", ")
  (global $__s79 (mut (ref null $str)) (ref.null $str))
  (data $__d80 "]")
  (global $__s80 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 86
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 65
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 62
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 129
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 75
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 58
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 42
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 19
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 51
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 51
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 50
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 1
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 15
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 50
    array.new_data $str $__d13
    global.set $__s13
    i32.const 0
    i32.const 48
    array.new_data $str $__d14
    global.set $__s14
    i32.const 0
    i32.const 49
    array.new_data $str $__d15
    global.set $__s15
    i32.const 0
    i32.const 50
    array.new_data $str $__d16
    global.set $__s16
    i32.const 0
    i32.const 7
    array.new_data $str $__d17
    global.set $__s17
    i32.const 0
    i32.const 1
    array.new_data $str $__d18
    global.set $__s18
    i32.const 0
    i32.const 14
    array.new_data $str $__d19
    global.set $__s19
    i32.const 0
    i32.const 4
    array.new_data $str $__d20
    global.set $__s20
    i32.const 0
    i32.const 1
    array.new_data $str $__d21
    global.set $__s21
    i32.const 0
    i32.const 19
    array.new_data $str $__d22
    global.set $__s22
    i32.const 0
    i32.const 5
    array.new_data $str $__d23
    global.set $__s23
    i32.const 0
    i32.const 8
    array.new_data $str $__d24
    global.set $__s24
    i32.const 0
    i32.const 8
    array.new_data $str $__d25
    global.set $__s25
    i32.const 0
    i32.const 16
    array.new_data $str $__d26
    global.set $__s26
    i32.const 0
    i32.const 14
    array.new_data $str $__d27
    global.set $__s27
    i32.const 0
    i32.const 15
    array.new_data $str $__d28
    global.set $__s28
    i32.const 0
    i32.const 15
    array.new_data $str $__d29
    global.set $__s29
    i32.const 0
    i32.const 13
    array.new_data $str $__d30
    global.set $__s30
    i32.const 0
    i32.const 10
    array.new_data $str $__d31
    global.set $__s31
    i32.const 0
    i32.const 12
    array.new_data $str $__d32
    global.set $__s32
    i32.const 0
    i32.const 11
    array.new_data $str $__d33
    global.set $__s33
    i32.const 0
    i32.const 17
    array.new_data $str $__d34
    global.set $__s34
    i32.const 0
    i32.const 5
    array.new_data $str $__d35
    global.set $__s35
    i32.const 0
    i32.const 12
    array.new_data $str $__d36
    global.set $__s36
    i32.const 0
    i32.const 13
    array.new_data $str $__d37
    global.set $__s37
    i32.const 0
    i32.const 14
    array.new_data $str $__d38
    global.set $__s38
    i32.const 0
    i32.const 16
    array.new_data $str $__d39
    global.set $__s39
    i32.const 0
    i32.const 17
    array.new_data $str $__d40
    global.set $__s40
    i32.const 0
    i32.const 7
    array.new_data $str $__d41
    global.set $__s41
    i32.const 0
    i32.const 8
    array.new_data $str $__d42
    global.set $__s42
    i32.const 0
    i32.const 19
    array.new_data $str $__d43
    global.set $__s43
    i32.const 0
    i32.const 9
    array.new_data $str $__d44
    global.set $__s44
    i32.const 0
    i32.const 8
    array.new_data $str $__d45
    global.set $__s45
    i32.const 0
    i32.const 14
    array.new_data $str $__d46
    global.set $__s46
    i32.const 0
    i32.const 11
    array.new_data $str $__d47
    global.set $__s47
    i32.const 0
    i32.const 12
    array.new_data $str $__d48
    global.set $__s48
    i32.const 0
    i32.const 14
    array.new_data $str $__d49
    global.set $__s49
    i32.const 0
    i32.const 14
    array.new_data $str $__d50
    global.set $__s50
    i32.const 0
    i32.const 12
    array.new_data $str $__d51
    global.set $__s51
    i32.const 0
    i32.const 21
    array.new_data $str $__d52
    global.set $__s52
    i32.const 0
    i32.const 9
    array.new_data $str $__d53
    global.set $__s53
    i32.const 0
    i32.const 12
    array.new_data $str $__d54
    global.set $__s54
    i32.const 0
    i32.const 13
    array.new_data $str $__d55
    global.set $__s55
    i32.const 0
    i32.const 13
    array.new_data $str $__d56
    global.set $__s56
    i32.const 0
    i32.const 13
    array.new_data $str $__d57
    global.set $__s57
    i32.const 0
    i32.const 21
    array.new_data $str $__d58
    global.set $__s58
    i32.const 0
    i32.const 9
    array.new_data $str $__d59
    global.set $__s59
    i32.const 0
    i32.const 12
    array.new_data $str $__d60
    global.set $__s60
    i32.const 0
    i32.const 13
    array.new_data $str $__d61
    global.set $__s61
    i32.const 0
    i32.const 13
    array.new_data $str $__d62
    global.set $__s62
    i32.const 0
    i32.const 12
    array.new_data $str $__d63
    global.set $__s63
    i32.const 0
    i32.const 12
    array.new_data $str $__d64
    global.set $__s64
    i32.const 0
    i32.const 21
    array.new_data $str $__d65
    global.set $__s65
    i32.const 0
    i32.const 5
    array.new_data $str $__d66
    global.set $__s66
    i32.const 0
    i32.const 5
    array.new_data $str $__d67
    global.set $__s67
    i32.const 0
    i32.const 9
    array.new_data $str $__d68
    global.set $__s68
    i32.const 0
    i32.const 10
    array.new_data $str $__d69
    global.set $__s69
    i32.const 0
    i32.const 17
    array.new_data $str $__d70
    global.set $__s70
    i32.const 0
    i32.const 10
    array.new_data $str $__d71
    global.set $__s71
    i32.const 0
    i32.const 11
    array.new_data $str $__d72
    global.set $__s72
    i32.const 0
    i32.const 14
    array.new_data $str $__d73
    global.set $__s73
    i32.const 0
    i32.const 13
    array.new_data $str $__d74
    global.set $__s74
    i32.const 0
    i32.const 22
    array.new_data $str $__d75
    global.set $__s75
    i32.const 0
    i32.const 3
    array.new_data $str $__d76
    global.set $__s76
    i32.const 0
    i32.const 46
    array.new_data $str $__d77
    global.set $__s77
    i32.const 0
    i32.const 1
    array.new_data $str $__d78
    global.set $__s78
    i32.const 0
    i32.const 2
    array.new_data $str $__d79
    global.set $__s79
    i32.const 0
    i32.const 1
    array.new_data $str $__d80
    global.set $__s80
    call $__init_types
  )
  (func $__new_30 (param $f0 anyref) (result (ref null $rec_Context))
    global.get $__ti_30
    local.get $f0
    struct.new $rec_Context
  )
  (func $__new_34 (param $f0 i32) (param $f1 i32) (param $f2 i32) (param $f3 anyref) (param $f4 i32) (result (ref null $rec_Place))
    global.get $__ti_34
    local.get $f0
    local.get $f1
    local.get $f2
    local.get $f3
    local.get $f4
    struct.new $rec_Place
  )
  (func $__new_40 (param $f0 anyref) (param $f1 i32) (param $f2 anyref) (param $f3 anyref) (result (ref null $rec_Scope))
    global.get $__ti_40
    local.get $f0
    local.get $f1
    local.get $f2
    local.get $f3
    struct.new $rec_Scope
  )
  (func $__new_26 (param $f0 anyref) (result (ref null $rec_Carried))
    global.get $__ti_26
    local.get $f0
    struct.new $rec_Carried
  )
  (func $__new_28 (param $f0 i32) (param $f1 anyref) (param $f2 i32) (param $f3 anyref) (param $f4 i32) (param $f5 anyref) (param $f6 anyref) (result (ref null $rec_CellEntry))
    global.get $__ti_28
    local.get $f0
    local.get $f1
    local.get $f2
    local.get $f3
    local.get $f4
    local.get $f5
    local.get $f6
    struct.new $rec_CellEntry
  )
  (func $__new_42 (param $f0 i32) (param $f1 i32) (param $f2 anyref) (param $f3 anyref) (result (ref null $rec_ScopeTree))
    global.get $__ti_42
    local.get $f0
    local.get $f1
    local.get $f2
    local.get $f3
    struct.new $rec_ScopeTree
  )
  (func $__new_38 (param $f0 i32) (param $f1 (ref null $rec_Place)) (param $f2 i32) (param $f3 i32) (param $f4 anyref) (result (ref null $rec_PlaceLink))
    global.get $__ti_38
    local.get $f0
    local.get $f1
    local.get $f2
    local.get $f3
    local.get $f4
    struct.new $rec_PlaceLink
  )
  (func $__new_32 (param $f0 (ref null $str)) (param $f1 anyref) (param $f2 anyref) (result (ref null $rec_Frame))
    global.get $__ti_32
    local.get $f0
    local.get $f1
    local.get $f2
    struct.new $rec_Frame
  )
  (func $__new_36 (param $f0 i32) (param $f1 i32) (param $f2 anyref) (result (ref null $rec_PlaceCount))
    global.get $__ti_36
    local.get $f0
    local.get $f1
    local.get $f2
    struct.new $rec_PlaceCount
  )
  (global $__ti_30 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_34 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_40 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_26 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_28 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_42 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_38 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_32 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_36 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tip1 $__tie1 $__tip4 $__tie4 $__tip5 $__tie5 $__tip6 $__tie6 $__tip7 $__tie7 $__tip8 $__tie8 $__tip9 $__tie9 $__tip13 $__tie13 $__tip14 $__tie14)
  (func $__init_types
    global.get $__s22
    ref.func $__tip1
    ref.func $__tie1
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_30
    global.get $__ti_30
    call $__ti_register
    global.get $__s34
    ref.func $__tip4
    ref.func $__tie4
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_34
    global.get $__ti_34
    call $__ti_register
    global.get $__s40
    ref.func $__tip5
    ref.func $__tie5
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_40
    global.get $__ti_40
    call $__ti_register
    global.get $__s43
    ref.func $__tip6
    ref.func $__tie6
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_26
    global.get $__ti_26
    call $__ti_register
    global.get $__s52
    ref.func $__tip7
    ref.func $__tie7
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_28
    global.get $__ti_28
    call $__ti_register
    global.get $__s58
    ref.func $__tip8
    ref.func $__tie8
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_42
    global.get $__ti_42
    call $__ti_register
    global.get $__s65
    ref.func $__tip9
    ref.func $__tie9
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_38
    global.get $__ti_38
    call $__ti_register
    global.get $__s70
    ref.func $__tip13
    ref.func $__tie13
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_32
    global.get $__ti_32
    call $__ti_register
    global.get $__s75
    ref.func $__tip14
    ref.func $__tie14
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_36
    global.get $__ti_36
    call $__ti_register
  )
  (@custom "botopink.needs" "exceptions\0agc\0a")
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
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (sub (array (mut i32))))
    (type $arr_bool (sub final $arr_i32 (array (mut i32))))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (sub (struct (field $v i64))))
    (type $box_u64 (sub final $box_i64 (struct (field $v i64))))
    (type $box_f64 (struct (field $v f64)))
    (type $box_bool (sub final $box_i32 (struct (field $v i32))))
    (type $box_big (struct (field $v (ref null $str))))
    (type $closure (sub (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $hostn (struct (field $next (mut (ref null $hostn))) (field $h i32) (field $t (ref null $task))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $cell (struct (field $filled (mut i32)) (field $value (mut anyref))))
    (type $__decl (sub (struct (field $ti (ref null $__tinfo)))))
    (type $__tinfo (struct (field $name (ref null $str)) (field $print funcref) (field $eq funcref) (field $display funcref) (field $kind i32)))
    (type $__print_sig (func (param anyref)))
    (type $__eq_sig (func (param anyref anyref) (result i32)))
  )
  (rec
    (type $sig_0 (func (param (ref null $closure)) (result anyref)))
  )
  (rec
    (type $sig_2 (func (param (ref null $closure) anyref anyref) (result anyref)))
  )
  (rec
    (type $rec_Carried (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut anyref)))))
    (type $brand_rec_Carried (struct (field i32) (field f64) (field i64) (field f32) (field i32) (field f32) (field f32) (field i32) (field i32) (field f32) (field i32) (field i64) (field f32) (field i64) (field f64) (field f32) (field i32) (field i64) (field i32) (field i32) (field i64) (field f32) (field i64) (field f64) (field i32) (field f64) (field f64) (field i32) (field f32) (field i64) (field i32) (field f64)))
  )
  (rec
    (type $rec_CellEntry (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut anyref)) (field $f2 (mut i32)) (field $f3 (mut anyref)) (field $f4 (mut i32)) (field $f5 (mut anyref)) (field $f6 (mut anyref)))))
    (type $brand_rec_CellEntry (struct (field f64) (field f64) (field i32) (field i32) (field i32) (field i32) (field f32) (field f64) (field i32) (field i32) (field i32) (field i32) (field f64) (field i32) (field f32) (field i64) (field i32) (field i64) (field i64) (field f64) (field f64) (field f32) (field i64) (field f64) (field i32) (field i64) (field i32) (field f32) (field f32) (field i32) (field f64) (field i32)))
  )
  (rec
    (type $rec_Context (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut anyref)))))
    (type $brand_rec_Context (struct (field f64) (field f64) (field i64) (field f64) (field f32) (field f32) (field i64) (field i64) (field i64) (field f32) (field i64) (field i32) (field i64) (field f32) (field i64) (field f64) (field i64) (field i64) (field i64) (field i64) (field f32) (field i32) (field i32) (field f64) (field i64) (field i64) (field f64) (field f64) (field i32) (field i32) (field i64) (field i32)))
  )
  (rec
    (type $rec_Place (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut i32)) (field $f2 (mut i32)) (field $f3 (mut anyref)) (field $f4 (mut i32)))))
    (type $brand_rec_Place (struct (field i64) (field f32) (field i32) (field i32) (field i64) (field i64) (field f64) (field f64) (field i64) (field f32) (field i32) (field i64) (field f32) (field i64) (field f64) (field i32) (field f32) (field i32) (field f32) (field f32) (field i32) (field i64) (field i64) (field f32) (field f64) (field i64) (field f32) (field f64) (field i32) (field f32) (field i64) (field f32)))
  )
  (rec
    (type $rec_PlaceCount (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut i32)) (field $f2 (mut anyref)))))
    (type $brand_rec_PlaceCount (struct (field f64) (field f32) (field i64) (field f64) (field i64) (field i32) (field f32) (field i32) (field i32) (field i32) (field f64) (field f64) (field f32) (field i64) (field f32) (field i32) (field i64) (field f32) (field f32) (field i32) (field i32) (field i32) (field f64) (field f64) (field i64) (field i64) (field f32) (field i32) (field f32) (field f64) (field f64) (field f32)))
  )
  (rec
    (type $rec_PlaceLink (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut (ref null $rec_Place))) (field $f2 (mut i32)) (field $f3 (mut i32)) (field $f4 (mut anyref)))))
    (type $brand_rec_PlaceLink (struct (field i64) (field i32) (field f64) (field i64) (field f64) (field i32) (field f32) (field i64) (field i32) (field f32) (field i64) (field f32) (field f64) (field i32) (field i64) (field i64) (field i32) (field i32) (field i32) (field f32) (field f32) (field f64) (field f64) (field i32) (field f64) (field f64) (field i32) (field i32) (field i64) (field i32) (field f32) (field i32)))
  )
  (rec
    (type $rec_Scope (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut anyref)) (field $f1 (mut i32)) (field $f2 (mut anyref)) (field $f3 (mut anyref)))))
    (type $brand_rec_Scope (struct (field f32) (field i64) (field i64) (field f32) (field f64) (field i32) (field i32) (field f64) (field f64) (field i32) (field i32) (field f32) (field f32) (field f64) (field i32) (field f64) (field f32) (field f32) (field i32) (field i64) (field f64) (field i32) (field i32) (field f32) (field i32) (field i64) (field f64) (field f64) (field f32) (field f32) (field f32) (field i32)))
  )
  (rec
    (type $rec_ScopeTree (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut i32)) (field $f2 (mut anyref)) (field $f3 (mut anyref)))))
    (type $brand_rec_ScopeTree (struct (field i64) (field i32) (field i64) (field f64) (field i32) (field f32) (field f64) (field i32) (field i64) (field f32) (field f32) (field i64) (field i64) (field f64) (field f64) (field f32) (field f32) (field f32) (field i32) (field i32) (field i64) (field i64) (field f64) (field i64) (field f64) (field i32) (field i64) (field i32) (field f32) (field f32) (field f32) (field f32)))
  )
  (rec
    (type $rec_Element (sub final $__decl (struct (field $ti (ref null $__tinfo)))))
    (type $brand_rec_Element (struct (field f32) (field i64) (field i32) (field f64) (field i64) (field i64) (field f32) (field i32) (field i64) (field i64) (field i64) (field f64) (field f64) (field i32) (field f64) (field i64) (field f64) (field f64) (field f64) (field f64) (field f32) (field i32) (field f32) (field i32) (field f32) (field f64) (field f64) (field f64) (field i64) (field f32) (field f32) (field i32)))
  )
  (rec
    (type $env0 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))) (field $c1 (mut (ref null $rec_Place))))))
    (type $env1 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env2 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env3 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env4 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))) (field $c1 (mut (ref null $rec_Place))))))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__print_decl" (func $__print_decl (param anyref)))
  (import "std@__rt" "__eq_decl" (func $__eq_decl (param anyref anyref) (result i32)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i32ToString" (func $__abi___std_number_i32ToString (param i32) (result arrayref)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (elem declare func $__lambda0 $__lambda1 $__lambda2 $__lambda3 $__lambda4)
  (func $context (param $ctx (ref null $rec_Context)) (result (ref null $closure))
    global.get $__s0
    call $__panic_fail
    unreachable
    ref.null $closure
  )
  (func $Place_none (result (ref null $rec_Place))
    (local $__mem0 i32)
    i32.const 0
    i32.const 0 ;; PlaceItem.Absent
    i32.const 0
    ref.null any
    i32.const 0
    call $__new_32
    return
  )
  (func $Place_key (param $k anyref) (result (ref null $rec_Place))
    (local $__mem0 i32)
    i32.const 0
    i32.const 4 ;; PlaceItem.Key
    i32.const 0
    local.get $k
    i32.const 0
    call $__new_32
    return
  )
  (func $Place_index (param $i i32) (result (ref null $rec_Place))
    (local $__mem0 i32)
    i32.const 0
    i32.const 3 ;; PlaceItem.Index
    local.get $i
    ref.null any
    i32.const 0
    call $__new_32
    return
  )
  (func $Place_with (param $self (ref null $rec_Place)) (param $key (ref null $rec_Place)) (result (ref null $rec_Place))
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $key
    struct.get $rec_Place $f1
    i32.const 4 ;; PlaceItem.Key
    i32.eq
    (if (result (ref null $rec_Place))
      (then
    local.get $self
    struct.get $rec_Place $f0
    i32.const 4 ;; PlaceItem.Key
    i32.const 0
    local.get $key
    struct.get $rec_Place $f3
    local.get $self
    struct.get $rec_Place $f4
    call $__new_32
    return
      )
      (else
        ref.null $rec_Place
      )
    )
    drop
    local.get $key
    struct.get $rec_Place $f1
    i32.const 3 ;; PlaceItem.Index
    i32.eq
    (if (result (ref null $rec_Place))
      (then
    local.get $self
    struct.get $rec_Place $f1
    i32.const 0 ;; PlaceItem.Absent
    i32.eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $self
    struct.get $rec_Place $f1
    i32.const 2 ;; PlaceItem.Plain
    i32.eq
      )
    )
    (if (result (ref null $rec_Place))
      (then
    local.get $self
    struct.get $rec_Place $f0
    i32.const 3 ;; PlaceItem.Index
    local.get $key
    struct.get $rec_Place $f2
    ref.null any
    local.get $self
    struct.get $rec_Place $f4
    call $__new_32
    return
      )
      (else
        ref.null $rec_Place
      )
    )
      )
      (else
        ref.null $rec_Place
      )
    )
    drop
    local.get $self
    return
  )
  (func $samePlace (param $a (ref null $rec_Place)) (param $b (ref null $rec_Place)) (result i32)
    local.get $a
    struct.get $rec_Place $f0
    local.get $b
    struct.get $rec_Place $f0
    i32.ne
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $a
    struct.get $rec_Place $f1
    local.get $b
    struct.get $rec_Place $f1
    i32.ne
      )
    )
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $a
    struct.get $rec_Place $f2
    local.get $b
    struct.get $rec_Place $f2
    i32.ne
      )
    )
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
    local.get $a
    struct.get $rec_Place $f1
    i32.const 4 ;; PlaceItem.Key
    i32.eq
    (if (result i32)
      (then
    local.get $a
    call $placeKey
    local.get $b
    call $placeKey
    call $sameKey
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 1
    return
  )
  (func $placeKey (param $p (ref null $rec_Place)) (result anyref)
    local.get $p
    struct.get $rec_Place $f3
    return
  )
  (func $Scope_root (result (ref null $rec_Scope))
    (local $__mem0 i32)
    ref.null any
    call $storeOf
    i32.const 0
    call $ownerSelf
    ref.null any
    call $__new_38
    return
  )
  (func $Scope_childAt (param $self (ref null $rec_Scope)) (param $key (ref null $rec_Place)) (result (ref null $rec_Scope))
    (local $__mem0 i32)
    local.get $self
    struct.get $rec_Scope $f0
    local.get $self
    struct.get $rec_Scope $f0
    local.get $self
    struct.get $rec_Scope $f2
    local.get $self
    struct.get $rec_Scope $f3
    local.get $self
    struct.get $rec_Scope $f1
    local.get $key
    call $openChild
    local.get $self
    struct.get $rec_Scope $f2
    local.get $self
    struct.get $rec_Scope $f3
    call $__new_38
    return
  )
  (func $Scope_close (param $self (ref null $rec_Scope)) (result i32)
    local.get $self
    struct.get $rec_Scope $f0
    call $closeStore
  )
  (func $Scope_detach (param $self (ref null $rec_Scope)) (result (ref null $rec_Scope))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $carried (ref null $rec_Carried))
    local.get $self
    struct.get $rec_Scope $f0
    local.get $self
    struct.get $rec_Scope $f2
    local.get $self
    struct.get $rec_Scope $f3
    local.get $self
    struct.get $rec_Scope $f1
    call $framesAt
    call $__new_26
    local.set $carried
    call $storeNew
    i32.const 0
    ref.null any
    local.get $carried
    call $__new_38
    return
  )
  (func $Scope_storeRef (param $self (ref null $rec_Scope)) (result anyref)
    local.get $self
    struct.get $rec_Scope $f0
    return
  )
  (func $Scope_cellId (param $self (ref null $rec_Scope)) (result i32)
    local.get $self
    struct.get $rec_Scope $f1
    return
  )
  (func $Scope_ownerRef (param $self (ref null $rec_Scope)) (result anyref)
    local.get $self
    struct.get $rec_Scope $f2
    return
  )
  (func $Scope_carriedRef (param $self (ref null $rec_Scope)) (result anyref)
    local.get $self
    struct.get $rec_Scope $f3
    return
  )
  (func $storeOf (param $frames anyref) (result anyref)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $store anyref)
    call $storeNew
    local.set $store
    local.get $store
    i32.const 0
    i32.const 1
    i32.const 0
    local.get $frames
    i32.const 0
    ref.null any
    i32.const 0
    ref.null any
    ref.null any
    call $__new_28
    ref.null any
    call $__new_40
    call $storeSet
    local.get $store
    return
  )
  (func $treeOf (param $store anyref) (param $owner anyref) (param $carried anyref) (result (ref null $rec_ScopeTree))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $c (ref null $rec_Carried))
    (local $t (ref null $rec_ScopeTree))
    (local $raw anyref)
    (local $__gc0 anyref)
    (local $__gc1 anyref)
    local.get $owner
    call $ownerForeign
    (if (result (ref null $rec_ScopeTree))
      (then
    global.get $__s1
    call $__panic_fail
    unreachable
    ref.null $rec_ScopeTree
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
    drop
    local.get $store
    call $storeLive
    i32.eqz
    (if (result (ref null $rec_ScopeTree))
      (then
    local.get $carried
    local.set $__gc0
    local.get $__gc0
    ref.test (ref null $rec_Carried)
    local.get $__gc0
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $rec_ScopeTree))
      (then
    local.get $carried
    ref.cast (ref null $rec_Carried)
    local.set $c
    i32.const 0
    i32.const 1
    i32.const 0
    local.get $c
    call $carriedFrames
    i32.const 0
    ref.null any
    i32.const 0
    ref.null any
    ref.null any
    call $__new_28
    ref.null any
    call $__new_40
    local.set $t
    local.get $store
    local.get $t
    call $storeSet
    local.get $t
    return
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
    drop
    local.get $store
    call $storeLive
    (if (result (ref null $rec_ScopeTree))
      (then
    local.get $store
    call $storeGet
    local.set $raw
    local.get $raw
    local.set $__gc1
    local.get $__gc1
    ref.test (ref null $rec_ScopeTree)
    local.get $__gc1
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $rec_ScopeTree))
      (then
    local.get $raw
    ref.cast (ref null $rec_ScopeTree)
    local.set $t
    local.get $t
    struct.get $rec_ScopeTree $f0
    i32.eqz
    (if (result (ref null $rec_ScopeTree))
      (then
    local.get $t
    return
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
      )
      (else
        ref.null $rec_ScopeTree
      )
    )
    drop
    global.get $__s2
    call $__panic_fail
    unreachable
    ref.null $rec_ScopeTree
  )
  (func $treeCells (param $t (ref null $rec_ScopeTree)) (result anyref)
    local.get $t
    struct.get $rec_ScopeTree $f2
    return
  )
  (func $treeLinks (param $t (ref null $rec_ScopeTree)) (result anyref)
    local.get $t
    struct.get $rec_ScopeTree $f3
    return
  )
  (func $withCell (param $t (ref null $rec_ScopeTree)) (param $e (ref null $rec_CellEntry)) (result (ref null $rec_ScopeTree))
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 0
    local.get $t
    struct.get $rec_ScopeTree $f1
    local.get $e
    struct.get $rec_CellEntry $f0
    local.get $e
    call $entryFrames
    local.get $e
    struct.get $rec_CellEntry $f2
    local.get $e
    call $entrySlot
    local.get $e
    struct.get $rec_CellEntry $f4
    local.get $e
    call $entryCounts
    local.get $t
    call $treeCells
    call $__new_28
    local.get $t
    call $treeLinks
    call $__new_40
    return
  )
  (func $cellOf (param $cells anyref) (param $id i32) (result (ref null $rec_CellEntry))
    (local $cur anyref)
    (local $e (ref null $rec_CellEntry))
    (local $__gc2 anyref)
    local.get $cells
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.set $__gc2
    local.get $__gc2
    ref.test (ref null $rec_CellEntry)
    local.get $__gc2
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $cur
    ref.cast (ref null $rec_CellEntry)
    local.set $e
    local.get $e
    struct.get $rec_CellEntry $f0
    local.get $id
    i32.eq
    (if (result (ref null $rec_CellEntry))
      (then
    local.get $e
    return
      )
      (else
        ref.null $rec_CellEntry
      )
    )
    drop
    local.get $e
    call $entryNext
    local.set $cur
      )
      (else
    global.get $__s3
    call $__panic_fail
    unreachable
      )
    )
        br $__continue
      )
    )
    unreachable ;; a loop with no break never ends
  )
  (func $openChild (param $store anyref) (param $owner anyref) (param $carried anyref) (param $parent i32) (param $key (ref null $rec_Place)) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $t (ref null $rec_ScopeTree))
    (local $p (ref null $rec_CellEntry))
    (local $frames anyref)
    (local $found anyref)
    (local $l (ref null $rec_PlaceLink))
    (local $c (ref null $rec_CellEntry))
    (local $kept (ref null $rec_ScopeTree))
    (local $id i32)
    (local $__gc3 anyref)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    local.set $t
    local.get $t
    call $treeCells
    local.get $parent
    call $cellOf
    local.set $p
    local.get $p
    call $entryFrames
    local.set $frames
    local.get $t
    call $treeLinks
    local.get $parent
    local.get $key
    call $linkAt
    local.set $found
    local.get $found
    local.set $__gc3
    local.get $__gc3
    ref.test (ref null $rec_PlaceLink)
    local.get $__gc3
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    local.get $found
    ref.cast (ref null $rec_PlaceLink)
    local.set $l
    local.get $parent
    i32.const 0
    i32.ne
    (if (result i32)
      (then
    local.get $l
    struct.get $rec_PlaceLink $f3
    local.get $p
    struct.get $rec_CellEntry $f2
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    local.get $key
    struct.get $rec_Place $f1
    i32.const 4 ;; PlaceItem.Key
    i32.eq
      )
      (else
    i32.const 0
      )
    )
    (if (result i32)
      (then
    global.get $__s4
    local.get $key
    call $placeKey
    call $keyText
    call $__str_concat
    global.get $__s5
    call $__str_concat
    call $__panic_fail
    unreachable
    i32.const 0
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $parent
    i32.const 0
    i32.eq
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $l
    struct.get $rec_PlaceLink $f3
    local.get $p
    struct.get $rec_CellEntry $f2
    i32.const 1
    global.get $__s6
    call $__i32_sub_chk
    i32.ge_s
      )
    )
    (if (result i32)
      (then
    local.get $t
    call $treeCells
    local.get $l
    struct.get $rec_PlaceLink $f2
    call $cellOf
    local.set $c
    local.get $t
    local.get $c
    struct.get $rec_CellEntry $f0
    local.get $frames
    local.get $c
    struct.get $rec_CellEntry $f2
    i32.const 1
    global.get $__s7
    call $__i32_add_chk
    local.get $c
    call $entrySlot
    local.get $c
    struct.get $rec_CellEntry $f4
    ref.null any
    ref.null any
    call $__new_28
    call $withCell
    local.set $kept
    local.get $store
    i32.const 0
    local.get $kept
    struct.get $rec_ScopeTree $f1
    local.get $kept
    call $treeCells
    local.get $parent
    local.get $key
    local.get $l
    struct.get $rec_PlaceLink $f2
    local.get $p
    struct.get $rec_CellEntry $f2
    local.get $kept
    call $treeLinks
    call $__new_36
    call $__new_40
    call $storeSet
    local.get $l
    struct.get $rec_PlaceLink $f2
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
    local.get $t
    struct.get $rec_ScopeTree $f1
    local.set $id
    local.get $store
    i32.const 0
    local.get $id
    i32.const 1
    global.get $__s8
    call $__i32_add_chk
    local.get $id
    local.get $frames
    i32.const 1
    ref.null any
    i32.const 0
    ref.null any
    local.get $t
    call $treeCells
    call $__new_28
    local.get $parent
    local.get $key
    local.get $id
    local.get $p
    struct.get $rec_CellEntry $f2
    local.get $t
    call $treeLinks
    call $__new_36
    call $__new_40
    call $storeSet
    local.get $id
    return
  )
  (func $linkAt (param $links anyref) (param $parent i32) (param $key (ref null $rec_Place)) (result anyref)
    (local $cur anyref)
    (local $l (ref null $rec_PlaceLink))
    (local $__gc4 anyref)
    local.get $links
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.set $__gc4
    local.get $__gc4
    ref.test (ref null $rec_PlaceLink)
    local.get $__gc4
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    local.get $cur
    ref.cast (ref null $rec_PlaceLink)
    local.set $l
    local.get $l
    struct.get $rec_PlaceLink $f0
    local.get $parent
    i32.eq
    (if (result i32)
      (then
    local.get $l
    struct.get $rec_PlaceLink $f1
    local.get $key
    call $samePlace
      )
      (else
    i32.const 0
      )
    )
    (if (result anyref)
      (then
    local.get $l
    call $linkSelf
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $l
    call $linkNext
    local.set $cur
    i32.const 0
      )
      (else
    ref.null any
    return
      )
    )
    drop
        br $__continue
      )
    )
    unreachable ;; a loop with no break never ends
  )
  (func $linkSelf (param $l (ref null $rec_PlaceLink)) (result anyref)
    local.get $l
    return
  )
  (func $linkNext (param $l (ref null $rec_PlaceLink)) (result anyref)
    local.get $l
    struct.get $rec_PlaceLink $f4
    return
  )
  (func $keyText (param $k anyref) (result (ref null $str))
    (local $__gc5 anyref)
    (local $k__is0 (ref null $str))
    (local $k__is1 i32)
    local.get $k
    local.tee $__gc5
    ref.test (ref null $str)
    local.get $__gc5
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $str))
      (then
    local.get $k
    ref.cast (ref null $str)
    local.set $k__is0
    global.get $__s9
    local.get $k__is0
    call $__str_concat
    global.get $__s9
    call $__str_concat
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $k
    i32.const -2147483648
    i32.const 2147483647
    call $__unk_int_in
    (if (result (ref null $str))
      (then
    local.get $k
    call $__unk_as_i32
    local.set $k__is1
    local.get $k__is1
    call $__std_number_i32ToString
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    global.get $__s10
    return
  )
  (func $framesAt (param $store anyref) (param $owner anyref) (param $carried anyref) (param $id i32) (result anyref)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    call $treeCells
    local.get $id
    call $cellOf
    call $entryFrames
    return
  )
  (func $carriedFrames (param $c (ref null $rec_Carried)) (result anyref)
    local.get $c
    struct.get $rec_Carried $f0
    return
  )
  (func $countAt (param $store anyref) (param $owner anyref) (param $carried anyref) (param $id i32) (param $callNo i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $t (ref null $rec_ScopeTree))
    (local $c (ref null $rec_CellEntry))
    (local $n i32)
    local.get $store
    local.get $owner
    local.get $carried
    call $treeOf
    local.set $t
    local.get $t
    call $treeCells
    local.get $id
    call $cellOf
    local.set $c
    local.get $c
    call $entryCounts
    local.get $callNo
    call $countIn
    local.set $n
    local.get $store
    local.get $t
    local.get $id
    local.get $c
    call $entryFrames
    local.get $c
    struct.get $rec_CellEntry $f2
    local.get $c
    call $entrySlot
    local.get $c
    struct.get $rec_CellEntry $f4
    local.get $callNo
    local.get $n
    i32.const 1
    global.get $__s11
    call $__i32_add_chk
    local.get $c
    call $entryCounts
    call $__new_34
    ref.null any
    call $__new_28
    call $withCell
    call $storeSet
    local.get $n
    return
  )
  (func $countIn (param $counts anyref) (param $callNo i32) (result i32)
    (local $cur anyref)
    (local $k (ref null $rec_PlaceCount))
    (local $__gc6 anyref)
    local.get $counts
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.set $__gc6
    local.get $__gc6
    ref.test (ref null $rec_PlaceCount)
    local.get $__gc6
    ref.is_null
    i32.eqz
    i32.and
    (if (result i32)
      (then
    local.get $cur
    ref.cast (ref null $rec_PlaceCount)
    local.set $k
    local.get $k
    struct.get $rec_PlaceCount $f0
    local.get $callNo
    i32.eq
    (if (result i32)
      (then
    local.get $k
    struct.get $rec_PlaceCount $f1
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    local.get $k
    call $countRest
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
    unreachable ;; a loop with no break never ends
  )
  (func $countRest (param $k (ref null $rec_PlaceCount)) (result anyref)
    local.get $k
    struct.get $rec_PlaceCount $f2
    return
  )
  (func $closeStore (param $store anyref) (result i32)
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
    i32.const 1
    i32.const 0
    ref.null any
    ref.null any
    call $__new_40
    call $storeClose
    i32.const 0
  )
  (func $entryFrames (param $e (ref null $rec_CellEntry)) (result anyref)
    local.get $e
    struct.get $rec_CellEntry $f1
    return
  )
  (func $entrySlot (param $e (ref null $rec_CellEntry)) (result anyref)
    local.get $e
    struct.get $rec_CellEntry $f3
    return
  )
  (func $entryCounts (param $e (ref null $rec_CellEntry)) (result anyref)
    local.get $e
    struct.get $rec_CellEntry $f5
    return
  )
  (func $entryNext (param $e (ref null $rec_CellEntry)) (result anyref)
    local.get $e
    struct.get $rec_CellEntry $f6
    return
  )
  (func $resolve (param $c (ref null $closure)) (param $scope (ref null $rec_Scope)) (param $key (ref null $rec_Place)) (result anyref)
    (local $__fnv0 (ref null $closure))
    i32.const 0
    (if (result anyref)
      (then
    unreachable ;; an arm under a behavior test no value passes (decision 810 (1))
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $c
    local.set $__fnv0
    local.get $__fnv0
    local.get $scope
    local.get $key
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_2)
    call_ref $sig_2
    return
  )
  (func $enter (param $scope anyref) (param $key anyref) (result anyref)
    (local $__gc7 anyref)
    (local $__gc8 anyref)
    local.get $scope
    local.set $__gc7
    local.get $__gc7
    ref.test (ref null $rec_Scope)
    local.get $__gc7
    ref.is_null
    i32.eqz
    i32.and
    (if (result anyref)
      (then
    local.get $key
    local.set $__gc8
    local.get $__gc8
    ref.test (ref null $rec_Place)
    local.get $__gc8
    ref.is_null
    i32.eqz
    i32.and
    (if (result anyref)
      (then
    local.get $scope
    ref.cast (ref null $rec_Scope)
    local.get $key
    ref.cast (ref null $rec_Place)
    call $Scope_childAt
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $scope
    ref.cast (ref null $rec_Scope)
    call $Place_none
    call $Scope_childAt
    return
      )
      (else
        ref.null any
      )
    )
    drop
    global.get $__s12
    call $__panic_fail
    unreachable
    ref.null any
  )
  (func $answer (param $value anyref) (result anyref)
    local.get $value
    return
  )
  (func $nowhere (result anyref)
    call $Place_none
    return
  )
  (func $root (result anyref)
    call $Scope_root
    return
  )
  (func $stamp (param $c (ref null $closure)) (param $cell anyref) (param $callNo i32) (result (ref null $closure))
    (local $__mem0 i32)
    (local $__gc9 anyref)
    local.get $cell
    local.set $__gc9
    local.get $__gc9
    ref.test (ref null $rec_Scope)
    local.get $__gc9
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $closure))
      (then
    local.get $c
    local.get $callNo
    i32.const 1 ;; PlaceItem.Body
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_storeRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_ownerRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_carriedRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_cellId
    local.get $callNo
    call $countAt
    ref.null any
    i32.const 1
    call $__new_32
    call $placed
    return
      )
      (else
        ref.null $closure
      )
    )
    drop
    global.get $__s12
    call $__panic_fail
    unreachable
    ref.null $closure
  )
  (func $placed (param $c (ref null $closure)) (param $mine (ref null $rec_Place)) (result (ref null $closure))
    ref.func $__lambda0
    i32.const 2 ;; arity
    i32.const 0
    local.get $c ;; capture c
    local.get $mine ;; capture mine
    struct.new $env0
    return
  )
  (func $countNext (param $counter anyref) (param $callNo i32) (result i32)
    (local $__mem0 i32)
    (local $counts anyref)
    (local $n i32)
    local.get $counter
    call $countCellFilled
    (if (result anyref)
      (then
    local.get $counter
    call $countCellGet
      )
      (else
    ref.null any
      )
    )
    local.set $counts
    local.get $counts
    local.get $callNo
    call $countIn
    local.set $n
    local.get $counter
    local.get $callNo
    local.get $n
    i32.const 1
    global.get $__s13
    call $__i32_add_chk
    local.get $counts
    call $__new_34
    call $countCellSet
    local.get $n
    return
  )
  (func $sameKey (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    local.get $b
    call $__unk_eq
    return
  )
  ;; countCellFilled — .Wasm(wasi: .CellFilled)
  (func $countCellFilled (param $counter anyref) (result i32)
    local.get $counter
    call $__memo_cell_filled
  )
  ;; countCellGet — .Wasm(wasi: .CellGet)
  (func $countCellGet (param $counter anyref) (result anyref)
    local.get $counter
    call $__memo_cell_get
  )
  ;; countCellSet — .Wasm(wasi: .CellSet)
  (func $countCellSet (param $counter anyref) (param $value anyref)
    local.get $counter
    local.get $value
    call $__memo_cell_set
  )
  ;; storeNew — .Wasm(wasi: .CellNew)
  (func $storeNew (result anyref)
    call $__memo_cell_new
  )
  ;; storeLive — .Wasm(wasi: .CellFilled)
  (func $storeLive (param $store anyref) (result i32)
    local.get $store
    call $__memo_cell_filled
  )
  ;; storeGet — .Wasm(wasi: .CellGet)
  (func $storeGet (param $store anyref) (result anyref)
    local.get $store
    call $__memo_cell_get
  )
  ;; storeSet — .Wasm(wasi: .CellSet)
  (func $storeSet (param $store anyref) (param $value anyref)
    local.get $store
    local.get $value
    call $__memo_cell_set
  )
  ;; storeClose — .Wasm(wasi: .CellSet)
  (func $storeClose (param $store anyref) (param $closed anyref)
    local.get $store
    local.get $closed
    call $__memo_cell_set
  )
  ;; ownerSelf — .Wasm(wasi: .CellNew)
  (func $ownerSelf (result anyref)
    call $__memo_cell_new
  )
  ;; ownerForeign — .Wasm(wasi: .CellFilled)
  (func $ownerForeign (param $owner anyref) (result i32)
    local.get $owner
    call $__memo_cell_filled
  )
  (func $cleanup (result i32)
    i32.const 0
  )
  (func $effect (param $f (ref null $closure)) (result (ref null $closure))
    ref.func $__lambda1
    i32.const 2 ;; arity
    i32.const 0
    struct.new $env1
    return
  )
  (func $Widget (result (ref null $closure))
    ref.func $__lambda2
    i32.const 2 ;; arity
    i32.const 0
    struct.new $env2
    return
  )
  (func $bpScopeRaw__enter (param $s anyref) (param $k anyref) (result anyref)
    local.get $s
    local.get $k
    call $enter
    return
  )
  (func $bpScopeRaw__answer (param $v anyref) (result anyref)
    local.get $v
    call $answer
    return
  )
  (func $bpScopeRaw__run0 (param $c (ref null $closure)) (param $s anyref) (param $k anyref) (result i32)
    (local $__fnv0 (ref null $closure))
    local.get $c
    local.set $__fnv0
    local.get $__fnv0
    local.get $s
    local.get $k
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_2)
    call_ref $sig_2
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    return
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (param $scope (ref null $rec_Scope)) (param $key (ref null $rec_Place)) (result anyref)
    (local $c (ref null $closure))
    (local $mine (ref null $rec_Place))
    local.get $__env
    struct.get $env0 $c0
    local.set $c
    local.get $__env
    struct.get $env0 $c1
    local.set $mine
    local.get $c
    local.get $scope
    local.get $key
    struct.get $rec_Place $f4
    (if (result (ref null $rec_Place))
      (then
    local.get $key
      )
      (else
    local.get $mine
    local.get $key
    call $Place_with
      )
    )
    call $resolve
  )
  (func $__lambda0 (type $sig_2) (param $__env (ref null $closure)) (param $__a0 anyref) (param $__a1 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    local.get $__a0
    ref.cast (ref null $rec_Scope)
    local.get $__a1
    ref.cast (ref null $rec_Place)
    call $__lambda0__b
  )
  (func $__lambda1__b (param $__env (ref null $env1)) (param $bpScope__ anyref) (param $bpKey__ anyref) (result i32)
    local.get $bpScope__
    local.get $bpKey__
    call $bpScopeRaw__enter
    drop
    i32.const 0
    struct.new $box_i32
    call $bpScopeRaw__answer
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    return
  )
  (func $__lambda1 (type $sig_2) (param $__env (ref null $closure)) (param $__a0 anyref) (param $__a1 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env1)
    local.get $__a0
    local.get $__a1
    call $__lambda1__b
    struct.new $box_i32
  )
  (func $__lambda2__b (param $__env (ref null $env2)) (param $bpScope__ anyref) (param $bpKey__ anyref) (result (ref null $rec_Element))
    (local $__mem0 i32)
    (local $bpCell__1 anyref)
    (local $__runc0 (ref null $closure))
    (local $__runm0 i32)
    (local $__runw0 anyref)
    local.get $bpScope__
    local.get $bpKey__
    call $bpScopeRaw__enter
    local.set $bpCell__1
    ref.func $__lambda3
    i32.const 0 ;; arity
    i32.const 0
    struct.new $env3
    call $effect
    local.get $bpCell__1
    i32.const 1
    call $stamp__T_i32
    local.tee $__runc0
    struct.get $closure $mark ;; the lambda's mark: a state machine?
    local.set $__runm0
    local.get $__runc0
    local.get $bpCell__1
    call $nowhere
    local.get $__runc0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_2)
    call_ref $sig_2
    local.set $__runw0
    local.get $__runm0
    (if (result anyref)
      (then
    local.get $__runw0
    ref.cast (ref null $task)
    call $__task_block_on
    struct.get $task $value ;; the settled value
      )
      (else
    local.get $__runw0
      )
    )
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    drop
    call $__new_42
    call $bpScopeRaw__answer
    ref.cast (ref null $rec_Element)
    return
  )
  (func $__lambda2 (type $sig_2) (param $__env (ref null $closure)) (param $__a0 anyref) (param $__a1 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env2)
    local.get $__a0
    local.get $__a1
    call $__lambda2__b
  )
  (func $__lambda3__b (param $__env (ref null $env3)) (result i32)
    call $cleanup
  )
  (func $__lambda3 (type $sig_0) (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env3)
    call $__lambda3__b
    struct.new $box_i32
  )
  (func $stamp__T_i32 (param $c (ref null $closure)) (param $cell anyref) (param $callNo i32) (result (ref null $closure))
    (local $__mem0 i32)
    (local $__gc10 anyref)
    local.get $cell
    local.set $__gc10
    local.get $__gc10
    ref.test (ref null $rec_Scope)
    local.get $__gc10
    ref.is_null
    i32.eqz
    i32.and
    (if (result (ref null $closure))
      (then
    local.get $c
    local.get $callNo
    i32.const 1 ;; PlaceItem.Body
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_storeRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_ownerRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_carriedRef
    local.get $cell
    ref.cast (ref null $rec_Scope)
    call $Scope_cellId
    local.get $callNo
    call $countAt
    ref.null any
    i32.const 1
    call $__new_32
    call $placed__T_i32
    return
      )
      (else
        ref.null $closure
      )
    )
    drop
    global.get $__s12
    call $__panic_fail
    unreachable
    ref.null $closure
  )
  (func $placed__T_i32 (param $c (ref null $closure)) (param $mine (ref null $rec_Place)) (result (ref null $closure))
    ref.func $__lambda4
    i32.const 2 ;; arity
    i32.const 0
    local.get $c ;; capture c
    local.get $mine ;; capture mine
    struct.new $env4
    return
  )
  (func $__lambda4__b (param $__env (ref null $env4)) (param $scope (ref null $rec_Scope)) (param $key (ref null $rec_Place)) (result anyref)
    (local $c (ref null $closure))
    (local $mine (ref null $rec_Place))
    local.get $__env
    struct.get $env4 $c0
    local.set $c
    local.get $__env
    struct.get $env4 $c1
    local.set $mine
    local.get $c
    local.get $scope
    local.get $key
    struct.get $rec_Place $f4
    (if (result (ref null $rec_Place))
      (then
    local.get $key
      )
      (else
    local.get $mine
    local.get $key
    call $Place_with
      )
    )
    call $resolve__T_i32
  )
  (func $__lambda4 (type $sig_2) (param $__env (ref null $closure)) (param $__a0 anyref) (param $__a1 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env4)
    local.get $__a0
    ref.cast (ref null $rec_Scope)
    local.get $__a1
    ref.cast (ref null $rec_Place)
    call $__lambda4__b
  )
  (func $resolve__T_i32 (param $c (ref null $closure)) (param $scope (ref null $rec_Scope)) (param $key (ref null $rec_Place)) (result anyref)
    (local $__fnv0 (ref null $closure))
    i32.const 0
    (if (result anyref)
      (then
    unreachable ;; an arm under a behavior test no value passes (decision 810 (1))
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $c
    local.set $__fnv0
    local.get $__fnv0
    local.get $scope
    local.get $key
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_2)
    call_ref $sig_2
    return
  )
  (func $__eq_Element (param $a (ref null $rec_Element)) (param $b (ref null $rec_Element)) (result i32)
    i32.const 1
  )
  (func $__unk_int_in (param $v anyref) (param $lo i32) (param $hi i32) (result i32)
    (local $k i32)
    (local $x f64)
    local.get $v
    ref.is_null
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_bool)
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.tee $k
    local.get $lo
    i32.ge_s
    local.get $k
    local.get $hi
    i32.le_s
    i32.and
    return
      )
    )
    local.get $v
    ref.test (ref null $box_f64)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    local.tee $x
    f64.floor
    local.get $x
    f64.ne
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $x
    local.get $lo
    f64.convert_i32_s
    f64.ge
    local.get $x
    local.get $hi
    f64.convert_i32_s
    f64.le
    i32.and
  )
  (func $__unk_as_i32 (param $v anyref) (result i32)
    local.get $v
    ref.test (ref null $box_f64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    i32.trunc_f64_s
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
  )
  (func $__unk_is_num (param $v anyref) (result i32)
    local.get $v
    ref.is_null
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    local.get $v
    ref.test (ref null $box_bool)
    i32.eqz
    i32.and
    local.get $v
    ref.test (ref null $box_f64)
    i32.or
  )
  (func $__unk_as_f64 (param $v anyref) (result f64)
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    f64.convert_i32_s
    return
      )
    )
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
  )
  (func $__unk_eq (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    call $__unk_is_num
    local.get $b
    call $__unk_is_num
    i32.and
    (if
      (then
    local.get $a
    call $__unk_as_f64
    local.get $b
    call $__unk_as_f64
    f64.eq
    return
      )
    )
    local.get $a
    ref.test (ref null $str)
    local.get $a
    ref.is_null
    i32.eqz
    i32.and
    local.get $b
    ref.test (ref null $str)
    i32.and
    local.get $b
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $a
    ref.cast (ref null $str)
    local.get $b
    ref.cast (ref null $str)
    call $__str_eq
    return
      )
    )
    local.get $a
    ref.test (ref null $box_bool)
    local.get $a
    ref.is_null
    i32.eqz
    i32.and
    local.get $b
    ref.test (ref null $box_bool)
    i32.and
    local.get $b
    ref.is_null
    i32.eqz
    i32.and
    (if
      (then
    local.get $a
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.get $b
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    i32.eq
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr1 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr2 (param $v i32)
    local.get $v
    i32.const 0
    i32.eq
    (if
      (then
    global.get $__s18
    call $__print_str_raw
    return
      )
    )
    local.get $v
    i32.const 1
    i32.eq
    (if
      (then
    global.get $__s19
    call $__print_str_raw
    return
      )
    )
    local.get $v
    i32.const 2
    i32.eq
    (if
      (then
    global.get $__s20
    call $__print_str_raw
    return
      )
    )
    local.get $v
    i32.const 3
    i32.eq
    (if
      (then
    global.get $__s21
    call $__print_str_raw
    return
      )
    )
    local.get $v
    i32.const 4
    i32.eq
    (if
      (then
    global.get $__s22
    call $__print_str_raw
    return
      )
    )
  )
  (func $__unk_print_q (param $v anyref)
    local.get $v
    ref.is_null
    (if
      (then
    global.get $__s25
    call $__print_str_raw
    return
      )
    )
    local.get $v
    call $__print_ebox
    (if
      (then
    return
      )
    )
    local.get $v
    call $__print_arrs
    (if
      (then
    return
      )
    )
    local.get $v
    ref.test (ref null $box_bool)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_bool)
    struct.get $box_bool $v
    call $__print_bool_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_f64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    call $__print_f64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_u64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_u64)
    struct.get $box_u64 $v
    call $__print_u64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    call $__print_i64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $str)
    (if
      (then
    local.get $v
    ref.cast (ref null $str)
    call $__print_quoted_raw
    return
      )
    )
    local.get $v
    call $__print_tagged_raw
  )
  (func $__pr3 (param $v anyref)
    local.get $v
    call $__unk_print_q
  )
  (func $__pr4 (param $v i32)
    local.get $v
    call $__print_bool_raw
  )
  (func $__pr0 (param $v (ref null $rec_Place))
    global.get $__s14
    call $__print_str_raw
    global.get $__s15
    call $__print_str_raw
    global.get $__s16
    call $__print_str_raw
    local.get $v
    struct.get $rec_Place $f0
    call $__pr1
    global.get $__s17
    call $__print_str_raw
    local.get $v
    struct.get $rec_Place $f1
    call $__pr2
    global.get $__s23
    call $__print_str_raw
    local.get $v
    struct.get $rec_Place $f2
    call $__pr1
    global.get $__s24
    call $__print_str_raw
    local.get $v
    struct.get $rec_Place $f3
    call $__pr3
    global.get $__s26
    call $__print_str_raw
    local.get $v
    struct.get $rec_Place $f4
    call $__pr4
    global.get $__s27
    call $__print_str_raw
  )
  (func $__tip3 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Place)
    call $__pr0
  )
  (func $__tie3 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Place)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr5 (param $v (ref null $rec_Scope))
    global.get $__s29
    call $__print_str_raw
    global.get $__s15
    call $__print_str_raw
    global.get $__s30
    call $__print_str_raw
    local.get $v
    struct.get $rec_Scope $f0
    call $__pr3
    global.get $__s31
    call $__print_str_raw
    local.get $v
    struct.get $rec_Scope $f1
    call $__pr1
    global.get $__s32
    call $__print_str_raw
    local.get $v
    struct.get $rec_Scope $f2
    call $__pr3
    global.get $__s33
    call $__print_str_raw
    local.get $v
    struct.get $rec_Scope $f3
    call $__pr3
    global.get $__s27
    call $__print_str_raw
  )
  (func $__tip4 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Scope)
    call $__pr5
  )
  (func $__tie4 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Scope)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr6 (param $v (ref null $rec_Carried))
    global.get $__s35
    call $__print_str_raw
    global.get $__s15
    call $__print_str_raw
    global.get $__s36
    call $__print_str_raw
    local.get $v
    struct.get $rec_Carried $f0
    call $__pr3
    global.get $__s27
    call $__print_str_raw
  )
  (func $__tip5 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Carried)
    call $__pr6
  )
  (func $__tie5 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Carried)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr7 (param $v (ref null $rec_CellEntry))
    global.get $__s38
    call $__print_str_raw
    global.get $__s15
    call $__print_str_raw
    global.get $__s39
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f0
    call $__pr1
    global.get $__s40
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f1
    call $__pr3
    global.get $__s41
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f2
    call $__pr1
    global.get $__s42
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f3
    call $__pr3
    global.get $__s43
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f4
    call $__pr4
    global.get $__s44
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f5
    call $__pr3
    global.get $__s45
    call $__print_str_raw
    local.get $v
    struct.get $rec_CellEntry $f6
    call $__pr3
    global.get $__s27
    call $__print_str_raw
  )
  (func $__tip6 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_CellEntry)
    call $__pr7
  )
  (func $__tie6 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_CellEntry)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr8 (param $v (ref null $rec_ScopeTree))
    global.get $__s47
    call $__print_str_raw
    global.get $__s15
    call $__print_str_raw
    global.get $__s48
    call $__print_str_raw
    local.get $v
    struct.get $rec_ScopeTree $f0
    call $__pr4
    global.get $__s49
    call $__print_str_raw
    local.get $v
    struct.get $rec_ScopeTree $f1
    call $__pr1
    global.get $__s50
    call $__print_str_raw
    local.get $v
    struct.get $rec_ScopeTree $f2
    call $__pr3
    global.get $__s51
    call $__print_str_raw
    local.get $v
    struct.get $rec_ScopeTree $f3
    call $__pr3
    global.get $__s27
    call $__print_str_raw
  )
  (func $__tip7 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_ScopeTree)
    call $__pr8
  )
  (func $__tie7 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_ScopeTree)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr10 (param $v anyref)
    local.get $v
    call $__print_tagged_raw
  )
  (func $__pr9 (param $v (ref null $rec_PlaceLink))
    global.get $__s53
    call $__print_str_raw
    global.get $__s15
    call $__print_str_raw
    global.get $__s54
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceLink $f0
    call $__pr1
    global.get $__s55
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceLink $f1
    call $__pr10
    global.get $__s56
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceLink $f2
    call $__pr1
    global.get $__s57
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceLink $f3
    call $__pr1
    global.get $__s58
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceLink $f4
    call $__pr3
    global.get $__s27
    call $__print_str_raw
  )
  (func $__tip8 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_PlaceLink)
    call $__pr9
  )
  (func $__tie8 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_PlaceLink)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr11 (param $v (ref null $rec_PlaceCount))
    global.get $__s60
    call $__print_str_raw
    global.get $__s15
    call $__print_str_raw
    global.get $__s61
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceCount $f0
    call $__pr1
    global.get $__s62
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceCount $f1
    call $__pr1
    global.get $__s63
    call $__print_str_raw
    local.get $v
    struct.get $rec_PlaceCount $f2
    call $__pr3
    global.get $__s27
    call $__print_str_raw
  )
  (func $__tip12 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_PlaceCount)
    call $__pr11
  )
  (func $__tie12 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_PlaceCount)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
  )
  (func $__pr12 (param $v (ref null $rec_Element))
    global.get $__s65
    call $__print_str_raw
  )
  (func $__tip19 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Element)
    call $__pr12
  )
  (func $__tie19 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Element)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Element)
    local.get $b
    ref.cast (ref null $rec_Element)
    call $__eq_Element
  )
  (func $__unk_eq_s2 (param $a (ref null $rec_Context)) (param $b (ref null $rec_Context)) (result i32)
    local.get $a
    struct.get $rec_Context $f0
    local.get $b
    struct.get $rec_Context $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s3 (param $a (ref null $rec_Place)) (param $b (ref null $rec_Place)) (result i32)
    local.get $a
    struct.get $rec_Place $f0
    local.get $b
    struct.get $rec_Place $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Place $f1
    local.get $b
    struct.get $rec_Place $f1
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Place $f2
    local.get $b
    struct.get $rec_Place $f2
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Place $f3
    local.get $b
    struct.get $rec_Place $f3
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Place $f4
    local.get $b
    struct.get $rec_Place $f4
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s4 (param $a (ref null $rec_Scope)) (param $b (ref null $rec_Scope)) (result i32)
    local.get $a
    struct.get $rec_Scope $f0
    local.get $b
    struct.get $rec_Scope $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Scope $f1
    local.get $b
    struct.get $rec_Scope $f1
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Scope $f2
    local.get $b
    struct.get $rec_Scope $f2
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Scope $f3
    local.get $b
    struct.get $rec_Scope $f3
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s5 (param $a (ref null $rec_Carried)) (param $b (ref null $rec_Carried)) (result i32)
    local.get $a
    struct.get $rec_Carried $f0
    local.get $b
    struct.get $rec_Carried $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s6 (param $a (ref null $rec_CellEntry)) (param $b (ref null $rec_CellEntry)) (result i32)
    local.get $a
    struct.get $rec_CellEntry $f0
    local.get $b
    struct.get $rec_CellEntry $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f1
    local.get $b
    struct.get $rec_CellEntry $f1
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f2
    local.get $b
    struct.get $rec_CellEntry $f2
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f3
    local.get $b
    struct.get $rec_CellEntry $f3
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f4
    local.get $b
    struct.get $rec_CellEntry $f4
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f5
    local.get $b
    struct.get $rec_CellEntry $f5
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_CellEntry $f6
    local.get $b
    struct.get $rec_CellEntry $f6
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s7 (param $a (ref null $rec_ScopeTree)) (param $b (ref null $rec_ScopeTree)) (result i32)
    local.get $a
    struct.get $rec_ScopeTree $f0
    local.get $b
    struct.get $rec_ScopeTree $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_ScopeTree $f1
    local.get $b
    struct.get $rec_ScopeTree $f1
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_ScopeTree $f2
    local.get $b
    struct.get $rec_ScopeTree $f2
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_ScopeTree $f3
    local.get $b
    struct.get $rec_ScopeTree $f3
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s8 (param $a (ref null $rec_PlaceLink)) (param $b (ref null $rec_PlaceLink)) (result i32)
    local.get $a
    struct.get $rec_PlaceLink $f0
    local.get $b
    struct.get $rec_PlaceLink $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceLink $f1
    local.get $b
    struct.get $rec_PlaceLink $f1
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceLink $f2
    local.get $b
    struct.get $rec_PlaceLink $f2
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceLink $f3
    local.get $b
    struct.get $rec_PlaceLink $f3
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceLink $f4
    local.get $b
    struct.get $rec_PlaceLink $f4
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s12 (param $a (ref null $rec_PlaceCount)) (param $b (ref null $rec_PlaceCount)) (result i32)
    local.get $a
    struct.get $rec_PlaceCount $f0
    local.get $b
    struct.get $rec_PlaceCount $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceCount $f1
    local.get $b
    struct.get $rec_PlaceCount $f1
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_PlaceCount $f2
    local.get $b
    struct.get $rec_PlaceCount $f2
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s19 (param $a (ref null $rec_Element)) (param $b (ref null $rec_Element)) (result i32)
    i32.const 1
  )
  (func $__unk_eq_s22 (param $a (ref null $box_i64)) (param $b (ref null $box_i64)) (result i32)
    local.get $a
    struct.get $box_i64 $v
    local.get $b
    struct.get $box_i64 $v
    i64.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_ref (param $a anyref) (param $b anyref) (result i32)
    local.get $a
    ref.is_null
    local.get $b
    ref.is_null
    i32.or
    (if
      (then
    local.get $a
    ref.is_null
    local.get $b
    ref.is_null
    i32.and
    return
      )
    )
    local.get $a
    ref.cast (ref null eq)
    local.get $b
    ref.cast (ref null eq)
    ref.eq
    (if
      (then
    i32.const 1
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Context)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Context)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Context)
    local.get $b
    ref.cast (ref null $rec_Context)
    call $__unk_eq_s2
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Place)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Place)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Place)
    local.get $b
    ref.cast (ref null $rec_Place)
    call $__unk_eq_s3
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Scope)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Scope)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Scope)
    local.get $b
    ref.cast (ref null $rec_Scope)
    call $__unk_eq_s4
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Carried)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Carried)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Carried)
    local.get $b
    ref.cast (ref null $rec_Carried)
    call $__unk_eq_s5
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_CellEntry)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_CellEntry)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_CellEntry)
    local.get $b
    ref.cast (ref null $rec_CellEntry)
    call $__unk_eq_s6
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_ScopeTree)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_ScopeTree)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_ScopeTree)
    local.get $b
    ref.cast (ref null $rec_ScopeTree)
    call $__unk_eq_s7
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_PlaceLink)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_PlaceLink)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_PlaceLink)
    local.get $b
    ref.cast (ref null $rec_PlaceLink)
    call $__unk_eq_s8
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_PlaceCount)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_PlaceCount)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_PlaceCount)
    local.get $b
    ref.cast (ref null $rec_PlaceCount)
    call $__unk_eq_s12
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Element)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Element)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Element)
    local.get $b
    ref.cast (ref null $rec_Element)
    call $__unk_eq_s19
    return
      )
    )
    local.get $a
    ref.test (ref null $box_i64)
    (if
      (then
    local.get $b
    ref.test (ref null $box_i64)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $box_i64)
    local.get $b
    ref.cast (ref null $box_i64)
    call $__unk_eq_s22
    return
      )
    )
    local.get $a
    ref.test (ref null $__decl)
    local.get $b
    ref.test (ref null $__decl)
    i32.and
    (if
      (then
    local.get $a
    local.get $b
    call $__eq_decl
    return
      )
    )
    i32.const 0
  )
  (func $__pr13 (param $v (ref null $rec_Context))
    global.get $__s68
    call $__print_str_raw
    global.get $__s15
    call $__print_str_raw
    global.get $__s69
    call $__print_str_raw
    local.get $v
    struct.get $rec_Context $f0
    call $__pr3
    global.get $__s27
    call $__print_str_raw
  )
  (func $__print_tagged_raw (param $v anyref)
    local.get $v
    ref.test (ref null $closure)
    (if
      (then
    global.get $__s67
    call $__print_str_raw
    local.get $v
    ref.cast (ref null $closure)
    struct.get $closure $arity
    call $__print_i32_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Context)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Context)
    call $__pr13
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Place)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Place)
    call $__pr0
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Scope)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Scope)
    call $__pr5
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Carried)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Carried)
    call $__pr6
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_CellEntry)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_CellEntry)
    call $__pr7
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_ScopeTree)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_ScopeTree)
    call $__pr8
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_PlaceLink)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_PlaceLink)
    call $__pr9
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_PlaceCount)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_PlaceCount)
    call $__pr11
    return
      )
    )
    local.get $v
    ref.test (ref null $task)
    (if
      (then
    global.get $__s70
    call $__panic_fail
    unreachable
      )
    )
    local.get $v
    ref.test (ref null $rec_Element)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Element)
    call $__pr12
    return
      )
    )
    local.get $v
    ref.test (ref null $__decl)
    (if
      (then
    local.get $v
    call $__print_decl
    return
      )
    )
    unreachable
  )
  (func $__print_ebox (param $v anyref) (result i32)
    i32.const 0
  )
  (func $__print_arrs (param $v anyref) (result i32)
    i32.const 0
  )
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
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
  (func $__print_str_raw (param $s (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    local.get $s
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $s
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
  )
  (func $__print_str (param $s (ref null $str))
    local.get $s
    call $__print_str_raw
    call $__print_nl
  )
  (func $__print_bool (param $b i32)
    local.get $b
    call $__print_bool_raw
    call $__print_nl
  )
  (func $__print_bool_raw (param $b i32)
    local.get $b
    (if
      (then
        ;; "true" as a little-endian i32
        i32.const 16
        i32.const 1702195828
        i32.store
        i32.const 16
        i32.const 4
        call $__write_bytes
      )
      (else
        ;; "fals" + 'e'
        i32.const 16
        i32.const 1936482662
        i32.store
        i32.const 16
        i32.const 101
        i32.store8 offset=4
        i32.const 16
        i32.const 5
        call $__write_bytes
      )
    )
  )
  (func $__print_f64 (param $x f64)
    local.get $x
    call $__print_f64_raw
    call $__print_nl
  )
  (func $__print_f64_raw (param $x f64)
    (local $s i32) (local $top i32)
    global.get $__heap_ptr
    local.set $top
    local.get $x
    call $__std_number_floatToString
    local.set $s
    local.get $s
    i32.const 4
    i32.add
    local.get $s
    i32.load
    call $__write_bytes
    local.get $top
    global.set $__heap_ptr
  )
  (func $__str_concat (param $a (ref null $str)) (param $b (ref null $str)) (result (ref null $str))
    (local $r (ref null $str)) (local $alen i32) (local $blen i32)
    local.get $a
    array.len
    local.set $alen
    local.get $b
    array.len
    local.set $blen
    local.get $alen
    local.get $blen
    i32.add
    array.new_default $str
    local.set $r
    local.get $r
    i32.const 0
    local.get $a
    i32.const 0
    local.get $alen
    array.copy $str $str
    local.get $r
    local.get $alen
    local.get $b
    i32.const 0
    local.get $blen
    array.copy $str $str
    local.get $r
  )
  (func $__str_eq (param $a (ref null $str)) (param $b (ref null $str)) (result i32)
    (local $i i32) (local $n i32) (local $an i32) (local $bn i32)
    local.get $a
    ref.is_null
    local.set $an
    local.get $b
    ref.is_null
    local.set $bn
    local.get $an
    local.get $bn
    i32.or
    (if
      (then
        local.get $an
        local.get $bn
        i32.and
        return
      )
    )
    local.get $a
    array.len
    local.set $n
    local.get $n
    local.get $b
    array.len
    i32.ne
    (if
      (then
        i32.const 0
        return
      )
    )
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $a
        local.get $i
        array.get_u $str
        local.get $b
        local.get $i
        array.get_u $str
        i32.ne
        (if
          (then
            i32.const 0
            return
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 1
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
  (func $__panic_fail (param $msg (ref null $str))
    (local $n i32) (local $p i32) (local $i i32) (local $top i32)
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
    local.get $msg
    array.len
    local.set $n
    global.get $__heap_ptr
    local.set $top
    local.get $n
    call $__alloc
    local.set $p
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $p
        local.get $i
        i32.add
        local.get $msg
        local.get $i
        array.get_u $str
        i32.store8
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
    local.get $n
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
    local.get $top
    global.set $__heap_ptr
  )
  (func $__print_quoted_raw (param $s (ref null $str))
    (local $n i32) (local $i i32) (local $ch i32) (local $e i32)
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
    local.get $s
    array.len
    local.set $n
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $s
        local.get $i
        array.get_u $str
        local.set $ch
        i32.const 0
        local.set $e
        local.get $ch
        i32.const 34
        i32.eq
        local.get $ch
        i32.const 92
        i32.eq
        i32.or
        (if
          (then
            local.get $ch
            local.set $e
          )
        )
        local.get $ch
        i32.const 10
        i32.eq
        (if
          (then
            i32.const 110
            local.set $e
          )
        )
        local.get $ch
        i32.const 13
        i32.eq
        (if
          (then
            i32.const 114
            local.set $e
          )
        )
        local.get $ch
        i32.const 9
        i32.eq
        (if
          (then
            i32.const 116
            local.set $e
          )
        )
        local.get $e
        (if
          (then
            i32.const 8
            i32.const 92
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
            i32.const 8
            local.get $e
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
          (else
            i32.const 8
            local.get $ch
            i32.store8
            i32.const 8
            i32.const 1
            call $__write_bytes
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    i32.const 8
    i32.const 34
    i32.store8
    i32.const 8
    i32.const 1
    call $__write_bytes
  )
  (func $__print_i64_raw (param $v i64)
    local.get $v
    call $__std_number_i64ToString
    call $__print_str_raw
  )
  (func $__print_i64 (param $v i64)
    local.get $v
    call $__print_i64_raw
    call $__print_nl
  )
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
  (func $__print_u64_raw (param $v i64)
    local.get $v
    call $__std_number_u64ToString
    call $__print_str_raw
  )
  (func $__print_u64 (param $v i64)
    local.get $v
    call $__print_u64_raw
    call $__print_nl
  )
  (global $__task_head (mut (ref null $task)) (ref.null $task))
  (global $__task_tail (mut (ref null $task)) (ref.null $task))
  (global $__task_suspended (mut i32) (i32.const 0))
  (func $__task_new (param $kind i32) (param $frame structref) (result (ref null $task))
    i32.const 0
    ref.null $waiter
    ref.null any
    local.get $frame
    local.get $kind
    ref.null $task
    ref.null any
    i32.const 0
    struct.new $task
  )
  (func $__task_start (param $kind i32) (param $frame structref) (result (ref null $task))
    (local $t (ref null $task))
    local.get $kind
    local.get $frame
    call $__task_new
    local.tee $t
    call $__task_resume
    local.get $t
  )
  (func $__task_pending (param $t (ref null $task)) (result i32)
    local.get $t
    struct.get $task $state
    i32.eqz
  )
  (func $__task_listen (param $t (ref null $task)) (param $kind i32) (param $target (ref null $task)) (param $index i32)
    (local $n (ref null $waiter))
    local.get $t
    struct.get $task $waiters
    local.get $kind
    local.get $target
    local.get $index
    struct.new $waiter
    local.set $n
    local.get $t
    local.get $n
    struct.set $task $waiters
  )
  (func $__task_wait (param $t (ref null $task)) (param $w (ref null $task))
    local.get $t
    i32.const 0
    local.get $w
    i32.const 0
    call $__task_listen
  )
  (func $__task_settle (param $t (ref null $task)) (param $v anyref)
    local.get $t
    local.get $v
    struct.set $task $value
    local.get $t
    call $__task_wake
  )
  (func $__task_wake (param $t (ref null $task))
    (local $n (ref null $waiter)) (local $m (ref null $waiter)) (local $r (ref null $waiter)) (local $k i32) (local $w (ref null $task))
    local.get $t
    struct.get $task $state
    (if
      (then
        return
      )
    )
    local.get $t
    i32.const 1
    struct.set $task $state
    local.get $t
    struct.get $task $waiters
    local.set $n
    local.get $t
    ref.null $waiter
    struct.set $task $waiters
    local.get $t
    ref.null struct
    struct.set $task $frame
    (block $brk
      (loop $cont
        local.get $n
        ref.is_null
        br_if $brk
        local.get $n
        struct.get $waiter $next
        local.set $m
        local.get $n
        local.get $r
        struct.set $waiter $next
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
        ref.is_null
        br_if $brk
        local.get $r
        struct.get $waiter $kind
        local.set $k
        local.get $r
        struct.get $waiter $target
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
            struct.get $task $state
            i32.eqz
            (if
              (then
                local.get $w
                local.get $t
                struct.get $task $value
                struct.set $task $value
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
            struct.get $task $aux
            ref.cast (ref null $arr_any)
            local.get $r
            struct.get $waiter $slot
            local.get $t
            struct.get $task $value
            array.set $arr_any
            local.get $w
            local.get $w
            struct.get $task $left
            i32.const 1
            i32.sub
            struct.set $task $left
            local.get $w
            struct.get $task $left
            i32.eqz
            (if
              (then
                local.get $w
                local.get $w
                struct.get $task $aux
                struct.set $task $value
                local.get $w
                ref.null any
                struct.set $task $aux
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $r
        struct.get $waiter $next
        local.set $r
        br $cont
      )
    )
  )
  (func $__task_enqueue (param $t (ref null $task))
    local.get $t
    ref.null $task
    struct.set $task $next
    global.get $__task_tail
    ref.is_null
    (if
      (then
        local.get $t
        global.set $__task_head
      )
      (else
        global.get $__task_tail
        local.get $t
        struct.set $task $next
      )
    )
    local.get $t
    global.set $__task_tail
  )
  (func $__task_drain
    (local $t (ref null $task))
    (block $brk
      (loop $cont
        global.get $__task_head
        local.tee $t
        ref.is_null
        br_if $brk
        local.get $t
        struct.get $task $next
        global.set $__task_head
        global.get $__task_head
        ref.is_null
        (if
          (then
            ref.null $task
            global.set $__task_tail
          )
        )
        local.get $t
        call $__task_resume
        br $cont
      )
    )
  )
  (func $__task_block_on (param $t (ref null $task)) (result (ref null $task))
    (local $r (ref null $task))
    (block $brk
      (loop $cont
        local.get $t
        struct.get $task $state
        br_if $brk
        global.get $__task_head
        local.tee $r
        ref.is_null
        (if
          (then
            unreachable
          )
        )
        local.get $r
        struct.get $task $next
        global.set $__task_head
        global.get $__task_head
        ref.is_null
        (if
          (then
            ref.null $task
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
  (func $__task_resume (param $t (ref null $task))
    (local $k i32)
    local.get $t
    struct.get $task $kind ;; kind
    local.set $k
    unreachable
  )
  (func $__task_host_poll (result i32)
    i32.const 0
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (func $__memo_cell_new (result (ref null $cell))
    i32.const 0
    ref.null any
    struct.new $cell
  )
  (func $__memo_cell_filled (param $c anyref) (result i32)
    local.get $c
    ref.cast (ref null $cell)
    struct.get $cell $filled
  )
  (func $__memo_cell_get (param $c anyref) (result anyref)
    local.get $c
    ref.cast (ref null $cell)
    struct.get $cell $value
  )
  (func $__memo_cell_set (param $c anyref) (param $v anyref)
    local.get $c
    ref.cast (ref null $cell)
    local.get $v
    struct.set $cell $value
    local.get $c
    ref.cast (ref null $cell)
    i32.const 1
    struct.set $cell $filled
  )
  (func $__std_number_i32ToString (param $p0 i32) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_i32ToString
    ref.cast (ref null $str)
  )
  (func $__std_number_i64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_i64ToString
    ref.cast (ref null $str)
  )
  (func $__std_number_u64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_u64ToString
    ref.cast (ref null $str)
  )
  (data $__d0 "`use provide` / `use context` are lowered where they are written; this body never runs")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "scope-foreign: a scope is read in another process than its root's — pass `scope.detach()` to another process (decision 824 (3))")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "scope-closed: a scope is used after its root's `close()` (decision 825 (2))")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "a scope names a cell its tree does not hold (decision 817)")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "key-duplicate: two siblings carry the key ")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 " (decision 819 (5))")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "integer overflow: - on i32 at src/context.bp:306:52")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "integer overflow: + on i32 at src/context.bp:309:17")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "integer overflow: + on i32 at src/context.bp:317:9")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "\"")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "of another type")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "integer overflow: + on i32 at src/context.bp:373:9")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "a component is run with a `Scope` (decision 819)")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "integer overflow: + on i32 at src/context.bp:612:9")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (data $__d14 "Place")
  (global $__s14 (mut (ref null $str)) (ref.null $str))
  (data $__d15 "(")
  (global $__s15 (mut (ref null $str)) (ref.null $str))
  (data $__d16 "callNo: ")
  (global $__s16 (mut (ref null $str)) (ref.null $str))
  (data $__d17 ", item: ")
  (global $__s17 (mut (ref null $str)) (ref.null $str))
  (data $__d18 "PlaceItem.Absent")
  (global $__s18 (mut (ref null $str)) (ref.null $str))
  (data $__d19 "PlaceItem.Body")
  (global $__s19 (mut (ref null $str)) (ref.null $str))
  (data $__d20 "PlaceItem.Plain")
  (global $__s20 (mut (ref null $str)) (ref.null $str))
  (data $__d21 "PlaceItem.Index")
  (global $__s21 (mut (ref null $str)) (ref.null $str))
  (data $__d22 "PlaceItem.Key")
  (global $__s22 (mut (ref null $str)) (ref.null $str))
  (data $__d23 ", itemNo: ")
  (global $__s23 (mut (ref null $str)) (ref.null $str))
  (data $__d24 ", keyValue: ")
  (global $__s24 (mut (ref null $str)) (ref.null $str))
  (data $__d25 "null")
  (global $__s25 (mut (ref null $str)) (ref.null $str))
  (data $__d26 ", stamped: ")
  (global $__s26 (mut (ref null $str)) (ref.null $str))
  (data $__d27 ")")
  (global $__s27 (mut (ref null $str)) (ref.null $str))
  (data $__d28 "std@context.Place")
  (global $__s28 (mut (ref null $str)) (ref.null $str))
  (data $__d29 "Scope")
  (global $__s29 (mut (ref null $str)) (ref.null $str))
  (data $__d30 "scopeStore: ")
  (global $__s30 (mut (ref null $str)) (ref.null $str))
  (data $__d31 ", scopeCell: ")
  (global $__s31 (mut (ref null $str)) (ref.null $str))
  (data $__d32 ", scopeOwner: ")
  (global $__s32 (mut (ref null $str)) (ref.null $str))
  (data $__d33 ", scopeCarried: ")
  (global $__s33 (mut (ref null $str)) (ref.null $str))
  (data $__d34 "std@context.Scope")
  (global $__s34 (mut (ref null $str)) (ref.null $str))
  (data $__d35 "Carried")
  (global $__s35 (mut (ref null $str)) (ref.null $str))
  (data $__d36 "frames: ")
  (global $__s36 (mut (ref null $str)) (ref.null $str))
  (data $__d37 "std@context.Carried")
  (global $__s37 (mut (ref null $str)) (ref.null $str))
  (data $__d38 "CellEntry")
  (global $__s38 (mut (ref null $str)) (ref.null $str))
  (data $__d39 "cellNo: ")
  (global $__s39 (mut (ref null $str)) (ref.null $str))
  (data $__d40 ", cellFrames: ")
  (global $__s40 (mut (ref null $str)) (ref.null $str))
  (data $__d41 ", cellGen: ")
  (global $__s41 (mut (ref null $str)) (ref.null $str))
  (data $__d42 ", cellSlot: ")
  (global $__s42 (mut (ref null $str)) (ref.null $str))
  (data $__d43 ", cellFilled: ")
  (global $__s43 (mut (ref null $str)) (ref.null $str))
  (data $__d44 ", cellCounts: ")
  (global $__s44 (mut (ref null $str)) (ref.null $str))
  (data $__d45 ", cellNext: ")
  (global $__s45 (mut (ref null $str)) (ref.null $str))
  (data $__d46 "std@context.CellEntry")
  (global $__s46 (mut (ref null $str)) (ref.null $str))
  (data $__d47 "ScopeTree")
  (global $__s47 (mut (ref null $str)) (ref.null $str))
  (data $__d48 "treeClosed: ")
  (global $__s48 (mut (ref null $str)) (ref.null $str))
  (data $__d49 ", treeCount: ")
  (global $__s49 (mut (ref null $str)) (ref.null $str))
  (data $__d50 ", treeCells: ")
  (global $__s50 (mut (ref null $str)) (ref.null $str))
  (data $__d51 ", treeLinks: ")
  (global $__s51 (mut (ref null $str)) (ref.null $str))
  (data $__d52 "std@context.ScopeTree")
  (global $__s52 (mut (ref null $str)) (ref.null $str))
  (data $__d53 "PlaceLink")
  (global $__s53 (mut (ref null $str)) (ref.null $str))
  (data $__d54 "linkParent: ")
  (global $__s54 (mut (ref null $str)) (ref.null $str))
  (data $__d55 ", linkPlace: ")
  (global $__s55 (mut (ref null $str)) (ref.null $str))
  (data $__d56 ", linkChild: ")
  (global $__s56 (mut (ref null $str)) (ref.null $str))
  (data $__d57 ", linkSeen: ")
  (global $__s57 (mut (ref null $str)) (ref.null $str))
  (data $__d58 ", linkNext: ")
  (global $__s58 (mut (ref null $str)) (ref.null $str))
  (data $__d59 "std@context.PlaceLink")
  (global $__s59 (mut (ref null $str)) (ref.null $str))
  (data $__d60 "PlaceCount")
  (global $__s60 (mut (ref null $str)) (ref.null $str))
  (data $__d61 "countCall: ")
  (global $__s61 (mut (ref null $str)) (ref.null $str))
  (data $__d62 ", countValue: ")
  (global $__s62 (mut (ref null $str)) (ref.null $str))
  (data $__d63 ", countNext: ")
  (global $__s63 (mut (ref null $str)) (ref.null $str))
  (data $__d64 "std@context.PlaceCount")
  (global $__s64 (mut (ref null $str)) (ref.null $str))
  (data $__d65 "Element")
  (global $__s65 (mut (ref null $str)) (ref.null $str))
  (data $__d66 "test@main.Element")
  (global $__s66 (mut (ref null $str)) (ref.null $str))
  (data $__d67 "fn/")
  (global $__s67 (mut (ref null $str)) (ref.null $str))
  (data $__d68 "Context")
  (global $__s68 (mut (ref null $str)) (ref.null $str))
  (data $__d69 "contextValue: ")
  (global $__s69 (mut (ref null $str)) (ref.null $str))
  (data $__d70 "wasm cannot print a Task value dynamically yet")
  (global $__s70 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 86
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 129
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 75
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 58
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 42
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 19
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 51
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 51
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 50
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 1
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 15
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 50
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 48
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 50
    array.new_data $str $__d13
    global.set $__s13
    i32.const 0
    i32.const 5
    array.new_data $str $__d14
    global.set $__s14
    i32.const 0
    i32.const 1
    array.new_data $str $__d15
    global.set $__s15
    i32.const 0
    i32.const 8
    array.new_data $str $__d16
    global.set $__s16
    i32.const 0
    i32.const 8
    array.new_data $str $__d17
    global.set $__s17
    i32.const 0
    i32.const 16
    array.new_data $str $__d18
    global.set $__s18
    i32.const 0
    i32.const 14
    array.new_data $str $__d19
    global.set $__s19
    i32.const 0
    i32.const 15
    array.new_data $str $__d20
    global.set $__s20
    i32.const 0
    i32.const 15
    array.new_data $str $__d21
    global.set $__s21
    i32.const 0
    i32.const 13
    array.new_data $str $__d22
    global.set $__s22
    i32.const 0
    i32.const 10
    array.new_data $str $__d23
    global.set $__s23
    i32.const 0
    i32.const 12
    array.new_data $str $__d24
    global.set $__s24
    i32.const 0
    i32.const 4
    array.new_data $str $__d25
    global.set $__s25
    i32.const 0
    i32.const 11
    array.new_data $str $__d26
    global.set $__s26
    i32.const 0
    i32.const 1
    array.new_data $str $__d27
    global.set $__s27
    i32.const 0
    i32.const 17
    array.new_data $str $__d28
    global.set $__s28
    i32.const 0
    i32.const 5
    array.new_data $str $__d29
    global.set $__s29
    i32.const 0
    i32.const 12
    array.new_data $str $__d30
    global.set $__s30
    i32.const 0
    i32.const 13
    array.new_data $str $__d31
    global.set $__s31
    i32.const 0
    i32.const 14
    array.new_data $str $__d32
    global.set $__s32
    i32.const 0
    i32.const 16
    array.new_data $str $__d33
    global.set $__s33
    i32.const 0
    i32.const 17
    array.new_data $str $__d34
    global.set $__s34
    i32.const 0
    i32.const 7
    array.new_data $str $__d35
    global.set $__s35
    i32.const 0
    i32.const 8
    array.new_data $str $__d36
    global.set $__s36
    i32.const 0
    i32.const 19
    array.new_data $str $__d37
    global.set $__s37
    i32.const 0
    i32.const 9
    array.new_data $str $__d38
    global.set $__s38
    i32.const 0
    i32.const 8
    array.new_data $str $__d39
    global.set $__s39
    i32.const 0
    i32.const 14
    array.new_data $str $__d40
    global.set $__s40
    i32.const 0
    i32.const 11
    array.new_data $str $__d41
    global.set $__s41
    i32.const 0
    i32.const 12
    array.new_data $str $__d42
    global.set $__s42
    i32.const 0
    i32.const 14
    array.new_data $str $__d43
    global.set $__s43
    i32.const 0
    i32.const 14
    array.new_data $str $__d44
    global.set $__s44
    i32.const 0
    i32.const 12
    array.new_data $str $__d45
    global.set $__s45
    i32.const 0
    i32.const 21
    array.new_data $str $__d46
    global.set $__s46
    i32.const 0
    i32.const 9
    array.new_data $str $__d47
    global.set $__s47
    i32.const 0
    i32.const 12
    array.new_data $str $__d48
    global.set $__s48
    i32.const 0
    i32.const 13
    array.new_data $str $__d49
    global.set $__s49
    i32.const 0
    i32.const 13
    array.new_data $str $__d50
    global.set $__s50
    i32.const 0
    i32.const 13
    array.new_data $str $__d51
    global.set $__s51
    i32.const 0
    i32.const 21
    array.new_data $str $__d52
    global.set $__s52
    i32.const 0
    i32.const 9
    array.new_data $str $__d53
    global.set $__s53
    i32.const 0
    i32.const 12
    array.new_data $str $__d54
    global.set $__s54
    i32.const 0
    i32.const 13
    array.new_data $str $__d55
    global.set $__s55
    i32.const 0
    i32.const 13
    array.new_data $str $__d56
    global.set $__s56
    i32.const 0
    i32.const 12
    array.new_data $str $__d57
    global.set $__s57
    i32.const 0
    i32.const 12
    array.new_data $str $__d58
    global.set $__s58
    i32.const 0
    i32.const 21
    array.new_data $str $__d59
    global.set $__s59
    i32.const 0
    i32.const 10
    array.new_data $str $__d60
    global.set $__s60
    i32.const 0
    i32.const 11
    array.new_data $str $__d61
    global.set $__s61
    i32.const 0
    i32.const 14
    array.new_data $str $__d62
    global.set $__s62
    i32.const 0
    i32.const 13
    array.new_data $str $__d63
    global.set $__s63
    i32.const 0
    i32.const 22
    array.new_data $str $__d64
    global.set $__s64
    i32.const 0
    i32.const 7
    array.new_data $str $__d65
    global.set $__s65
    i32.const 0
    i32.const 17
    array.new_data $str $__d66
    global.set $__s66
    i32.const 0
    i32.const 3
    array.new_data $str $__d67
    global.set $__s67
    i32.const 0
    i32.const 7
    array.new_data $str $__d68
    global.set $__s68
    i32.const 0
    i32.const 14
    array.new_data $str $__d69
    global.set $__s69
    i32.const 0
    i32.const 46
    array.new_data $str $__d70
    global.set $__s70
    call $__init_types
  )
  (func $__new_32 (param $f0 i32) (param $f1 i32) (param $f2 i32) (param $f3 anyref) (param $f4 i32) (result (ref null $rec_Place))
    global.get $__ti_32
    local.get $f0
    local.get $f1
    local.get $f2
    local.get $f3
    local.get $f4
    struct.new $rec_Place
  )
  (func $__new_38 (param $f0 anyref) (param $f1 i32) (param $f2 anyref) (param $f3 anyref) (result (ref null $rec_Scope))
    global.get $__ti_38
    local.get $f0
    local.get $f1
    local.get $f2
    local.get $f3
    struct.new $rec_Scope
  )
  (func $__new_26 (param $f0 anyref) (result (ref null $rec_Carried))
    global.get $__ti_26
    local.get $f0
    struct.new $rec_Carried
  )
  (func $__new_28 (param $f0 i32) (param $f1 anyref) (param $f2 i32) (param $f3 anyref) (param $f4 i32) (param $f5 anyref) (param $f6 anyref) (result (ref null $rec_CellEntry))
    global.get $__ti_28
    local.get $f0
    local.get $f1
    local.get $f2
    local.get $f3
    local.get $f4
    local.get $f5
    local.get $f6
    struct.new $rec_CellEntry
  )
  (func $__new_40 (param $f0 i32) (param $f1 i32) (param $f2 anyref) (param $f3 anyref) (result (ref null $rec_ScopeTree))
    global.get $__ti_40
    local.get $f0
    local.get $f1
    local.get $f2
    local.get $f3
    struct.new $rec_ScopeTree
  )
  (func $__new_36 (param $f0 i32) (param $f1 (ref null $rec_Place)) (param $f2 i32) (param $f3 i32) (param $f4 anyref) (result (ref null $rec_PlaceLink))
    global.get $__ti_36
    local.get $f0
    local.get $f1
    local.get $f2
    local.get $f3
    local.get $f4
    struct.new $rec_PlaceLink
  )
  (func $__new_34 (param $f0 i32) (param $f1 i32) (param $f2 anyref) (result (ref null $rec_PlaceCount))
    global.get $__ti_34
    local.get $f0
    local.get $f1
    local.get $f2
    struct.new $rec_PlaceCount
  )
  (func $__new_42 (result (ref null $rec_Element))
    global.get $__ti_42
    struct.new $rec_Element
  )
  (global $__ti_32 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_38 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_26 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_28 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_40 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_36 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_34 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_42 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tip3 $__tie3 $__tip4 $__tie4 $__tip5 $__tie5 $__tip6 $__tie6 $__tip7 $__tie7 $__tip8 $__tie8 $__tip12 $__tie12 $__tip19 $__tie19)
  (func $__init_types
    global.get $__s28
    ref.func $__tip3
    ref.func $__tie3
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_32
    global.get $__ti_32
    call $__ti_register
    global.get $__s34
    ref.func $__tip4
    ref.func $__tie4
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_38
    global.get $__ti_38
    call $__ti_register
    global.get $__s37
    ref.func $__tip5
    ref.func $__tie5
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_26
    global.get $__ti_26
    call $__ti_register
    global.get $__s46
    ref.func $__tip6
    ref.func $__tie6
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_28
    global.get $__ti_28
    call $__ti_register
    global.get $__s52
    ref.func $__tip7
    ref.func $__tie7
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_40
    global.get $__ti_40
    call $__ti_register
    global.get $__s59
    ref.func $__tip8
    ref.func $__tie8
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_36
    global.get $__ti_36
    call $__ti_register
    global.get $__s64
    ref.func $__tip12
    ref.func $__tie12
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_34
    global.get $__ti_34
    call $__ti_register
    global.get $__s66
    ref.func $__tip19
    ref.func $__tie19
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_42
    global.get $__ti_42
    call $__ti_register
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
