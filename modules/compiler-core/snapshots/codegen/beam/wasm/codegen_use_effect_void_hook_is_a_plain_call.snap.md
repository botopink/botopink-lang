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

----- WASM TEXT -- std/context.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\16\00\00\00R\0bRenderScope\01\06framesi")
  (data (i32.const 284) "\1c\00\00\00R\05Frame\03\03keys\05valuei\06parenti")
  (data (i32.const 316) "\19\00\00\00R\08Rendered\02\05valuei\05scopeT")
  (global $__heap_ptr (mut i32) (i32.const 348))
  ;; Contexts (decision 354) — what a component's body reads from above it,
  ;; React's context in botopink's spelling.
  ;; 
  ;; A context is a declared object, its identity the declaration (decision
  ;; 281): `pub val ThemeContext = Context<Theme>();` — no default value, and
  ;; no other way to make one (`context-not-declared`). A component provides a
  ;; value to everything it renders below it, and a body reads the nearest
  ;; value provided above it:
  ;; 
  ;;     use provide(ThemeContext, Theme(mode: .Dark));   // the children's
  ;;     val theme = use context(ThemeContext);           // the nearest above
  ;; 
  ;; Both are hooks, so they are `use`d, never called for a value; `provide`
  ;; only in a component's body (a `@Component<R>` whose `R` implements
  ;; `@Renderable`), before it renders a child. `use` exists only where there
  ;; is a render tree — a decorator body, a template body and a
  ;; `comptime { … }` have none (`use-outside-render-tree`). A read with no
  ;; provider above it is `context-unbound` at run time.
  ;; 
  ;; A component at run time is a lambda over a `RenderScope` (decision 388):
  ;; calling `Card(item)` only makes the lambda, and the render library runs it
  ;; — `c.run(scope)` answers a `Rendered`, the body's result and the scope its
  ;; `use provide(…)`s made for its children. The library runs the root with
  ;; `RenderScope.root()` and each child with the scope its parent answered;
  ;; inside a component body `await c` runs `c` with the body's children scope,
  ;; outside every body with `RenderScope.root()`. The scope travels
  ;; explicitly: no "current context", on any target.
  ;; 
  ;; The work is the compiler's: each `use provide(…)` / `use context(…)` is
  ;; lowered where it is written — `provide` makes the children's scope and
  ;; `context` looks the received one up. Neither hook below is ever called:
  ;; the checker refuses every reference to them but a `use`'s operand, and the
  ;; bodies panic.
  ;; A context of `T`, named by the `val` that declares it.
  ;; Gives `value` to every component this component renders below it — never
  ;; to itself or a sibling; the nearest provider wins.
  (func $provide (export "provide") (param $ctx i32) (param $value i32) (result i32)
    unreachable
    i32.const 0
  )
  ;; The value of `ctx` provided nearest above this body.
  (func $context (export "context") (param $ctx i32) (result i32)
    unreachable
    i32.const 0
  )
  ;; ── the render scope (decision 388) ──────────────────────────────────────────
  ;; The scope a component's lambda runs with: the contexts provided above it.
  ;; Opaque — made only by `RenderScope.root()` (`render-scope-construction`);
  ;; every other scope is one a component's `run` answered.
  (func $RenderScope_root (result i32)
    (local $__mem0 i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  ;; What `c.run(scope)` answers: the component body's result and the scope its
  ;; `use provide(…)`s made for the children it renders (the scope it received
  ;; when it provides nothing).
  ;; ── what the scope lowering calls (decision 388) ─────────────────────────────
  ;; 
  ;; A program never names these: the compiler imports them under names no
  ;; source can spell. A `@Component` function answers `{ scope -> … }`; each
  ;; `return v` of its body answers `rendered(v, <children's scope>)`; `use
  ;; provide(C, v)` binds `push(<children's scope>, <C's identity>, v)` for the
  ;; children, `use context(C)` is `find(<received scope>, <C's identity>, "C")`,
  ;; a `use` of a hook and an `await` of a component value run the lambda and
  ;; read `valueOf` of what it answers, and an `await` outside every body runs it
  ;; with `root()`. A context's identity is the declaration of its `val` (281) —
  ;; the compiler writes it, never a program.
  ;; One provided value over the frames it was provided in.
  ;; The children's scope: `value` provided for `key` over `scope`.
  (func $push (export "push") (param $scope i32) (param $key i32) (param $value i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 288
    i32.store
    local.get $__mem1
    local.get $key
    i32.store offset=4
    local.get $__mem1
    local.get $value
    i32.store offset=8
    local.get $__mem1
    local.get $scope
    i32.load ;; .frames
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  ;; The value provided nearest above for `key`; `context-unbound` when no
  ;; provider of `name` is above.
  ;; LANGUAGE GAP: the wasm backend does not lower a component — the two `unknown` fields are read through `frameValue` / `frameParent`, since wasm boxes a field read as `unknown` only as a function's answer.
  (func $find (export "find") (param $scope i32) (param $key i32) (param $name i32) (result i32)
    (local $cur i32)
    (local $f i32)
    (local $__mem0 i32)
    local.get $scope
    i32.load ;; .frames
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
    i32.const 288
    i32.eq
    i32.and
    (if
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
      )
      (else
    unreachable
      )
    )
        br $__continue
      )
    )
    i32.const 0
  )
  ;; A body's answer: its result over its children's scope.
  (func $rendered (export "rendered") (param $value i32) (param $scope i32) (result i32)
    (local $__mem0 i32)
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 320
    i32.store
    local.get $__mem0
    local.get $value
    i32.store offset=4
    local.get $__mem0
    local.get $scope
    i32.store offset=8
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  ;; The result a run answered.
  (func $valueOf (export "valueOf") (param $r i32) (result i32)
    local.get $r
    i32.load ;; .value
    return
  )
  ;; The empty scope, for an `await` of a component value outside every body.
  (func $root (export "root") (result i32)
    call $RenderScope_root
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
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Renderable
fn cleanup() {
    0;
}
fn effect() -> @Component<i32> {
    return 0;
}
fn Widget() -> @Component<Element> {
    use effect { -> cleanup(); };
    return Element();
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: the wasm backend does not lower a component yet: a `@Component` is a lambda over a `RenderScope` (decision 388), lowered on erlang, beam and commonJS
  ┌─ :5:4
  │
5 │ fn effect() -> @Component<i32> {
  │    ^
```

