----- SOURCE CODE -- std/failure.bp
```botopink
//// std/failure — the two records a failure that is not a typed error carries
//// (decisions 431, 492).
////
//// `HostError` is what a host binding that writes `result: true` answers on
//// the `Error` side: the host's message and `kind`, always `"host"`.
//// `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`
//// (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise
//// from a binding without `result: true`) or `crash` (a VM or emitted-code
//// fault, a wasm trap).
////
//// `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`
//// for a raise it caught — the one way to contain a crash (decision 431 (3)).
//// `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,
//// awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read
//// back by `await` like any failing task (decision 432). The kinds
//// (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`
//// and an integer overflow or division by zero are `panic`, their message
//// the text the program wrote. A raise of a binding declared outside std without
//// `result: true` is `host` (decision 546), its message the host's text — on
//// commonJS an `Error`'s `message`, else `String(e)`, the call run through
//// `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is
//// `crash`, its message the same text. On erlang and beam a
//// host raise is the raise of a binding declared outside std without `result:
//// true` — a library's or the program's, whose calls are wrapped to mark it
//// (decision 546) — its message the reason by `~tp` (decision 489's reading);
//// a raise nothing marked, a failing match or a std binding's, is `crash`,
//// its message the reason by `~tp` too.
////
//// Both are bodyless: each backend wraps the call (a JavaScript `try` /
//// rejection handler, an erlang `try … catch`; beam compiles the erlang
//// form). On wasm (decision 518) each is a private body over `caught`, the
//// `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that
//// catches the program's aborts (wasm exception handling), so the binding
//// declares `needs: [.Exceptions]` and a program reaching it runs with the
//// host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort
//// is `panic`; a trap (an overflow or a division by zero there, a host
//// fault) is no exception and is not caught. `attemptTask` contains what
//// the thunk raises before the task's first `await`.

import {compiler};

pub type HostErrorName {
    Error,
    Throw,
    Exit,
}

pub type HostError(message: string, kind: string, name: HostErrorName, detail: ?string)

pub type Failure(message: string, kind: string)

// Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops
// with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.
// Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`
// inside std); `panic("not implemented")` is what `todo` was.
#[compiler.external(
    .Erlang("erlang:error({panic, $0})"),
    .JavaScript("(() => { throw Object.defineProperty(new Error($0), '__bp_panic', { value: true }) })()"),
)]
pub declare fn panic(message: string = "panic") -> noreturn;

// The Node forms read an abort by the `__bp_panic` mark the backend puts on
// every one it raises — `panic`, `@todo`, an integer overflow or division
// by zero, a failed `assert` (whose mark carries its message) — or a test
// body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the
// backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,
// M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task
// (decision 432): marked `__bp_fails`, resolved with the value, rejected with
// the `Failure` (`__bp_failure`); a failing task `f` answers is read as
// `await` reads it.
#[compiler.external(
    .JavaScript("""((__f, __k) => { try { return { ok: __f() }; } catch (__e) { return { error: __k(__e) }; } })($0, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash")))"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)($0)"""),
    .Wasm(body: attemptOnWasm),
)]
pub declare fn attempt<T>(f: fn() -> T) -> Result<T, Failure>;

#[compiler.external(
    .JavaScript("""((__f, __k) => { const __t = (async () => { const __x = __f(); return (__x != null && __x.__bp_fails === true) ? await __x.then((__v) => ({ ok: __v }), (__e) => { if (__x.__bp_failure === true) { return { error: __e }; } throw __e; }) : await __x; })().then((__v) => __v, (__e) => { __t.__bp_failure = true; throw __k(__e); }); __t.__bp_fails = true; __t.catch(() => {}); return __t; })($0, ((__e) => (__e != null && __e.__bp_panic != null) ? new Failure(typeof __e.__bp_panic === "string" ? __e.__bp_panic : __e.message, "panic") : (__e != null && typeof __e.__bp_assert_loc === "string") ? new Failure(__e.message, "panic") : new Failure((__e instanceof Error) ? __e.message : String(__e), (__e != null && __e.__bp_host === true) ? "host" : "crash")))"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch error:{__T, __M} when (__T =:= panic orelse __T =:= todo orelse __T =:= integer_overflow) andalso (is_binary(__M) orelse is_list(__M)) -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, _, _, __M} -> {error, {'std@failure@@Failure', unicode:characters_to_binary(__M), <<"panic">>}}; error:{bp_assert, __M, _} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"panic">>}}; error:{bp_host, __M} when is_binary(__M) -> {error, {'std@failure@@Failure', __M, <<"host">>}}; _:__R -> {error, {'std@failure@@Failure', unicode:characters_to_binary(io_lib:format("~tp", [__R])), <<"crash">>}} end end)($0)"""),
    .Wasm(body: attemptTaskOnWasm),
)]
pub declare fn attemptTask<T>(f: fn() -> Async<T>) -> Async<Result<T, Failure>>;

// wasm's form (decision 518): the thunk's value, or the message of the abort
// it raised — `Error` of the abort's text, which `attempt` makes a `panic`.
// The bodies over it are compiled on every target, so it has a form on each;
// only wasm calls it (`attempt`'s own forms answer elsewhere).
#[compiler.external(
    .JavaScript("""((__f) => { try { return { ok: __f() }; } catch (__e) { return { error: (__e instanceof Error) ? __e.message : String(__e) }; } })($0)"""),
    .Erlang("""(fun(__F) -> try {ok, __F()} catch _:__R -> {error, unicode:characters_to_binary(io_lib:format("~tp", [__R]))} end end)($0)"""),
    .Wasm(wasi: .Attempt, needs: [.Exceptions]),
)]
declare fn caught<T>(f: fn() -> T) -> Result<T, string>;

fn attemptOnWasm<T>(f: fn() -> T) -> Result<T, Failure> {
    case caught(f) {
        Ok(v) -> return v;
        Error(m) -> throw Failure(message: m, kind: "panic");
    }
}

// The task the thunk started — or the `Failure` it raised before its first
// `await` — and then its value.
async fn attemptTaskOnWasm<T>(f: fn() -> Async<T>) -> Async<Result<T, Failure>> {
    case caught(f) {
        Ok(t) -> return await t;
        Error(m) -> throw Failure(message: m, kind: "panic");
    }
}

```

----- WASM TEXT -- std/failure.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (array (mut i32)))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
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
    (type $rec_Failure (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $str))))))
    (type $brand_rec_Failure (struct (field f32) (field f64) (field i64) (field i64) (field i32) (field f32) (field f64) (field i32) (field i64) (field i64) (field f64) (field i32) (field f32) (field f64) (field f32) (field f32) (field i64) (field i32) (field f32) (field f64) (field f32) (field f32) (field i64) (field f64) (field i32) (field i32) (field i32) (field f32) (field f32) (field f64) (field f64) (field i64)))
  )
  (rec
    (type $frame0 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $closure))) (field $s1 (mut i32)) (field $s2 (mut i32)) (field $s3 (mut i32)) (field $s4 (mut (ref null $result))) (field $s5 (mut (ref null $task))) (field $s6 (mut (ref null $task))) (field $s7 (mut (ref null $str)))))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (tag $__bp_panic (param anyref))
  ;; std/failure — the two records a failure that is not a typed error carries
  ;; (decisions 431, 492).
  ;; 
  ;; `HostError` is what a host binding that writes `result: true` answers on
  ;; the `Error` side: the host's message and `kind`, always `"host"`.
  ;; `Failure` is what `attempt` answers on the `Error` side: `kind` is `panic`
  ;; (`panic`, `@todo`, `x!`, an overflow, a division by zero), `host` (a raise
  ;; from a binding without `result: true`) or `crash` (a VM or emitted-code
  ;; fault, a wasm trap).
  ;; 
  ;; `attempt(f)` runs `f` and answers `Ok` of its value, or `Error(Failure)`
  ;; for a raise it caught — the one way to contain a crash (decision 431 (3)).
  ;; `attemptTask(f)` is its `Async` form (decision 494): the task `f` answers,
  ;; awaited, or the `Failure` it crashed with — a `Async<Result<…>>` read
  ;; back by `await` like any failing task (decision 432). The kinds
  ;; (decision 492): a `panic` / `@todo` (and so `x!`), a failed `assert`
  ;; and an integer overflow or division by zero are `panic`, their message
  ;; the text the program wrote. A raise of a binding declared outside std without
  ;; `result: true` is `host` (decision 546), its message the host's text — on
  ;; commonJS an `Error`'s `message`, else `String(e)`, the call run through
  ;; `__bp_host_mark`, which marks it `__bp_host`; any raise nothing marked is
  ;; `crash`, its message the same text. On erlang and beam a
  ;; host raise is the raise of a binding declared outside std without `result:
  ;; true` — a library's or the program's, whose calls are wrapped to mark it
  ;; (decision 546) — its message the reason by `~tp` (decision 489's reading);
  ;; a raise nothing marked, a failing match or a std binding's, is `crash`,
  ;; its message the reason by `~tp` too.
  ;; 
  ;; Both are bodyless: each backend wraps the call (a JavaScript `try` /
  ;; rejection handler, an erlang `try … catch`; beam compiles the erlang
  ;; form). On wasm (decision 518) each is a private body over `caught`, the
  ;; `wasi: .Attempt` adapter: the thunk runs inside a `try_table` that
  ;; catches the program's aborts (wasm exception handling), so the binding
  ;; declares `needs: [.Exceptions]` and a program reaching it runs with the
  ;; host's exceptions on (`-W exceptions=y` on wasmtime). On wasm an abort
  ;; is `panic`; a trap (an overflow or a division by zero there, a host
  ;; fault) is no exception and is not caught. `attemptTask` contains what
  ;; the thunk raises before the task's first `await`.
  ;; Decision 606 (2) — the abort `attempt` catches as a `panic` `Failure`: the program stops
  ;; with `panic: <message>` (decision 535) unless an `attempt` above it answers the `Failure`.
  ;; Imported where it is used, `import {failure.panic} from "std";` (`import {failure.panic};`
  ;; inside std); `panic("not implemented")` is what `todo` was.
  ;; declare fn panic — no wasm implementation (host-backed)
  ;; The Node forms read an abort by the `__bp_panic` mark the backend puts on
  ;; every one it raises — `panic`, `@todo`, an integer overflow or division
  ;; by zero, a failed `assert` (whose mark carries its message) — or a test
  ;; body's `assert` (`__bp_assert_loc`); the Erlang forms by the reasons the
  ;; backends raise for them (`{panic, M}`, `{todo, M}`, `{integer_overflow,
  ;; M}`, `{bp_assert, M, Where}`). `attemptTask` answers a failing task
  ;; (decision 432): marked `__bp_fails`, resolved with the value, rejected with
  ;; the `Failure` (`__bp_failure`); a failing task `f` answers is read as
  ;; `await` reads it.
  ;; attempt — .Wasm(body: attemptOnWasm)
  (func $attempt (export "attempt") (param $f (ref null $closure)) (result (ref null $result))
    local.get $f
    call $attemptOnWasm
  )
  ;; attemptTask — .Wasm(body: attemptTaskOnWasm)
  (func $attemptTask (export "attemptTask") (param $f (ref null $closure)) (result (ref null $task))
    local.get $f
    call $attemptTaskOnWasm
  )
  ;; wasm's form (decision 518): the thunk's value, or the message of the abort
  ;; it raised — `Error` of the abort's text, which `attempt` makes a `panic`.
  ;; The bodies over it are compiled on every target, so it has a form on each;
  ;; only wasm calls it (`attempt`'s own forms answer elsewhere).
  ;; caught — .Wasm(wasi: .Attempt)
  (func $caught (param $f (ref null $closure)) (result (ref null $result))
    local.get $f
    call $__wasi_attempt
  )
  (func $attemptOnWasm (param $f (ref null $closure)) (result (ref null $result))
    (local $__mem0 i32)
    (local $v i32)
    (local $m i32)
    (local $__case_0 (ref null $result))
    (local $v__0 anyref)
    (local $m__1 (ref null $str))
    local.get $f
    call $caught
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $v__0
    i32.const 0
    local.get $v__0
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $m__1
    i32.const 1
    local.get $m__1
    global.get $__s0
    call $__new_23
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  ;; The task the thunk started — or the `Failure` it raised before its first
  ;; `await` — and then its value.
  ;; @Async — a state machine (decision 392)
  (func $attemptTaskOnWasm (param $f (ref null $closure)) (result (ref null $task))
    (local $__fr (ref null $frame0))
    struct.new_default $frame0 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $f
    struct.set $frame0 $s0
    i32.const 0 ;; attemptTaskOnWasm__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $attemptTaskOnWasm__body (param $__task (ref null $task)) (result (ref null $result))
    (local $f (ref null $closure))
    (local $__mem0 i32)
    (local $t i32)
    (local $m i32)
    (local $__frame (ref null $frame0))
    (local $__seek i32)
    (local $__state i32)
    (local $__case_0_0 (ref null $result))
    (local $t__2 (ref null $task))
    (local $__aw1 (ref null $task))
    (local $m__3 (ref null $str))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame0)
    local.set $__frame
    local.get $__frame
    struct.get $frame0 $s0
    local.set $f
    local.get $__frame
    struct.get $frame0 $s1
    local.set $__mem0
    local.get $__frame
    struct.get $frame0 $s2
    local.set $t
    local.get $__frame
    struct.get $frame0 $s3
    local.set $m
    local.get $__frame
    struct.get $frame0 $s4
    local.set $__case_0_0
    local.get $__frame
    struct.get $frame0 $s5
    local.set $t__2
    local.get $__frame
    struct.get $frame0 $s6
    local.set $__aw1
    local.get $__frame
    struct.get $frame0 $s7
    local.set $m__3
    local.get $__frame
    struct.get $frame0 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $f
    call $caught
    local.set $__case_0_0
      )
    )
    local.get $__case_0_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0_0
    struct.get $result $payload
    ref.cast (ref null $task)
    local.set $t__2
    i32.const 0
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
    local.get $t__2
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $f
    struct.set $frame0 $s0
    local.get $__frame
    local.get $__mem0
    struct.set $frame0 $s1
    local.get $__frame
    local.get $t
    struct.set $frame0 $s2
    local.get $__frame
    local.get $m
    struct.set $frame0 $s3
    local.get $__frame
    local.get $__case_0_0
    struct.set $frame0 $s4
    local.get $__frame
    local.get $t__2
    struct.set $frame0 $s5
    local.get $__frame
    local.get $__aw1
    struct.set $frame0 $s6
    local.get $__frame
    local.get $m__3
    struct.set $frame0 $s7
    local.get $__frame
    i32.const 1
    struct.set $frame0 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $result
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    struct.new $result
    return
      )
      (else
    local.get $__case_0_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $m__3
    i32.const 1
    local.get $m__3
    global.get $__s0
    call $__new_23
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  (func $attemptTaskOnWasm__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $attemptTaskOnWasm__body
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
  (func $__eq_Failure (param $a (ref null $rec_Failure)) (param $b (ref null $rec_Failure)) (result i32)
    local.get $a
    struct.get $rec_Failure $f0
    local.get $b
    struct.get $rec_Failure $f0
    call $__str_eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    struct.get $rec_Failure $f1
    local.get $b
    struct.get $rec_Failure $f1
    call $__str_eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
  )
  (func $__pr1 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr0 (param $v (ref null $rec_Failure))
    global.get $__s1
    call $__print_str_raw
    global.get $__s2
    call $__print_str_raw
    global.get $__s3
    call $__print_str_raw
    local.get $v
    struct.get $rec_Failure $f0
    call $__pr1
    global.get $__s4
    call $__print_str_raw
    local.get $v
    struct.get $rec_Failure $f1
    call $__pr1
    global.get $__s5
    call $__print_str_raw
  )
  (func $__tip4 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Failure)
    call $__pr0
  )
  (func $__tie4 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Failure)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Failure)
    local.get $b
    ref.cast (ref null $rec_Failure)
    call $__eq_Failure
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
    call $attemptTaskOnWasm__step
    return
      )
    )
    unreachable
  )
  (func $__task_host_poll (result i32)
    i32.const 0
  )
  (func $__wasi_attempt (param $f (ref null $closure)) (result (ref null $result))
    (local $v anyref) (local $m (ref null $str))
    (block $caught (result anyref)
      (try_table (result anyref) (catch $__bp_panic $caught)
        local.get $f
        local.get $f
        struct.get $closure $fn
        ref.cast (ref null $sig_0)
        call_ref $sig_0
      )
      local.set $v
      i32.const 0
      local.get $v
      struct.new $result
      return
    )
    ref.cast (ref null $exn)
    struct.get $exn $msg
    local.set $m
    i32.const 1
    local.get $m
    struct.new $result
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
  (data $__d0 "panic")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "Failure")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "(")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "message: ")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 ", kind: ")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 ")")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "std@failure.Failure")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 7
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 1
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 9
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 8
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 1
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 19
    array.new_data $str $__d6
    global.set $__s6
    call $__init_types
  )
  (func $__new_23 (param $f0 (ref null $str)) (param $f1 (ref null $str)) (result (ref null $rec_Failure))
    global.get $__ti_23
    local.get $f0
    local.get $f1
    struct.new $rec_Failure
  )
  (global $__ti_23 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tip4 $__tie4)
  (func $__init_types
    global.get $__s6
    ref.func $__tip4
    ref.func $__tie4
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_23
    global.get $__ti_23
    call $__ti_register
  )
  (@custom "botopink.needs" "exceptions\0agc\0a")
)
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/testing/asserts.bp
```botopink
//// std/testing/asserts — the canonical assertion API every test is written against
//// (1.0.10-beta front 01-std, `asserts-api.md`; decisions 74 and 67).
////
//// Reference:
////   Node.js  — https://nodejs.org/api/assert.html
////   Erlang   — (no equivalent module; pattern matching does the same job)
////
//// Every assertion answers `-> Result<void, string>` (the return is the effect):
//// success is `Ok`, failure is `Error(message)`. The caller writes
//// `try asserts.equals(a, b);` and a failure propagates to the enclosing
//// `test` body, which ends as `FAIL <name>  (<message>)  at <file>:<line>`
//// (the test body is a fallible context — `conformance/docs.md` § Tests). A `-test`
//// helper that is itself `-> Result<void, string>` composes an assertion
//// with `try` and nothing else; nothing here panics.
////
//// Five rules (`asserts-api.md` § The shape of every function):
////   1. `-> Result<void, string>`; the `ok` position is `return;`.
////   2. `actual` first, `expected` second — everywhere (`matches(actual, pattern)`).
////   3. One literal message per function, `asserts.<fn>: <what>`; no value
////      rendering (a generic `T` has no `toString`). The call site's `@src()`
////      and the runner's `at <file>:<line>` say where; the message says which.
////   4. Pure botopink on the path that runs everywhere: `==`, `!=`, `== false`,
////      `.length`, `.contains()`, `.startsWith()`, `.endsWith()`, `.indexOf()`,
////      `.isOk()`, `.isError()`, `!= null` — host-backed primitives only. A
////      primitive `default fn` (`Bool.negate`, `Array.contains`) is not lowered
////      when a std module is compiled as a consumer's embedded import today,
////      so none is used here (measured 2026-09-20; `libs/std/AGENTS.md`).
////   5. No `pub declare fn` in the file, so `import {asserts} from "std"`
////      passes STD-001 on every target. The four functions that need a host
////      — `matches`, `deepEquals`, `throws`, `throwsWith` — sit on the two
////      PRIVATE cells `regexMatches` and `canonical`, which carry Node and
////      Erlang templates, and on `failure.attempt` (decisions 431, 493): beam
////      compiles the Erlang ones at build time, and wasm, which has no host,
////      refuses the module where those four call their cells — and so every
////      import of it (decision 146).
////
//// The module is named `asserts` (plural) because the unqualified `assert`
//// is a reserved keyword statement; `import {asserts} from "std";` then
//// `asserts.isTrue(x)` keeps the qualified-call style.
////
//// `==` is the language's rule: structural for primitives, reference for
//// arrays and records on commonJS (`===`) and structural on erlang (`=:=`).
//// `equals` on two arrays therefore passes on erlang and fails on commonJS;
//// `deepEquals` is the cross-target answer (both sides are rendered by the
//// same host, so key order agrees).

import {failure, failure.Failure, failure.panic, compiler};

// ── boolean ──────────────────────────────────────────────────────────────────

// Fails when `condition` is false.
pub fn isTrue(condition: bool) -> Result<void, string> {
    if (condition == false) throw "asserts.isTrue: condition was false";
    return;
}

// Fails when `condition` is true — the dual of `isTrue`, for "this must not
// happen" branches you would otherwise spell as `isTrue(!cond)`.
pub fn isFalse(condition: bool) -> Result<void, string> {
    if (condition) throw "asserts.isFalse: condition was true";
    return;
}

// ── equality ─────────────────────────────────────────────────────────────────

// Fails when `actual != expected` (the language's `==`; see the docblock).
pub fn equals<T>(actual: T, expected: T) -> Result<void, string> {
    if (actual != expected) throw "asserts.equals: values differ";
    return;
}

// Fails when `actual == expected`.
pub fn notEquals<T>(actual: T, expected: T) -> Result<void, string> {
    if (actual == expected) throw "asserts.notEquals: values match";
    return;
}

// Fails when `|actual - expected| > tolerance`. Pick a tolerance that fits the
// operation's numerical budget, not `0.0`. The absolute value is an inline
// `if` rather than `math.abs` — a std module does not import another.
pub fn approxEquals(
    actual: f64,
    expected: f64,
    tolerance: f64,
) -> Result<void, string> {
    val diff = actual - expected;
    val absDiff = if (diff >= 0.0) diff else 0.0 - diff;
    if (absDiff > tolerance)
        throw "asserts.approxEquals: values differ by more than tolerance";
    return;
}

// Private: a value rendered canonically by the host — `JSON.stringify` on
// Node, `io_lib:format("~0tp")` on Erlang. Lifted from the old onze's
// `onzeKey`, where it keyed the call log for the same reason: two values that
// render the same are structurally equal on that host.
#[compiler.external(
    .JavaScript("""JSON.stringify($0)"""),
    .Erlang("""iolist_to_binary(io_lib:format("~0tp", [$0]))"""),
)]
declare fn canonical<T>(v: T) -> string;

// Fails when the two values differ structurally — arrays and records by
// content, on every target. Needs Node or Erlang at run time (`canonical`).
pub fn deepEquals<T>(actual: T, expected: T) -> Result<void, string> {
    if (canonical(actual) != canonical(expected))
        throw "asserts.deepEquals: values differ structurally";
    return;
}

// ── nil ──────────────────────────────────────────────────────────────────────

// Fails when the optional holds a value. `!= null`, never truthiness — on
// commonJS `if (x)` is false for `0`.
pub fn isNil<T>(value: ?T) -> Result<void, string> {
    if (value != null) throw "asserts.isNil: value was present";
    return;
}

// Fails when the optional is absent.
pub fn isNotNil<T>(value: ?T) -> Result<void, string> {
    if (value == null) throw "asserts.isNotNil: value was null";
    return;
}

// ── result ───────────────────────────────────────────────────────────────────

// Fails when `result` is `Error`. Read the payload at the call site with the
// builtin methods (`try equals(r.unwrapOr(0), 42);`).
pub fn isOk<T, E>(result: Result<T, E>) -> Result<void, string> {
    if (result.isError()) throw "asserts.isOk: result was Error";
    return;
}

// Fails when `result` is `Ok`. To assert that a `Result`-returning body
// fails, this is the tool — `throws` is for a `panic` or a host throw.
pub fn isError<T, E>(result: Result<T, E>) -> Result<void, string> {
    if (result.isOk()) throw "asserts.isError: result was Ok";
    return;
}

// ── string ───────────────────────────────────────────────────────────────────

// Fails when `needle` is not a substring of `actual`.
pub fn contains(actual: string, needle: string) -> Result<void, string> {
    if (actual.contains(needle) == false)
        throw "asserts.contains: needle not in actual";
    return;
}

// Fails when `needle` is a substring of `actual`.
pub fn notContains(actual: string, needle: string) -> Result<void, string> {
    if (actual.contains(needle))
        throw "asserts.notContains: needle found in actual";
    return;
}

// Fails when `actual` does not start with `prefix`.
pub fn startsWith(actual: string, prefix: string) -> Result<void, string> {
    if (actual.startsWith(prefix) == false)
        throw "asserts.startsWith: prefix does not match";
    return;
}

// Fails when `actual` does not end with `suffix`.
pub fn endsWith(actual: string, suffix: string) -> Result<void, string> {
    if (actual.endsWith(suffix) == false)
        throw "asserts.endsWith: suffix does not match";
    return;
}

// Private `regex.matches` twin, actual-first: inlined here rather than via a
// cross-module call so this file stays self-contained (std-internal modules
// do not import each other). PCRE-ish on both hosts.
#[compiler.external(.JavaScript("""(new RegExp($1).test($0))"""), .Erlang("""(re:run($0, $1) =/= nomatch)"""))]
declare fn regexMatches(actual: string, pattern: string) -> bool;

// Fails when the regular expression `pattern` (the host's native flavour)
// does not match `actual`. Use `contains` for a literal needle. Needs Node or
// Erlang at run time (`regexMatches`).
pub fn matches(actual: string, pattern: string) -> Result<void, string> {
    if (regexMatches(actual, pattern) == false)
        throw "asserts.matches: pattern did not match";
    return;
}

// ── collection ───────────────────────────────────────────────────────────────

// Fails when the array has elements.
pub fn isEmpty<T>(actual: T[]) -> Result<void, string> {
    if (actual.length != 0) throw "asserts.isEmpty: array was not empty";
    return;
}

// Fails when the array is empty.
pub fn isNotEmpty<T>(actual: T[]) -> Result<void, string> {
    if (actual.length == 0) throw "asserts.isNotEmpty: array was empty";
    return;
}

// Fails when the array's length is not `expected`.
pub fn lengthIs<T>(actual: T[], expected: i32) -> Result<void, string> {
    if (actual.length != expected) throw "asserts.lengthIs: length differs";
    return;
}

// Fails when no element `==` `element` (`Array.indexOf` — reference equality
// for records on commonJS; extract with `.at(i)` and `deepEquals` instead).
pub fn includes<T>(actual: T[], element: T) -> Result<void, string> {
    if (actual.indexOf(element) < 0)
        throw "asserts.includes: element not found";
    return;
}

// Fails when some element `==` `element`.
pub fn notIncludes<T>(actual: T[], element: T) -> Result<void, string> {
    if (actual.indexOf(element) >= 0)
        throw "asserts.notIncludes: element found";
    return;
}

// ── numeric ──────────────────────────────────────────────────────────────────

// Fails when `actual` is outside `[low, high]` (both ends included). `i32`
// only: a generic `T` cannot be compared with `<`, and `f64` callers have
// `approxEquals`. `positive`/`negative` are `greaterThan(x, 0)`/`lessThan(x, 0)`.
pub fn between(actual: i32, low: i32, high: i32) -> Result<void, string> {
    // Bound first: an `if (a < b || c > d)` condition does not parse today
    // (the condition grammar stops at `||`; a `val` initialiser takes the
    // whole expression) — a parser gap, recorded by the front that owns it.
    val outside = actual < low || actual > high;
    if (outside) throw "asserts.between: value out of range";
    return;
}

// Fails when `actual <= bound`.
pub fn greaterThan(actual: i32, bound: i32) -> Result<void, string> {
    if (actual <= bound) throw "asserts.greaterThan: value not greater";
    return;
}

// Fails when `actual >= bound`.
pub fn lessThan(actual: i32, bound: i32) -> Result<void, string> {
    if (actual >= bound) throw "asserts.lessThan: value not less";
    return;
}

// ── exceptions ───────────────────────────────────────────────────────────────

// Private: the message `failure.attempt` caught, or `""` for a body that
// completed.
fn caughtMessage<T>(r: Result<T, Failure>) -> string {
    val text = case r {
        Ok(v) -> "";
        Error(f) -> f.message;
    };
    return text;
}

// Fails when `body` completes normally — for a `panic` or a host raise from
// code whose return carries no `Result` (a failing `Result` is `isError`).
// Generic over the body's own type and run under `failure.attempt` (decisions
// 431, 493), so it needs Node or Erlang at run time.
pub fn throws<T>(body: fn() -> T) -> Result<void, string> {
    val r = failure.attempt(body);
    if (r.isOk()) throw "asserts.throws: body did not raise";
    return;
}

// Fails when `body` completes normally, or when the caught message does not
// contain `needle`. The message is `failure.attempt`'s `Failure.message`: a
// `panic(text)` / `@todo(text)` is its own `text` on every target, byte for
// byte — a needle with a `"`, a `\` or a non-ASCII character matches alike;
// any other host raise is its JS `message` (else `String(e)`) on Node and
// the reason by `~tp` on Erlang (`badarg`).
pub fn throwsWith<T>(body: fn() -> T, needle: string) -> Result<void, string> {
    val r = failure.attempt(body);
    if (r.isOk()) throw "asserts.throwsWith: body did not raise";
    if (caughtMessage(r).contains(needle) == false)
        throw "asserts.throwsWith: message does not contain needle";
    return;
}

// ── utility ──────────────────────────────────────────────────────────────────

// Always `Error("asserts.fail: <message>")` — the one function whose message
// carries caller text; the escape for a branch the test asserts is unreachable.
pub fn fail(message: string) -> Result<void, string> {
    throw "asserts.fail: " + message;
}

// The `Error` payload of an assertion's result, or `""` for `Ok`. Not
// a `-> Result` fn: it is how a test reads a failure message to compare or
// snapshot it (`test-snap.md`), matching over the builtin `Result` enum in a
// function the manual-construction rule does not apply to.
pub fn errorText(r: Result<void, string>) -> string {
    val text = case r {
        Ok(v) -> "";
        Error(e) -> e;
    };
    return text;
}

// ── tests ────────────────────────────────────────────────────────────────────
// One test per function per path, written with `try`; a fail path asserts
// `isError` over the assertion's own result and pins the literal message
// through `errorText` (no host cell, no panic).

fn parsePort(s: string) -> Result<i32, string> {
    if (s == "") throw "empty input";
    return 8080;
}

fn explode() -> i32 {
    panic("boom: the widget is on fire");
    return 0;
}

// boolean

test "asserts: isTrue passes on true" {
    try isTrue(true);
    try isTrue(1 + 1 == 2);
}

test "asserts: isTrue fails on false" {
    val r = isTrue(1 == 2);
    try isError(r);
    try equals(errorText(r), "asserts.isTrue: condition was false");
}

test "asserts: isFalse passes on false" {
    try isFalse(false);
    try isFalse("abc".startsWith("z"));
}

test "asserts: isFalse fails on true" {
    val r = isFalse(true);
    try isError(r);
    try equals(errorText(r), "asserts.isFalse: condition was true");
}

// equality

test "asserts: equals passes on equal primitives" {
    try equals(42, 42);
    try equals("hello", "hello");
    try equals(true, true);
}

test "asserts: equals fails on different values" {
    val r = equals("ana", "bob");
    try isError(r);
    try equals(errorText(r), "asserts.equals: values differ");
}

test "asserts: notEquals passes when the values differ" {
    try notEquals(1, 2);
    try notEquals("a", "b");
}

test "asserts: notEquals fails on equal values" {
    val r = notEquals(7, 7);
    try isError(r);
    try equals(errorText(r), "asserts.notEquals: values match");
}

test "asserts: approxEquals accepts a value inside the tolerance" {
    try approxEquals(3.14159, 3.14, 0.01);
    try approxEquals(0.0, 0.0, 0.0);
}

test "asserts: approxEquals fails outside the tolerance" {
    val r = approxEquals(1.0, 2.0, 0.5);
    try isError(r);
    try equals(
        errorText(r),
        "asserts.approxEquals: values differ by more than tolerance",
    );
}

test "asserts: deepEquals compares arrays by content on every target" {
    val left = [1, 2, 3];
    val right = [1, 2, 3];
    try deepEquals(left, right);
}

test "asserts: deepEquals fails on structurally different values" {
    val r = deepEquals([1, 2], [2, 1]);
    try isError(r);
    try equals(errorText(r), "asserts.deepEquals: values differ structurally");
}

// nil

test "asserts: isNil and isNotNil read an optional" {
    val xs = [10, 20, 30];
    try isNotNil(xs.at(1));
    try isNil(xs.at(9));
}

test "asserts: isNil fails on a present value" {
    val xs = [10];
    val r = isNil(xs.at(0));
    try isError(r);
    try equals(errorText(r), "asserts.isNil: value was present");
}

test "asserts: isNotNil fails on null" {
    val xs = [10];
    val r = isNotNil(xs.at(5));
    try isError(r);
    try equals(errorText(r), "asserts.isNotNil: value was null");
}

// result

test "asserts: isOk and isError read a Result" {
    try isOk(parsePort("8080"));
    try isError(parsePort(""));
}

test "asserts: the Ok payload is read with unwrapOr" {
    val port = parsePort("8080").unwrapOr(0);
    try equals(port, 8080);
}

test "asserts: isOk fails on an Error" {
    val r = isOk(parsePort(""));
    try isError(r);
    try equals(errorText(r), "asserts.isOk: result was Error");
}

test "asserts: isError fails on an Ok" {
    val r = isError(parsePort("1"));
    try isError(r);
    try equals(errorText(r), "asserts.isError: result was Ok");
}

// string

test "asserts: contains, startsWith and endsWith over a string" {
    try contains("hello world", "o w");
    try notContains("hello world", "xyz");
    try startsWith("/api/users", "/api");
    try endsWith("page.bp", ".bp");
}

test "asserts: contains fails on a missing needle" {
    val r = contains("hello", "xyz");
    try isError(r);
    try equals(errorText(r), "asserts.contains: needle not in actual");
}

test "asserts: notContains fails on a present needle" {
    val r = notContains("hello", "ell");
    try isError(r);
    try equals(errorText(r), "asserts.notContains: needle found in actual");
}

test "asserts: startsWith fails on another prefix" {
    val r = startsWith("/api", "/v2");
    try isError(r);
    try equals(errorText(r), "asserts.startsWith: prefix does not match");
}

test "asserts: endsWith fails on another suffix" {
    val r = endsWith("page.bp", ".js");
    try isError(r);
    try equals(errorText(r), "asserts.endsWith: suffix does not match");
}

test "asserts: matches takes the actual first and the pattern second" {
    try matches("555-1234", "^[0-9]{3}-[0-9]{4}$");
    try matches("abc123def", "[0-9]+");
}

test "asserts: matches fails when the pattern does not match" {
    val r = matches("abc", "^[0-9]+$");
    try isError(r);
    try equals(errorText(r), "asserts.matches: pattern did not match");
}

// collection

test "asserts: isEmpty, isNotEmpty and lengthIs over an array" {
    val none: i32[] = [];
    try isEmpty(none);
    try isNotEmpty([1]);
    try lengthIs([1, 2, 3], 3);
    try lengthIs(none, 0);
}

test "asserts: isEmpty fails on elements" {
    val r = isEmpty([1]);
    try isError(r);
    try equals(errorText(r), "asserts.isEmpty: array was not empty");
}

test "asserts: isNotEmpty fails on an empty array" {
    val none: i32[] = [];
    val r = isNotEmpty(none);
    try isError(r);
    try equals(errorText(r), "asserts.isNotEmpty: array was empty");
}

test "asserts: lengthIs fails on another length" {
    val r = lengthIs([1, 2], 3);
    try isError(r);
    try equals(errorText(r), "asserts.lengthIs: length differs");
}

test "asserts: includes and notIncludes over an array" {
    try includes([1, 2, 3], 2);
    try notIncludes(["a", "b"], "z");
}

test "asserts: includes fails on a missing element" {
    val r = includes([1, 2, 3], 4);
    try isError(r);
    try equals(errorText(r), "asserts.includes: element not found");
}

test "asserts: notIncludes fails on a present element" {
    val r = notIncludes([1, 2, 3], 2);
    try isError(r);
    try equals(errorText(r), "asserts.notIncludes: element found");
}

// numeric

test "asserts: between is inclusive on both ends" {
    try between(5, 1, 10);
    try between(1, 1, 10);
    try between(10, 1, 10);
}

test "asserts: between fails outside the range" {
    val r = between(0, 1, 10);
    try isError(r);
    try equals(errorText(r), "asserts.between: value out of range");
}

test "asserts: greaterThan and lessThan are strict" {
    try greaterThan(3, 2);
    try lessThan(2, 3);
}

test "asserts: greaterThan fails on an equal value" {
    val r = greaterThan(2, 2);
    try isError(r);
    try equals(errorText(r), "asserts.greaterThan: value not greater");
}

test "asserts: lessThan fails on a greater value" {
    val r = lessThan(3, 2);
    try isError(r);
    try equals(errorText(r), "asserts.lessThan: value not less");
}

// exceptions

test "asserts: throws catches a panicking body" {
    try throws({ ->
        explode();
        0
    });
}

test "asserts: throws fails when the body completes" {
    val r = throws({ ->
        0
    });
    try isError(r);
    try equals(errorText(r), "asserts.throws: body did not raise");
}

test "asserts: throwsWith checks the message" {
    try throwsWith({ ->
        explode();
        0
    }, "on fire");
}

fn quoteRaiser() -> i32 {
    panic("withHeader(\"Set-Cookie\", v) \\ twice");
    return 0;
}

test "asserts: throwsWith matches a needle with a quote or a backslash on every target" {
    try throwsWith({ ->
        quoteRaiser();
        0
    }, "withHeader(\"Set-Cookie\"");
    try throwsWith({ ->
        quoteRaiser();
        0
    }, "v) \\ twice");
    // The raised text itself, not a rendering of it: the escaped spelling
    // `\"` is not in the message.
    val escaped = throwsWith({ ->
        quoteRaiser();
        0
    }, "withHeader(\\\"");
    try equals(
        errorText(escaped),
        "asserts.throwsWith: message does not contain needle",
    );
}

test "asserts: throwsWith fails when the body completes" {
    val r = throwsWith({ ->
        0
    }, "anything");
    try isError(r);
    try equals(errorText(r), "asserts.throwsWith: body did not raise");
}

test "asserts: throwsWith fails on a message without the needle" {
    val r = throwsWith({ ->
        explode();
        0
    }, "not in the message");
    try isError(r);
    try equals(
        errorText(r),
        "asserts.throwsWith: message does not contain needle",
    );
}

// utility

test "asserts: fail always answers Error and carries the caller's text" {
    val r = fail("this branch is unreachable");
    try isError(r);
    try equals(errorText(r), "asserts.fail: this branch is unreachable");
}

test "asserts: errorText answers the empty string for Ok" {
    try equals(errorText(isTrue(true)), "");
}

```

----- WASM TEXT -- std/testing/asserts.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (array (mut i32)))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
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
    (type $rec_Failure (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $str))))))
    (type $brand_rec_Failure (struct (field f32) (field f64) (field i64) (field i64) (field i32) (field f32) (field f64) (field i32) (field i64) (field i64) (field f64) (field i32) (field f32) (field f64) (field f32) (field f32) (field i64) (field i32) (field f32) (field f64) (field f32) (field f32) (field i64) (field f64) (field i32) (field i32) (field i32) (field f32) (field f32) (field f64) (field f64) (field i64)))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__eq_decl" (func $__eq_decl (param anyref anyref) (result i32)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@string" "std:text.contains" (func $__std_text_contains (param i32 i32) (result i32)))
  (import "std@string" "std:text.startsWith" (func $__std_text_startsWith (param i32 i32) (result i32)))
  (import "std@string" "std:text.endsWith" (func $__std_text_endsWith (param i32 i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (tag $__bp_panic (param anyref))
  ;; declare fn panic — no wasm implementation (host-backed)
  ;; attempt — .Wasm(body: attemptOnWasm)
  (func $attempt (param $f (ref null $closure)) (result (ref null $result))
    local.get $f
    call $attemptOnWasm
  )
  ;; caught — .Wasm(wasi: .Attempt)
  (func $caught (param $f (ref null $closure)) (result (ref null $result))
    local.get $f
    call $__wasi_attempt
  )
  (func $attemptOnWasm (param $f (ref null $closure)) (result (ref null $result))
    (local $__mem0 i32)
    (local $v i32)
    (local $m i32)
    (local $__case_0 (ref null $result))
    (local $v__0 anyref)
    (local $m__1 (ref null $str))
    local.get $f
    call $caught
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $v__0
    i32.const 0
    local.get $v__0
    struct.new $result
    return
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $result))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $m__1
    i32.const 1
    local.get $m__1
    global.get $__s0
    call $__new_23
    struct.new $result
    return
      )
      (else
    ref.null $result
      )
    )
      )
    )
  )
  ;; std/testing/asserts — the canonical assertion API every test is written against
  ;; (1.0.10-beta front 01-std, `asserts-api.md`; decisions 74 and 67).
  ;; 
  ;; Reference:
  ;;   Node.js  — https://nodejs.org/api/assert.html
  ;;   Erlang   — (no equivalent module; pattern matching does the same job)
  ;; 
  ;; Every assertion answers `-> Result<void, string>` (the return is the effect):
  ;; success is `Ok`, failure is `Error(message)`. The caller writes
  ;; `try asserts.equals(a, b);` and a failure propagates to the enclosing
  ;; `test` body, which ends as `FAIL <name>  (<message>)  at <file>:<line>`
  ;; (the test body is a fallible context — `conformance/docs.md` § Tests). A `-test`
  ;; helper that is itself `-> Result<void, string>` composes an assertion
  ;; with `try` and nothing else; nothing here panics.
  ;; 
  ;; Five rules (`asserts-api.md` § The shape of every function):
  ;;   1. `-> Result<void, string>`; the `ok` position is `return;`.
  ;;   2. `actual` first, `expected` second — everywhere (`matches(actual, pattern)`).
  ;;   3. One literal message per function, `asserts.<fn>: <what>`; no value
  ;;      rendering (a generic `T` has no `toString`). The call site's `@src()`
  ;;      and the runner's `at <file>:<line>` say where; the message says which.
  ;;   4. Pure botopink on the path that runs everywhere: `==`, `!=`, `== false`,
  ;;      `.length`, `.contains()`, `.startsWith()`, `.endsWith()`, `.indexOf()`,
  ;;      `.isOk()`, `.isError()`, `!= null` — host-backed primitives only. A
  ;;      primitive `default fn` (`Bool.negate`, `Array.contains`) is not lowered
  ;;      when a std module is compiled as a consumer's embedded import today,
  ;;      so none is used here (measured 2026-09-20; `libs/std/AGENTS.md`).
  ;;   5. No `pub declare fn` in the file, so `import {asserts} from "std"`
  ;;      passes STD-001 on every target. The four functions that need a host
  ;;      — `matches`, `deepEquals`, `throws`, `throwsWith` — sit on the two
  ;;      PRIVATE cells `regexMatches` and `canonical`, which carry Node and
  ;;      Erlang templates, and on `failure.attempt` (decisions 431, 493): beam
  ;;      compiles the Erlang ones at build time, and wasm, which has no host,
  ;;      refuses the module where those four call their cells — and so every
  ;;      import of it (decision 146).
  ;; 
  ;; The module is named `asserts` (plural) because the unqualified `assert`
  ;; is a reserved keyword statement; `import {asserts} from "std";` then
  ;; `asserts.isTrue(x)` keeps the qualified-call style.
  ;; 
  ;; `==` is the language's rule: structural for primitives, reference for
  ;; arrays and records on commonJS (`===`) and structural on erlang (`=:=`).
  ;; `equals` on two arrays therefore passes on erlang and fails on commonJS;
  ;; `deepEquals` is the cross-target answer (both sides are rendered by the
  ;; same host, so key order agrees).
  ;; ── boolean ──────────────────────────────────────────────────────────────────
  ;; Fails when `condition` is false.
  (func $isTrue (export "isTrue") (param $condition i32) (result (ref null $result))
    local.get $condition
    i32.const 0
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s1
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when `condition` is true — the dual of `isTrue`, for "this must not
  ;; happen" branches you would otherwise spell as `isTrue(!cond)`.
  (func $isFalse (export "isFalse") (param $condition i32) (result (ref null $result))
    local.get $condition
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s2
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; ── equality ─────────────────────────────────────────────────────────────────
  ;; Fails when `actual != expected` (the language's `==`; see the docblock).
  (func $equals (export "equals") (param $actual anyref) (param $expected anyref) (result (ref null $result))
    local.get $actual
    local.get $expected
    call $__unk_eq
    i32.eqz
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s3
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when `actual == expected`.
  (func $notEquals (export "notEquals") (param $actual anyref) (param $expected anyref) (result (ref null $result))
    local.get $actual
    local.get $expected
    call $__unk_eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s4
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when `|actual - expected| > tolerance`. Pick a tolerance that fits the
  ;; operation's numerical budget, not `0.0`. The absolute value is an inline
  ;; `if` rather than `math.abs` — a std module does not import another.
  (func $approxEquals (export "approxEquals") (param $actual f64) (param $expected f64) (param $tolerance f64) (result (ref null $result))
    (local $diff f64)
    (local $absDiff f64)
    local.get $actual
    local.get $expected
    f64.sub
    local.set $diff
    local.get $diff
    f64.const 0.0
    f64.ge
    (if (result f64)
      (then
    local.get $diff
      )
      (else
    f64.const 0.0
    local.get $diff
    f64.sub
      )
    )
    local.set $absDiff
    local.get $absDiff
    local.get $tolerance
    f64.gt
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s5
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Private: a value rendered canonically by the host — `JSON.stringify` on
  ;; Node, `io_lib:format("~0tp")` on Erlang. Lifted from the old onze's
  ;; `onzeKey`, where it keyed the call log for the same reason: two values that
  ;; render the same are structurally equal on that host.
  ;; declare fn canonical — no wasm implementation (host-backed)
  ;; Fails when the two values differ structurally — arrays and records by
  ;; content, on every target. Needs Node or Erlang at run time (`canonical`).
  ;; ── nil ──────────────────────────────────────────────────────────────────────
  ;; Fails when the optional holds a value. `!= null`, never truthiness — on
  ;; commonJS `if (x)` is false for `0`.
  (func $isNil (export "isNil") (param $value anyref) (result (ref null $result))
    local.get $value
    ref.is_null
    i32.eqz
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s6
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when the optional is absent.
  (func $isNotNil (export "isNotNil") (param $value anyref) (result (ref null $result))
    local.get $value
    ref.is_null
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s7
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; ── result ───────────────────────────────────────────────────────────────────
  ;; Fails when `result` is `Error`. Read the payload at the call site with the
  ;; builtin methods (`try equals(r.unwrapOr(0), 42);`).
  (func $isOk (export "isOk") (param $result (ref null $result)) (result (ref null $result))
    local.get $result
    struct.get $result $tag
    i32.const 0
    i32.ne
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s8
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when `result` is `Ok`. To assert that a `Result`-returning body
  ;; fails, this is the tool — `throws` is for a `panic` or a host throw.
  (func $isError (export "isError") (param $result (ref null $result)) (result (ref null $result))
    local.get $result
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s9
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; ── string ───────────────────────────────────────────────────────────────────
  ;; Fails when `needle` is not a substring of `actual`.
  (func $contains (export "contains") (param $actual (ref null $str)) (param $needle (ref null $str)) (result (ref null $result))
    (local $__gc0 (ref null $str))
    (local $__gc1 (ref null $str))
    (local $__gc2 i32)
    local.get $actual
    local.get $needle
    local.set $__gc0
    local.set $__gc1
    global.get $__heap_ptr
    local.set $__gc2
    local.get $__gc1
    call $__gc_to_lin_str
    local.get $__gc0
    call $__gc_to_lin_str
    call $__std_text_contains
    local.get $__gc2
    global.set $__heap_ptr
    i32.const 0
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s10
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when `needle` is a substring of `actual`.
  (func $notContains (export "notContains") (param $actual (ref null $str)) (param $needle (ref null $str)) (result (ref null $result))
    (local $__gc3 (ref null $str))
    (local $__gc4 (ref null $str))
    (local $__gc5 i32)
    local.get $actual
    local.get $needle
    local.set $__gc3
    local.set $__gc4
    global.get $__heap_ptr
    local.set $__gc5
    local.get $__gc4
    call $__gc_to_lin_str
    local.get $__gc3
    call $__gc_to_lin_str
    call $__std_text_contains
    local.get $__gc5
    global.set $__heap_ptr
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s11
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when `actual` does not start with `prefix`.
  (func $startsWith (export "startsWith") (param $actual (ref null $str)) (param $prefix (ref null $str)) (result (ref null $result))
    (local $__gc6 (ref null $str))
    (local $__gc7 (ref null $str))
    (local $__gc8 i32)
    local.get $actual
    local.get $prefix
    local.set $__gc6
    local.set $__gc7
    global.get $__heap_ptr
    local.set $__gc8
    local.get $__gc7
    call $__gc_to_lin_str
    local.get $__gc6
    call $__gc_to_lin_str
    call $__std_text_startsWith
    local.get $__gc8
    global.set $__heap_ptr
    i32.const 0
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s12
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when `actual` does not end with `suffix`.
  (func $endsWith (export "endsWith") (param $actual (ref null $str)) (param $suffix (ref null $str)) (result (ref null $result))
    (local $__gc9 (ref null $str))
    (local $__gc10 (ref null $str))
    (local $__gc11 i32)
    local.get $actual
    local.get $suffix
    local.set $__gc9
    local.set $__gc10
    global.get $__heap_ptr
    local.set $__gc11
    local.get $__gc10
    call $__gc_to_lin_str
    local.get $__gc9
    call $__gc_to_lin_str
    call $__std_text_endsWith
    local.get $__gc11
    global.set $__heap_ptr
    i32.const 0
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s13
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Private `regex.matches` twin, actual-first: inlined here rather than via a
  ;; cross-module call so this file stays self-contained (std-internal modules
  ;; do not import each other). PCRE-ish on both hosts.
  ;; declare fn regexMatches — no wasm implementation (host-backed)
  ;; Fails when the regular expression `pattern` (the host's native flavour)
  ;; does not match `actual`. Use `contains` for a literal needle. Needs Node or
  ;; Erlang at run time (`regexMatches`).
  ;; ── collection ───────────────────────────────────────────────────────────────
  ;; Fails when the array has elements.
  (func $isEmpty (export "isEmpty") (param $actual (ref null $arr_any)) (result (ref null $result))
    local.get $actual
    array.len
    i32.const 0
    i32.ne
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s14
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when the array is empty.
  (func $isNotEmpty (export "isNotEmpty") (param $actual (ref null $arr_any)) (result (ref null $result))
    local.get $actual
    array.len
    i32.const 0
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s15
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when the array's length is not `expected`.
  (func $lengthIs (export "lengthIs") (param $actual (ref null $arr_any)) (param $expected i32) (result (ref null $result))
    local.get $actual
    array.len
    local.get $expected
    i32.ne
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s16
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when no element `==` `element` (`Array.indexOf` — reference equality
  ;; for records on commonJS; extract with `.at(i)` and `deepEquals` instead).
  (func $includes (export "includes") (param $actual (ref null $arr_any)) (param $element anyref) (result (ref null $result))
    local.get $actual
    local.get $element
    call $__arr_indexOfEq_any
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s17
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when some element `==` `element`.
  (func $notIncludes (export "notIncludes") (param $actual (ref null $arr_any)) (param $element anyref) (result (ref null $result))
    local.get $actual
    local.get $element
    call $__arr_indexOfEq_any
    i32.const 0
    i32.ge_s
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s18
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; ── numeric ──────────────────────────────────────────────────────────────────
  ;; Fails when `actual` is outside `[low, high]` (both ends included). `i32`
  ;; only: a generic `T` cannot be compared with `<`, and `f64` callers have
  ;; `approxEquals`. `positive`/`negative` are `greaterThan(x, 0)`/`lessThan(x, 0)`.
  (func $between (export "between") (param $actual i32) (param $low i32) (param $high i32) (result (ref null $result))
    (local $outside i32)
    local.get $actual
    local.get $low
    i32.lt_s
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $actual
    local.get $high
    i32.gt_s
      )
    )
    local.set $outside
    local.get $outside
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s19
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when `actual <= bound`.
  (func $greaterThan (export "greaterThan") (param $actual i32) (param $bound i32) (result (ref null $result))
    local.get $actual
    local.get $bound
    i32.le_s
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s20
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when `actual >= bound`.
  (func $lessThan (export "lessThan") (param $actual i32) (param $bound i32) (result (ref null $result))
    local.get $actual
    local.get $bound
    i32.ge_s
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s21
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; ── exceptions ───────────────────────────────────────────────────────────────
  ;; Private: the message `failure.attempt` caught, or `""` for a body that
  ;; completed.
  (func $caughtMessage (param $r (ref null $result)) (result (ref null $str))
    (local $text (ref null $str))
    (local $v i32)
    (local $f i32)
    (local $__case_0 (ref null $result))
    (local $v__2 anyref)
    (local $f__3 (ref null $rec_Failure))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $v__2
    global.get $__s22
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $rec_Failure)
    local.set $f__3
    local.get $f__3
    struct.get $rec_Failure $f0
      )
      (else
    ref.null $str
      )
    )
      )
    )
    local.set $text
    local.get $text
    return
  )
  ;; Fails when `body` completes normally — for a `panic` or a host raise from
  ;; code whose return carries no `Result` (a failing `Result` is `isError`).
  ;; Generic over the body's own type and run under `failure.attempt` (decisions
  ;; 431, 493), so it needs Node or Erlang at run time.
  (func $throws (export "throws") (param $body (ref null $closure)) (result (ref null $result))
    (local $r (ref null $result))
    local.get $body
    call $attempt
    local.set $r
    local.get $r
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s23
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; Fails when `body` completes normally, or when the caught message does not
  ;; contain `needle`. The message is `failure.attempt`'s `Failure.message`: a
  ;; `panic(text)` / `@todo(text)` is its own `text` on every target, byte for
  ;; byte — a needle with a `"`, a `\` or a non-ASCII character matches alike;
  ;; any other host raise is its JS `message` (else `String(e)`) on Node and
  ;; the reason by `~tp` on Erlang (`badarg`).
  (func $throwsWith (export "throwsWith") (param $body (ref null $closure)) (param $needle (ref null $str)) (result (ref null $result))
    (local $r (ref null $result))
    (local $__gc12 (ref null $str))
    (local $__gc13 (ref null $str))
    (local $__gc14 i32)
    local.get $body
    call $attempt
    local.set $r
    local.get $r
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s24
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    local.get $r
    call $caughtMessage
    local.get $needle
    local.set $__gc12
    local.set $__gc13
    global.get $__heap_ptr
    local.set $__gc14
    local.get $__gc13
    call $__gc_to_lin_str
    local.get $__gc12
    call $__gc_to_lin_str
    call $__std_text_contains
    local.get $__gc14
    global.set $__heap_ptr
    i32.const 0
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s25
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  ;; ── utility ──────────────────────────────────────────────────────────────────
  ;; Always `Error("asserts.fail: <message>")` — the one function whose message
  ;; carries caller text; the escape for a branch the test asserts is unreachable.
  (func $fail (export "fail") (param $message (ref null $str)) (result (ref null $result))
    i32.const 1
    global.get $__s26
    local.get $message
    call $__str_concat
    struct.new $result
    return
  )
  ;; The `Error` payload of an assertion's result, or `""` for `Ok`. Not
  ;; a `-> Result` fn: it is how a test reads a failure message to compare or
  ;; snapshot it (`test-snap.md`), matching over the builtin `Result` enum in a
  ;; function the manual-construction rule does not apply to.
  (func $errorText (export "errorText") (param $r (ref null $result)) (result (ref null $str))
    (local $text (ref null $str))
    (local $v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $e__4 (ref null $str))
    local.get $r
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $v
    global.get $__s22
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $e__4
    local.get $e__4
      )
      (else
    ref.null $str
      )
    )
      )
    )
    local.set $text
    local.get $text
    return
  )
  ;; ── tests ────────────────────────────────────────────────────────────────────
  ;; One test per function per path, written with `try`; a fail path asserts
  ;; `isError` over the assertion's own result and pins the literal message
  ;; through `errorText` (no host cell, no panic).
  (func $parsePort (param $s (ref null $str)) (result (ref null $result))
    local.get $s
    global.get $__s22
    call $__str_eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s27
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 8080
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $explode (result i32)
    global.get $__s28
    i32.const 1
    call $__panic_raise
    unreachable
    i32.const 0
    return
  )
  ;; boolean
  ;; equality
  ;; nil
  ;; result
  ;; string
  ;; collection
  ;; numeric
  ;; exceptions
  (func $quoteRaiser (result i32)
    global.get $__s29
    i32.const 1
    call $__panic_raise
    unreachable
    i32.const 0
    return
  )
  ;; utility
  (func $__eq_Failure (param $a (ref null $rec_Failure)) (param $b (ref null $rec_Failure)) (result i32)
    local.get $a
    struct.get $rec_Failure $f0
    local.get $b
    struct.get $rec_Failure $f0
    call $__str_eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    local.get $a
    struct.get $rec_Failure $f1
    local.get $b
    struct.get $rec_Failure $f1
    call $__str_eq
    i32.eqz
    (if
      (then i32.const 0 return)
    )
    i32.const 1
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
  (func $__unk_same (param $a anyref) (param $b anyref) (result i32)
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
  (func $__arr_indexOfEq_any (param $xs (ref null $arr_any)) (param $x anyref) (result i32)
    (local $n i32)
    (local $i i32)
    local.get $xs
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $xs
    local.get $i
    array.get $arr_any
    local.get $x
    call $__unk_same
    (if
      (then
    local.get $i
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
    i32.const -1
  )
  (func $__pr1 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr0 (param $v (ref null $rec_Failure))
    global.get $__s30
    call $__print_str_raw
    global.get $__s31
    call $__print_str_raw
    global.get $__s32
    call $__print_str_raw
    local.get $v
    struct.get $rec_Failure $f0
    call $__pr1
    global.get $__s33
    call $__print_str_raw
    local.get $v
    struct.get $rec_Failure $f1
    call $__pr1
    global.get $__s34
    call $__print_str_raw
  )
  (func $__tip3 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Failure)
    call $__pr0
  )
  (func $__tie3 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Failure)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Failure)
    local.get $b
    ref.cast (ref null $rec_Failure)
    call $__eq_Failure
  )
  (func $__unk_eq_s2 (param $a (ref null $result)) (param $b (ref null $result)) (result i32)
    local.get $a
    struct.get $result $tag
    local.get $b
    struct.get $result $tag
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $result $payload
    local.get $b
    struct.get $result $payload
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
  (func $__unk_eq_s3 (param $a (ref null $rec_Failure)) (param $b (ref null $rec_Failure)) (result i32)
    local.get $a
    struct.get $rec_Failure $f0
    local.get $b
    struct.get $rec_Failure $f0
    call $__unk_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_Failure $f1
    local.get $b
    struct.get $rec_Failure $f1
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
    ref.test (ref null $result)
    (if
      (then
    local.get $b
    ref.test (ref null $result)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $result)
    local.get $b
    ref.cast (ref null $result)
    call $__unk_eq_s2
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Failure)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Failure)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Failure)
    local.get $b
    ref.cast (ref null $rec_Failure)
    call $__unk_eq_s3
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
  (func $__panic_raise (param $msg (ref null $str)) (param $print i32)
    local.get $msg
    local.get $print
    struct.new $exn
    throw $__bp_panic
  )
  (func $__wasi_attempt (param $f (ref null $closure)) (result (ref null $result))
    (local $v anyref) (local $m (ref null $str))
    (block $caught (result anyref)
      (try_table (result anyref) (catch $__bp_panic $caught)
        local.get $f
        local.get $f
        struct.get $closure $fn
        ref.cast (ref null $sig_0)
        call_ref $sig_0
      )
      local.set $v
      i32.const 0
      local.get $v
      struct.new $result
      return
    )
    ref.cast (ref null $exn)
    struct.get $exn $msg
    local.set $m
    i32.const 1
    local.get $m
    struct.new $result
  )
  (func $__gc_to_lin_str (param $s (ref null $str)) (result i32)
    (local $n i32) (local $p i32) (local $i i32)
    local.get $s
    array.len
    local.set $n
    local.get $n
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
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
        i32.store8 offset=4
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
  (func $__lin_to_gc_str (param $p i32) (result (ref null $str))
    (local $r (ref null $str)) (local $n i32) (local $i i32)
    local.get $p
    i32.load
    local.set $n
    local.get $n
    array.new_default $str
    local.set $r
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $r
        local.get $i
        local.get $p
        local.get $i
        i32.add
        i32.load8_u offset=4
        array.set $str
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
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
  (data $__d0 "panic")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "asserts.isTrue: condition was false")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "asserts.isFalse: condition was true")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "asserts.equals: values differ")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "asserts.notEquals: values match")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "asserts.approxEquals: values differ by more than tolerance")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "asserts.isNil: value was present")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "asserts.isNotNil: value was null")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "asserts.isOk: result was Error")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "asserts.isError: result was Ok")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 "asserts.contains: needle not in actual")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "asserts.notContains: needle found in actual")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "asserts.startsWith: prefix does not match")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "asserts.endsWith: suffix does not match")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (data $__d14 "asserts.isEmpty: array was not empty")
  (global $__s14 (mut (ref null $str)) (ref.null $str))
  (data $__d15 "asserts.isNotEmpty: array was empty")
  (global $__s15 (mut (ref null $str)) (ref.null $str))
  (data $__d16 "asserts.lengthIs: length differs")
  (global $__s16 (mut (ref null $str)) (ref.null $str))
  (data $__d17 "asserts.includes: element not found")
  (global $__s17 (mut (ref null $str)) (ref.null $str))
  (data $__d18 "asserts.notIncludes: element found")
  (global $__s18 (mut (ref null $str)) (ref.null $str))
  (data $__d19 "asserts.between: value out of range")
  (global $__s19 (mut (ref null $str)) (ref.null $str))
  (data $__d20 "asserts.greaterThan: value not greater")
  (global $__s20 (mut (ref null $str)) (ref.null $str))
  (data $__d21 "asserts.lessThan: value not less")
  (global $__s21 (mut (ref null $str)) (ref.null $str))
  (data $__d22 "")
  (global $__s22 (mut (ref null $str)) (ref.null $str))
  (data $__d23 "asserts.throws: body did not raise")
  (global $__s23 (mut (ref null $str)) (ref.null $str))
  (data $__d24 "asserts.throwsWith: body did not raise")
  (global $__s24 (mut (ref null $str)) (ref.null $str))
  (data $__d25 "asserts.throwsWith: message does not contain needle")
  (global $__s25 (mut (ref null $str)) (ref.null $str))
  (data $__d26 "asserts.fail: ")
  (global $__s26 (mut (ref null $str)) (ref.null $str))
  (data $__d27 "empty input")
  (global $__s27 (mut (ref null $str)) (ref.null $str))
  (data $__d28 "boom: the widget is on fire")
  (global $__s28 (mut (ref null $str)) (ref.null $str))
  (data $__d29 "withHeader(\"Set-Cookie\", v) \\ twice")
  (global $__s29 (mut (ref null $str)) (ref.null $str))
  (data $__d30 "Failure")
  (global $__s30 (mut (ref null $str)) (ref.null $str))
  (data $__d31 "(")
  (global $__s31 (mut (ref null $str)) (ref.null $str))
  (data $__d32 "message: ")
  (global $__s32 (mut (ref null $str)) (ref.null $str))
  (data $__d33 ", kind: ")
  (global $__s33 (mut (ref null $str)) (ref.null $str))
  (data $__d34 ")")
  (global $__s34 (mut (ref null $str)) (ref.null $str))
  (data $__d35 "std@failure.Failure")
  (global $__s35 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 35
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 35
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 29
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 31
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 58
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 32
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 32
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 30
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 30
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 38
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 43
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 41
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 39
    array.new_data $str $__d13
    global.set $__s13
    i32.const 0
    i32.const 36
    array.new_data $str $__d14
    global.set $__s14
    i32.const 0
    i32.const 35
    array.new_data $str $__d15
    global.set $__s15
    i32.const 0
    i32.const 32
    array.new_data $str $__d16
    global.set $__s16
    i32.const 0
    i32.const 35
    array.new_data $str $__d17
    global.set $__s17
    i32.const 0
    i32.const 34
    array.new_data $str $__d18
    global.set $__s18
    i32.const 0
    i32.const 35
    array.new_data $str $__d19
    global.set $__s19
    i32.const 0
    i32.const 38
    array.new_data $str $__d20
    global.set $__s20
    i32.const 0
    i32.const 32
    array.new_data $str $__d21
    global.set $__s21
    i32.const 0
    i32.const 0
    array.new_data $str $__d22
    global.set $__s22
    i32.const 0
    i32.const 34
    array.new_data $str $__d23
    global.set $__s23
    i32.const 0
    i32.const 38
    array.new_data $str $__d24
    global.set $__s24
    i32.const 0
    i32.const 51
    array.new_data $str $__d25
    global.set $__s25
    i32.const 0
    i32.const 14
    array.new_data $str $__d26
    global.set $__s26
    i32.const 0
    i32.const 11
    array.new_data $str $__d27
    global.set $__s27
    i32.const 0
    i32.const 27
    array.new_data $str $__d28
    global.set $__s28
    i32.const 0
    i32.const 35
    array.new_data $str $__d29
    global.set $__s29
    i32.const 0
    i32.const 7
    array.new_data $str $__d30
    global.set $__s30
    i32.const 0
    i32.const 1
    array.new_data $str $__d31
    global.set $__s31
    i32.const 0
    i32.const 9
    array.new_data $str $__d32
    global.set $__s32
    i32.const 0
    i32.const 8
    array.new_data $str $__d33
    global.set $__s33
    i32.const 0
    i32.const 1
    array.new_data $str $__d34
    global.set $__s34
    i32.const 0
    i32.const 19
    array.new_data $str $__d35
    global.set $__s35
    call $__init_types
  )
  (func $__new_23 (param $f0 (ref null $str)) (param $f1 (ref null $str)) (result (ref null $rec_Failure))
    global.get $__ti_23
    local.get $f0
    local.get $f1
    struct.new $rec_Failure
  )
  (global $__ti_23 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tip3 $__tie3)
  (func $__init_types
    global.get $__s35
    ref.func $__tip3
    ref.func $__tie3
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_23
    global.get $__ti_23
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
fn at<T>(xs: T[], x: T) -> i32 {
    return xs.indexOf(x);
}

fn lastAt<T>(xs: T[], x: T) -> i32 {
    return xs.lastIndexOf(x);
}

fn holds<T>(xs: T[], x: T) -> bool {
    return xs.contains(x);
}

pub fn main() -> void {
    print(asserts.includes([1, 2], 2).isOk());
    print(asserts.includes([1, 2], 3).isOk());
    print(at([2.5, 3.5], 3.5));
    print(at(["a", "b"], "b"));
    print(lastAt([1, 2, 1], 1));
    print(lastAt([true, false], true));
    print(holds(["x"], "y"));
}

import {io.terminal.print} from "std";
import {testing.asserts} from "std";
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (array (mut i32)))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
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
  (import "std@__rt" "__eq_decl" (func $__eq_decl (param anyref anyref) (result i32)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@string" "std:text.contains" (func $__std_text_contains (param i32 i32) (result i32)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $contains (param $actual (ref null $str)) (param $needle (ref null $str)) (result (ref null $result))
    (local $__gc0 (ref null $str))
    (local $__gc1 (ref null $str))
    (local $__gc2 i32)
    local.get $actual
    local.get $needle
    local.set $__gc0
    local.set $__gc1
    global.get $__heap_ptr
    local.set $__gc2
    local.get $__gc1
    call $__gc_to_lin_str
    local.get $__gc0
    call $__gc_to_lin_str
    call $__std_text_contains
    local.get $__gc2
    global.set $__heap_ptr
    i32.const 0
    i32.eq
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s0
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $isEmpty (param $actual (ref null $arr_any)) (result (ref null $result))
    local.get $actual
    array.len
    i32.const 0
    i32.ne
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s1
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $includes (param $actual (ref null $arr_any)) (param $element anyref) (result (ref null $result))
    local.get $actual
    local.get $element
    call $__arr_indexOfEq_any
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s2
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $at (param $xs (ref null $arr_any)) (param $x anyref) (result i32)
    local.get $xs
    local.get $x
    call $__arr_indexOfEq_any
    return
  )
  (func $lastAt (param $xs (ref null $arr_any)) (param $x anyref) (result i32)
    local.get $xs
    local.get $x
    call $__arr_lastIndexOfEq_any
    return
  )
  (func $holds (param $xs (ref null $arr_any)) (param $x anyref) (result i32)
    local.get $xs
    local.get $x
    call $__arr_indexOfEq_any
    i32.const -1
    i32.ne
    return
  )
  (func $main (export "main")
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__mem2 i32)
    (local $__mem3 i32)
    (local $__mem4 i32)
    (local $__mem5 i32)
    (local $__mem6 i32)
    i32.const 1
    i32.const 2
    array.new_fixed $arr_i32 2
    i32.const 2
    call $includes__T_i32
    struct.get $result $tag
    i32.eqz
    call $__print_bool
    i32.const 1
    i32.const 2
    array.new_fixed $arr_i32 2
    i32.const 3
    call $includes__T_i32
    struct.get $result $tag
    i32.eqz
    call $__print_bool
    f64.const 2.5
    f64.const 3.5
    array.new_fixed $arr_f64 2
    f64.const 3.5
    call $at__T_f64
    call $__print_i32
    global.get $__s3
    global.get $__s4
    array.new_fixed $arr_any 2
    global.get $__s4
    call $at__T_string
    call $__print_i32
    i32.const 1
    i32.const 2
    i32.const 1
    array.new_fixed $arr_i32 3
    i32.const 1
    call $lastAt__T_i32
    call $__print_i32
    i32.const 1
    i32.const 0
    array.new_fixed $arr_i32 2
    i32.const 1
    call $lastAt__T_i32
    call $__print_i32
    global.get $__s5
    array.new_fixed $arr_any 1
    global.get $__s6
    call $holds__T_string
    call $__print_bool
  )
  (func $includes__T_i32 (param $actual (ref null $arr_i32)) (param $element i32) (result (ref null $result))
    local.get $actual
    local.get $element
    call $__arr_indexOf_i32
    i32.const 0
    i32.lt_s
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s2
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (func $at__T_f64 (param $xs (ref null $arr_f64)) (param $x f64) (result i32)
    local.get $xs
    local.get $x
    call $__arr_indexOf_f64
    return
  )
  (func $at__T_string (param $xs (ref null $arr_any)) (param $x (ref null $str)) (result i32)
    local.get $xs
    local.get $x
    call $__arr_indexOf_any
    return
  )
  (func $lastAt__T_i32 (param $xs (ref null $arr_i32)) (param $x i32) (result i32)
    local.get $xs
    local.get $x
    call $__arr_lastIndexOf_i32
    return
  )
  (func $holds__T_string (param $xs (ref null $arr_any)) (param $x (ref null $str)) (result i32)
    local.get $xs
    local.get $x
    call $__arr_indexOf_any
    i32.const -1
    i32.ne
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
  (func $__f64_eq (param $a f64) (param $b f64) (result i32)
    local.get $a
    local.get $a
    f64.ne
    local.get $b
    local.get $b
    f64.ne
    i32.and ;; both NaN
    local.get $a
    i64.reinterpret_f64
    local.get $b
    i64.reinterpret_f64
    i64.eq ;; the same bits
    i32.or
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
  (func $__unk_same (param $a anyref) (param $b anyref) (result i32)
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
  (func $__arr_indexOfEq_any (param $xs (ref null $arr_any)) (param $x anyref) (result i32)
    (local $n i32)
    (local $i i32)
    local.get $xs
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $xs
    local.get $i
    array.get $arr_any
    local.get $x
    call $__unk_same
    (if
      (then
    local.get $i
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
    i32.const -1
  )
  (func $__arr_lastIndexOfEq_any (param $xs (ref null $arr_any)) (param $x anyref) (result i32)
    (local $n i32)
    (local $i i32)
    local.get $xs
    array.len
    local.set $n
    local.get $n
    local.set $i
    (block $brk
    (loop $cont
    local.get $i
    i32.eqz
    br_if $brk
    local.get $i
    i32.const 1
    i32.sub
    local.set $i
    local.get $xs
    local.get $i
    array.get $arr_any
    local.get $x
    call $__unk_same
    (if
      (then
    local.get $i
    return
      )
    )
    br $cont
    )
    )
    i32.const -1
  )
  (func $__arr_indexOf_i32 (param $xs (ref null $arr_i32)) (param $x i32) (result i32)
    (local $n i32)
    (local $i i32)
    local.get $xs
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $xs
    local.get $i
    array.get $arr_i32
    local.get $x
    i32.eq
    (if
      (then
    local.get $i
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
    i32.const -1
  )
  (func $__arr_indexOf_f64 (param $xs (ref null $arr_f64)) (param $x f64) (result i32)
    (local $n i32)
    (local $i i32)
    local.get $xs
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $xs
    local.get $i
    array.get $arr_f64
    local.get $x
    f64.eq
    (if
      (then
    local.get $i
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
    i32.const -1
  )
  (func $__arr_indexOf_any (param $xs (ref null $arr_any)) (param $x (ref null $str)) (result i32)
    (local $n i32)
    (local $i i32)
    local.get $xs
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    local.get $x
    call $__str_eq
    (if
      (then
    local.get $i
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
    i32.const -1
  )
  (func $__arr_lastIndexOf_i32 (param $xs (ref null $arr_i32)) (param $x i32) (result i32)
    (local $n i32)
    (local $i i32)
    local.get $xs
    array.len
    local.set $n
    local.get $n
    local.set $i
    (block $brk
    (loop $cont
    local.get $i
    i32.eqz
    br_if $brk
    local.get $i
    i32.const 1
    i32.sub
    local.set $i
    local.get $xs
    local.get $i
    array.get $arr_i32
    local.get $x
    i32.eq
    (if
      (then
    local.get $i
    return
      )
    )
    br $cont
    )
    )
    i32.const -1
  )
  (func $__unk_eq_s1 (param $a (ref null $result)) (param $b (ref null $result)) (result i32)
    local.get $a
    struct.get $result $tag
    local.get $b
    struct.get $result $tag
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $result $payload
    local.get $b
    struct.get $result $payload
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
  (func $__unk_eq_arr_i32 (param $a (ref null $arr_i32)) (param $b (ref null $arr_i32)) (result i32)
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
    array.get $arr_i32
    local.get $b
    local.get $i
    array.get $arr_i32
    i32.eq
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
  (func $__unk_eq_arr_f64 (param $a (ref null $arr_f64)) (param $b (ref null $arr_f64)) (result i32)
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
    array.get $arr_f64
    local.get $b
    local.get $i
    array.get $arr_f64
    call $__f64_eq
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
    ref.test (ref null $result)
    (if
      (then
    local.get $b
    ref.test (ref null $result)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $result)
    local.get $b
    ref.cast (ref null $result)
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
    ref.test (ref null $arr_i32)
    (if
      (then
    local.get $b
    ref.test (ref null $arr_i32)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $arr_i32)
    local.get $b
    ref.cast (ref null $arr_i32)
    call $__unk_eq_arr_i32
    return
      )
    )
    local.get $a
    ref.test (ref null $arr_f64)
    (if
      (then
    local.get $b
    ref.test (ref null $arr_f64)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $arr_f64)
    local.get $b
    ref.cast (ref null $arr_f64)
    call $__unk_eq_arr_f64
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
  (func $__gc_to_lin_str (param $s (ref null $str)) (result i32)
    (local $n i32) (local $p i32) (local $i i32)
    local.get $s
    array.len
    local.set $n
    local.get $n
    i32.const 4
    i32.add
    call $__alloc
    local.set $p
    local.get $p
    local.get $n
    i32.store
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
        i32.store8 offset=4
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $p
  )
  (func $__lin_to_gc_str (param $p i32) (result (ref null $str))
    (local $r (ref null $str)) (local $n i32) (local $i i32)
    local.get $p
    i32.load
    local.set $n
    local.get $n
    array.new_default $str
    local.set $r
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $r
        local.get $i
        local.get $p
        local.get $i
        i32.add
        i32.load8_u offset=4
        array.set $str
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
  )
  (data $__d0 "asserts.contains: needle not in actual")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "asserts.isEmpty: array was not empty")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "asserts.includes: element not found")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "a")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "b")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "x")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "y")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 38
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 36
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 35
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 1
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 1
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 1
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 1
    array.new_data $str $__d6
    global.set $__s6
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
true
false
1
1
2
0
false
```
