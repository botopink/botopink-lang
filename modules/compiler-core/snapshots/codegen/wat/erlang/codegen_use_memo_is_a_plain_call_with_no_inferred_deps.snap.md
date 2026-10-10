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

----- ERLANG -- std/context.erl
```erlang
-module(std@context).
-export([provide/2, context/1, push/3, find/3, rendered/2, valueOf/1, root/0]).

%%% Contexts (decision 354) — what a component's body reads from above it,

%%% React's context in botopink's spelling.

%%% 

%%% A context is a declared object, its identity the declaration (decision

%%% 281): `pub val ThemeContext = Context<Theme>();` — no default value, and

%%% no other way to make one (`context-not-declared`). A component provides a

%%% value to everything it renders below it, and a body reads the nearest

%%% value provided above it:

%%% 

%%%     use provide(ThemeContext, Theme(mode: .Dark));   // the children's

%%%     val theme = use context(ThemeContext);           // the nearest above

%%% 

%%% Both are hooks, so they are `use`d, never called for a value; `provide`

%%% only in a component's body (a `@Component<R>` whose `R` implements

%%% `@Renderable`), before it renders a child. `use` exists only where there

%%% is a render tree — a decorator body, a template body and a

%%% `comptime { … }` have none (`use-outside-render-tree`). A read with no

%%% provider above it is `context-unbound` at run time.

%%% 

%%% A component at run time is a lambda over a `RenderScope` (decision 388):

%%% calling `Card(item)` only makes the lambda, and the render library runs it

%%% — `c.run(scope)` answers a `Rendered`, the body's result and the scope its

%%% `use provide(…)`s made for its children. The library runs the root with

%%% `RenderScope.root()` and each child with the scope its parent answered;

%%% inside a component body `await c` runs `c` with the body's children scope,

%%% outside every body with `RenderScope.root()`. The scope travels

%%% explicitly: no "current context", on any target.

%%% 

%%% The work is the compiler's: each `use provide(…)` / `use context(…)` is

%%% lowered where it is written — `provide` makes the children's scope and

%%% `context` looks the received one up. Neither hook below is ever called:

%%% the checker refuses every reference to them but a `use`'s operand, and the

%%% bodies panic.

% A context of `T`, named by the `val` that declares it.

%% type Context: 

% Gives `value` to every component this component renders below it — never

% to itself or a sibling; the nearest provider wins.

provide(Ctx, Value) ->
    erlang:error({panic, <<"`use provide` / `use context` are lowered where they are written; this body never runs">>}).

% The value of `ctx` provided nearest above this body.

context(Ctx) ->
    erlang:error({panic, <<"`use provide` / `use context` are lowered where they are written; this body never runs">>}).

% ── the render scope (decision 388) ──────────────────────────────────────────

% The scope a component's lambda runs with: the contexts provided above it.

% Opaque — made only by `RenderScope.root()` (`render-scope-construction`);

% every other scope is one a component's `run` answered.

%% type RenderScope: frames

% What `c.run(scope)` answers: the component body's result and the scope its

% `use provide(…)`s made for the children it renders (the scope it received

% when it provides nothing).

%% type Rendered: value, scope

% ── what the scope lowering calls (decision 388) ─────────────────────────────

% 

% A program never names these: the compiler imports them under names no

% source can spell. A `@Component` function answers `{ scope -> … }`; each

% `return v` of its body answers `rendered(v, <children's scope>)`; `use

% provide(C, v)` binds `push(<children's scope>, <C's identity>, v)` for the

% children, `use context(C)` is `find(<received scope>, <C's identity>, "C")`,

% a `use` of a hook and an `await` of a component value run the lambda and

% read `valueOf` of what it answers, and an `await` outside every body runs it

% with `root()`. A context's identity is the declaration of its `val` (281) —

% the compiler writes it, never a program.

% One provided value over the frames it was provided in.

%% type Frame: key, value, parent

% The children's scope: `value` provided for `key` over `scope`.

push(Scope, Key, Value) ->
    {std@context@@RenderScope, {std@context@@Frame, Key, Value, erlang:element(2, Scope)}}.

% The value provided nearest above for `key`; `context-unbound` when no

% provider of `name` is above.

% LANGUAGE GAP: the wasm backend does not lower a component — the two `unknown` fields are read through `frameValue` / `frameParent`, since wasm boxes a field read as `unknown` only as a function's answer.

find(Scope, Key, Name) ->
    try
        Cur = erlang:element(2, Scope),
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
                    erlang:error({panic, <<"context-unbound: no `use provide(", Name/binary, ", ...)` above this `use context(", Name/binary, ")` (decision 354)">>}),
                    Cur@1
            end,
            __BpLoop(Cur@3)
        end)(Cur)
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% A body's answer: its result over its children's scope.

rendered(Value, Scope) ->
    {std@context@@Rendered, Value, Scope}.

% The result a run answered.

valueOf(R) ->
    erlang:element(2, R).

% The empty scope, for an `await` of a component value outside every body.

root() ->
    std@context@@RenderScope:root().

frameValue(F) ->
    erlang:element(3, F).

frameParent(F) ->
    erlang:element(4, F).
```

----- ERLANG -- std@context@@Context.erl
```erlang
-module(std@context@@Context).
-export(['__bp_format'/1]).

'__bp_format'(_) -> {record, "Context", []}.
```

----- ERLANG -- std@context@@RenderScope.erl
```erlang
-module(std@context@@RenderScope).
-export([root/0, '__bp_get'/2, '__bp_format'/1]).

root() ->
    {std@context@@RenderScope, undefined}.

'__bp_get'(V, frames) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "RenderScope", [{"frames", erlang:element(2, V)}]}.
```

----- ERLANG -- std@context@@Rendered.erl
```erlang
-module(std@context@@Rendered).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, value) -> erlang:element(2, V);
'__bp_get'(V, scope) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Rendered", [{"value", erlang:element(2, V)}, {"scope", erlang:element(3, V)}]}.
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
val Element = type() implement @Renderable
fn state(initial: i32) -> @Component<i32> {
    return initial;
}
fn memo() -> @Component<i32> {
    return 0;
}
fn Counter() -> @Component<Element> {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    return Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% import bpScopePush__, bpScopeFind__, bpScopeRendered__, bpScopeValue__, bpScopeRoot__

%% type Element: 

state(Initial) ->
    fun(BpScope__) ->
        std@context:rendered(Initial, BpScope__)
    end.

memo() ->
    fun(BpScope__) ->
        std@context:rendered(0, BpScope__)
    end.

'Counter'() ->
    fun(BpScope__) ->
        #{count := Count, setCount := SetCount} = std@context:valueOf((state(0))(BpScope__)),
        Doubled = std@context:valueOf((memo(fun() ->
            std@context:rendered('__bp_int'((Count * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:10:46">>), BpScope__)
        end))(BpScope__)),
        std@context:rendered({test@main@@Element}, BpScope__)
    end.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
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
