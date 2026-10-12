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
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (data (i32.const 256) "\56\00\00\00`use provide` / `use context` are lowered where they are written; this body never runs")
  (data (i32.const 348) "\16\00\00\00R\0bRenderScope\01\06framesi")
  (data (i32.const 376) "\1c\00\00\00R\05Frame\03\03keys\05valuei\06parenti")
  (data (i32.const 408) "\21\00\00\00context-unbound: no `use provide(")
  (data (i32.const 448) "\20\00\00\00, ...)` above this `use context(")
  (data (i32.const 484) "\11\00\00\00)` (decision 354)")
  (data (i32.const 508) "\19\00\00\00R\08Rendered\02\05valuei\05scopeT")
  (global $__heap_ptr (mut i32) (i32.const 540))
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
    i32.const 256
    call $__panic_fail
    unreachable
    i32.const 0
  )
  ;; The value of `ctx` provided nearest above this body.
  (func $context (export "context") (param $ctx i32) (result i32)
    i32.const 256
    call $__panic_fail
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
    i32.const 352
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
    i32.const 352
    i32.store
    local.get $__mem0
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 380
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
    i32.const 380
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
    i32.const 408
    local.get $name
    call $__str_concat
    i32.const 448
    call $__str_concat
    local.get $name
    call $__str_concat
    i32.const 484
    call $__str_concat
    call $__panic_fail
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
    i32.const 512
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
  ;; Scratch layout below the data section (which starts at 256):
  ;;   0..8  WASI iovec   8  newline byte
  ;;  16..32 bool text   64..128 i32 digits
  (func $__write_bytes (param $p i32) (param $n i32)
    i32.const 0
    local.get $p
    i32.store
    i32.const 4
    local.get $n
    i32.store
    i32.const 1
    i32.const 0
    i32.const 1
    i32.const 8
    call $fd_write
    drop
  )
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
  (func $__str_concat (param $a i32) (param $b i32) (result i32)
    (local $base i32) (local $alen i32) (local $blen i32)
    local.get $a
    i32.load
    local.set $alen
    local.get $b
    i32.load
    local.set $blen
    ;; allocate 4 (length prefix) + alen + blen
    i32.const 4
    local.get $alen
    i32.add
    local.get $blen
    i32.add
    call $__alloc
    local.set $base
    ;; store combined length prefix
    local.get $base
    local.get $alen
    local.get $blen
    i32.add
    i32.store
    ;; copy a's bytes: base+4 <- a+4
    local.get $base
    i32.const 4
    i32.add
    local.get $a
    i32.const 4
    i32.add
    local.get $alen
    memory.copy
    ;; copy b's bytes: base+4+alen <- b+4
    local.get $base
    i32.const 4
    i32.add
    local.get $alen
    i32.add
    local.get $b
    i32.const 4
    i32.add
    local.get $blen
    memory.copy
    local.get $base
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
  (func $__panic_fail (param $msg i32)
    local.get $msg
    i32.const 4
    i32.add
    local.get $msg
    i32.load
    call $__write_err
    i32.const 188
    i32.const 10
    i32.store8
    i32.const 188
    i32.const 1
    call $__write_err
  )
)
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

----- COMPILE DIAGNOSTIC -- main
```text
error: the wasm backend does not lower a component yet: a `@Component` is a lambda over a `RenderScope` (decision 388), lowered on erlang, beam and commonJS
  ┌─ :2:4
  │
2 │ fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Component<#(i32, fn(action: i32) -> i32)> {
  │    ^
```

