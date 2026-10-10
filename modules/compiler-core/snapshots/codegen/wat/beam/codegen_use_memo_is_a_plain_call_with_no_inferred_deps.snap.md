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

----- BEAM ASSEMBLY -- std/context.S
```erlang
{module, std@context}.
{exports, [{provide, 2}, {context, 1}, {push, 3}, {find, 3}, {rendered, 2}, {valueOf, 1}, {root, 0}]}.
{attributes, []}.
{labels, 37}.
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
% Gives `value` to every component this component renders below it — never
% to itself or a sibling; the nearest provider wins.

{function, provide, 2, 3}.
  {label, 2}.
    {line, [{location, "std@context.erl", 1}]}.
    {func_info, {atom, std@context}, {atom, provide}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"`use provide` / `use context` are lowered where they are written; this body never runs">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.
% The value of `ctx` provided nearest above this body.

{function, context, 1, 5}.
  {label, 4}.
    {line, [{location, "std@context.erl", 2}]}.
    {func_info, {atom, std@context}, {atom, context}, 1}.
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
% source can spell. A `@Component` function answers `{ scope -> … }`; each
% `return v` of its body answers `rendered(v, <children's scope>)`; `use
% provide(C, v)` binds `push(<children's scope>, <C's identity>, v)` for the
% children, `use context(C)` is `find(<received scope>, <C's identity>, "C")`,
% a `use` of a hook and an `await` of a component value run the lambda and
% read `valueOf` of what it answers, and an `await` outside every body runs it
% with `root()`. A context's identity is the declaration of its `val` (281) —
% the compiler writes it, never a program.
% One provided value over the frames it was provided in.
% The children's scope: `value` provided for `key` over `scope`.

{function, push, 3, 7}.
  {label, 6}.
    {line, [{location, "std@context.erl", 4}]}.
    {func_info, {atom, std@context}, {atom, push}, 3}.
  {label, 7}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 20}, [{x, 0}, 2, {atom, std@context@@RenderScope}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 20}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Frame}, {y, 1}, {y, 2}, {x, 0}]}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@RenderScope}, {x, 0}]}}.
    {deallocate, 3}.
    return.
% The value provided nearest above for `key`; `context-unbound` when no
% provider of `name` is above.
% LANGUAGE GAP: the wasm backend does not lower a component — the two `unknown` fields are read through `frameValue` / `frameParent`, since wasm boxes a field read as `unknown` only as a function's answer.

{function, find, 3, 9}.
  {label, 8}.
    {line, [{location, "std@context.erl", 5}]}.
    {func_info, {atom, std@context}, {atom, find}, 3}.
  {label, 9}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 21}, [{x, 0}, 2, {atom, std@context@@RenderScope}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 21}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "std@context.erl", 6}]}.
  {label, 22}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 23}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 25}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {atom, false}, {x, 0}}.
  {label, 26}.
    {test, is_eq, {f, 24}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 28}.
    {test, is_eq_exact, {f, 27}, [{x, 0}, {y, 1}]}.
    {move, {y, 4}, {x, 0}}.
    {call_last, 1, {f, 17}, 6}.
  {label, 27}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 29}}.
  {label, 24}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<")` (decision 354)">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<", ...)` above this `use context(">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"context-unbound: no `use provide(">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 29}.
    {jump, {f, 22}}.
  {label, 23}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 6}.
    return.
% A body's answer: its result over its children's scope.

{function, rendered, 2, 11}.
  {label, 10}.
    {line, [{location, "std@context.erl", 6}]}.
    {func_info, {atom, std@context}, {atom, rendered}, 2}.
  {label, 11}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@Rendered}, {y, 0}, {y, 1}]}}.
    {deallocate, 2}.
    return.
% The result a run answered.

{function, valueOf, 1, 13}.
  {label, 12}.
    {line, [{location, "std@context.erl", 7}]}.
    {func_info, {atom, std@context}, {atom, valueOf}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 3, {atom, std@context@@Rendered}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 34}.
    {deallocate, 1}.
    return.
% The empty scope, for an `await` of a component value outside every body.

{function, root, 0, 15}.
  {label, 14}.
    {line, [{location, "std@context.erl", 8}]}.
    {func_info, {atom, std@context}, {atom, root}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {call_ext_last, 0, {extfunc, std@context@@RenderScope, root, 0}, 0}.

{function, frameValue, 1, 17}.
  {label, 16}.
    {line, [{location, "std@context.erl", 9}]}.
    {func_info, {atom, std@context}, {atom, frameValue}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 35}.
    {deallocate, 1}.
    return.

{function, frameParent, 1, 19}.
  {label, 18}.
    {line, [{location, "std@context.erl", 10}]}.
    {func_info, {atom, std@context}, {atom, frameParent}, 1}.
  {label, 19}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 36}, [{x, 0}, 4, {atom, std@context@@Frame}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 36}.
    {deallocate, 1}.
    return.

{function, '-bp_stringify-', 1, 31}.
  {label, 30}.
    {line, [{location, "std@context.erl", 6}]}.
    {func_info, {atom, std@context}, {atom, '-bp_stringify-'}, 1}.
  {label, 31}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 32}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 32}.
    {test, is_integer, {f, 33}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 33}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 0}.
```

----- BEAM ASSEMBLY -- std@context@@Context.S
```erlang
{module, std@context@@Context}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 4}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "std@context@@Context.erl", 1}]}.
    {func_info, {atom, std@context@@Context}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
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
    {line, [{location, "std@context@@RenderScope.erl", 3}]}.
    {func_info, {atom, std@context@@RenderScope}, {atom, root}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@context@@RenderScope}, {atom, undefined}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_get', 2, 5}.
  {label, 4}.
    {line, [{location, "std@context@@RenderScope.erl", 4}]}.
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
    {line, [{location, "std@context@@RenderScope.erl", 4}]}.
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
    {line, [{location, "std@context@@Rendered.erl", 4}]}.
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
    {line, [{location, "std@context@@Rendered.erl", 4}]}.
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
    {line, [{location, "std@context@@Frame.erl", 4}]}.
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
    {line, [{location, "std@context@@Frame.erl", 4}]}.
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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 22}.

{function, state, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, state}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {deallocate, 1}.
    return.

{function, memo, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, memo}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {deallocate, 0}.
    return.

{function, 'Counter', 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, 'Counter'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 0, 0, {x, 0}, {list, []}}.
    {deallocate, 0}.
    return.

{function, '-state/1-fun-0-', 2, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-state/1-fun-0-'}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@context, rendered, 2}, 2}.

{function, '-memo/0-fun-1-', 1, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-memo/0-fun-1-'}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@context, rendered, 2}, 1}.

{function, '-Counter/1-fun-3-', 2, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-Counter/1-fun-3-'}, 2}.
  {label, 19}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 20}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 20}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at test@main.bp:10:46">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 21}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@context, rendered, 2}, 2}.

{function, '-Counter/0-fun-2-', 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-Counter/0-fun-2-'}, 1}.
  {label, 13}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {call_ext, 1, {extfunc, std@context, valueOf, 1}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_map, {f, 14}, [{x, 1}]}.
    {get_map_elements, {f, 16}, {x, 1}, {list, [{atom, count}, {x, 0}]}}.
  {label, 16}.
    {move, {x, 0}, {y, 2}}.
    {get_map_elements, {f, 17}, {x, 1}, {list, [{atom, setCount}, {x, 0}]}}.
  {label, 17}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {atom, undefined}, {y, 2}}.
    {move, {atom, undefined}, {y, 3}}.
  {label, 15}.
    {move, {x, 1}, {x, 0}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, [{y, 2}, {y, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 1}, {x, 0}}.
    %% unresolved_call: memo/1
    {move, {literal, {unresolved_call, memo, 1}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_fun, 1}.
    {call_ext, 1, {extfunc, std@context, valueOf, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 2, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@Element}]}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@context, rendered, 2}, 6}.
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
