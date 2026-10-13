----- SOURCE CODE -- std/context.bp
```botopink
//// Contexts (decisions 354, 378, 379) — what a component's body reads from
//// above it, React's context in botopink's spelling.
////
//// A context is named by its value's type. `createContext(value)` at module
//// level declares the default of that type — one declaration per type in
//// the program:
////
////     pub val themeContext = comptime createContext(Theme(mode: .Light));
////
//// A component provides a context to everything it renders below it, and a
//// body reads the nearest one of a type provided above it, else the type's
//// declared default:
////
////     use provide(createContext(Theme(mode: .Dark)));   // the children's
////     val theme = use context(Theme);                    // the nearest above
////
//// Both are hooks, so they are `use`d, never called for a value; `provide`
//// only in a component's body (a `@Component<R>` whose `R` implements
//// `@Renderable`), before it renders a child. `use` exists only where there
//// is a render tree — a decorator body, a template body and a
//// `comptime { … }` have none (`use-outside-render-tree`). A read of a type
//// with no declared default is refused at build, at the read.
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
//// `context` looks the received one up, the declared default when nothing
//// of its type is provided. Neither hook below is ever called: the checker
//// refuses every reference to them but a `use`'s operand, and the bodies
//// panic.

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
pub fn provide<T>(ctx: Context<T>) -> @Component<void> {
    @panic(
        "`use provide` / `use context` are lowered where they are written; this body never runs",
    );
}

// The value of the context of type `T` provided nearest above this body, or
// `T`'s declared default: `use context(T)` answers `T`, which the checker
// reads off the type the argument names (decision 379 (3)).
pub fn context(comptime t: @Expr<type>) -> @Component<unknown> {
    @panic(
        "`use provide` / `use context` are lowered where they are written; this body never runs",
    );
}

// Decision 416 — the record `T` built from the contexts of its fields'
// types: each field the nearest context of its type provided above, else
// that type's declared default, else the field's own default (`use
// inject(Deps)`). `T` is a record; a behavior is read with `use context`.
// `createContext(value, Behavior)` keys a context by the behavior its value
// implements, so a field typed by the behavior reads it.
pub fn inject(comptime t: @Expr<type>) -> @Component<unknown> {
    @panic(
        "`use inject` is lowered where it is written; this body never runs",
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
// provide(c)` binds `push(<children's scope>, <T's identity>, c)` for the
// children (a context is its value at run time: the compiler writes
// `createContext(v)` as `v`), `use context(T)` is `find(<received scope>, <T's
// identity>, <T's declared default>)`,
// a `use` of a hook and an `await` of a component value run the lambda and
// read `valueOf` of what it answers, and an `await` outside every body runs it
// with `root()`. A context's identity is its value's type (379) — the
// compiler writes it, never a program.

// One provided value over the frames it was provided in.
pub type Frame(key: string, value: unknown, parent: unknown)

// The children's scope: `value` provided for `key` over `scope`.
pub fn push(scope: RenderScope, key: string, value: unknown) -> RenderScope {
    return RenderScope(
        frames: Frame(key: key, value: value, parent: scope.frames),
    );
}

// The value provided nearest above for `key`, else `fallback` — the type's
// declared default (decision 378 (3): no read is unbound).
// The two `unknown` fields are read through `frameValue` / `frameParent`: wasm boxes a field read as `unknown` only as a function's answer.
pub fn find(scope: RenderScope, key: string, fallback: unknown) -> unknown {
    var cur = scope.frames;
    loop {
        if (cur is Frame) {
            val f: Frame = cur;
            if (f.key == key) return frameValue(f);
            cur = frameParent(f);
        } else return frameValue(Frame(key: key, value: fallback, parent: null)); // the default read back as a provided value is
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
//// Contexts (decisions 354, 378, 379) — what a component's body reads from

//// above it, React's context in botopink's spelling.

//// 

//// A context is named by its value's type. `createContext(value)` at module

//// level declares the default of that type — one declaration per type in

//// the program:

//// 

////     pub val themeContext = comptime createContext(Theme(mode: .Light));

//// 

//// A component provides a context to everything it renders below it, and a

//// body reads the nearest one of a type provided above it, else the type's

//// declared default:

//// 

////     use provide(createContext(Theme(mode: .Dark)));   // the children's

////     val theme = use context(Theme);                    // the nearest above

//// 

//// Both are hooks, so they are `use`d, never called for a value; `provide`

//// only in a component's body (a `@Component<R>` whose `R` implements

//// `@Renderable`), before it renders a child. `use` exists only where there

//// is a render tree — a decorator body, a template body and a

//// `comptime { … }` have none (`use-outside-render-tree`). A read of a type

//// with no declared default is refused at build, at the read.

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
    (() => { throw new Error("`use provide` / `use context` are lowered where they are written; this body never runs") })();
}
exports.provide = provide;

// The value of the context of type `T` provided nearest above this body, or

// `T`'s declared default: `use context(T)` answers `T`, which the checker

// reads off the type the argument names (decision 379 (3)).

function context(t) {
    (() => { throw new Error("`use provide` / `use context` are lowered where they are written; this body never runs") })();
}
exports.context = context;

// Decision 416 — the record `T` built from the contexts of its fields'

// types: each field the nearest context of its type provided above, else

// that type's declared default, else the field's own default (`use

// inject(Deps)`). `T` is a record; a behavior is read with `use context`.

// `createContext(value, Behavior)` keys a context by the behavior its value

// implements, so a field typed by the behavior reads it.

function inject(t) {
    (() => { throw new Error("`use inject` is lowered where it is written; this body never runs") })();
}
exports.inject = inject;

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

// provide(c)` binds `push(<children's scope>, <T's identity>, c)` for the

// children (a context is its value at run time: the compiler writes

// `createContext(v)` as `v`), `use context(T)` is `find(<received scope>, <T's

// identity>, <T's declared default>)`,

// a `use` of a hook and an `await` of a component value run the lambda and

// read `valueOf` of what it answers, and an `await` outside every body runs it

// with `root()`. A context's identity is its value's type (379) — the

// compiler writes it, never a program.

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

// The value provided nearest above for `key`, else `fallback` — the type's

// declared default (decision 378 (3): no read is unbound).

// The two `unknown` fields are read through `frameValue` / `frameParent`: wasm boxes a field read as `unknown` only as a function's answer.

function find(scope, key, fallback) {
    let cur = scope.frames;
    while (true) {
    if (cur instanceof Frame) { const f = cur; if ((f.key === key)) { return frameValue(f); } cur = frameParent(f); } else { return frameValue(new Frame(key, fallback, null)); }
    // the default read back as a provided value is;
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

Object.defineProperty(exports, "__bp_priv__", { value: { Context, createContext, provide, context, inject, RenderScope, Rendered, Frame, push, find, rendered, valueOf, root, frameValue, frameParent } });
```

----- TYPESCRIPT TYPEDEF -- std/context.d.ts
```typescript
export declare class Context<T> {
    readonly contextValue: T;
    constructor(contextValue: T);
}


export declare function createContext<T>(value: T): Context<T>;


export declare function provide<T>(ctx: Context<T>): void;


export declare function context(t: any): unknown;


export declare function inject(t: any): unknown;


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


export declare function find(scope: RenderScope, key: string, fallback: unknown): unknown;


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

Object.defineProperty(exports, "__bp_priv__", { value: { bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__, Element, optimistic, LikeWidget } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
```
