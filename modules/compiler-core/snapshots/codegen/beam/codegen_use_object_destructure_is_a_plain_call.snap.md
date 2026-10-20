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
//// only in a component's body (a `Component<R>` whose `R` implements
//// `@Renderable`), before it renders a child. `use` exists only where there
//// is a render tree — a decorator body, a template body and a
//// `comptime { … }` have none (`use-outside-render-tree`). A read naming a
//// bare type (`use context(Theme)`) is refused at the argument
//// (`context-read-by-type`).
////
//// A component at run time is a lambda over a `RenderScope` (decision 388):
//// calling `Card(item)` only makes the lambda, and the render library runs it
//// — `c.run(scope)` answers a `Rendered`, the body's result and the scope its
//// `use provide(…)`s made for its children. The library runs the root with
//// `RenderScope.root()` and each child with the scope its parent answered;
//// inside a component body `use c` runs `c` with the body's children scope
//// (decision 791 (3)), and an `await` of a component is refused (791 (4)).
//// The scope travels explicitly: no "current context", on any target.
////
//// The work is the compiler's: each `use provide(…)` / `use context(…)` is
//// lowered where it is written — `provide` makes the children's scope and
//// `context` looks the received one up, the declared default when nothing
//// of its type is provided. Neither hook below is ever called: the checker
//// refuses every reference to them but a `use`'s operand, and the bodies
//// panic.

import {failure.panic};

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
// source can spell. A `Component` function answers `{ scope -> … }`; each
// `return v` of its body answers `rendered(v, <children's scope>)`; `use
// provide(c)` binds `push(<children's scope>, <T's identity>, c)` for the
// children (a context is its value at run time: the compiler writes
// `createContext(v)` as `v`), `use context(ctx)` is `find(<received scope>,
// <ctx's type's identity>, ctx)`,
// a `use` of a hook or of a component value runs the lambda and reads
// `valueOf` of what it answers. A context's identity is its value's type
// (379) — the compiler writes it, never a program.

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

// The empty scope, the root's (`RenderScope.root()`).
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

----- BEAM ASSEMBLY -- std/context.S
```erlang
{module, std@context}.
{exports, [{createContext, 1}, {provide, 1}, {context, 1}, {inject, 1}, {push, 3}, {find, 3}, {rendered, 2}, {valueOf, 1}, {root, 0}, {'__bp_priv__frameParent', 1}, {'__bp_priv__frameValue', 1}]}.
{attributes, []}.
{labels, 41}.
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
%%% only in a component's body (a `Component<R>` whose `R` implements
%%% `@Renderable`), before it renders a child. `use` exists only where there
%%% is a render tree — a decorator body, a template body and a
%%% `comptime { … }` have none (`use-outside-render-tree`). A read naming a
%%% bare type (`use context(Theme)`) is refused at the argument
%%% (`context-read-by-type`).
%%% 
%%% A component at run time is a lambda over a `RenderScope` (decision 388):
%%% calling `Card(item)` only makes the lambda, and the render library runs it
%%% — `c.run(scope)` answers a `Rendered`, the body's result and the scope its
%%% `use provide(…)`s made for its children. The library runs the root with
%%% `RenderScope.root()` and each child with the scope its parent answered;
%%% inside a component body `use c` runs `c` with the body's children scope
%%% (decision 791 (3)), and an `await` of a component is refused (791 (4)).
%%% The scope travels explicitly: no "current context", on any target.
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
% ── the render scope (decision 388) ──────────────────────────────────────────
% The scope a component's lambda runs with: the contexts provided above it.
% Opaque — made only by `RenderScope.root()` (`render-scope-construction`);
% every other scope is one a component's `run` answered.
% What `c.run(scope)` answers: the component body's result and the scope its
% `use provide(…)`s made for the children it renders (the scope it received
% when it provides nothing).
% ── what the scope lowering calls (decision 388) ─────────────────────────────
% 
% A program never names these: the compiler imports them under names no
% source can spell. A `Component` function answers `{ scope -> … }`; each
% `return v` of its body answers `rendered(v, <children's scope>)`; `use
% provide(c)` binds `push(<children's scope>, <T's identity>, c)` for the
% children (a context is its value at run time: the compiler writes
% `createContext(v)` as `v`), `use context(ctx)` is `find(<received scope>,
% <ctx's type's identity>, ctx)`,
% a `use` of a hook or of a component value runs the lambda and reads
% `valueOf` of what it answers. A context's identity is its value's type
% (379) — the compiler writes it, never a program.
% One provided value over the frames it was provided in.
% The children's scope: `value` provided for `key` over `scope`.

{function, push, 3, 11}.
  {label, 10}.
    {line, [{location, "std@context.erl", 6}]}.
    {func_info, {atom, std@context}, {atom, push}, 3}.
  {label, 11}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 24}, [{x, 0}, 2, {atom, std@context@@RenderScope}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 24}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Frame}, {y, 1}, {y, 2}, {x, 0}]}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@RenderScope}, {x, 0}]}}.
    {deallocate, 3}.
    return.
% The value provided nearest above for `key`, else `fallback` — the type's
% declared default (decision 378 (3): no read is unbound).
% The two `unknown` fields are read through `frameValue` / `frameParent`: wasm boxes a field read as `unknown` only as a function's answer.

{function, find, 3, 13}.
  {label, 12}.
    {line, [{location, "std@context.erl", 7}]}.
    {func_info, {atom, std@context}, {atom, find}, 3}.
  {label, 13}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 25}, [{x, 0}, 2, {atom, std@context@@RenderScope}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 25}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@context.erl", 8}]}.
  {label, 26}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 27}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 29}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 30}}.
  {label, 29}.
    {move, {atom, false}, {x, 0}}.
  {label, 30}.
    {test, is_eq, {f, 28}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 32}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {y, 1}]}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 1, {f, 21}, 5}.
  {label, 31}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 33}}.
  {label, 28}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Frame}, {y, 1}, {y, 2}, {atom, undefined}]}}.
    {call_last, 1, {f, 21}, 5}.
  {label, 33}.
    {jump, {f, 26}}.
  {label, 27}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
% A body's answer: its result over its children's scope.

{function, rendered, 2, 15}.
  {label, 14}.
    {line, [{location, "std@context.erl", 8}]}.
    {func_info, {atom, std@context}, {atom, rendered}, 2}.
  {label, 15}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Rendered}, {y, 0}, {y, 1}]}}.
    {deallocate, 2}.
    return.
% The result a run answered.

{function, valueOf, 1, 17}.
  {label, 16}.
    {line, [{location, "std@context.erl", 9}]}.
    {func_info, {atom, std@context}, {atom, valueOf}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 3, {atom, std@context@@Rendered}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 34}.
    {deallocate, 1}.
    return.
% The empty scope, the root's (`RenderScope.root()`).

{function, root, 0, 19}.
  {label, 18}.
    {line, [{location, "std@context.erl", 10}]}.
    {func_info, {atom, std@context}, {atom, root}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {call_ext_last, 0, {extfunc, std@context@@RenderScope, root, 0}, 0}.

{function, frameValue, 1, 21}.
  {label, 20}.
    {line, [{location, "std@context.erl", 11}]}.
    {func_info, {atom, std@context}, {atom, frameValue}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 35}.
    {deallocate, 1}.
    return.

{function, frameParent, 1, 23}.
  {label, 22}.
    {line, [{location, "std@context.erl", 12}]}.
    {func_info, {atom, std@context}, {atom, frameParent}, 1}.
  {label, 23}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 36}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 36}.
    {deallocate, 1}.
    return.

{function, '__bp_priv__frameParent', 1, 38}.
  {label, 37}.
    {line, [{location, "std@context.erl", 13}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__frameParent'}, 1}.
  {label, 38}.
    {call_only, 1, {f, 23}}.

{function, '__bp_priv__frameValue', 1, 40}.
  {label, 39}.
    {line, [{location, "std@context.erl", 14}]}.
    {func_info, {atom, std@context}, {atom, '__bp_priv__frameValue'}, 1}.
  {label, 40}.
    {call_only, 1, {f, 21}}.
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

----- BEAM ASSEMBLY -- std@context@@RenderScope.S
```erlang
{module, std@context@@RenderScope}.
{exports, [{root, 0}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, root, 0, 3}.
  {label, 2}.
    {line, [{location, "std@context@@RenderScope.erl", 5}]}.
    {func_info, {atom, std@context@@RenderScope}, {atom, root}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@RenderScope}, {atom, undefined}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_get', 2, 5}.
  {label, 4}.
    {line, [{location, "std@context@@RenderScope.erl", 6}]}.
    {func_info, {atom, std@context@@RenderScope}, {atom, '__bp_get'}, 2}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, frames}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "std@context@@RenderScope.erl", 6}]}.
    {func_info, {atom, std@context@@RenderScope}, {atom, '__bp_format'}, 1}.
  {label, 8}.
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
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"RenderScope">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- std@context@@Rendered.S
```erlang
{module, std@context@@Rendered}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "std@context@@Rendered.erl", 6}]}.
    {func_info, {atom, std@context@@Rendered}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, value}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, scope}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 7}.
  {label, 6}.
    {line, [{location, "std@context@@Rendered.erl", 6}]}.
    {func_info, {atom, std@context@@Rendered}, {atom, '__bp_format'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"scope">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"value">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Rendered">>}, {y, 1}]}}.
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
    {line, [{location, "std@context@@Frame.erl", 6}]}.
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
    {line, [{location, "std@context@@Frame.erl", 6}]}.
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
val Element = type() implement Renderable
component fn state(initial: i32) -> Component<i32> {
    return initial;
}
component fn Counter() -> Component<Element> {
    val {count, setCount} = use state(0);
    return Element();
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'__bp_priv__Counter', 0}, {'__bp_priv__state', 1}]}.
{attributes, []}.
{labels, 18}.

{function, state, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, state}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {deallocate, 1}.
    return.

{function, 'Counter', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, 'Counter'}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
    {deallocate, 0}.
    return.

{function, '__bp_priv__Counter', 0, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__Counter'}, 0}.
  {label, 15}.
    {call_only, 0, {f, 5}}.

{function, '__bp_priv__state', 1, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__state'}, 1}.
  {label, 17}.
    {call_only, 1, {f, 3}}.

{function, '-state/1-fun-0-', 2, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-state/1-fun-0-'}, 2}.
  {label, 7}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@context, rendered, 2}, 2}.

{function, '-Counter/0-fun-1-', 1, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-Counter/0-fun-1-'}, 1}.
  {label, 9}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {call_ext, 1, {extfunc, std@context, valueOf, 1}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_map, {f, 10}, [{x, 1}]}.
    {get_map_elements, {f, 12}, {x, 1}, {list, [{atom, count}, {x, 0}]}}.
  {label, 12}.
    {move, {x, 0}, {y, 2}}.
    {get_map_elements, {f, 13}, {x, 1}, {list, [{atom, setCount}, {x, 0}]}}.
  {label, 13}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 11}}.
  {label, 10}.
    {move, {atom, undefined}, {y, 2}}.
    {move, {atom, undefined}, {y, 3}}.
  {label, 11}.
    {move, {x, 1}, {x, 0}}.
    {test_heap, 2, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Element}]}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@context, rendered, 2}, 4}.
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
