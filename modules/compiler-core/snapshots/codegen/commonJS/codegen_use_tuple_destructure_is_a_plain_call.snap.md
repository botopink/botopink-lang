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

----- JAVASCRIPT -- std/context.js
```javascript
function __bp_eq(a, b, d) {
    if (Object.is(a, b)) {
        return true;
    }
    if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
        return false;
    }
    if (Array.isArray(a)) {
        return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
    }
    const k = Object.keys(a);
    return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
}

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

// ── the place (decisions 819, 820, 821, 884, 891) ────────────────────────────

// Where a component stands among its siblings (819 (2)): the number of the

// call that made it, and its item half — absent, a count the call's

// component body or plain function made (821), a list runner's index, or a

// key. A program passes `Place.none()` (the place the value carries), or

// runs one by hand with `Place.key(k)` / `Place.index(i)` (819 (3), 884).

// `stamped` marks a place a making call wrote (820 (1)): a runner's never is.

class Place {
    constructor(callNo, item, itemNo, keyValue, stamped) {
        this.callNo = callNo;
        this.item = item;
        this.itemNo = itemNo;
        this.keyValue = keyValue;
        this.stamped = stamped;
    }

    static none() {
        return new Place(0, PlaceItem.Absent, 0, null, false);
    }

    static key(k) {
        return new Place(0, PlaceItem.Key, 0, k, false);
    }

    static index(i) {
        return new Place(0, PlaceItem.Index, i, null, false);
    }

    with(key) {
        if (__bp_eq_PlaceItem(key.item, PlaceItem.Key)) { return new Place(this.callNo, PlaceItem.Key, 0, key.keyValue, this.stamped); }
        if (__bp_eq_PlaceItem(key.item, PlaceItem.Index)) { if ((__bp_eq_PlaceItem(this.item, PlaceItem.Absent) || __bp_eq_PlaceItem(this.item, PlaceItem.Plain))) { return new Place(this.callNo, PlaceItem.Index, key.itemNo, null, this.stamped); } }
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

// Whether two places name one child: the call's number and the item half,

// a key compared by value (818 (3)).

function samePlace(a, b) {
    if ((((a.callNo !== b.callNo) || (!__bp_eq_PlaceItem(a.item, b.item))) || (a.itemNo !== b.itemNo))) { return false; }
    if (__bp_eq_PlaceItem(a.item, PlaceItem.Key)) { return sameKey(placeKey(a), placeKey(b)); }
    return true;
}

function placeKey(p) {
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
        return new Scope(this.scopeStore, openChild(this.scopeStore, this.scopeOwner, this.scopeCarried, this.scopeCell, key), this.scopeOwner, this.scopeCarried);
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

// A root's tree: whether it is closed, the count of its cells, each cell's

// state and each `place → cell` link, the latest entry for an id or a place

// first. Public as `Frame` is: a program never names it.

class ScopeTree {
    constructor(treeClosed, treeCount, treeCells, treeLinks) {
        this.treeClosed = treeClosed;
        this.treeCount = treeCount;
        this.treeCells = treeCells;
        this.treeLinks = treeLinks;
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

// One cell of a root's tree: its contexts, the number of its renders, its

// hook's slot (816, 818 (1)) and the count of the values each call of its

// body made in the current render (821 (1)).

class CellEntry {
    constructor(cellNo, cellFrames, cellGen, cellSlot, cellFilled, cellCounts, cellNext) {
        this.cellNo = cellNo;
        this.cellFrames = cellFrames;
        this.cellGen = cellGen;
        this.cellSlot = cellSlot;
        this.cellFilled = cellFilled;
        this.cellCounts = cellCounts;
        this.cellNext = cellNext;
    }
}
CellEntry.prototype.__bp = "CellEntry";
exports.CellEntry = CellEntry;

// A child cell at a place of its parent, and the parent's render that last

// met it (817 (1)).

class PlaceLink {
    constructor(linkParent, linkPlace, linkChild, linkSeen, linkNext) {
        this.linkParent = linkParent;
        this.linkPlace = linkPlace;
        this.linkChild = linkChild;
        this.linkSeen = linkSeen;
        this.linkNext = linkNext;
    }
}
PlaceLink.prototype.__bp = "PlaceLink";
exports.PlaceLink = PlaceLink;

// The count of the values call `countCall` made in one render or one entry.

class PlaceCount {
    constructor(countCall, countValue, countNext) {
        this.countCall = countCall;
        this.countValue = countValue;
        this.countNext = countNext;
    }
}
PlaceCount.prototype.__bp = "PlaceCount";
exports.PlaceCount = PlaceCount;

// A new root's store, its one cell holding `frames`.

function storeOf(frames) {
    const store = ({ v: undefined });
    ((__s, __v) => { __s.v = __v; return undefined; })(store, new ScopeTree(false, 1, new CellEntry(0, frames, 0, null, false, null, null), null));
    return store;
}

// The root's tree, live and in its own process; a detached root's starts in

// each process that reads it from the contexts it carries.

function treeOf(store, owner, carried) {
    (() => { if (false) { return (() => { throw Object.defineProperty(new Error("scope-foreign: a scope is read in another process than its root's — pass `scope.detach()` to another process (decision 824 (3))"), '__bp_panic', { value: true }) })(); } })();
    if ((!(store.v !== undefined))) { if (carried instanceof Carried) { const c = carried; const t = new ScopeTree(false, 1, new CellEntry(0, carriedFrames(c), 0, null, false, null, null), null); ((__s, __v) => { __s.v = __v; return undefined; })(store, t); return t; } }
    if ((store.v !== undefined)) { const raw = store.v; if (raw instanceof ScopeTree) { const t = raw; if ((!t.treeClosed)) { return t; } } }
    (() => { throw Object.defineProperty(new Error("scope-closed: a scope is used after its root's `close()` (decision 825 (2))"), '__bp_panic', { value: true }) })();
}

function treeCells(t) {
    return t.treeCells;
}

function treeLinks(t) {
    return t.treeLinks;
}

// `t` with `e` as cell `e.cellNo`'s state.

function withCell(t, e) {
    return new ScopeTree(false, t.treeCount, new CellEntry(e.cellNo, entryFrames(e), e.cellGen, entrySlot(e), e.cellFilled, entryCounts(e), treeCells(t)), treeLinks(t));
}

// Cell `id`'s state in `cells`.

function cellOf(cells, id) {
    let cur = cells;
    while (true) {
    if (cur instanceof CellEntry) { const e = cur; if ((e.cellNo === id)) { return e; } cur = entryNext(e); } else { (() => { throw Object.defineProperty(new Error("a scope names a cell its tree does not hold (decision 817)"), '__bp_panic', { value: true }) })(); }
}
}

// The child of cell `parent` at `key`, entered for a render: its id.

function openChild(store, owner, carried, parent, key) {
    const t = treeOf(store, owner, carried);
    const p = cellOf(treeCells(t), parent);
    const frames = entryFrames(p);
    const found = linkAt(treeLinks(t), parent, key);
    if (found instanceof PlaceLink) { const l = found; /* Two siblings with one key in one render (819 (5)); the root's */ /* children are each run's own. */ (() => { if ((((parent !== 0) && (l.linkSeen === p.cellGen)) && __bp_eq_PlaceItem(key.item, PlaceItem.Key))) { return (() => { throw Object.defineProperty(new Error((("key-duplicate: two siblings carry the key " + keyText(placeKey(key))) + " (decision 819 (5))")), '__bp_panic', { value: true }) })(); } })(); /* Met in the parent's previous render or in this one: the same cell, */ /* its contexts taken anew and its counts reset (816 (2), 817 (5)). */ if (((parent === 0) || (l.linkSeen >= __bp_int((p.cellGen - 1), -2147483648, 2147483647, "- on i32 at src/context.bp:295:52")))) { const c = cellOf(treeCells(t), l.linkChild); const kept = withCell(t, new CellEntry(c.cellNo, frames, __bp_int((c.cellGen + 1), -2147483648, 2147483647, "+ on i32 at src/context.bp:298:17"), entrySlot(c), c.cellFilled, null, null)); ((__s, __v) => { __s.v = __v; return undefined; })(store, new ScopeTree(false, kept.treeCount, treeCells(kept), new PlaceLink(parent, key, l.linkChild, p.cellGen, treeLinks(kept)))); return l.linkChild; } }
    // A place not met in the parent's previous render: a fresh cell.;
    const id = t.treeCount;
    ((__s, __v) => { __s.v = __v; return undefined; })(store, new ScopeTree(false, __bp_int((id + 1), -2147483648, 2147483647, "+ on i32 at src/context.bp:306:9"), new CellEntry(id, frames, 1, null, false, null, treeCells(t)), new PlaceLink(parent, key, id, p.cellGen, treeLinks(t))));
    return id;
}

// The latest link of cell `parent` at `key`, or null.

function linkAt(links, parent, key) {
    let cur = links;
    while (true) {
    if (cur instanceof PlaceLink) { const l = cur; if (((l.linkParent === parent) && samePlace(l.linkPlace, key))) { return linkSelf(l); } cur = linkNext(l); } else { return null; }
}
}

function linkSelf(l) {
    return l;
}

function linkNext(l) {
    return l.linkNext;
}

// A key as a failure names it.

function keyText(k) {
    if (typeof k === "string") { return (("\"" + k) + "\""); }
    if (((_v) => (typeof _v === "number" && Number.isInteger(_v) && _v >= -2147483648 && _v <= 2147483647))(k)) { return k.toString(); }
    return "of another type";
}

// The contexts cell `id` holds now.

function framesAt(store, owner, carried, id) {
    return entryFrames(cellOf(treeCells(treeOf(store, owner, carried)), id));
}

function carriedFrames(c) {
    return c.frames;
}

// `value` provided for `key` in cell `id`.

function provideAt(store, owner, carried, id, key, value) {
    const t = treeOf(store, owner, carried);
    const c = cellOf(treeCells(t), id);
    const frames = new Frame(key, value, entryFrames(c));
    ((__s, __v) => { __s.v = __v; return undefined; })(store, withCell(t, new CellEntry(id, frames, c.cellGen, entrySlot(c), c.cellFilled, entryCounts(c), null)));
}

// The count of the values call `callNo` made before this one in cell `id`'s

// current render; the cell counts this one (821 (1)).

function countAt(store, owner, carried, id, callNo) {
    const t = treeOf(store, owner, carried);
    const c = cellOf(treeCells(t), id);
    const n = countIn(entryCounts(c), callNo);
    ((__s, __v) => { __s.v = __v; return undefined; })(store, withCell(t, new CellEntry(id, entryFrames(c), c.cellGen, entrySlot(c), c.cellFilled, new PlaceCount(callNo, __bp_int((n + 1), -2147483648, 2147483647, "+ on i32 at src/context.bp:362:9"), entryCounts(c)), null)));
    return n;
}

// The latest count of call `callNo` in `counts`, else 0.

function countIn(counts, callNo) {
    let cur = counts;
    while (true) {
    if (cur instanceof PlaceCount) { const k = cur; if ((k.countCall === callNo)) { return k.countValue; } cur = countRest(k); } else { return 0; }
}
}

function countRest(k) {
    return k.countNext;
}

// Cell `id`'s slot: what `make` answered on the cell's first render, kept

// while the cell stands (816 (1), 818 (1)).

function slotAt(store, owner, carried, id, make) {
    const c = cellOf(treeCells(treeOf(store, owner, carried)), id);
    if (c.cellFilled) { return entrySlot(c); }
    const value = make();
    const t = treeOf(store, owner, carried);
    const now = cellOf(treeCells(t), id);
    ((__s, __v) => { __s.v = __v; return undefined; })(store, withCell(t, new CellEntry(id, entryFrames(now), now.cellGen, value, true, entryCounts(now), null)));
    return value;
}

// The root's tree closed; a closed one is left as it is.

function closeStore(store) {
    if ((!(store.v !== undefined))) { return; }
    ((__s, __v) => { __s.v = __v; return undefined; })(store, new ScopeTree(true, 0, null, null));
}

function entryFrames(e) {
    return e.cellFrames;
}

function entrySlot(e) {
    return e.cellSlot;
}

function entryCounts(e) {
    return e.cellCounts;
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

function stamp(c, cell, callNo) {
    if (cell instanceof Scope) { return placed(c, new Place(callNo, PlaceItem.Body, countAt(cell.storeRef(), cell.ownerRef(), cell.carriedRef(), cell.cellId(), callNo), null, true)); }
    (() => { throw Object.defineProperty(new Error("a component is run with a `Scope` (decision 819)"), '__bp_panic', { value: true }) })();
}
exports.stamp = stamp;

function stampPlain(c, counter, callNo) {
    return placed(c, new Place(callNo, PlaceItem.Plain, countNext(counter, callNo), null, true));
}
exports.stampPlain = stampPlain;

function stampKeyed(c, callNo, k) {
    return placed(c, new Place(callNo, PlaceItem.Key, 0, k, true));
}
exports.stampKeyed = stampKeyed;

// `c` carrying `mine`.

function placed(c, mine) {
    return (scope, key) => {
    return resolve(c, scope, (() => { if (key.stamped) { return key; } else { return mine.with(key); } })());
};
}

// `use memo(make)` written as call `callNo` of a body: the slot of its own

// child cell (818 (1)), filled on that cell's first render.

function memoIn(cell, callNo, make) {
    if (cell instanceof Scope) { const child = cell.childAt(new Place(callNo, PlaceItem.Body, countAt(cell.storeRef(), cell.ownerRef(), cell.carriedRef(), cell.cellId(), callNo), null, true)); return slotAt(child.storeRef(), child.ownerRef(), child.carriedRef(), child.cellId(), make); }
    (() => { throw Object.defineProperty(new Error("a component is run with a `Scope` (decision 819)"), '__bp_panic', { value: true }) })();
}
exports.memoIn = memoIn;

// A plain function entry's counter of the values each of its calls made

// (821 (2)).

function countNew() {
    return ({ v: undefined });
}
exports.countNew = countNew;

// The entry's counter gone: on erlang and beam its process-dictionary entry.

function countEnd(counter) {
    ((__s, __v) => { __s.v = __v; return undefined; })(counter, null);
}
exports.countEnd = countEnd;

// The count of the values call `callNo` made before this one in the entry.

function countNext(counter, callNo) {
    const counts = (() => { if ((counter.v !== undefined)) { return counter.v; } else { return null; } })();
    const n = countIn(counts, callNo);
    ((__s, __v) => { __s.v = __v; return undefined; })(counter, new PlaceCount(callNo, __bp_int((n + 1), -2147483648, 2147483647, "+ on i32 at src/context.bp:569:9"), counts));
    return n;
}

function frameValue(f) {
    return f.value;
}

function frameParent(f) {
    return f.parent;
}

// ── the store's host side (decision 824) ─────────────────────────────────────

// Two keys compared by value (818 (3)).

function sameKey(a, b) {
    return __bp_eq(a, b, 0);
}

// countCellNew: per-call template (see annotation)

// countCellFilled: per-call template (see annotation)

// countCellGet: per-call template (see annotation)

// countCellSet: per-call template (see annotation)

// countCellEnd: per-call template (see annotation)

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

Object.defineProperty(exports, "__bp_priv__", { value: { Context, createContext, provide, context, inject, Place, PlaceItem, PlaceItem$Absent, PlaceItem$Body, PlaceItem$Plain, PlaceItem$Index, PlaceItem$Key, samePlace, placeKey, Scope, ScopeTree, Carried, CellEntry, PlaceLink, PlaceCount, storeOf, treeOf, treeCells, treeLinks, withCell, cellOf, openChild, linkAt, linkSelf, linkNext, keyText, framesAt, carriedFrames, provideAt, countAt, countIn, countRest, slotAt, closeStore, entryFrames, entrySlot, entryCounts, entryNext, resolve, run, Frame, enter, received, provideIn, find, answer, nowhere, root, stamp, stampPlain, stampKeyed, placed, memoIn, countNew, countEnd, countNext, frameValue, frameParent, sameKey } });
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
    readonly stamped: boolean;
    constructor(callNo: number, item: PlaceItem, itemNo: number, keyValue: unknown, stamped: boolean);
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
    readonly treeLinks: unknown;
    constructor(treeClosed: boolean, treeCount: number, treeCells: unknown, treeLinks: unknown);
}


export declare class Carried {
    readonly frames: unknown;
    constructor(frames: unknown);
}


export declare class CellEntry {
    readonly cellNo: number;
    readonly cellFrames: unknown;
    readonly cellGen: number;
    readonly cellSlot: unknown;
    readonly cellFilled: boolean;
    readonly cellCounts: unknown;
    readonly cellNext: unknown;
    constructor(cellNo: number, cellFrames: unknown, cellGen: number, cellSlot: unknown, cellFilled: boolean, cellCounts: unknown, cellNext: unknown);
}


export declare class PlaceLink {
    readonly linkParent: number;
    readonly linkPlace: Place;
    readonly linkChild: number;
    readonly linkSeen: number;
    readonly linkNext: unknown;
    constructor(linkParent: number, linkPlace: Place, linkChild: number, linkSeen: number, linkNext: unknown);
}


export declare class PlaceCount {
    readonly countCall: number;
    readonly countValue: number;
    readonly countNext: unknown;
    constructor(countCall: number, countValue: number, countNext: unknown);
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


export declare function stamp(c: Promise<unknown>, cell: unknown, callNo: number): Composition<unknown>;


export declare function stampPlain(c: Promise<unknown>, counter: unknown, callNo: number): Composition<unknown>;


export declare function stampKeyed(c: Promise<unknown>, callNo: number, k: unknown): Composition<unknown>;




export declare function memoIn(cell: unknown, callNo: number, make: () => unknown): unknown;


export declare function countNew(): unknown;


export declare function countEnd(counter: unknown): void;

































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

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

const { enter: bpScopeEnter__, answer: bpScopeAnswer__, nowhere: bpScopeNowhere__, stamp: bpStamp__ } = require("./std/context.js");

class Element {
}
Element.prototype.__bp = "Element";

function optimistic(base, f) {
    return (bpScope__, bpKey__) => {
    bpScopeEnter__(bpScope__, bpKey__);
    const push = (action) => {
    return f(base, action);
};
    return bpScopeAnswer__([base, push]);
};
}

function LikeWidget() {
    return (bpScope__, bpKey__) => {
    const bpCell__1 = bpScopeEnter__(bpScope__, bpKey__);
    const [ shown, push ] = bpStamp__(optimistic(12, (c, a) => {
    return __bp_int((c + a), -2147483648, 2147483647, "+ on i32 at main.bp:7:57");
}), bpCell__1, 1)(bpCell__1, bpScopeNowhere__());
    push(shown);
    return bpScopeAnswer__(new Element());
};
}

Object.defineProperty(exports, "__bp_priv__", { value: { bpScopeEnter__, bpScopeAnswer__, bpScopeNowhere__, bpStamp__, Element, optimistic, LikeWidget } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
