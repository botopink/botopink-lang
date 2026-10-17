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
pub fn context(comptime t: anytype) -> @Component<unknown> {
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
pub fn inject(comptime t: anytype) -> @Component<unknown> {
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

----- WASM TEXT -- std/context.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $rec_Context (struct (field $f0 (mut anyref))))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
    (type $rec_RenderScope (struct (field $f0 (mut anyref))))
    (type $rec_Frame (struct (field $f0 (mut (ref null $str))) (field $f1 (mut anyref)) (field $f2 (mut anyref))))
    (type $box_i32 (struct (field $v i32)))
    (type $rec_Rendered (struct (field $f0 (mut anyref)) (field $f1 (mut (ref null $rec_RenderScope)))))
  )
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  ;; Contexts (decisions 354, 378, 379) — what a component's body reads from
  ;; above it, React's context in botopink's spelling.
  ;; 
  ;; A context is named by its value's type. `createContext(value)` at module
  ;; level declares the default of that type — one declaration per type in
  ;; the program:
  ;; 
  ;;     pub val themeContext = comptime createContext(Theme(mode: .Light));
  ;; 
  ;; A component provides a context to everything it renders below it, and a
  ;; body reads the nearest one of a type provided above it, else the type's
  ;; declared default:
  ;; 
  ;;     use provide(createContext(Theme(mode: .Dark)));   // the children's
  ;;     val theme = use context(Theme);                    // the nearest above
  ;; 
  ;; Both are hooks, so they are `use`d, never called for a value; `provide`
  ;; only in a component's body (a `@Component<R>` whose `R` implements
  ;; `@Renderable`), before it renders a child. `use` exists only where there
  ;; is a render tree — a decorator body, a template body and a
  ;; `comptime { … }` have none (`use-outside-render-tree`). A read of a type
  ;; with no declared default is refused at build, at the read.
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
    struct.new $rec_Context
    return
  )
  ;; Gives `ctx` to every component this component renders below it — never
  ;; to itself or a sibling; the nearest provider of a type wins.
  (func $provide (export "provide") (param $ctx (ref null $rec_Context)) (result (ref null $closure))
    global.get $__s0
    call $__panic_fail
    unreachable
    ref.null $closure
  )
  ;; The value of the context of type `T` provided nearest above this body, or
  ;; `T`'s declared default: `use context(T)` answers `T`, which the checker
  ;; reads off the type the argument names (decision 379 (3)).
  (func $context (export "context") (param $t i32) (result (ref null $closure))
    global.get $__s0
    call $__panic_fail
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
    call $__panic_fail
    unreachable
    ref.null $closure
  )
  ;; ── the render scope (decision 388) ──────────────────────────────────────────
  ;; The scope a component's lambda runs with: the contexts provided above it.
  ;; Opaque — made only by `RenderScope.root()` (`render-scope-construction`);
  ;; every other scope is one a component's `run` answered.
  (func $RenderScope_root (result (ref null $rec_RenderScope))
    (local $__mem0 i32)
    ref.null any
    struct.new $rec_RenderScope
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
  ;; provide(c)` binds `push(<children's scope>, <T's identity>, c)` for the
  ;; children (a context is its value at run time: the compiler writes
  ;; `createContext(v)` as `v`), `use context(T)` is `find(<received scope>, <T's
  ;; identity>, <T's declared default>)`,
  ;; a `use` of a hook and an `await` of a component value run the lambda and
  ;; read `valueOf` of what it answers, and an `await` outside every body runs it
  ;; with `root()`. A context's identity is its value's type (379) — the
  ;; compiler writes it, never a program.
  ;; One provided value over the frames it was provided in.
  ;; The children's scope: `value` provided for `key` over `scope`.
  (func $push (export "push") (param $scope (ref null $rec_RenderScope)) (param $key (ref null $str)) (param $value anyref) (result (ref null $rec_RenderScope))
    (local $__mem0 i32)
    (local $__mem1 i32)
    local.get $key
    local.get $value
    local.get $scope
    struct.get $rec_RenderScope $f0
    struct.new $rec_Frame
    struct.new $rec_RenderScope
    return
  )
  ;; The value provided nearest above for `key`, else `fallback` — the type's
  ;; declared default (decision 378 (3): no read is unbound).
  ;; The two `unknown` fields are read through `frameValue` / `frameParent`: wasm boxes a field read as `unknown` only as a function's answer.
  (func $find (export "find") (param $scope (ref null $rec_RenderScope)) (param $key (ref null $str)) (param $fallback anyref) (result anyref)
    (local $__mem0 i32)
    (local $cur anyref)
    (local $f (ref null $rec_Frame))
    (local $__gc0 anyref)
    local.get $scope
    struct.get $rec_RenderScope $f0
    local.set $cur
    (block $__break
      (loop $__continue
    i32.const 1
        i32.eqz
        br_if $__break
    local.get $cur
    local.set $__gc0
    local.get $__gc0
    ref.test (ref null $rec_Frame)
    local.get $__gc0
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
    struct.new $rec_Frame
    call $frameValue
    return
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
    struct.new $box_i32
  )
  ;; A body's answer: its result over its children's scope.
  (func $rendered (export "rendered") (param $value anyref) (param $scope (ref null $rec_RenderScope)) (result (ref null $rec_Rendered))
    (local $__mem0 i32)
    local.get $value
    local.get $scope
    struct.new $rec_Rendered
    return
  )
  ;; The result a run answered.
  (func $valueOf (export "valueOf") (param $r (ref null $rec_Rendered)) (result anyref)
    local.get $r
    struct.get $rec_Rendered $f0
    return
  )
  ;; The empty scope, for an `await` of a component value outside every body.
  (func $root (export "root") (result (ref null $rec_RenderScope))
    call $RenderScope_root
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
  (data $__d0 "`use provide` / `use context` are lowered where they are written; this body never runs")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "`use inject` is lowered where it is written; this body never runs")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
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
  )
  (@custom "botopink.needs" "gc\0a")
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

----- WASM TEXT -- main.wat
```wasm
(module
  (import "wasi_snapshot_preview1" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0 $__lambda1 $__lambda2 $__lambda3))
  (data (i32.const 256) "\18\00\00\00R\07Context\01\0ccontextValueG")
  (data (i32.const 284) "\01\00\00\00i")
  (data (i32.const 292) "\56\00\00\00`use provide` / `use context` are lowered where they are written; this body never runs")
  (data (i32.const 384) "\41\00\00\00`use inject` is lowered where it is written; this body never runs")
  (data (i32.const 456) "\16\00\00\00R\0bRenderScope\01\06framesi")
  (data (i32.const 484) "\1c\00\00\00R\05Frame\03\03keys\05valuei\06parenti")
  (data (i32.const 516) "\19\00\00\00R\08Rendered\02\05valueG\05scopeT")
  (data (i32.const 548) "\0a\00\00\00R\07Element\00")
  (data (i32.const 564) "\2a\00\00\00integer overflow: + on i32 at main.bp:7:57")
  (global $__heap_ptr (mut i32) (i32.const 612))
  (func $createContext (param $value i32) (result i32)
    (local $__mem0 i32)
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 260
    i32.store
    local.get $__mem0
    i32.const 288
    i32.store offset=8
    local.get $__mem0
    local.get $value
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $provide (param $ctx i32) (result i32)
    i32.const 292
    call $__panic_fail
    unreachable
    i32.const 0
  )
  (func $context (param $t i32) (result i32)
    i32.const 292
    call $__panic_fail
    unreachable
    i32.const 0
  )
  (func $inject (param $t i32) (result i32)
    i32.const 384
    call $__panic_fail
    unreachable
    i32.const 0
  )
  (func $RenderScope_root (result i32)
    (local $__mem0 i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 460
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add
    return
  )
  (func $push (param $scope i32) (param $key i32) (param $value i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 460
    i32.store
    local.get $__mem0
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 488
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
  (func $find (param $scope i32) (param $key i32) (param $fallback i32) (result i32)
    (local $__mem0 i32)
    (local $cur i32)
    (local $f i32)
    (local $__mem1 i32)
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
    i32.const 488
    i32.eq
    i32.and
    (if (result i32)
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
    i32.const 0
      )
      (else
    i32.const 16
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 488
    i32.store
    local.get $__mem1
    local.get $key
    i32.store offset=4
    local.get $__mem1
    local.get $fallback
    i32.store offset=8
    local.get $__mem1
    i32.const 0
    i32.store offset=12
    local.get $__mem1
    i32.const 4
    i32.add
    call $frameValue
    return
      )
    )
    drop
        br $__continue
      )
    )
    i32.const 0
  )
  (func $rendered (param $value i32) (param $scope i32) (result i32)
    (local $__mem0 i32)
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 520
    i32.store
    local.get $__mem0
    i32.const 288
    i32.store offset=12
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
  (func $valueOf (param $r i32) (result i32)
    local.get $r
    i32.load ;; .value
    return
  )
  (func $root (result i32)
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
  (func $optimistic (param $base i32) (param $f i32) (result i32)
    (local $__mem0 i32)
    i32.const 16
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    i32.const 0
    i32.store offset=4
    local.get $__mem0
    local.get $f
    i32.store offset=8 ;; capture f
    local.get $__mem0
    local.get $base
    i32.store offset=12 ;; capture base
    local.get $__mem0
    i32.const 4
    i32.add ;; a component's lambda: past its mark
    return
  )
  (func $LikeWidget (result i32)
    (local $__mem0 i32)
    i32.const 8
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 0
    i32.store
    local.get $__mem0
    i32.const 1
    i32.store offset=4
    local.get $__mem0
    i32.const 4
    i32.add ;; a component's lambda: past its mark
    return
  )
  (func $bpScopeRaw__rendered (param $v i32) (param $s i32) (result i32)
    local.get $v
    local.get $s
    call $rendered
    return
  )
  (func $bpScopeRaw__value0 (param $r i32) (result i32)
    local.get $r
    call $valueOf
    return
  )
  (func $bpScopeRaw__run1 (param $c i32) (param $s i32) (result i32)
    (local $__fnv0 i32)
    local.get $c
    local.set $__fnv0
    local.get $__fnv0
    local.get $s
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    return
  )
  (func $__lambda0 (param $__env i32) (param $bpScope__ i32) (result i32)
    (local $f i32)
    (local $base i32)
    (local $__mem0 i32)
    (local $push i32)
    (local $__mem1 i32)
    local.get $__env
    i32.load offset=4
    local.set $f
    local.get $__env
    i32.load offset=8
    local.set $base
    i32.const 12
    call $__alloc
    local.set $__mem0
    local.get $__mem0
    i32.const 2
    i32.store
    local.get $__mem0
    local.get $f
    i32.store offset=4 ;; capture f
    local.get $__mem0
    local.get $base
    i32.store offset=8 ;; capture base
    local.get $__mem0
    local.set $push
    i32.const 8
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    local.get $base
    i32.store
    local.get $__mem1
    local.get $push
    i32.store offset=4
    local.get $__mem1
    local.get $bpScope__
    call $bpScopeRaw__rendered
    return
  )
  (func $__lambda1 (param $__env i32) (param $bpScope__ i32) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $shown i32)
    (local $push i32)
    (local $__runc0 i32)
    (local $__runm0 i32)
    (local $__runw0 i32)
    (local $__fnv1 i32)
    (local $__mem2 i32)
    i32.const 12
    i32.const 4
    call $__alloc
    local.set $__mem1
    local.get $__mem1
    i32.const 3
    i32.store
    local.get $__mem1
    call $optimistic
    local.tee $__runc0
    i32.const 4
    i32.sub
    i32.load ;; the lambda's mark: a state machine?
    local.set $__runm0
    local.get $__runc0
    local.get $bpScope__
    local.get $__runc0
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    local.set $__runw0
    local.get $__runm0
    (if (result i32)
      (then
    local.get $__runw0
    call $__task_block_on
    i32.load offset=8 ;; the settled value
      )
      (else
    local.get $__runw0
      )
    )
    call $bpScopeRaw__value0
    local.set $__mem0
    local.get $__mem0
    i32.load
    local.set $shown
    local.get $__mem0
    i32.load offset=4
    local.set $push
    local.get $push
    local.set $__fnv1
    local.get $__fnv1
    local.get $shown
    local.get $__fnv1
    i32.load ;; table index
    call_indirect (param i32 i32) (result i32)
    drop
    i32.const 4
    call $__alloc
    local.set $__mem2
    local.get $__mem2
    i32.const 552
    i32.store
    local.get $__mem2
    i32.const 4
    i32.add
    local.get $bpScope__
    call $bpScopeRaw__rendered
    return
  )
  (func $__lambda2 (param $__env i32) (param $action i32) (result i32)
    (local $f i32)
    (local $base i32)
    (local $__fnv0 i32)
    local.get $__env
    i32.load offset=4
    local.set $f
    local.get $__env
    i32.load offset=8
    local.set $base
    local.get $f
    local.set $__fnv0
    local.get $__fnv0
    local.get $base
    local.get $action
    local.get $__fnv0
    i32.load ;; table index
    call_indirect (param i32 i32 i32) (result i32)
  )
  (func $__lambda3 (param $__env i32) (param $c i32) (param $a i32) (result i32)
    local.get $c
    local.get $a
    i32.const 564
    call $__i32_add_chk
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
    i32.const 188
    i64.const 9071397899755888
    i64.store
    i32.const 188
    i32.const 7
    call $__write_err
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
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site i32) (result i32)
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
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site i32) (result i32)
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
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site i32) (result i32)
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
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site i32) (result i64)
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
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site i32) (result i64)
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
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site i32) (result i64)
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
  (global $__task_head (mut i32) (i32.const 0))
  (global $__task_tail (mut i32) (i32.const 0))
  (global $__task_suspended (mut i32) (i32.const 0))
  (func $__task_new (param $kind i32) (param $frame i32) (result i32)
    (local $t i32)
    i32.const 40
    call $__alloc
    local.set $t
    local.get $t
    local.get $kind
    i32.store offset=20
    local.get $t
    local.get $frame
    i32.store offset=16
    local.get $t
  )
  (func $__task_start (param $kind i32) (param $frame i32) (result i32)
    (local $t i32)
    local.get $kind
    local.get $frame
    call $__task_new
    local.tee $t
    call $__task_resume
    local.get $t
  )
  (func $__task_pending (param $t i32) (result i32)
    local.get $t
    i32.load
    i32.eqz
  )
  (func $__task_listen (param $t i32) (param $kind i32) (param $target i32) (param $index i32)
    (local $n i32)
    i32.const 16
    call $__alloc
    local.set $n
    local.get $n
    local.get $t
    i32.load offset=4
    i32.store
    local.get $n
    local.get $kind
    i32.store offset=4
    local.get $n
    local.get $target
    i32.store offset=8
    local.get $n
    local.get $index
    i32.store offset=12
    local.get $t
    local.get $n
    i32.store offset=4
  )
  (func $__task_wait (param $t i32) (param $w i32)
    local.get $t
    i32.const 0
    local.get $w
    i32.const 0
    call $__task_listen
  )
  (func $__task_settle_i32 (param $t i32) (param $v i32)
    local.get $t
    local.get $v
    i32.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_settle_i64 (param $t i32) (param $v i64)
    local.get $t
    local.get $v
    i64.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_settle_f64 (param $t i32) (param $v f64)
    local.get $t
    local.get $v
    f64.store offset=8
    local.get $t
    call $__task_wake
  )
  (func $__task_wake (param $t i32)
    (local $n i32) (local $m i32) (local $r i32) (local $k i32) (local $w i32)
    local.get $t
    i32.load
    (if
      (then
        return
      )
    )
    local.get $t
    i32.const 1
    i32.store
    local.get $t
    i32.load offset=4
    local.set $n
    local.get $t
    i32.const 0
    i32.store offset=4
    (block $brk
      (loop $cont
        local.get $n
        i32.eqz
        br_if $brk
        local.get $n
        i32.load
        local.set $m
        local.get $n
        local.get $r
        i32.store
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
        i32.eqz
        br_if $brk
        local.get $r
        i32.load offset=4
        local.set $k
        local.get $r
        i32.load offset=8
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
            i32.load
            i32.eqz
            (if
              (then
                local.get $w
                local.get $t
                i64.load offset=8
                i64.store offset=8
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
            i32.load offset=28
            i32.const 4
            i32.add
            local.get $r
            i32.load offset=12
            i32.const 4
            i32.mul
            i32.add
            local.get $t
            i32.load offset=8
            i32.store
            local.get $w
            local.get $w
            i32.load offset=32
            i32.const 1
            i32.sub
            i32.store offset=32
            local.get $w
            i32.load offset=32
            i32.eqz
            (if
              (then
                local.get $w
                local.get $w
                i32.load offset=28
                i32.store offset=8
                local.get $w
                call $__task_wake
              )
            )
          )
        )
        local.get $r
        i32.load
        local.set $r
        br $cont
      )
    )
  )
  (func $__task_enqueue (param $t i32)
    local.get $t
    i32.const 0
    i32.store offset=24
    global.get $__task_tail
    (if
      (then
        global.get $__task_tail
        local.get $t
        i32.store offset=24
      )
      (else
        local.get $t
        global.set $__task_head
      )
    )
    local.get $t
    global.set $__task_tail
  )
  (func $__task_drain
    (local $t i32)
    (block $brk
      (loop $cont
        global.get $__task_head
        local.tee $t
        i32.eqz
        br_if $brk
        local.get $t
        i32.load offset=24
        global.set $__task_head
        global.get $__task_head
        i32.eqz
        (if
          (then
            i32.const 0
            global.set $__task_tail
          )
        )
        local.get $t
        call $__task_resume
        br $cont
      )
    )
  )
  (func $__task_block_on (param $t i32) (result i32)
    (local $r i32)
    (block $brk
      (loop $cont
        local.get $t
        i32.load
        br_if $brk
        global.get $__task_head
        local.tee $r
        i32.eqz
        (if
          (then
            unreachable
          )
        )
        local.get $r
        i32.load offset=24
        global.set $__task_head
        global.get $__task_head
        i32.eqz
        (if
          (then
            i32.const 0
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
  (func $__task_resume (param $t i32)
    (local $k i32)
    local.get $t
    i32.load offset=20 ;; kind
    local.set $k
    unreachable
  )
  (func $__task_host_poll (result i32)
    i32.const 0
  )
  (func $__chk_fail (param $site i32)
    local.get $site
    call $__panic_fail
    unreachable
  )
)
```

----- RUN LOG -----
```logs
```
