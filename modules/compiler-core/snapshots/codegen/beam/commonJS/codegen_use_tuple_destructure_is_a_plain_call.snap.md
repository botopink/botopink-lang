----- SOURCE CODE -- std/context.bp
```botopink
//// Contexts (decision 354) — what a component's body reads from above it,
//// React's context in botopink's spelling.
////
//// A context is a declared object, its identity the declaration (decision
//// 281): `pub val ThemeContext = Context<Theme>();` — no default value, and
//// no other way to make one (`context-not-declared`). A component provides a
//// value to everything it renders below it, and a body reads the nearest
//// value provided above it:
////
////     use provide(ThemeContext, Theme(mode: .Dark));   // the children's
////     val theme = use context(ThemeContext);           // the nearest above
////
//// Both are hooks, so they are `use`d, never called for a value; `provide`
//// only in a component's body (a `@Component<R>` whose `R` implements
//// `@Renderable`), before it renders a child. `use` exists only where there
//// is a render tree — a decorator body, a template body and a
//// `comptime { … }` have none (`use-outside-render-tree`). A read with no
//// provider above it is `context-unbound` at run time.
////
//// A component at run time is a lambda over a `RenderScope` (decision 388):
//// calling `Card(item)` only makes the lambda, and the render library runs it
//// — `c.run(scope)` answers a `Rendered`, the body's result and the scope its
//// `use provide(…)`s made for its children. The library runs the root with
//// `RenderScope.root()` and each child with the scope its parent answered;
//// inside a component body `await c` runs `c` with the body's children scope,
//// outside every body with `RenderScope.root()`. The scope travels
//// explicitly: no "current context", on any target.
////
//// The work is the compiler's: each `use provide(…)` / `use context(…)` is
//// lowered where it is written — `provide` makes the children's scope and
//// `context` looks the received one up. Neither hook below is ever called:
//// the checker refuses every reference to them but a `use`'s operand, and the
//// bodies panic.

// A context of `T`, named by the `val` that declares it.
pub type Context<T>()

// Gives `value` to every component this component renders below it — never
// to itself or a sibling; the nearest provider wins.
pub fn provide<T>(ctx: Context<T>, value: T) -> @Component<void> {
    @panic(
        "`use provide` / `use context` are lowered where they are written; this body never runs",
    );
}

// The value of `ctx` provided nearest above this body.
pub fn context<T>(ctx: Context<T>) -> @Component<T> {
    @panic(
        "`use provide` / `use context` are lowered where they are written; this body never runs",
    );
}

// ── the render scope (decision 388) ──────────────────────────────────────────

// The scope a component's lambda runs with: the contexts provided above it.
// Opaque — made only by `RenderScope.root()` (`render-scope-construction`);
// every other scope is one a component's `run` answered.
pub type RenderScope(frames: unknown) {
    // The empty scope a render starts from: nothing provided.
    pub fn root() -> RenderScope {
        return RenderScope(frames: null);
    }
}

// What `c.run(scope)` answers: the component body's result and the scope its
// `use provide(…)`s made for the children it renders (the scope it received
// when it provides nothing).
pub type Rendered<R>(value: R, scope: RenderScope)

// ── what the scope lowering calls (decision 388) ─────────────────────────────
//
// A program never names these: the compiler imports them under names no
// source can spell. A `@Component` function answers `{ scope -> … }`; each
// `return v` of its body answers `rendered(v, <children's scope>)`; `use
// provide(C, v)` binds `push(<children's scope>, <C's identity>, v)` for the
// children, `use context(C)` is `find(<received scope>, <C's identity>, "C")`,
// a `use` of a hook and an `await` of a component value run the lambda and
// read `valueOf` of what it answers, and an `await` outside every body runs it
// with `root()`. A context's identity is the declaration of its `val` (281) —
// the compiler writes it, never a program.

// One provided value over the frames it was provided in.
pub type Frame(key: string, value: unknown, parent: unknown)

// The children's scope: `value` provided for `key` over `scope`.
pub fn push(scope: RenderScope, key: string, value: unknown) -> RenderScope {
    return RenderScope(
        frames: Frame(key: key, value: value, parent: scope.frames),
    );
}

// The value provided nearest above for `key`; `context-unbound` when no
// provider of `name` is above.
// LANGUAGE GAP: the wasm backend does not lower a component — the two `unknown` fields are read through `frameValue` / `frameParent`, since wasm boxes a field read as `unknown` only as a function's answer.
pub fn find(scope: RenderScope, key: string, name: string) -> unknown {
    var cur = scope.frames;
    loop {
        if (cur is Frame) {
            val f: Frame = cur;
            if (f.key == key) return frameValue(f);
            cur = frameParent(f);
        } else @panic(
            "context-unbound: no `use provide("
                + name
                + ", ...)` above this `use context("
                + name
                + ")` (decision 354)",
        );
    }
}

// A body's answer: its result over its children's scope.
pub fn rendered(value: unknown, scope: RenderScope) -> Rendered<unknown> {
    return Rendered(value: value, scope: scope);
}

// The result a run answered.
pub fn valueOf(r: Rendered<unknown>) -> unknown {
    return r.value;
}

// The empty scope, for an `await` of a component value outside every body.
pub fn root() -> RenderScope {
    return RenderScope.root();
}

fn frameValue(f: Frame) -> unknown {
    return f.value;
}

fn frameParent(f: Frame) -> unknown {
    return f.parent;
}

```

----- JAVASCRIPT -- std/context.js
```javascript
//// Contexts (decision 354) — what a component's body reads from above it,

//// React's context in botopink's spelling.

//// 

//// A context is a declared object, its identity the declaration (decision

//// 281): `pub val ThemeContext = Context<Theme>();` — no default value, and

//// no other way to make one (`context-not-declared`). A component provides a

//// value to everything it renders below it, and a body reads the nearest

//// value provided above it:

//// 

////     use provide(ThemeContext, Theme(mode: .Dark));   // the children's

////     val theme = use context(ThemeContext);           // the nearest above

//// 

//// Both are hooks, so they are `use`d, never called for a value; `provide`

//// only in a component's body (a `@Component<R>` whose `R` implements

//// `@Renderable`), before it renders a child. `use` exists only where there

//// is a render tree — a decorator body, a template body and a

//// `comptime { … }` have none (`use-outside-render-tree`). A read with no

//// provider above it is `context-unbound` at run time.

//// 

//// A component at run time is a lambda over a `RenderScope` (decision 388):

//// calling `Card(item)` only makes the lambda, and the render library runs it

//// — `c.run(scope)` answers a `Rendered`, the body's result and the scope its

//// `use provide(…)`s made for its children. The library runs the root with

//// `RenderScope.root()` and each child with the scope its parent answered;

//// inside a component body `await c` runs `c` with the body's children scope,

//// outside every body with `RenderScope.root()`. The scope travels

//// explicitly: no "current context", on any target.

//// 

//// The work is the compiler's: each `use provide(…)` / `use context(…)` is

//// lowered where it is written — `provide` makes the children's scope and

//// `context` looks the received one up. Neither hook below is ever called:

//// the checker refuses every reference to them but a `use`'s operand, and the

//// bodies panic.

// A context of `T`, named by the `val` that declares it.

class Context {
}
Context.prototype.__bp = "Context";
exports.Context = Context;

// Gives `value` to every component this component renders below it — never

// to itself or a sibling; the nearest provider wins.

function provide(ctx, value) {
    (() => { throw new Error("`use provide` / `use context` are lowered where they are written; this body never runs") })();
}
exports.provide = provide;

// The value of `ctx` provided nearest above this body.

function context(ctx) {
    (() => { throw new Error("`use provide` / `use context` are lowered where they are written; this body never runs") })();
}
exports.context = context;

// ── the render scope (decision 388) ──────────────────────────────────────────

// The scope a component's lambda runs with: the contexts provided above it.

// Opaque — made only by `RenderScope.root()` (`render-scope-construction`);

// every other scope is one a component's `run` answered.

class RenderScope {
    constructor(frames) {
        this.frames = frames;
    }

    static root() {
        return new RenderScope(null);
    }
}
RenderScope.prototype.__bp = "RenderScope";
exports.RenderScope = RenderScope;

// What `c.run(scope)` answers: the component body's result and the scope its

// `use provide(…)`s made for the children it renders (the scope it received

// when it provides nothing).

class Rendered {
    constructor(value, scope) {
        this.value = value;
        this.scope = scope;
    }
}
Rendered.prototype.__bp = "Rendered";
exports.Rendered = Rendered;

// ── what the scope lowering calls (decision 388) ─────────────────────────────

// 

// A program never names these: the compiler imports them under names no

// source can spell. A `@Component` function answers `{ scope -> … }`; each

// `return v` of its body answers `rendered(v, <children's scope>)`; `use

// provide(C, v)` binds `push(<children's scope>, <C's identity>, v)` for the

// children, `use context(C)` is `find(<received scope>, <C's identity>, "C")`,

// a `use` of a hook and an `await` of a component value run the lambda and

// read `valueOf` of what it answers, and an `await` outside every body runs it

// with `root()`. A context's identity is the declaration of its `val` (281) —

// the compiler writes it, never a program.

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

// The children's scope: `value` provided for `key` over `scope`.

function push(scope, key, value) {
    return new RenderScope(new Frame(key, value, scope.frames));
}
exports.push = push;

// The value provided nearest above for `key`; `context-unbound` when no

// provider of `name` is above.

// LANGUAGE GAP: the wasm backend does not lower a component — the two `unknown` fields are read through `frameValue` / `frameParent`, since wasm boxes a field read as `unknown` only as a function's answer.

function find(scope, key, name) {
    let cur = scope.frames;
    while (true) {
    if (cur instanceof Frame) { const f = cur; if ((f.key === key)) { return frameValue(f); } cur = frameParent(f); } else { (() => { throw new Error((((("context-unbound: no `use provide(" + name) + ", ...)` above this `use context(") + name) + ")` (decision 354)")) })(); }
}
}
exports.find = find;

// A body's answer: its result over its children's scope.

function rendered(value, scope) {
    return new Rendered(value, scope);
}
exports.rendered = rendered;

// The result a run answered.

function valueOf(r) {
    return r.value;
}
exports.valueOf = valueOf;

// The empty scope, for an `await` of a component value outside every body.

function root() {
    return RenderScope.root();
}
exports.root = root;

function frameValue(f) {
    return f.value;
}

function frameParent(f) {
    return f.parent;
}
```

----- TYPESCRIPT TYPEDEF -- std/context.d.ts
```typescript
export declare class Context<T> {
    constructor();
}


export declare function provide<T>(ctx: Context<T>, value: T): void;


export declare function context<T>(ctx: Context<T>): T;


export declare class RenderScope {
    readonly frames: unknown;
    constructor(frames: unknown);
    root(): RenderScope;
}


export declare class Rendered<R> {
    readonly value: R;
    readonly scope: RenderScope;
    constructor(value: R, scope: RenderScope);
}


export declare class Frame {
    readonly key: string;
    readonly value: unknown;
    readonly parent: unknown;
    constructor(key: string, value: unknown, parent: unknown);
}


export declare function push(scope: RenderScope, key: string, value: unknown): RenderScope;


export declare function find(scope: RenderScope, key: string, name: string): unknown;


export declare function rendered(value: unknown, scope: RenderScope): Rendered<unknown>;


export declare function valueOf(r: Rendered<unknown>): unknown;


export declare function root(): RenderScope;





```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Renderable
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Component<#(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    return #(base, push);
}
fn LikeWidget() -> @Component<Element> {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push(shown);
    return Element();
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

const { push: bpScopePush__, find: bpScopeFind__, rendered: bpScopeRendered__, valueOf: bpScopeValue__, root: bpScopeRoot__ } = require("./std/context.js");

class Element {
}
Element.prototype.__bp = "Element";

function optimistic(base, f) {
    return (bpScope__) => {
    const push = (action) => {
    return f(base, action);
};
    return bpScopeRendered__([base, push], bpScope__);
};
}

function LikeWidget() {
    return (bpScope__) => {
    const [ shown, push ] = bpScopeValue__(optimistic(12, (c, a) => {
    return __bp_int((c + a), -2147483648, 2147483647, "+ on i32 at main.bp:7:57");
})(bpScope__));
    push(shown);
    return bpScopeRendered__(new Element(), bpScope__);
};
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
