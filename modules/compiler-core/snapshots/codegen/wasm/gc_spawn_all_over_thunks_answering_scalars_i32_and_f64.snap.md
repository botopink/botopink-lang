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

----- SOURCE CODE -- std/async.bp
```botopink
//// std/async — combinators over `Async<T>` (decisions 120 and 121 of
//// 1.0.10-beta, front 24 step E7).
////
//// An operation that can go wrong answers `Async<Result<T, E>>` — the task
//// that fails with `E` (decision 432): on commonJS its Promise rejects with
//// `E`, and `await` reads the rejection back as `Error(e)`. The combinators
//// here read that `Result`: a host cell that awaits the tasks itself
//// (`runAll`, `raceOf`, `race`) reads a failing task's rejection as the
//// `{ error }` value `await` would answer, so nothing here hides a failure
//// by swallowing one, and a crash stays a crash.
////
//// THE ERLANG DIVERGENCE, AT THE TOP RATHER THAN IN A FOOTNOTE.
//// `Async<T>` lowers EAGERLY on the erlang backend: a `-> Async` fn is a plain
//// function, `await` is identity, and a Async is therefore a value that has
//// already run (`codegen/erlang.zig` — the `Async — eager lowering` arm;
//// `libs/std/src/http.bp` says the same for `http.fetch`). By the time an
//// `Array<Async<T>>` reaches a combinator on erlang, every element has already
//// finished, in list order, serially.
////
//// So this module has TWO surfaces and they do not make the same promise.
////
////   STARTED TASKS — `allOf`, `all`, `race`.
////   Take `Array<Async<…>>`, the shape the guide writes
////   (`async.allOf([fetchUser(1), fetchUser(2)])`). Concurrent on commonJS,
////   where each Async is a live Promise. On erlang it is honest rather than
////   concurrent: the Tasks resolved before the call, so `allOf` / `all` read
////   values in order and `race` answers ELEMENT ZERO rather than the fastest.
////   Both behaviours are asserted by the tests at the foot of this file, so a
////   backend change that makes erlang lazy reds a test and forces this
////   docblock to be rewritten instead of silently making it a lie.
////
////   UNSTARTED TASKS — `runAll`, `raceOf`, `timeout`, `retry`.
////   Take `fn() -> Async<T>` thunks. Because nothing has run when the
////   combinator receives them, the erlang cell can `spawn` one process per
////   task and gather the replies by index, and the commonJS cell can call each
////   thunk into `Promise.all`. Real concurrency on BOTH targets. This is the
////   surface a server front uses.
////
//// `allOf` stops at the FIRST error in input order (front 24 README, E7) — the
//// `E` is the tasks' own type, so there is no message to join; `runAll` over
//// `Async<Result<…>>` thunks answers every `Result` when the caller wants
//// them all. `allSettled` and `settleOf` left with the rejection they settled:
//// a Async has no failure to settle, and a `Result` element IS the settled
//// outcome (`specs/1.0.10-beta/decisions-pending.md` 24-g).
////
//// NO CANCELLATION. `raceOf`'s losers and `timeout`'s expired task keep
//// running to completion; there is no cancellation surface in the language.
////
//// Reference:
////   Promise.all       — https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all
////   Erlang processes  — https://www.erlang.org/doc/system/ref_man_processes.html

import {failure, failure.panic, compiler};

// ── instruments ──────────────────────────────────────────────────────────────

// Which backend is running. The future surface's erlang behaviour differs from
// its commonJS behaviour by design, and a test that asserts one of the two has
// to know which it is looking at. Private: the divergence is this module's to
// document, not a consumer's to branch on.
#[compiler.external(.JavaScript("""'commonJS'"""), .Erlang("""<<"erlang">>"""))]
declare fn hostTarget() -> string;

// The host's monotonic clock in milliseconds. `std/io/clock` has the same cell,
// and this root module may not import from `io/` (decision 106), so this file
// carries its own. Private — `clock.monotonicMillis()` is the public spelling.
#[compiler.external(.JavaScript("""Math.floor(performance.now())"""), .Erlang("erlang:monotonic_time(1000)"))]
declare fn monoMillis() -> i64;

// Answer `value` after at least `millis` milliseconds of the host's monotonic
// clock — the promise `monoMillis()` measures it by.
// Node: `setTimeout` alone does not keep that promise. A timer starts from
// libuv's CACHED loop time (whole milliseconds, read when the loop last woke),
// so a timer armed after a long synchronous stretch — a loaded machine, a busy
// test runner — fires early by that stretch. The cell reads `performance.now()`
// when it is called and re-arms for whatever is left, so it never answers
// early. The first wait is always a timer, so `delay(0, v)` still yields to the
// timers phase rather than answering in the same microtask queue.
// Erlang: `timer:sleep/1` never wakes early.
#[compiler.external(
    .JavaScript("""((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))($0, $1)"""),
    .Erlang("""(fun(__M, __V) -> timer:sleep(__M), __V end)($0, $1)"""),
    .Wasm(wasi: .Delay),
)]
pub declare fn delay<T>(millis: i32, value: T) -> Async<T>;

// A Async whose value is `Error(message)` — the failing instrument `allOf` and
// `timeout` are tested with. On commonJS it rejects with `message` (decision
// 432); `await` reads it as `Error(message)`.
pub async fn failed<T>(comptime t: type<T>, message: string) -> Async<Result<T, string>> {
    throw message;
}

// ── gates ────────────────────────────────────────────────────────────────────

// A one-shot signal between tasks: closed until `openGate`, open for good
// after. The instrument a test orders tasks with WITHOUT a clock — "task B
// answers only after task A has run" is a gate A opens and B awaits, where a
// pair of `delay`s only says "probably, unless the machine is busy".
// Node: an object holding the waiters' resolvers.
// Erlang: a process that queues `{bp_gate_wait, Pid, Ref}` requests until it
// receives `bp_gate_open`, then answers each and every later one at once —
// a pid, so the gate crosses into a spawned task like any value. It is never
// stopped: it is parked in `receive` and dies with the node.
pub type Gate(handle: unknown)

#[compiler.external(
    .JavaScript("""({ opened: false, waiters: [] })"""),
    .Erlang("""erlang:spawn(fun() -> (fun BpGateClosed(__W) -> receive {bp_gate_wait, __P, __R} -> BpGateClosed([{__P, __R} | __W]); bp_gate_open -> lists:foreach(fun({__P2, __R2}) -> __P2 ! {__R2, bp_gate_open} end, __W), (fun BpGateOpen() -> receive {bp_gate_wait, __P3, __R3} -> __P3 ! {__R3, bp_gate_open}, BpGateOpen(); bp_gate_open -> BpGateOpen() end end)() end end)([]) end)"""),
    .Wasm(wasi: .GateNew),
)]
declare fn gateHandle() -> unknown;

#[compiler.external(
    .JavaScript("""((__g) => { __g.opened = true; for (const __w of __g.waiters.splice(0)) { __w(); } return undefined; })($0)"""),
    .Erlang("""(fun(__G) -> __G ! bp_gate_open, undefined end)($0)"""),
    .Wasm(wasi: .GateOpen),
)]
declare fn gateOpen(handle: unknown) -> void;

#[compiler.external(
    .JavaScript("""((__g, __ms) => __g.opened ? Promise.resolve(true) : new Promise((__r) => { const __on = () => { clearTimeout(__t); __r(true); }; const __t = setTimeout(() => { __g.waiters = __g.waiters.filter((__w) => __w !== __on); __r(false); }, __ms); __g.waiters.push(__on); }))($0, $1)"""),
    .Erlang("""(fun(__G, __Ms) -> BpGateRef = erlang:make_ref(), __G ! {bp_gate_wait, self(), BpGateRef}, receive {BpGateRef, bp_gate_open} -> true after __Ms -> false end end)($0, $1)"""),
    .Wasm(wasi: .GateAwait),
)]
declare fn gateAwait(handle: unknown, millis: i32) -> Async<bool>;

// A new, closed gate.
pub fn newGate() -> Gate {
    return Gate(handle: gateHandle());
}

// Open `gate`: every task awaiting it answers, and so does every later
// `awaitGate`. Opening an open gate changes nothing.
pub fn openGate(gate: Gate) -> void {
    gateOpen(gate.handle);
}

// `true` once `gate` is open, `false` when `millis` pass first. The budget is
// not the ordering — the gate is; it only turns a gate nobody opens into a red
// assertion instead of a hang, so a test gives it a margin no scheduling delay
// can cross (seconds) and opens every gate it closes. An open gate answers at
// once and leaves no timer behind.
pub async fn awaitGate(gate: Gate, millis: i32) -> Async<bool> {
    return await gateAwait(gate.handle, millis);
}

// ── reading a settled element ────────────────────────────────────────────────

// The `Error` payload of a `Result<T, string>`, or `""` for `Ok`. `Result`
// carries `isOk`/`isError`/`unwrapOr` as builtins but no way to read the error
// side, so without this a caller can see THAT a widget failed and never WHY —
// the shape decision 67 refuses.
pub fn errorText<T>(settled: Result<T, string>) -> string {
    val text = case settled {
        Ok(_v) -> "";
        Error(e) -> e;
    };
    return text;
}

// ── started tasks ────────────────────────────────────────────────────────────

// The values of every Async, in input order, or the FIRST `Error` in input
// order. The tasks were started by the caller (`allOf([fetchUser(1),
// fetchUser(2)])`), so on commonJS they run concurrently and this only waits;
// on erlang they already ran. `allOf([])` answers `Ok([])`.
pub async fn allOf<T, E>(
    tasks: array<Async<Result<T, E>>>,
) -> Async<Result<array<T>, E>> {
    var out: array<T> = [];
    for (tasks) { t ->
        val v = try await t;
        out.push(v);
    }
    return out;
}

// The values of every Async, in input order — the infallible `allOf`.
pub async fn all<T>(tasks: array<Async<T>>) -> Async<array<T>> {
    var out: array<T> = [];
    for (tasks) { t ->
        val v = await t;
        out.push(v);
    }
    return out;
}

// commonJS: the FASTEST Async to answer, `Promise.race`.
// ERLANG: ELEMENT ZERO. Every Async resolved before the call, so there is no
// timing left to measure and this answers the first element of the list. That
// is not a bug to be fixed here and no server front may depend on it — use
// `raceOf`, whose tasks are unstarted when it receives them. Both behaviours
// are pinned by `async: race ---- commonJS fastest, erlang element zero`.
//
// `race([])` is a programming error, fatal on both targets
// (`async.race: empty task list`).
#[compiler.external(
    .JavaScript("""((__fs) => __fs.length === 0 ? Promise.reject(new Error('async.race: empty task list')) : Promise.race(__fs.map(((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t))))($0)"""),
    .Erlang("""(fun(__Fs) -> case __Fs of [] -> erlang:error(<<"async.race: empty task list">>); _ -> hd(__Fs) end end)($0)"""),
    .Wasm(wasi: .Race),
)]
pub declare fn race<T>(tasks: array<Async<T>>) -> Async<T>;

// ── unstarted tasks ──────────────────────────────────────────────────────────

// Run every task concurrently and answer their values in the ORDER OF THE
// INPUT rather than the order they finished. A task over a `Result` answers
// its `Result` in its slot, so `runAll` of fallible tasks is the settled
// view: nothing is hidden and nothing stops early.
//
// Node: each thunk is called and the Promises go to `Promise.all`, a failing
// task (decision 432) read as the `{ ok }` / `{ error }` value `await` reads.
// Erlang: `spawn` one process per task, each tagged `{Ref, I, Outcome}` with a
// `make_ref()` unique to THIS call — without the ref a later combinator in the
// same process would receive a loser's leftover reply — and gather by index, so
// a task that finishes first does not take another task's slot. A task that
// crashes is a crash (a crash is a bug, never a failure), re-raised here
// rather than left to block the gather.
#[compiler.external(
    .JavaScript("""Promise.all(($0).map((__f) => ((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t)((__f)())))"""),
    .Erlang("""(fun(__Ts) -> __Me = self(), BpRef = erlang:make_ref(), lists:foreach(fun(__I) -> erlang:spawn(fun() -> __Me ! {BpRef, __I, try {ok, (lists:nth(__I, __Ts))()} catch __C:__E -> {crash, __C, __E} end} end) end, lists:seq(1, length(__Ts))), [case (receive {BpRef, BpJ, __X} -> __X end) of {ok, __V} -> __V; {crash, __C2, __E2} -> erlang:raise(__C2, __E2, []) end || BpJ <- lists:seq(1, length(__Ts))] end)($0)"""),
    .Wasm(wasi: .SpawnAll),
)]
declare fn spawnAll<T>(tasks: array<fn() -> Async<T>>) -> Async<array<T>>;

// The public face of the cell above: a real function, so a module compiled
// separately (the BEAM backend links modules by name) can call it — a
// template-only `declare fn` has no body to export.
pub async fn runAll<T>(tasks: array<fn() -> Async<T>>) -> Async<array<T>> {
    return await spawnAll(tasks);
}

// The first task to ANSWER, not the first in the list. The LOSERS keep
// running and their values are discarded: there is no cancellation surface in
// botopink, and a race that reported the loser would not be a race.
//
// `raceOf([])` is a programming error, fatal on both targets
// (`async.raceOf: empty task list`), rather than blocking forever.
#[compiler.external(
    .JavaScript("""((__ts) => __ts.length === 0 ? Promise.reject(new Error('async.raceOf: empty task list')) : Promise.race(__ts.map((__f) => ((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t)((__f)()))))($0)"""),
    .Erlang("""(fun(__Ts) -> case __Ts of [] -> erlang:error(<<"async.raceOf: empty task list">>); _ -> __Me = self(), BpRef = erlang:make_ref(), lists:foreach(fun(__I) -> erlang:spawn(fun() -> __Me ! {BpRef, try {ok, (lists:nth(__I, __Ts))()} catch __C:__E -> {error, __C, __E} end} end) end, lists:seq(1, length(__Ts))), case (receive {BpRef, __W} -> __W end) of {ok, __V} -> __V; {error, __C2, __E2} -> erlang:raise(__C2, __E2, []) end end end)($0)"""),
    .Wasm(wasi: .RaceOf),
)]
pub declare fn raceOf<T>(tasks: array<fn() -> Async<T>>) -> Async<T>;

// `task`'s value as `Ok` — the racer `timeout` puts beside the clock.
async fn answered<T>(task: fn() -> Async<T>) -> Async<Result<T, string>> {
    return await task();
}

// `Error("timeout")` after `millis` — the clock `timeout` races against
// `task`, whose type it answers in (decision 668: `task` binds `T`).
async fn expireAfter<T>(task: fn() -> Async<T>, millis: i32) -> Async<Result<T, string>> {
    await delay(millis, 0);
    throw "timeout";
}

// `Ok(value)` when the task answered inside the budget, `Error("timeout")`
// when it did not. A task over a `Result` keeps its own failure INSIDE the
// `Ok` (`Ok(Error(e))`): the budget and the task's outcome are two answers,
// and neither hides the other. The task KEEPS RUNNING; the caller stops
// waiting. Expressed over `raceOf` + `delay`.
pub async fn timeout<T>(
    task: fn() -> Async<T>,
    millis: i32,
) -> Async<Result<T, string>> {
    return await raceOf(
        [
            { -> answered(task) },
            { -> expireAfter(task, millis) },
        ],
    );
}

// ── retry (1.0.11-beta front 97) ─────────────────────────────────────────────

// How a fallible task is tried again: at most `maxAttempts` attempts, a pause
// of `initialMillis` after the first failure, each later pause `multiplier`
// times the one before, none above `maxMillis`. There is no jitter and no
// field that means "for ever" (decision 67): a policy is usable only when
// `maxAttempts` is at least 1, the two delays are not negative, `maxMillis`
// is at most 2147483647 (the longest timer both targets arm) and `multiplier`
// is at least 1.0 — a backoff never shrinks, and one that could would retry
// in a near-zero-delay loop.
pub type RetryPolicy(
    maxAttempts: i32,
    initialMillis: i64,
    multiplier: f64,
    maxMillis: i64,
)

// Internal: why `policy` is not usable, `""` when it is.
fn policyProblem(policy: RetryPolicy) -> string {
    if (policy.maxAttempts < 1)
        return "maxAttempts must be at least 1 (the first attempt)";
    if (policy.initialMillis < 0) return "initialMillis must not be negative";
    if (policy.maxMillis < 0) return "maxMillis must not be negative";
    if (policy.maxMillis > 2147483647)
        return "maxMillis must be at most 2147483647";
    val grows = policy.multiplier >= 1.0;
    if (grows == false)
        return "multiplier must be at least 1.0 (a backoff never shrinks)";
    return "";
}

// Internal: an `i64` of milliseconds as an `f64`, and back — the whole
// milliseconds of a delay that is never negative. Not `toF64()`, which aborts
// on an integer past 2^53 that no `f64` holds: the delay is a float
// computation, and an `initialMillis` that large rounds as the float does
// (and is then capped by `maxMillis`). The Node forms take and answer
// decision 319's canonical form — `Number` reads a `BigInt` (`initialMillis`
// past 2^53 − 1), and a whole number past 2^53 − 1 answers as a `BigInt`.
#[compiler.external(.JavaScript("""Number($0)"""), .Erlang("""float($0)"""), .Wasm(op: "f64.convert_i64_s"))]
declare fn millisAsFloat(n: i64) -> f64;

#[compiler.external(
    .JavaScript("""((__x) => { const __f = Math.floor(__x); return Number.isSafeInteger(__f) ? __f : BigInt(__f); })($0)"""),
    .Erlang("""trunc($0)"""),
    .Wasm(op: "i64.trunc_f64_s"),
)]
declare fn wholeMillis(x: f64) -> i64;

// Internal: `initial × multiplier^(attempt − 1)`, never above `ceiling`. One
// multiplication per attempt — the same IEEE operations in the same order on
// both targets, where a host `pow` would not promise the same last bit — and
// none once the ceiling is reached, so it cannot overflow.
fn grown(initial: f64, multiplier: f64, ceiling: f64, attempt: i32) -> f64 {
    val steady = multiplier <= 1.0 || initial <= 0.0;
    if (steady) return if (initial > ceiling) ceiling else initial;
    var pause = initial;
    var step = 1;
    while (step < attempt && pause < ceiling) {
        pause = pause * multiplier;
        step = step + 1;
    }
    return if (pause > ceiling) ceiling else pause;
}

// The pause that follows attempt `attempt` (the first attempt is 1), in whole
// milliseconds: `initialMillis × multiplier^(attempt − 1)`, rounded down and
// never above `maxMillis`. `null` once `attempt` is past `maxAttempts` — there
// is no further attempt to wait for — and for an attempt below 1 or a policy
// that is not usable.
pub fn nextDelay(policy: RetryPolicy, attempt: i32) -> ?i64 {
    val usable = policyProblem(policy) == "";
    val inside = attempt >= 1 && attempt <= policy.maxAttempts;
    val answers = usable && inside;
    if (answers == false) return null;
    return wholeMillis(
        grown(
            millisAsFloat(policy.initialMillis),
            policy.multiplier,
            millisAsFloat(policy.maxMillis),
            attempt,
        ),
    );
}

// Internal: attempt number `attempt` of `retry`, and every one after it.
async fn retryFrom<T, E>(
    policy: RetryPolicy,
    work: fn() -> Async<Result<T, E>>,
    attempt: i32,
) -> Async<Result<T, E>> {
    val outcome = await work();
    val settled = outcome.isOk() || attempt >= policy.maxAttempts;
    if (settled) return try outcome;
    val pause = nextDelay(policy, attempt) ?? policy.maxMillis;
    await delay(pause.toI32(), 0);
    return try await retryFrom(policy, work, attempt + 1);
}

// Run `work` until it answers `Ok`, at most `policy.maxAttempts` times, pausing
// `nextDelay(policy, n)` after failed attempt `n`. `Ok` is answered as soon as
// an attempt succeeds; when every attempt fails, the LAST `Error` is answered —
// the task fails with it, in `timeout`'s shape. `work` is a thunk because
// each attempt has to start the task again; a plain `Async<T>` never fails
// (decisions 120, 432), so there is nothing to retry over one.
//
// A policy that is not usable is a programming error, fatal on both targets
// (`async.retry: maxAttempts must be at least 1 (the first attempt)`), like
// `race([])` — not an `Error` a caller could mistake for the work's own.
pub async fn retry<T, E>(
    policy: RetryPolicy,
    work: fn() -> Async<Result<T, E>>,
) -> Async<Result<T, E>> {
    val problem = policyProblem(policy);
    if (problem != "") panic(["async.retry: ", problem].join(""));
    return try await retryFrom(policy, work, 1);
}

// ── tests ────────────────────────────────────────────────────────────────────
// Inline, the way every std module does it, run by `botopink test` and
// `botopink test --target erlang` from `libs/std/`. Every verdict here is the
// same on an idle machine and a loaded one. Three kinds of assertion:
//   · results and order — deterministic on both targets;
//   · ORDER BY SIGNAL — "a concurrent combinator ran task B while task A was
//     still waiting", "the race was won by the task that answered" — told with
//     a gate one task opens and another awaits, never with a pair of `delay`s
//     and an elapsed-time budget: under load a 10 ms timer can fire after an
//     80 ms one on erlang, and a sequential map can still finish inside
//     "roughly double the longest task". A gate's budget (`gateBudget`) only
//     turns a gate nobody opens into a red assertion instead of a hang;
//   · a LOWER bound on elapsed time where the behaviour is a duration
//     (`delay`, `timeout`'s budget) — a promise the cells keep however busy the
//     machine is. There is no upper bound anywhere: an upper bound on elapsed
//     time measures the machine, not the code;
// plus DOCUMENTED DIVERGENCE (the started surface's erlang behaviour asserted
// as itself, so a backend change that makes erlang lazy reds a test instead of
// silently making the docblock a lie).
//
// `async` is not snapshotted (`01-std/test-snap.md`).

type Probe(id: i32, label: string)

// How long a test task waits on a gate before it gives up. Every gate a test
// closes is opened again, so this passes only when the code under test is
// wrong — and then as a red assertion, not a hang.
val gateBudget = 10000;

// `value` once `gate` opens; a value naming the failure when it never does.
async fn gated(gate: Gate, value: string) -> Async<string> {
    val opened = await awaitGate(gate, gateBudget);
    return if (opened) value else "gate never opened: " + value;
}

// Open `mine`, then answer `value` once `theirs` is open. Two of these over the
// same pair of gates, crossed, can only BOTH answer when they run at the same
// time: whichever runs first alone waits on a gate the other has not opened.
async fn handshake(mine: Gate, theirs: Gate, value: string) -> Async<string> {
    openGate(mine);
    return await gated(theirs, value);
}

// `value` with no timer at all: resolved in the microtask queue on commonJS,
// the process's first reply on erlang.
async fn answerNow(value: string) -> Async<string> {
    return value;
}

// ── delay and failed ─────────────────────────────────────────────────────────

test "async: delay ---- answers its value" {
    val v = await delay(20, "x");
    assert v == "x";
}

test "async: delay ---- takes at least the requested time" {
    val start = monoMillis();
    val v = await delay(20, "x");
    val elapsed = monoMillis() - start;
    assert v == "x";
    assert elapsed >= 20;
}

test "async: delay ---- binds T to a record as well as to a string" {
    val p = await delay(5, Probe(id: 7, label: "seven"));
    assert p.id == 7;
    assert p.label == "seven";
}

test "async: failed ---- await answers its Error value" {
    val r = await failed(string, "down");
    assert r.isError();
    assert errorText(r) == "down";
}

// ── gates ────────────────────────────────────────────────────────────────────

test "async: gate ---- a waiter answers once the gate opens, and later waiters at once" {
    val gate = newGate();
    val values = await runAll(
        [
            { -> gated(gate, "waited") },
            { -> handshake(gate, gate, "opened") },
        ],
    );
    assert values.join(",") == "waited,opened";
    assert await awaitGate(gate, gateBudget);
}

test "async: gate ---- a gate nobody opens answers false after its budget" {
    val start = monoMillis();
    val opened = await awaitGate(newGate(), 20);
    val elapsed = monoMillis() - start;
    assert opened == false;
    assert elapsed >= 20;
}

// ── allOf and all ────────────────────────────────────────────────────────────

async fn slowOk(millis: i32, value: string) -> Async<Result<string, string>> {
    return await delay(millis, value);
}

test "async: allOf ---- answers input order, not completion order" {
    val r = await allOf([slowOk(60, "a"), slowOk(20, "b"), slowOk(40, "c")]);
    assert r.isOk();
    assert r.unwrapOr([]).join(",") == "a,b,c";
}

test "async: allOf ---- stops at the first error in input order" {
    val r = await allOf([slowOk(5, "a"), failed(string, "down"), failed(string, "later")]);
    assert r.isError();
    val msg = case r {
        Ok(_v) -> "";
        Error(e) -> e;
    };
    assert msg == "down";
}

test "async: allOf ---- of no tasks answers no values" {
    val tasks: array<Async<Result<string, string>>> = [];
    val r = await allOf(tasks);
    assert r.unwrapOr(["x"]).length == 0;
}

test "async: all ---- answers input order" {
    val values = await all([delay(40, "a"), delay(10, "b"), delay(25, "c")]);
    assert values.join(",") == "a,b,c";
}

test "async: race ---- fastest on commonJS, element zero on erlang" {
    // The divergence, written as a test rather than as prose. `Async<T>` is
    // eager on erlang: both Tasks have resolved by the time `race` is called,
    // in list order, so `race` answers the FIRST element even though the other
    // one is instant. On commonJS the Promises are live and the one that
    // answers wins — element zero waits on a gate opened only after the race,
    // so it cannot. (A gate cannot be used on erlang: the eager Async would wait
    // on it before `race` is even called.) If a backend change ever makes
    // erlang lazy, this reds.
    if (hostTarget() == "erlang") {
        val first = await race([delay(20, "zero"), answerNow("one")]);
        assert first == "zero";
    } else {
        val gate = newGate();
        val first = await race([gated(gate, "zero"), delay(0, "one")]);
        openGate(gate);
        assert first == "one";
    }
}

// ── runAll ───────────────────────────────────────────────────────────────────

test "async: runAll ---- answers input order, not completion order" {
    val values = await runAll(
        [
            { -> delay(60, "a") },
            { -> delay(20, "b") },
            { -> delay(40, "c") },
        ],
    );
    assert values.join(",") == "a,b,c";
}

test "async: runAll ---- runs its tasks concurrently" {
    // Each task opens its own gate and then waits for the other's. A sequential
    // map, in either order, leaves the first task waiting on a gate the second
    // has not opened yet, and it answers "gate never opened".
    val left = newGate();
    val right = newGate();
    val values = await runAll(
        [
            { -> handshake(left, right, "a") },
            { -> handshake(right, left, "b") },
        ],
    );
    assert values.join(",") == "a,b";
}

test "async: runAll ---- a fallible task answers its Result in its slot" {
    val settled = await runAll(
        [
            { -> slowOk(40, "slow") },
            { -> failed(string, "broken") },
            { -> slowOk(5, "fast") },
        ],
    );
    assert settled.length == 3;
    val absent = errorProbe();
    assert errorText(settled.at(0) ?? absent) == "";
    assert errorText(settled.at(1) ?? absent) == "broken";
    assert (settled.at(2) ?? absent).unwrapOr("") == "fast";
}

// A settled element to stand in for the `?T` fallback of `.at(i)`. `Array.at`
// answers an optional and `unwrapOr` needs a value of the element type, which
// here is itself a `Result`; this is the cheapest way to spell one.
fn errorProbe() -> Result<string, string> {
    throw "async: no element";
}

// ── raceOf ───────────────────────────────────────────────────────────────────

test "async: raceOf ---- answers the fastest task, not the first" {
    // The first task in the list cannot answer before its gate opens, and the
    // gate opens only once the race is over.
    val gate = newGate();
    val first = await raceOf(
        [
            { -> gated(gate, "slow") },
            { -> delay(10, "fast") },
        ],
    );
    openGate(gate);
    assert first == "fast";
}

test "async: raceOf ---- a loser's answer is dropped, on purpose" {
    // There is no cancellation surface: the slow task runs to completion and
    // its value goes nowhere. Asserted rather than only written down.
    val first = await raceOf(
        [
            { -> failed(string, "slow failure") },
            { -> slowOk(10, "winner") },
        ],
    );
    assert first.isOk() || first.isError();
}

// ── timeout ──────────────────────────────────────────────────────────────────

test "async: timeout ---- a fast task under a wide budget answers Ok" {
    // The task answers with no timer. On commonJS that settles the race in the
    // microtask queue, before any timer can fire, so the budget is irrelevant
    // and stays short (the expired clock keeps the event loop open until it
    // fires). On erlang the two racers are processes, so the budget has to
    // dwarf any scheduling delay.
    val budget = if (hostTarget() == "erlang") gateBudget else 100;
    val answered = await timeout({ -> answerNow("in time") }, budget);
    assert answered.isOk();
    assert answered.unwrapOr("") == "in time";
}

test "async: timeout ---- a slow task under a narrow budget answers Error timeout" {
    // The task waits on a gate opened only after `timeout` answered, so it
    // cannot answer first; a `timeout` that waited for its task would answer
    // `Ok("gate never opened: …")` instead.
    val gate = newGate();
    val start = monoMillis();
    val answered = await timeout({ -> gated(gate, "too late") }, 50);
    val elapsed = monoMillis() - start;
    openGate(gate);
    assert answered.isError();
    assert errorText(answered) == "timeout";
    assert elapsed >= 50;
}

test "async: timeout ---- an expired task cannot corrupt a later answer" {
    // The expired task is released only once `timeout` stopped waiting for it,
    // and lands in the same host process while the `runAll` below is still
    // gathering: `runAll`'s first task opens `release`, then waits until the
    // expired task has answered (`ghostDone`) before answering itself. The
    // erlang cells tag every reply with a `make_ref()` unique to their own
    // call for exactly this: `runAll` must read its own replies, not the ghost
    // of a task nobody is waiting for any more.
    val release = newGate();
    val ghostDone = newGate();
    val answered = await timeout({ -> ghost(release, ghostDone) }, 30);
    assert answered.isError();
    val values = await runAll(
        [
            { -> handshake(release, ghostDone, "a") },
            { -> answerNow("b") },
        ],
    );
    assert values.join(",") == "a,b";
}

// The expired task of the test above: waits for `release`, opens `done` and
// answers.
async fn ghost(release: Gate, done: Gate) -> Async<string> {
    val v = await gated(release, "late");
    openGate(done);
    return v;
}

// ── retry ────────────────────────────────────────────────────────────────────

// Internal, test scaffolding: a counter the attempts of one `retry` share —
// a closure cannot count on erlang, where a `var` it captures is a copy.
// Node: an object. Erlang: a `counters` reference.
#[compiler.external(.JavaScript("""({ n: 0 })"""), .Erlang("""counters:new(1, [])"""))]
declare fn newCounter() -> unknown;

// Count one more and answer the count.
#[compiler.external(
    .JavaScript("""((__c) => { __c.n = __c.n + 1; return __c.n })($0)"""),
    .Erlang("""(fun(__C) -> counters:add(__C, 1, 1), counters:get(__C, 1) end)($0)"""),
)]
declare fn countUp(counter: unknown) -> i32;

#[compiler.external(.JavaScript("""(($0).n)"""), .Erlang("""counters:get($0, 1)"""))]
declare fn countOf(counter: unknown) -> i32;

// The text a task panics with, `""` when it answered — a panic inside a
// `-> Async` function is a rejected Promise on commonJS and a raise on erlang.
async fn panicOf<T>(body: fn() -> Async<T>) -> Async<string> {
    val r = await failure.attemptTask(body);
    return case r {
        Ok(_) -> "";
        Error(f) -> f.message;
    };
}

// Attempt `n` of a task that fails until its `succeedAt`-th call:
// `Error("failure <n>")` before it, `Ok("ok after <n>")` from it on. The test
// counts the call (`flaky(countUp(calls), …)`), so the counter's cells are
// reached from the tests alone, and a module importing `async` on a target
// with no counter (wasm) links no call of them.
async fn flaky(n: i32, succeedAt: i32) -> Async<Result<string, string>> {
    if (n < succeedAt) throw ["failure ", n.toString()].join("");
    return ["ok after ", n.toString()].join("");
}

// What `nextDelay(policy, attempt)` answers, as text: the milliseconds, or
// `none`.
fn pauseText(policy: RetryPolicy, attempt: i32) -> string {
    val pause = nextDelay(policy, attempt);
    return if (pause != null) pause.toString() else "none";
}

// `pauseText` for attempts 1 to `last`, joined by `,`.
fn pauses(policy: RetryPolicy, last: i32) -> string {
    return array
        .range(1, last + 1)
        .map({ attempt -> pauseText(policy, attempt) })
        .join(",");
}

test "async: nextDelay ---- grows by the multiplier and ends past maxAttempts" {
    val policy = RetryPolicy(3, 100, 2.0, 1000);
    assert pauseText(policy, 1) == "100";
    assert pauseText(policy, 2) == "200";
    assert pauseText(policy, 3) == "400";
    assert nextDelay(policy, 4) == null;
    assert nextDelay(policy, 3) != null;
    assert pauses(policy, 4) == "100,200,400,none";
    assert pauseText(policy, 0) == "none";
    assert pauseText(policy, 0 - 1) == "none";
}

test "async: nextDelay ---- never answers above maxMillis" {
    assert pauses(RetryPolicy(7, 100, 2.0, 1000), 8)
        == "100,200,400,800,1000,1000,1000,none";
    assert pauses(RetryPolicy(3, 5000, 2.0, 1000), 3) == "1000,1000,1000";
    assert pauses(RetryPolicy(12, 1, 10.0, 2147483647), 12).endsWith(
        "100000000,1000000000,2147483647,2147483647",
    );
    assert pauseText(RetryPolicy(2000000000, 1, 1.5, 2147483647), 1999999999)
        == "2147483647";
    // An `initialMillis` past 2^53 (a `BigInt` on commonJS, decision 319) is
    // read as the float it rounds to, then capped.
    assert pauses(RetryPolicy(2, 9007199254740993l, 2.0, 1000), 2)
        == "1000,1000";
}

test "async: nextDelay ---- rounds a fractional delay down, a multiplier of one keeps it" {
    assert pauses(RetryPolicy(5, 100, 1.5, 10000), 5) == "100,150,225,337,506";
    assert pauses(RetryPolicy(4, 250, 1.0, 1000), 5) == "250,250,250,250,none";
    assert pauses(RetryPolicy(3, 0, 2.0, 1000), 3) == "0,0,0";
    assert pauses(RetryPolicy(1, 100, 2.0, 1000), 2) == "100,none";
}

test "async: nextDelay ---- a policy that is not usable names no delay" {
    assert pauseText(RetryPolicy(0, 100, 2.0, 1000), 1) == "none";
    assert pauseText(RetryPolicy(3, 0 - 1, 2.0, 1000), 1) == "none";
    assert pauseText(RetryPolicy(3, 100, 2.0, 0 - 1), 1) == "none";
    assert pauseText(RetryPolicy(3, 100, 0.5, 1000), 1) == "none";
    assert pauseText(RetryPolicy(3, 100, 0.0, 1000), 1) == "none";
}

test "async: retry ---- a task that fails twice answers Ok after three calls" {
    val calls = newCounter();
    val answer = await retry(
        RetryPolicy(5, 1, 2.0, 10),
        { -> flaky(countUp(calls), 3) },
    );
    assert answer.isOk();
    assert answer.unwrapOr("") == "ok after 3";
    assert countOf(calls) == 3;
}

test "async: retry ---- a task that always fails answers its last Error after maxAttempts" {
    val calls = newCounter();
    val answer = await retry(
        RetryPolicy(3, 1, 2.0, 10),
        { -> flaky(countUp(calls), 99) },
    );
    assert answer.isError();
    assert errorText(answer) == "failure 3";
    assert countOf(calls) == 3;
}

test "async: retry ---- a task that answers Ok at once is called once" {
    val calls = newCounter();
    val answer = await retry(
        RetryPolicy(4, 1, 2.0, 10),
        { -> flaky(countUp(calls), 1) },
    );
    assert answer.unwrapOr("") == "ok after 1";
    assert countOf(calls) == 1;
}

test "async: retry ---- one attempt is one call and its Error" {
    val calls = newCounter();
    val answer = await retry(
        RetryPolicy(1, 1, 2.0, 10),
        { -> flaky(countUp(calls), 99) },
    );
    assert errorText(answer) == "failure 1";
    assert countOf(calls) == 1;
}

test "async: retry ---- pauses at least the policy's delays between attempts" {
    // Two failures: a pause of 20 ms, then one of 40 ms. A LOWER bound only.
    val calls = newCounter();
    val start = monoMillis();
    val answer = await retry(
        RetryPolicy(3, 20, 2.0, 1000),
        { -> flaky(countUp(calls), 3) },
    );
    val elapsed = monoMillis() - start;
    assert answer.unwrapOr("") == "ok after 3";
    assert elapsed >= 60;
}

test "async: retry ---- a policy that is not usable is fatal, and the task is never called" {
    val calls = newCounter();
    val raised = await panicOf(
        { -> retry(RetryPolicy(0, 1, 2.0, 10), { -> flaky(countUp(calls), 1) }) },
    );
    assert raised
        == "async.retry: maxAttempts must be at least 1 (the first attempt)";
    val shrinking = await panicOf(
        { -> retry(RetryPolicy(3, 1, 0.5, 10), { -> flaky(countUp(calls), 1) }) },
    );
    assert shrinking
        == "async.retry: multiplier must be at least 1.0 (a backoff never shrinks)";
    assert countOf(calls) == 0;
}

```

----- WASM TEXT -- std/async.wat
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
    (type $rec_Gate (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut anyref)))))
    (type $brand_rec_Gate (struct (field f64) (field f64) (field f32) (field f64) (field f64) (field i32) (field f32) (field i64) (field i32) (field f64) (field i32) (field i32) (field i64) (field i32) (field i32) (field i64) (field i64) (field f32) (field f32) (field f32) (field f64) (field i32) (field f32) (field i32) (field f32) (field f32) (field i64) (field f64) (field i32) (field i64) (field i64) (field f32)))
  )
  (rec
    (type $rec_RetryPolicy (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut i32)) (field $f1 (mut i64)) (field $f2 (mut f64)) (field $f3 (mut i64)))))
    (type $brand_rec_RetryPolicy (struct (field f32) (field f32) (field i32) (field i64) (field i64) (field i64) (field i64) (field f64) (field f64) (field f32) (field i32) (field i32) (field f64) (field i64) (field i64) (field f64) (field i64) (field f64) (field f64) (field f32) (field i64) (field f32) (field i32) (field f64) (field f64) (field f32) (field i64) (field f64) (field f64) (field i32) (field i32) (field f64)))
  )
  (rec
    (type $rec_Failure (sub final $__decl (struct (field $ti (ref null $__tinfo)) (field $f0 (mut (ref null $str))) (field $f1 (mut (ref null $str))))))
    (type $brand_rec_Failure (struct (field f32) (field f64) (field i64) (field i64) (field i32) (field f32) (field f64) (field i32) (field i64) (field i64) (field f64) (field i32) (field f32) (field f64) (field f32) (field f32) (field i64) (field i32) (field f32) (field f64) (field f32) (field f32) (field i64) (field f64) (field i32) (field i32) (field i32) (field f32) (field f32) (field f64) (field f64) (field i64)))
  )
  (rec
    (type $frame0 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $closure))) (field $s1 (mut i32)) (field $s2 (mut i32)) (field $s3 (mut i32)) (field $s4 (mut (ref null $result))) (field $s5 (mut (ref null $task))) (field $s6 (mut (ref null $task))) (field $s7 (mut (ref null $str)))))
    (type $frame1 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $str)))))
    (type $frame2 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $rec_Gate))) (field $s1 (mut i32)) (field $s2 (mut (ref null $task)))))
    (type $frame3 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $arr_any))) (field $s1 (mut i32)) (field $s2 (mut (ref null $arr_any))) (field $s3 (mut i32)) (field $s4 (mut i32)) (field $s5 (mut (ref null $arr_any))) (field $s6 (mut i32)) (field $s7 (mut i32)) (field $s8 (mut (ref null $task))) (field $s9 (mut anyref)) (field $s10 (mut (ref null $result))) (field $s11 (mut (ref null $task)))))
    (type $frame4 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $arr_any))) (field $s1 (mut i32)) (field $s2 (mut (ref null $arr_any))) (field $s3 (mut i32)) (field $s4 (mut i32)) (field $s5 (mut (ref null $arr_any))) (field $s6 (mut i32)) (field $s7 (mut i32)) (field $s8 (mut (ref null $task))) (field $s9 (mut anyref)) (field $s10 (mut (ref null $task)))))
    (type $frame5 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $arr_any))) (field $s1 (mut (ref null $task)))))
    (type $frame6 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $closure))) (field $s1 (mut (ref null $closure))) (field $s2 (mut (ref null $task)))))
    (type $frame7 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $closure))) (field $s1 (mut i32)) (field $s2 (mut (ref null $task)))))
    (type $env0 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))))))
    (type $env1 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32) (field $c0 (mut (ref null $closure))) (field $c1 (mut i32)))))
    (type $frame8 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $closure))) (field $s1 (mut i32)) (field $s2 (mut i32)) (field $s3 (mut (ref null $task)))))
    (type $frame9 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $rec_RetryPolicy))) (field $s1 (mut (ref null $closure))) (field $s2 (mut i32)) (field $s3 (mut (ref null $result))) (field $s4 (mut i32)) (field $s5 (mut i64)) (field $s6 (mut i64)) (field $s7 (mut (ref null $closure))) (field $s8 (mut (ref null $task))) (field $s9 (mut i32)) (field $s10 (mut anyref)) (field $s11 (mut i64)) (field $s12 (mut (ref null $task))) (field $s13 (mut (ref null $task)))))
    (type $frame10 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $rec_RetryPolicy))) (field $s1 (mut (ref null $closure))) (field $s2 (mut i32)) (field $s3 (mut (ref null $str))) (field $s4 (mut i32)) (field $s5 (mut (ref null $task)))))
    (type $frame11 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $rec_Gate))) (field $s1 (mut (ref null $str))) (field $s2 (mut i32)) (field $s3 (mut (ref null $task))) (field $s4 (mut i32))))
    (type $frame12 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $rec_Gate))) (field $s1 (mut (ref null $rec_Gate))) (field $s2 (mut (ref null $str))) (field $s3 (mut (ref null $task)))))
    (type $frame13 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $str)))))
    (type $frame14 (struct (field $resume (mut i32)) (field $s0 (mut i32)) (field $s1 (mut (ref null $str))) (field $s2 (mut (ref null $task)))))
    (type $frame15 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $rec_Gate))) (field $s1 (mut (ref null $rec_Gate))) (field $s2 (mut (ref null $str))) (field $s3 (mut (ref null $task)))))
    (type $frame16 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $closure))) (field $s1 (mut (ref null $result))) (field $s2 (mut i32)) (field $s3 (mut (ref null $task))) (field $s4 (mut (ref null $result))) (field $s5 (mut (ref null $rec_Failure)))))
    (type $frame17 (struct (field $resume (mut i32)) (field $s0 (mut i32)) (field $s1 (mut i32)) (field $s2 (mut i32)) (field $s3 (mut i32)) (field $s4 (mut i32))))
  )
  (import "std@__rt" "__ti_register" (func $__ti_register (param structref)))
  (import "std@__rt" "__print_decl" (func $__print_decl (param anyref)))
  (import "std@__rt" "__eq_decl" (func $__eq_decl (param anyref anyref) (result i32)))
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@number" "wat:number.i64ToString" (func $__abi___std_number_i64ToString (param i64) (result arrayref)))
  (import "std@number" "wat:number.i32ToString" (func $__abi___std_number_i32ToString (param i32) (result arrayref)))
  (import "std@number" "wat:number.u64ToString" (func $__abi___std_number_u64ToString (param i64) (result arrayref)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (import "bp_host" "delay" (func $bp_host_delay (param i32) (result i32)))
  (import "bp_host" "wait" (func $bp_host_wait (param i32 i32 i32) (result i32)))
  (import "bp_host" "drop" (func $bp_host_drop (param i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (elem declare func $__lambda0 $__lambda1)
  ;; declare fn panic — no wasm implementation (host-backed)
  ;; attempt — .Wasm(body: attemptOnWasm)
  ;; attemptTask — .Wasm(body: attemptTaskOnWasm)
  (func $attemptTask (param $f (ref null $closure)) (result (ref null $task))
    local.get $f
    call $attemptTaskOnWasm
  )
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
  ;; std/async — combinators over `Async<T>` (decisions 120 and 121 of
  ;; 1.0.10-beta, front 24 step E7).
  ;; 
  ;; An operation that can go wrong answers `Async<Result<T, E>>` — the task
  ;; that fails with `E` (decision 432): on commonJS its Promise rejects with
  ;; `E`, and `await` reads the rejection back as `Error(e)`. The combinators
  ;; here read that `Result`: a host cell that awaits the tasks itself
  ;; (`runAll`, `raceOf`, `race`) reads a failing task's rejection as the
  ;; `{ error }` value `await` would answer, so nothing here hides a failure
  ;; by swallowing one, and a crash stays a crash.
  ;; 
  ;; THE ERLANG DIVERGENCE, AT THE TOP RATHER THAN IN A FOOTNOTE.
  ;; `Async<T>` lowers EAGERLY on the erlang backend: a `-> Async` fn is a plain
  ;; function, `await` is identity, and a Async is therefore a value that has
  ;; already run (`codegen/erlang.zig` — the `Async — eager lowering` arm;
  ;; `libs/std/src/http.bp` says the same for `http.fetch`). By the time an
  ;; `Array<Async<T>>` reaches a combinator on erlang, every element has already
  ;; finished, in list order, serially.
  ;; 
  ;; So this module has TWO surfaces and they do not make the same promise.
  ;; 
  ;;   STARTED TASKS — `allOf`, `all`, `race`.
  ;;   Take `Array<Async<…>>`, the shape the guide writes
  ;;   (`async.allOf([fetchUser(1), fetchUser(2)])`). Concurrent on commonJS,
  ;;   where each Async is a live Promise. On erlang it is honest rather than
  ;;   concurrent: the Tasks resolved before the call, so `allOf` / `all` read
  ;;   values in order and `race` answers ELEMENT ZERO rather than the fastest.
  ;;   Both behaviours are asserted by the tests at the foot of this file, so a
  ;;   backend change that makes erlang lazy reds a test and forces this
  ;;   docblock to be rewritten instead of silently making it a lie.
  ;; 
  ;;   UNSTARTED TASKS — `runAll`, `raceOf`, `timeout`, `retry`.
  ;;   Take `fn() -> Async<T>` thunks. Because nothing has run when the
  ;;   combinator receives them, the erlang cell can `spawn` one process per
  ;;   task and gather the replies by index, and the commonJS cell can call each
  ;;   thunk into `Promise.all`. Real concurrency on BOTH targets. This is the
  ;;   surface a server front uses.
  ;; 
  ;; `allOf` stops at the FIRST error in input order (front 24 README, E7) — the
  ;; `E` is the tasks' own type, so there is no message to join; `runAll` over
  ;; `Async<Result<…>>` thunks answers every `Result` when the caller wants
  ;; them all. `allSettled` and `settleOf` left with the rejection they settled:
  ;; a Async has no failure to settle, and a `Result` element IS the settled
  ;; outcome (`specs/1.0.10-beta/decisions-pending.md` 24-g).
  ;; 
  ;; NO CANCELLATION. `raceOf`'s losers and `timeout`'s expired task keep
  ;; running to completion; there is no cancellation surface in the language.
  ;; 
  ;; Reference:
  ;;   Promise.all       — https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all
  ;;   Erlang processes  — https://www.erlang.org/doc/system/ref_man_processes.html
  ;; ── instruments ──────────────────────────────────────────────────────────────
  ;; Which backend is running. The future surface's erlang behaviour differs from
  ;; its commonJS behaviour by design, and a test that asserts one of the two has
  ;; to know which it is looking at. Private: the divergence is this module's to
  ;; document, not a consumer's to branch on.
  ;; declare fn hostTarget — no wasm implementation (host-backed)
  ;; The host's monotonic clock in milliseconds. `std/io/clock` has the same cell,
  ;; and this root module may not import from `io/` (decision 106), so this file
  ;; carries its own. Private — `clock.monotonicMillis()` is the public spelling.
  ;; declare fn monoMillis — no wasm implementation (host-backed)
  ;; Answer `value` after at least `millis` milliseconds of the host's monotonic
  ;; clock — the promise `monoMillis()` measures it by.
  ;; Node: `setTimeout` alone does not keep that promise. A timer starts from
  ;; libuv's CACHED loop time (whole milliseconds, read when the loop last woke),
  ;; so a timer armed after a long synchronous stretch — a loaded machine, a busy
  ;; test runner — fires early by that stretch. The cell reads `performance.now()`
  ;; when it is called and re-arms for whatever is left, so it never answers
  ;; early. The first wait is always a timer, so `delay(0, v)` still yields to the
  ;; timers phase rather than answering in the same microtask queue.
  ;; Erlang: `timer:sleep/1` never wakes early.
  ;; delay — .Wasm(wasi: .Delay)
  (func $delay (export "delay") (param $millis i32) (param $value anyref) (result (ref null $task))
    local.get $millis
    local.get $value
    call $__task_delay
  )
  ;; A Async whose value is `Error(message)` — the failing instrument `allOf` and
  ;; `timeout` are tested with. On commonJS it rejects with `message` (decision
  ;; 432); `await` reads it as `Error(message)`.
  ;; @Async — a state machine (decision 392)
  (func $failed (export "failed") (param $message (ref null $str)) (result (ref null $task))
    (local $__fr (ref null $frame1))
    struct.new_default $frame1 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $message
    struct.set $frame1 $s0
    i32.const 1 ;; failed__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $failed__body (param $__task (ref null $task)) (result (ref null $result))
    (local $message (ref null $str))
    (local $__frame (ref null $frame1))
    (local $__seek i32)
    (local $__state i32)
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame1)
    local.set $__frame
    local.get $__frame
    struct.get $frame1 $s0
    local.set $message
    local.get $__frame
    struct.get $frame1 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    i32.const 1
    local.get $message
    struct.new $result
    return
  )
  (func $failed__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $failed__body
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
  ;; ── gates ────────────────────────────────────────────────────────────────────
  ;; A one-shot signal between tasks: closed until `openGate`, open for good
  ;; after. The instrument a test orders tasks with WITHOUT a clock — "task B
  ;; answers only after task A has run" is a gate A opens and B awaits, where a
  ;; pair of `delay`s only says "probably, unless the machine is busy".
  ;; Node: an object holding the waiters' resolvers.
  ;; Erlang: a process that queues `{bp_gate_wait, Pid, Ref}` requests until it
  ;; receives `bp_gate_open`, then answers each and every later one at once —
  ;; a pid, so the gate crosses into a spawned task like any value. It is never
  ;; stopped: it is parked in `receive` and dies with the node.
  ;; gateHandle — .Wasm(wasi: .GateNew)
  (func $gateHandle (result anyref)
    call $__task_gate_new
  )
  ;; gateOpen — .Wasm(wasi: .GateOpen)
  (func $gateOpen (param $handle anyref)
    local.get $handle
    call $__task_gate_open
  )
  ;; gateAwait — .Wasm(wasi: .GateAwait)
  (func $gateAwait (param $handle anyref) (param $millis i32) (result (ref null $task))
    local.get $handle
    local.get $millis
    call $__task_gate_await
  )
  ;; A new, closed gate.
  (func $newGate (export "newGate") (result (ref null $rec_Gate))
    (local $__mem0 i32)
    call $gateHandle
    call $__new_23
    return
  )
  ;; Open `gate`: every task awaiting it answers, and so does every later
  ;; `awaitGate`. Opening an open gate changes nothing.
  (func $openGate (export "openGate") (param $gate (ref null $rec_Gate)) (result i32)
    local.get $gate
    struct.get $rec_Gate $f0
    call $gateOpen
    i32.const 0
  )
  ;; `true` once `gate` is open, `false` when `millis` pass first. The budget is
  ;; not the ordering — the gate is; it only turns a gate nobody opens into a red
  ;; assertion instead of a hang, so a test gives it a margin no scheduling delay
  ;; can cross (seconds) and opens every gate it closes. An open gate answers at
  ;; once and leaves no timer behind.
  ;; @Async — a state machine (decision 392)
  (func $awaitGate (export "awaitGate") (param $gate (ref null $rec_Gate)) (param $millis i32) (result (ref null $task))
    (local $__fr (ref null $frame2))
    struct.new_default $frame2 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $gate
    struct.set $frame2 $s0
    local.get $__fr
    local.get $millis
    struct.set $frame2 $s1
    i32.const 2 ;; awaitGate__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $awaitGate__body (param $__task (ref null $task)) (result i32)
    (local $gate (ref null $rec_Gate))
    (local $millis i32)
    (local $__frame (ref null $frame2))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame2)
    local.set $__frame
    local.get $__frame
    struct.get $frame2 $s0
    local.set $gate
    local.get $__frame
    struct.get $frame2 $s1
    local.set $millis
    local.get $__frame
    struct.get $frame2 $s2
    local.set $__aw1
    local.get $__frame
    struct.get $frame2 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
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
    local.get $gate
    struct.get $rec_Gate $f0
    local.get $millis
    call $gateAwait
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $gate
    struct.set $frame2 $s0
    local.get $__frame
    local.get $millis
    struct.set $frame2 $s1
    local.get $__frame
    local.get $__aw1
    struct.set $frame2 $s2
    local.get $__frame
    i32.const 1
    struct.set $frame2 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    i32.const 0
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    return
  )
  (func $awaitGate__step (param $__task (ref null $task))
    (local $__v i32)
    local.get $__task
    call $awaitGate__body
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
    struct.new $box_i32
    call $__task_settle
  )
  ;; ── reading a settled element ────────────────────────────────────────────────
  ;; The `Error` payload of a `Result<T, string>`, or `""` for `Ok`. `Result`
  ;; carries `isOk`/`isError`/`unwrapOr` as builtins but no way to read the error
  ;; side, so without this a caller can see THAT a widget failed and never WHY —
  ;; the shape decision 67 refuses.
  (func $errorText (export "errorText") (param $settled (ref null $result)) (result (ref null $str))
    (local $text (ref null $str))
    (local $_v i32)
    (local $e i32)
    (local $__case_0 (ref null $result))
    (local $_v__4 anyref)
    (local $e__5 (ref null $str))
    local.get $settled
    local.set $__case_0
    local.get $__case_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    local.set $_v__4
    global.get $__s1
      )
      (else
    local.get $__case_0
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    local.get $__case_0
    struct.get $result $payload
    ref.cast (ref null $str)
    local.set $e__5
    local.get $e__5
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
  ;; ── started tasks ────────────────────────────────────────────────────────────
  ;; The values of every Async, in input order, or the FIRST `Error` in input
  ;; order. The tasks were started by the caller (`allOf([fetchUser(1),
  ;; fetchUser(2)])`), so on commonJS they run concurrently and this only waits;
  ;; on erlang they already ran. `allOf([])` answers `Ok([])`.
  ;; @Async — a state machine (decision 392)
  (func $allOf (export "allOf") (param $tasks (ref null $arr_any)) (result (ref null $task))
    (local $__fr (ref null $frame3))
    struct.new_default $frame3 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $tasks
    struct.set $frame3 $s0
    i32.const 3 ;; allOf__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $allOf__body (param $__task (ref null $task)) (result (ref null $result))
    (local $tasks (ref null $arr_any))
    (local $__mem0 i32)
    (local $out (ref null $arr_any))
    (local $t i32)
    (local $v i32)
    (local $__frame (ref null $frame3))
    (local $__seek i32)
    (local $__state i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $t__sh0 (ref null $task))
    (local $v__sh1 anyref)
    (local $__gc0 (ref null $result))
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame3)
    local.set $__frame
    local.get $__frame
    struct.get $frame3 $s0
    local.set $tasks
    local.get $__frame
    struct.get $frame3 $s1
    local.set $__mem0
    local.get $__frame
    struct.get $frame3 $s2
    local.set $out
    local.get $__frame
    struct.get $frame3 $s3
    local.set $t
    local.get $__frame
    struct.get $frame3 $s4
    local.set $v
    local.get $__frame
    struct.get $frame3 $s5
    local.set $__iter0
    local.get $__frame
    struct.get $frame3 $s6
    local.set $__idx0
    local.get $__frame
    struct.get $frame3 $s7
    local.set $__len0
    local.get $__frame
    struct.get $frame3 $s8
    local.set $t__sh0
    local.get $__frame
    struct.get $frame3 $s9
    local.set $v__sh1
    local.get $__frame
    struct.get $frame3 $s10
    local.set $__gc0
    local.get $__frame
    struct.get $frame3 $s11
    local.set $__aw1
    local.get $__frame
    struct.get $frame3 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    array.new_fixed $arr_any 0
    local.set $out
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $tasks
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
      )
    )
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $task)
        local.set $t__sh0
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
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
    local.get $t__sh0
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $tasks
    struct.set $frame3 $s0
    local.get $__frame
    local.get $__mem0
    struct.set $frame3 $s1
    local.get $__frame
    local.get $out
    struct.set $frame3 $s2
    local.get $__frame
    local.get $t
    struct.set $frame3 $s3
    local.get $__frame
    local.get $v
    struct.set $frame3 $s4
    local.get $__frame
    local.get $__iter0
    struct.set $frame3 $s5
    local.get $__frame
    local.get $__idx0
    struct.set $frame3 $s6
    local.get $__frame
    local.get $__len0
    struct.set $frame3 $s7
    local.get $__frame
    local.get $t__sh0
    struct.set $frame3 $s8
    local.get $__frame
    local.get $v__sh1
    struct.set $frame3 $s9
    local.get $__frame
    local.get $__gc0
    struct.set $frame3 $s10
    local.get $__frame
    local.get $__aw1
    struct.set $frame3 $s11
    local.get $__frame
    i32.const 1
    struct.set $frame3 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $result
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $result)
    local.set $__gc0
    local.get $__gc0
    struct.get $result $tag
    (if
      (then
    local.get $__gc0
    return ;; propagate Error
      )
    )
    local.get $__gc0
    struct.get $result $payload
    local.set $v__sh1
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $out
    local.get $v__sh1
    call $__arr_push_any
    local.set $out
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
      )
    )
    i32.const 0
    local.get $out
    struct.new $result
    return
  )
  (func $allOf__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $allOf__body
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
  ;; The values of every Async, in input order — the infallible `allOf`.
  ;; @Async — a state machine (decision 392)
  (func $all (export "all") (param $tasks (ref null $arr_any)) (result (ref null $task))
    (local $__fr (ref null $frame4))
    struct.new_default $frame4 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $tasks
    struct.set $frame4 $s0
    i32.const 4 ;; all__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $all__body (param $__task (ref null $task)) (result (ref null $arr_any))
    (local $tasks (ref null $arr_any))
    (local $__mem0 i32)
    (local $out (ref null $arr_any))
    (local $t i32)
    (local $v i32)
    (local $__frame (ref null $frame4))
    (local $__seek i32)
    (local $__state i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $t__sh2 (ref null $task))
    (local $v__sh3 anyref)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame4)
    local.set $__frame
    local.get $__frame
    struct.get $frame4 $s0
    local.set $tasks
    local.get $__frame
    struct.get $frame4 $s1
    local.set $__mem0
    local.get $__frame
    struct.get $frame4 $s2
    local.set $out
    local.get $__frame
    struct.get $frame4 $s3
    local.set $t
    local.get $__frame
    struct.get $frame4 $s4
    local.set $v
    local.get $__frame
    struct.get $frame4 $s5
    local.set $__iter0
    local.get $__frame
    struct.get $frame4 $s6
    local.set $__idx0
    local.get $__frame
    struct.get $frame4 $s7
    local.set $__len0
    local.get $__frame
    struct.get $frame4 $s8
    local.set $t__sh2
    local.get $__frame
    struct.get $frame4 $s9
    local.set $v__sh3
    local.get $__frame
    struct.get $frame4 $s10
    local.set $__aw1
    local.get $__frame
    struct.get $frame4 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    array.new_fixed $arr_any 0
    local.set $out
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $tasks
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
      )
    )
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $task)
        local.set $t__sh2
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
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
    local.get $t__sh2
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $tasks
    struct.set $frame4 $s0
    local.get $__frame
    local.get $__mem0
    struct.set $frame4 $s1
    local.get $__frame
    local.get $out
    struct.set $frame4 $s2
    local.get $__frame
    local.get $t
    struct.set $frame4 $s3
    local.get $__frame
    local.get $v
    struct.set $frame4 $s4
    local.get $__frame
    local.get $__iter0
    struct.set $frame4 $s5
    local.get $__frame
    local.get $__idx0
    struct.set $frame4 $s6
    local.get $__frame
    local.get $__len0
    struct.set $frame4 $s7
    local.get $__frame
    local.get $t__sh2
    struct.set $frame4 $s8
    local.get $__frame
    local.get $v__sh3
    struct.set $frame4 $s9
    local.get $__frame
    local.get $__aw1
    struct.set $frame4 $s10
    local.get $__frame
    i32.const 1
    struct.set $frame4 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $arr_any
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    local.set $v__sh3
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $out
    local.get $v__sh3
    call $__arr_push_any
    local.set $out
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
      )
    )
    local.get $out
    return
  )
  (func $all__step (param $__task (ref null $task))
    (local $__v (ref null $arr_any))
    local.get $__task
    call $all__body
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
  ;; commonJS: the FASTEST Async to answer, `Promise.race`.
  ;; ERLANG: ELEMENT ZERO. Every Async resolved before the call, so there is no
  ;; timing left to measure and this answers the first element of the list. That
  ;; is not a bug to be fixed here and no server front may depend on it — use
  ;; `raceOf`, whose tasks are unstarted when it receives them. Both behaviours
  ;; are pinned by `async: race ---- commonJS fastest, erlang element zero`.
  ;; 
  ;; `race([])` is a programming error, fatal on both targets
  ;; (`async.race: empty task list`).
  ;; race — .Wasm(wasi: .Race)
  (func $race (export "race") (param $tasks (ref null $arr_any)) (result (ref null $task))
    local.get $tasks
    call $__task_race
  )
  ;; ── unstarted tasks ──────────────────────────────────────────────────────────
  ;; Run every task concurrently and answer their values in the ORDER OF THE
  ;; INPUT rather than the order they finished. A task over a `Result` answers
  ;; its `Result` in its slot, so `runAll` of fallible tasks is the settled
  ;; view: nothing is hidden and nothing stops early.
  ;; 
  ;; Node: each thunk is called and the Promises go to `Promise.all`, a failing
  ;; task (decision 432) read as the `{ ok }` / `{ error }` value `await` reads.
  ;; Erlang: `spawn` one process per task, each tagged `{Ref, I, Outcome}` with a
  ;; `make_ref()` unique to THIS call — without the ref a later combinator in the
  ;; same process would receive a loser's leftover reply — and gather by index, so
  ;; a task that finishes first does not take another task's slot. A task that
  ;; crashes is a crash (a crash is a bug, never a failure), re-raised here
  ;; rather than left to block the gather.
  ;; spawnAll — .Wasm(wasi: .SpawnAll)
  (func $spawnAll (param $tasks (ref null $arr_any)) (result (ref null $task))
    local.get $tasks
    call $__task_spawn_all
  )
  ;; The public face of the cell above: a real function, so a module compiled
  ;; separately (the BEAM backend links modules by name) can call it — a
  ;; template-only `declare fn` has no body to export.
  ;; @Async — a state machine (decision 392)
  (func $runAll (export "runAll") (param $tasks (ref null $arr_any)) (result (ref null $task))
    (local $__fr (ref null $frame5))
    struct.new_default $frame5 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $tasks
    struct.set $frame5 $s0
    i32.const 5 ;; runAll__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $runAll__body (param $__task (ref null $task)) (result (ref null $arr_any))
    (local $tasks (ref null $arr_any))
    (local $__frame (ref null $frame5))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame5)
    local.set $__frame
    local.get $__frame
    struct.get $frame5 $s0
    local.set $tasks
    local.get $__frame
    struct.get $frame5 $s1
    local.set $__aw1
    local.get $__frame
    struct.get $frame5 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
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
    local.get $tasks
    call $spawnAll
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $tasks
    struct.set $frame5 $s0
    local.get $__frame
    local.get $__aw1
    struct.set $frame5 $s1
    local.get $__frame
    i32.const 1
    struct.set $frame5 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $arr_any
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $arr_any)
    return
  )
  (func $runAll__step (param $__task (ref null $task))
    (local $__v (ref null $arr_any))
    local.get $__task
    call $runAll__body
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
  ;; The first task to ANSWER, not the first in the list. The LOSERS keep
  ;; running and their values are discarded: there is no cancellation surface in
  ;; botopink, and a race that reported the loser would not be a race.
  ;; 
  ;; `raceOf([])` is a programming error, fatal on both targets
  ;; (`async.raceOf: empty task list`), rather than blocking forever.
  ;; raceOf — .Wasm(wasi: .RaceOf)
  (func $raceOf (export "raceOf") (param $tasks (ref null $arr_any)) (result (ref null $task))
    local.get $tasks
    call $__task_race_of
  )
  ;; `task`'s value as `Ok` — the racer `timeout` puts beside the clock.
  ;; @Async — a state machine (decision 392)
  (func $answered (param $task (ref null $closure)) (result (ref null $task))
    (local $__fr (ref null $frame6))
    struct.new_default $frame6 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $task
    struct.set $frame6 $s0
    i32.const 6 ;; answered__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $answered__body (param $__task (ref null $task)) (result (ref null $result))
    (local $task (ref null $closure))
    (local $__frame (ref null $frame6))
    (local $__seek i32)
    (local $__state i32)
    (local $__fnv0 (ref null $closure))
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame6)
    local.set $__frame
    local.get $__frame
    struct.get $frame6 $s0
    local.set $task
    local.get $__frame
    struct.get $frame6 $s1
    local.set $__fnv0
    local.get $__frame
    struct.get $frame6 $s2
    local.set $__aw1
    local.get $__frame
    struct.get $frame6 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
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
    local.get $task
    local.set $__fnv0
    local.get $__fnv0
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_0)
    call_ref $sig_0
    ref.cast (ref null $task)
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $task
    struct.set $frame6 $s0
    local.get $__frame
    local.get $__fnv0
    struct.set $frame6 $s1
    local.get $__frame
    local.get $__aw1
    struct.set $frame6 $s2
    local.get $__frame
    i32.const 1
    struct.set $frame6 $resume ;; the resume index
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
  (func $answered__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $answered__body
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
  ;; `Error("timeout")` after `millis` — the clock `timeout` races against
  ;; `task`, whose type it answers in (decision 668: `task` binds `T`).
  ;; @Async — a state machine (decision 392)
  (func $expireAfter (param $task (ref null $closure)) (param $millis i32) (result (ref null $task))
    (local $__fr (ref null $frame7))
    struct.new_default $frame7 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $task
    struct.set $frame7 $s0
    local.get $__fr
    local.get $millis
    struct.set $frame7 $s1
    i32.const 7 ;; expireAfter__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $expireAfter__body (param $__task (ref null $task)) (result (ref null $result))
    (local $task (ref null $closure))
    (local $millis i32)
    (local $__frame (ref null $frame7))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame7)
    local.set $__frame
    local.get $__frame
    struct.get $frame7 $s0
    local.set $task
    local.get $__frame
    struct.get $frame7 $s1
    local.set $millis
    local.get $__frame
    struct.get $frame7 $s2
    local.set $__aw1
    local.get $__frame
    struct.get $frame7 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
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
    local.get $millis
    i32.const 0
    struct.new $box_i32
    call $delay
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $task
    struct.set $frame7 $s0
    local.get $__frame
    local.get $millis
    struct.set $frame7 $s1
    local.get $__frame
    local.get $__aw1
    struct.set $frame7 $s2
    local.get $__frame
    i32.const 1
    struct.set $frame7 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $result
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    drop
      )
    )
    i32.const 1
    global.get $__s2
    struct.new $result
    return
  )
  (func $expireAfter__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $expireAfter__body
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
  ;; `Ok(value)` when the task answered inside the budget, `Error("timeout")`
  ;; when it did not. A task over a `Result` keeps its own failure INSIDE the
  ;; `Ok` (`Ok(Error(e))`): the budget and the task's outcome are two answers,
  ;; and neither hides the other. The task KEEPS RUNNING; the caller stops
  ;; waiting. Expressed over `raceOf` + `delay`.
  ;; @Async — a state machine (decision 392)
  (func $timeout (export "timeout") (param $task (ref null $closure)) (param $millis i32) (result (ref null $task))
    (local $__fr (ref null $frame8))
    struct.new_default $frame8 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $task
    struct.set $frame8 $s0
    local.get $__fr
    local.get $millis
    struct.set $frame8 $s1
    i32.const 8 ;; timeout__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $timeout__body (param $__task (ref null $task)) (result (ref null $result))
    (local $task (ref null $closure))
    (local $millis i32)
    (local $__mem0 i32)
    (local $__frame (ref null $frame8))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame8)
    local.set $__frame
    local.get $__frame
    struct.get $frame8 $s0
    local.set $task
    local.get $__frame
    struct.get $frame8 $s1
    local.set $millis
    local.get $__frame
    struct.get $frame8 $s2
    local.set $__mem0
    local.get $__frame
    struct.get $frame8 $s3
    local.set $__aw1
    local.get $__frame
    struct.get $frame8 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
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
    ref.func $__lambda0
    i32.const 0 ;; arity
    i32.const 0
    local.get $task ;; capture task
    struct.new $env0
    ref.func $__lambda1
    i32.const 0 ;; arity
    i32.const 0
    local.get $task ;; capture task
    local.get $millis ;; capture millis
    struct.new $env1
    array.new_fixed $arr_any 2
    call $raceOf
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $task
    struct.set $frame8 $s0
    local.get $__frame
    local.get $millis
    struct.set $frame8 $s1
    local.get $__frame
    local.get $__mem0
    struct.set $frame8 $s2
    local.get $__frame
    local.get $__aw1
    struct.set $frame8 $s3
    local.get $__frame
    i32.const 1
    struct.set $frame8 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $result
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $result)
    return
  )
  (func $timeout__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $timeout__body
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
  ;; ── retry (1.0.11-beta front 97) ─────────────────────────────────────────────
  ;; How a fallible task is tried again: at most `maxAttempts` attempts, a pause
  ;; of `initialMillis` after the first failure, each later pause `multiplier`
  ;; times the one before, none above `maxMillis`. There is no jitter and no
  ;; field that means "for ever" (decision 67): a policy is usable only when
  ;; `maxAttempts` is at least 1, the two delays are not negative, `maxMillis`
  ;; is at most 2147483647 (the longest timer both targets arm) and `multiplier`
  ;; is at least 1.0 — a backoff never shrinks, and one that could would retry
  ;; in a near-zero-delay loop.
  ;; Internal: why `policy` is not usable, `""` when it is.
  (func $policyProblem (param $policy (ref null $rec_RetryPolicy)) (result (ref null $str))
    (local $grows i32)
    local.get $policy
    struct.get $rec_RetryPolicy $f0
    i32.const 1
    i32.lt_s
    (if (result (ref null $str))
      (then
    global.get $__s3
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $policy
    struct.get $rec_RetryPolicy $f1
    i32.const 0
    i64.extend_i32_s
    i64.lt_s
    (if (result (ref null $str))
      (then
    global.get $__s4
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $policy
    struct.get $rec_RetryPolicy $f3
    i32.const 0
    i64.extend_i32_s
    i64.lt_s
    (if (result (ref null $str))
      (then
    global.get $__s5
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $policy
    struct.get $rec_RetryPolicy $f3
    i32.const 2147483647
    i64.extend_i32_s
    i64.gt_s
    (if (result (ref null $str))
      (then
    global.get $__s6
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    local.get $policy
    struct.get $rec_RetryPolicy $f2
    f64.const 1.0
    f64.ge
    local.set $grows
    local.get $grows
    i32.const 0
    i32.eq
    (if (result (ref null $str))
      (then
    global.get $__s7
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    global.get $__s1
    return
  )
  ;; Internal: an `i64` of milliseconds as an `f64`, and back — the whole
  ;; milliseconds of a delay that is never negative. Not `toF64()`, which aborts
  ;; on an integer past 2^53 that no `f64` holds: the delay is a float
  ;; computation, and an `initialMillis` that large rounds as the float does
  ;; (and is then capped by `maxMillis`). The Node forms take and answer
  ;; decision 319's canonical form — `Number` reads a `BigInt` (`initialMillis`
  ;; past 2^53 − 1), and a whole number past 2^53 − 1 answers as a `BigInt`.
  ;; millisAsFloat — .Wasm(op: "f64.convert_i64_s")
  (func $millisAsFloat (param $n i64) (result f64)
    local.get $n
    f64.convert_i64_s
  )
  ;; wholeMillis — .Wasm(op: "i64.trunc_f64_s")
  (func $wholeMillis (param $x f64) (result i64)
    local.get $x
    i64.trunc_f64_s
  )
  ;; Internal: `initial × multiplier^(attempt − 1)`, never above `ceiling`. One
  ;; multiplication per attempt — the same IEEE operations in the same order on
  ;; both targets, where a host `pow` would not promise the same last bit — and
  ;; none once the ceiling is reached, so it cannot overflow.
  (func $grown (param $initial f64) (param $multiplier f64) (param $ceiling f64) (param $attempt i32) (result f64)
    (local $steady i32)
    (local $pause f64)
    (local $step i32)
    local.get $multiplier
    f64.const 1.0
    f64.le
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $initial
    f64.const 0.0
    f64.le
      )
    )
    local.set $steady
    local.get $steady
    (if (result f64)
      (then
    local.get $initial
    local.get $ceiling
    f64.gt
    (if (result f64)
      (then
    local.get $ceiling
      )
      (else
    local.get $initial
      )
    )
    return
      )
      (else
        f64.const 0
      )
    )
    drop
    local.get $initial
    local.set $pause
    i32.const 1
    local.set $step
    (block $__break
      (loop $__continue
    local.get $step
    local.get $attempt
    i32.lt_s
    (if (result i32)
      (then
    local.get $pause
    local.get $ceiling
    f64.lt
      )
      (else
    i32.const 0
      )
    )
        i32.eqz
        br_if $__break
    local.get $pause
    local.get $multiplier
    f64.mul
    local.set $pause
    local.get $step
    i32.const 1
    global.get $__s8
    call $__i32_add_chk
    local.set $step
        br $__continue
      )
    )
    i32.const 0
    drop
    local.get $pause
    local.get $ceiling
    f64.gt
    (if (result f64)
      (then
    local.get $ceiling
      )
      (else
    local.get $pause
      )
    )
    return
  )
  ;; The pause that follows attempt `attempt` (the first attempt is 1), in whole
  ;; milliseconds: `initialMillis × multiplier^(attempt − 1)`, rounded down and
  ;; never above `maxMillis`. `null` once `attempt` is past `maxAttempts` — there
  ;; is no further attempt to wait for — and for an attempt below 1 or a policy
  ;; that is not usable.
  (func $nextDelay (export "nextDelay") (param $policy (ref null $rec_RetryPolicy)) (param $attempt i32) (result anyref)
    (local $usable i32)
    (local $inside i32)
    (local $answers i32)
    local.get $policy
    call $policyProblem
    global.get $__s1
    call $__str_eq
    local.set $usable
    local.get $attempt
    i32.const 1
    i32.ge_s
    (if (result i32)
      (then
    local.get $attempt
    local.get $policy
    struct.get $rec_RetryPolicy $f0
    i32.le_s
      )
      (else
    i32.const 0
      )
    )
    local.set $inside
    local.get $usable
    (if (result i32)
      (then
    local.get $inside
      )
      (else
    i32.const 0
      )
    )
    local.set $answers
    local.get $answers
    i32.const 0
    i32.eq
    (if (result anyref)
      (then
    ref.null any
    return
      )
      (else
        ref.null any
      )
    )
    drop
    local.get $policy
    struct.get $rec_RetryPolicy $f1
    call $millisAsFloat
    local.get $policy
    struct.get $rec_RetryPolicy $f2
    local.get $policy
    struct.get $rec_RetryPolicy $f3
    call $millisAsFloat
    local.get $attempt
    call $grown
    call $wholeMillis
    struct.new $box_i64
    return
  )
  ;; Internal: attempt number `attempt` of `retry`, and every one after it.
  ;; @Async — a state machine (decision 392)
  (func $retryFrom (param $policy (ref null $rec_RetryPolicy)) (param $work (ref null $closure)) (param $attempt i32) (result (ref null $task))
    (local $__fr (ref null $frame9))
    struct.new_default $frame9 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $policy
    struct.set $frame9 $s0
    local.get $__fr
    local.get $work
    struct.set $frame9 $s1
    local.get $__fr
    local.get $attempt
    struct.set $frame9 $s2
    i32.const 9 ;; retryFrom__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $retryFrom__body (param $__task (ref null $task)) (result (ref null $result))
    (local $policy (ref null $rec_RetryPolicy))
    (local $work (ref null $closure))
    (local $attempt i32)
    (local $outcome (ref null $result))
    (local $settled i32)
    (local $pause i64)
    (local $__bp_nullish i64)
    (local $__frame (ref null $frame9))
    (local $__seek i32)
    (local $__state i32)
    (local $__fnv0 (ref null $closure))
    (local $__aw1 (ref null $task))
    (local $__cnd1 i32)
    (local $__opt2 anyref)
    (local $__conv0 i64)
    (local $__aw2 (ref null $task))
    (local $__aw3 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame9)
    local.set $__frame
    local.get $__frame
    struct.get $frame9 $s0
    local.set $policy
    local.get $__frame
    struct.get $frame9 $s1
    local.set $work
    local.get $__frame
    struct.get $frame9 $s2
    local.set $attempt
    local.get $__frame
    struct.get $frame9 $s3
    local.set $outcome
    local.get $__frame
    struct.get $frame9 $s4
    local.set $settled
    local.get $__frame
    struct.get $frame9 $s5
    local.set $pause
    local.get $__frame
    struct.get $frame9 $s6
    local.set $__bp_nullish
    local.get $__frame
    struct.get $frame9 $s7
    local.set $__fnv0
    local.get $__frame
    struct.get $frame9 $s8
    local.set $__aw1
    local.get $__frame
    struct.get $frame9 $s9
    local.set $__cnd1
    local.get $__frame
    struct.get $frame9 $s10
    local.set $__opt2
    local.get $__frame
    struct.get $frame9 $s11
    local.set $__conv0
    local.get $__frame
    struct.get $frame9 $s12
    local.set $__aw2
    local.get $__frame
    struct.get $frame9 $s13
    local.set $__aw3
    local.get $__frame
    struct.get $frame9 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
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
    local.get $work
    local.set $__fnv0
    local.get $__fnv0
    local.get $__fnv0
    struct.get $closure $fn ;; the entry
    ref.cast (ref null $sig_0)
    call_ref $sig_0
    ref.cast (ref null $task)
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $policy
    struct.set $frame9 $s0
    local.get $__frame
    local.get $work
    struct.set $frame9 $s1
    local.get $__frame
    local.get $attempt
    struct.set $frame9 $s2
    local.get $__frame
    local.get $outcome
    struct.set $frame9 $s3
    local.get $__frame
    local.get $settled
    struct.set $frame9 $s4
    local.get $__frame
    local.get $pause
    struct.set $frame9 $s5
    local.get $__frame
    local.get $__bp_nullish
    struct.set $frame9 $s6
    local.get $__frame
    local.get $__fnv0
    struct.set $frame9 $s7
    local.get $__frame
    local.get $__aw1
    struct.set $frame9 $s8
    local.get $__frame
    local.get $__cnd1
    struct.set $frame9 $s9
    local.get $__frame
    local.get $__opt2
    struct.set $frame9 $s10
    local.get $__frame
    local.get $__conv0
    struct.set $frame9 $s11
    local.get $__frame
    local.get $__aw2
    struct.set $frame9 $s12
    local.get $__frame
    local.get $__aw3
    struct.set $frame9 $s13
    local.get $__frame
    i32.const 1
    struct.set $frame9 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $result
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $result)
    local.set $outcome
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $outcome
    struct.get $result $tag
    i32.eqz
    (if (result i32)
      (then
    i32.const 1
      )
      (else
    local.get $attempt
    local.get $policy
    struct.get $rec_RetryPolicy $f0
    i32.ge_s
      )
    )
    local.set $settled
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd1 ;; the condition, read back
      )
      (else
    local.get $settled
    local.tee $__cnd1
      )
    )
    (if (result (ref null $result))
      (then
    local.get $outcome
    return
      )
      (else
        ref.null $result
      )
    )
    drop
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result anyref)
      (then
    local.get $__opt2 ;; the condition, read back
      )
      (else
    local.get $policy
    local.get $attempt
    call $nextDelay
    local.tee $__opt2
      )
    )
    ref.is_null
    i32.eqz
    (if (result i64)
      (then
    local.get $__opt2
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    local.set $__bp_nullish
    local.get $__bp_nullish
      )
      (else
    local.get $policy
    struct.get $rec_RetryPolicy $f3
      )
    )
    local.set $pause
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 2
    i32.ge_u
    local.get $__state
    i32.const 2
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    (block $__aw2
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 2
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
    br $__aw2 ;; resumed here
      )
    )
    br $__aw2 ;; resuming past this await
      )
    )
    local.get $pause
    local.set $__conv0
    local.get $__conv0
    i64.const -2147483648
    i64.ge_s
    local.get $__conv0
    i64.const 2147483647
    i64.le_s
    i32.and
    i32.eqz
    (if
      (then
    global.get $__s9
    local.get $__conv0
    call $__std_number_i64ToString
    call $__str_concat
    global.get $__s10
    call $__str_concat
    call $__panic_fail
    unreachable
      )
    )
    local.get $__conv0
    i32.wrap_i64
    i32.const 0
    struct.new $box_i32
    call $delay
    local.set $__aw2
    local.get $__aw2
    call $__task_pending
    (if
      (then
    local.get $__aw2
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $policy
    struct.set $frame9 $s0
    local.get $__frame
    local.get $work
    struct.set $frame9 $s1
    local.get $__frame
    local.get $attempt
    struct.set $frame9 $s2
    local.get $__frame
    local.get $outcome
    struct.set $frame9 $s3
    local.get $__frame
    local.get $settled
    struct.set $frame9 $s4
    local.get $__frame
    local.get $pause
    struct.set $frame9 $s5
    local.get $__frame
    local.get $__bp_nullish
    struct.set $frame9 $s6
    local.get $__frame
    local.get $__fnv0
    struct.set $frame9 $s7
    local.get $__frame
    local.get $__aw1
    struct.set $frame9 $s8
    local.get $__frame
    local.get $__cnd1
    struct.set $frame9 $s9
    local.get $__frame
    local.get $__opt2
    struct.set $frame9 $s10
    local.get $__frame
    local.get $__conv0
    struct.set $frame9 $s11
    local.get $__frame
    local.get $__aw2
    struct.set $frame9 $s12
    local.get $__frame
    local.get $__aw3
    struct.set $frame9 $s13
    local.get $__frame
    i32.const 2
    struct.set $frame9 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $result
    return ;; suspended
      )
    )
    )
    local.get $__aw2
    struct.get $task $value ;; the settled value
    drop
      )
    )
    (block $__aw3
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 3
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
    br $__aw3 ;; resumed here
      )
    )
    br $__aw3 ;; resuming past this await
      )
    )
    local.get $policy
    local.get $work
    local.get $attempt
    i32.const 1
    global.get $__s11
    call $__i32_add_chk
    call $retryFrom
    local.set $__aw3
    local.get $__aw3
    call $__task_pending
    (if
      (then
    local.get $__aw3
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $policy
    struct.set $frame9 $s0
    local.get $__frame
    local.get $work
    struct.set $frame9 $s1
    local.get $__frame
    local.get $attempt
    struct.set $frame9 $s2
    local.get $__frame
    local.get $outcome
    struct.set $frame9 $s3
    local.get $__frame
    local.get $settled
    struct.set $frame9 $s4
    local.get $__frame
    local.get $pause
    struct.set $frame9 $s5
    local.get $__frame
    local.get $__bp_nullish
    struct.set $frame9 $s6
    local.get $__frame
    local.get $__fnv0
    struct.set $frame9 $s7
    local.get $__frame
    local.get $__aw1
    struct.set $frame9 $s8
    local.get $__frame
    local.get $__cnd1
    struct.set $frame9 $s9
    local.get $__frame
    local.get $__opt2
    struct.set $frame9 $s10
    local.get $__frame
    local.get $__conv0
    struct.set $frame9 $s11
    local.get $__frame
    local.get $__aw2
    struct.set $frame9 $s12
    local.get $__frame
    local.get $__aw3
    struct.set $frame9 $s13
    local.get $__frame
    i32.const 3
    struct.set $frame9 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $result
    return ;; suspended
      )
    )
    )
    local.get $__aw3
    struct.get $task $value ;; the settled value
    ref.cast (ref null $result)
    return
  )
  (func $retryFrom__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $retryFrom__body
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
  ;; Run `work` until it answers `Ok`, at most `policy.maxAttempts` times, pausing
  ;; `nextDelay(policy, n)` after failed attempt `n`. `Ok` is answered as soon as
  ;; an attempt succeeds; when every attempt fails, the LAST `Error` is answered —
  ;; the task fails with it, in `timeout`'s shape. `work` is a thunk because
  ;; each attempt has to start the task again; a plain `Async<T>` never fails
  ;; (decisions 120, 432), so there is nothing to retry over one.
  ;; 
  ;; A policy that is not usable is a programming error, fatal on both targets
  ;; (`async.retry: maxAttempts must be at least 1 (the first attempt)`), like
  ;; `race([])` — not an `Error` a caller could mistake for the work's own.
  ;; @Async — a state machine (decision 392)
  (func $retry (export "retry") (param $policy (ref null $rec_RetryPolicy)) (param $work (ref null $closure)) (result (ref null $task))
    (local $__fr (ref null $frame10))
    struct.new_default $frame10 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $policy
    struct.set $frame10 $s0
    local.get $__fr
    local.get $work
    struct.set $frame10 $s1
    i32.const 10 ;; retry__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $retry__body (param $__task (ref null $task)) (result (ref null $result))
    (local $policy (ref null $rec_RetryPolicy))
    (local $work (ref null $closure))
    (local $__mem0 i32)
    (local $problem (ref null $str))
    (local $__frame (ref null $frame10))
    (local $__seek i32)
    (local $__state i32)
    (local $__cnd0 i32)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame10)
    local.set $__frame
    local.get $__frame
    struct.get $frame10 $s0
    local.set $policy
    local.get $__frame
    struct.get $frame10 $s1
    local.set $work
    local.get $__frame
    struct.get $frame10 $s2
    local.set $__mem0
    local.get $__frame
    struct.get $frame10 $s3
    local.set $problem
    local.get $__frame
    struct.get $frame10 $s4
    local.set $__cnd0
    local.get $__frame
    struct.get $frame10 $s5
    local.set $__aw1
    local.get $__frame
    struct.get $frame10 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $policy
    call $policyProblem
    local.set $problem
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd0 ;; the condition, read back
      )
      (else
    local.get $problem
    global.get $__s1
    call $__str_eq
    i32.eqz
    local.tee $__cnd0
      )
    )
    (if (result (ref null $result))
      (then
    global.get $__s12
    local.get $problem
    array.new_fixed $arr_any 2
    global.get $__s1
    call $__arr_join_any
    call $__panic_fail
    unreachable
    ref.null $result
      )
      (else
        ref.null $result
      )
    )
    drop
      )
    )
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
    local.get $policy
    local.get $work
    i32.const 1
    call $retryFrom
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $policy
    struct.set $frame10 $s0
    local.get $__frame
    local.get $work
    struct.set $frame10 $s1
    local.get $__frame
    local.get $__mem0
    struct.set $frame10 $s2
    local.get $__frame
    local.get $problem
    struct.set $frame10 $s3
    local.get $__frame
    local.get $__cnd0
    struct.set $frame10 $s4
    local.get $__frame
    local.get $__aw1
    struct.set $frame10 $s5
    local.get $__frame
    i32.const 1
    struct.set $frame10 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $result
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $result)
    return
  )
  (func $retry__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $retry__body
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
  ;; ── tests ────────────────────────────────────────────────────────────────────
  ;; Inline, the way every std module does it, run by `botopink test` and
  ;; `botopink test --target erlang` from `libs/std/`. Every verdict here is the
  ;; same on an idle machine and a loaded one. Three kinds of assertion:
  ;;   · results and order — deterministic on both targets;
  ;;   · ORDER BY SIGNAL — "a concurrent combinator ran task B while task A was
  ;;     still waiting", "the race was won by the task that answered" — told with
  ;;     a gate one task opens and another awaits, never with a pair of `delay`s
  ;;     and an elapsed-time budget: under load a 10 ms timer can fire after an
  ;;     80 ms one on erlang, and a sequential map can still finish inside
  ;;     "roughly double the longest task". A gate's budget (`gateBudget`) only
  ;;     turns a gate nobody opens into a red assertion instead of a hang;
  ;;   · a LOWER bound on elapsed time where the behaviour is a duration
  ;;     (`delay`, `timeout`'s budget) — a promise the cells keep however busy the
  ;;     machine is. There is no upper bound anywhere: an upper bound on elapsed
  ;;     time measures the machine, not the code;
  ;; plus DOCUMENTED DIVERGENCE (the started surface's erlang behaviour asserted
  ;; as itself, so a backend change that makes erlang lazy reds a test instead of
  ;; silently making the docblock a lie).
  ;; 
  ;; `async` is not snapshotted (`01-std/test-snap.md`).
  ;; How long a test task waits on a gate before it gives up. Every gate a test
  ;; closes is opened again, so this passes only when the code under test is
  ;; wrong — and then as a red assertion, not a hang.
  (global $gateBudget i32 (i32.const 10000))
  ;; `value` once `gate` opens; a value naming the failure when it never does.
  ;; @Async — a state machine (decision 392)
  (func $gated (param $gate (ref null $rec_Gate)) (param $value (ref null $str)) (result (ref null $task))
    (local $__fr (ref null $frame11))
    struct.new_default $frame11 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $gate
    struct.set $frame11 $s0
    local.get $__fr
    local.get $value
    struct.set $frame11 $s1
    i32.const 11 ;; gated__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $gated__body (param $__task (ref null $task)) (result (ref null $str))
    (local $gate (ref null $rec_Gate))
    (local $value (ref null $str))
    (local $opened i32)
    (local $__frame (ref null $frame11))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    (local $__cnd0 i32)
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame11)
    local.set $__frame
    local.get $__frame
    struct.get $frame11 $s0
    local.set $gate
    local.get $__frame
    struct.get $frame11 $s1
    local.set $value
    local.get $__frame
    struct.get $frame11 $s2
    local.set $opened
    local.get $__frame
    struct.get $frame11 $s3
    local.set $__aw1
    local.get $__frame
    struct.get $frame11 $s4
    local.set $__cnd0
    local.get $__frame
    struct.get $frame11 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
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
    local.get $gate
    global.get $gateBudget
    call $awaitGate
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $gate
    struct.set $frame11 $s0
    local.get $__frame
    local.get $value
    struct.set $frame11 $s1
    local.get $__frame
    local.get $opened
    struct.set $frame11 $s2
    local.get $__frame
    local.get $__aw1
    struct.set $frame11 $s3
    local.get $__frame
    local.get $__cnd0
    struct.set $frame11 $s4
    local.get $__frame
    i32.const 1
    struct.set $frame11 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $str
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    local.set $opened
      )
    )
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd0 ;; the condition, read back
      )
      (else
    local.get $opened
    local.tee $__cnd0
      )
    )
    (if (result (ref null $str))
      (then
    local.get $value
      )
      (else
    global.get $__s13
    local.get $value
    call $__str_concat
      )
    )
    return
  )
  (func $gated__step (param $__task (ref null $task))
    (local $__v (ref null $str))
    local.get $__task
    call $gated__body
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
  ;; Open `mine`, then answer `value` once `theirs` is open. Two of these over the
  ;; same pair of gates, crossed, can only BOTH answer when they run at the same
  ;; time: whichever runs first alone waits on a gate the other has not opened.
  ;; @Async — a state machine (decision 392)
  (func $handshake (param $mine (ref null $rec_Gate)) (param $theirs (ref null $rec_Gate)) (param $value (ref null $str)) (result (ref null $task))
    (local $__fr (ref null $frame12))
    struct.new_default $frame12 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $mine
    struct.set $frame12 $s0
    local.get $__fr
    local.get $theirs
    struct.set $frame12 $s1
    local.get $__fr
    local.get $value
    struct.set $frame12 $s2
    i32.const 12 ;; handshake__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $handshake__body (param $__task (ref null $task)) (result (ref null $str))
    (local $mine (ref null $rec_Gate))
    (local $theirs (ref null $rec_Gate))
    (local $value (ref null $str))
    (local $__frame (ref null $frame12))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame12)
    local.set $__frame
    local.get $__frame
    struct.get $frame12 $s0
    local.set $mine
    local.get $__frame
    struct.get $frame12 $s1
    local.set $theirs
    local.get $__frame
    struct.get $frame12 $s2
    local.set $value
    local.get $__frame
    struct.get $frame12 $s3
    local.set $__aw1
    local.get $__frame
    struct.get $frame12 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $mine
    call $openGate
    drop
      )
    )
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
    local.get $theirs
    local.get $value
    call $gated
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $mine
    struct.set $frame12 $s0
    local.get $__frame
    local.get $theirs
    struct.set $frame12 $s1
    local.get $__frame
    local.get $value
    struct.set $frame12 $s2
    local.get $__frame
    local.get $__aw1
    struct.set $frame12 $s3
    local.get $__frame
    i32.const 1
    struct.set $frame12 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $str
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $str)
    return
  )
  (func $handshake__step (param $__task (ref null $task))
    (local $__v (ref null $str))
    local.get $__task
    call $handshake__body
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
  ;; `value` with no timer at all: resolved in the microtask queue on commonJS,
  ;; the process's first reply on erlang.
  ;; @Async — a state machine (decision 392)
  (func $answerNow (param $value (ref null $str)) (result (ref null $task))
    (local $__fr (ref null $frame13))
    struct.new_default $frame13 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $value
    struct.set $frame13 $s0
    i32.const 13 ;; answerNow__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $answerNow__body (param $__task (ref null $task)) (result (ref null $str))
    (local $value (ref null $str))
    (local $__frame (ref null $frame13))
    (local $__seek i32)
    (local $__state i32)
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame13)
    local.set $__frame
    local.get $__frame
    struct.get $frame13 $s0
    local.set $value
    local.get $__frame
    struct.get $frame13 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $value
    return
  )
  (func $answerNow__step (param $__task (ref null $task))
    (local $__v (ref null $str))
    local.get $__task
    call $answerNow__body
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
  ;; ── delay and failed ─────────────────────────────────────────────────────────
  ;; ── gates ────────────────────────────────────────────────────────────────────
  ;; ── allOf and all ────────────────────────────────────────────────────────────
  ;; @Async — a state machine (decision 392)
  (func $slowOk (param $millis i32) (param $value (ref null $str)) (result (ref null $task))
    (local $__fr (ref null $frame14))
    struct.new_default $frame14 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $millis
    struct.set $frame14 $s0
    local.get $__fr
    local.get $value
    struct.set $frame14 $s1
    i32.const 14 ;; slowOk__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $slowOk__body (param $__task (ref null $task)) (result (ref null $result))
    (local $millis i32)
    (local $value (ref null $str))
    (local $__frame (ref null $frame14))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame14)
    local.set $__frame
    local.get $__frame
    struct.get $frame14 $s0
    local.set $millis
    local.get $__frame
    struct.get $frame14 $s1
    local.set $value
    local.get $__frame
    struct.get $frame14 $s2
    local.set $__aw1
    local.get $__frame
    struct.get $frame14 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
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
    local.get $millis
    local.get $value
    call $delay
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $millis
    struct.set $frame14 $s0
    local.get $__frame
    local.get $value
    struct.set $frame14 $s1
    local.get $__frame
    local.get $__aw1
    struct.set $frame14 $s2
    local.get $__frame
    i32.const 1
    struct.set $frame14 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $result
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $str)
    struct.new $result
    return
  )
  (func $slowOk__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $slowOk__body
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
  ;; ── runAll ───────────────────────────────────────────────────────────────────
  ;; A settled element to stand in for the `?T` fallback of `.at(i)`. `Array.at`
  ;; answers an optional and `unwrapOr` needs a value of the element type, which
  ;; here is itself a `Result`; this is the cheapest way to spell one.
  (func $errorProbe (result (ref null $result))
    i32.const 1
    global.get $__s14
    struct.new $result
    return
  )
  ;; ── raceOf ───────────────────────────────────────────────────────────────────
  ;; ── timeout ──────────────────────────────────────────────────────────────────
  ;; The expired task of the test above: waits for `release`, opens `done` and
  ;; answers.
  ;; @Async — a state machine (decision 392)
  (func $ghost (param $release (ref null $rec_Gate)) (param $done (ref null $rec_Gate)) (result (ref null $task))
    (local $__fr (ref null $frame15))
    struct.new_default $frame15 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $release
    struct.set $frame15 $s0
    local.get $__fr
    local.get $done
    struct.set $frame15 $s1
    i32.const 15 ;; ghost__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $ghost__body (param $__task (ref null $task)) (result (ref null $str))
    (local $release (ref null $rec_Gate))
    (local $done (ref null $rec_Gate))
    (local $v (ref null $str))
    (local $__frame (ref null $frame15))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame15)
    local.set $__frame
    local.get $__frame
    struct.get $frame15 $s0
    local.set $release
    local.get $__frame
    struct.get $frame15 $s1
    local.set $done
    local.get $__frame
    struct.get $frame15 $s2
    local.set $v
    local.get $__frame
    struct.get $frame15 $s3
    local.set $__aw1
    local.get $__frame
    struct.get $frame15 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
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
    local.get $release
    global.get $__s15
    call $gated
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $release
    struct.set $frame15 $s0
    local.get $__frame
    local.get $done
    struct.set $frame15 $s1
    local.get $__frame
    local.get $v
    struct.set $frame15 $s2
    local.get $__frame
    local.get $__aw1
    struct.set $frame15 $s3
    local.get $__frame
    i32.const 1
    struct.set $frame15 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $str
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $str)
    local.set $v
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $done
    call $openGate
    drop
      )
    )
    local.get $v
    return
  )
  (func $ghost__step (param $__task (ref null $task))
    (local $__v (ref null $str))
    local.get $__task
    call $ghost__body
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
  ;; ── retry ────────────────────────────────────────────────────────────────────
  ;; Internal, test scaffolding: a counter the attempts of one `retry` share —
  ;; a closure cannot count on erlang, where a `var` it captures is a copy.
  ;; Node: an object. Erlang: a `counters` reference.
  ;; declare fn newCounter — no wasm implementation (host-backed)
  ;; Count one more and answer the count.
  ;; declare fn countUp — no wasm implementation (host-backed)
  ;; declare fn countOf — no wasm implementation (host-backed)
  ;; The text a task panics with, `""` when it answered — a panic inside a
  ;; `-> Async` function is a rejected Promise on commonJS and a raise on erlang.
  ;; @Async — a state machine (decision 392)
  (func $panicOf (param $body (ref null $closure)) (result (ref null $task))
    (local $__fr (ref null $frame16))
    struct.new_default $frame16 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $body
    struct.set $frame16 $s0
    i32.const 16 ;; panicOf__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $panicOf__body (param $__task (ref null $task)) (result (ref null $str))
    (local $body (ref null $closure))
    (local $r (ref null $result))
    (local $f i32)
    (local $__frame (ref null $frame16))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    (local $__case_0_0 (ref null $result))
    (local $f__6 (ref null $rec_Failure))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame16)
    local.set $__frame
    local.get $__frame
    struct.get $frame16 $s0
    local.set $body
    local.get $__frame
    struct.get $frame16 $s1
    local.set $r
    local.get $__frame
    struct.get $frame16 $s2
    local.set $f
    local.get $__frame
    struct.get $frame16 $s3
    local.set $__aw1
    local.get $__frame
    struct.get $frame16 $s4
    local.set $__case_0_0
    local.get $__frame
    struct.get $frame16 $s5
    local.set $f__6
    local.get $__frame
    struct.get $frame16 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
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
    local.get $body
    call $attemptTask
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $body
    struct.set $frame16 $s0
    local.get $__frame
    local.get $r
    struct.set $frame16 $s1
    local.get $__frame
    local.get $f
    struct.set $frame16 $s2
    local.get $__frame
    local.get $__aw1
    struct.set $frame16 $s3
    local.get $__frame
    local.get $__case_0_0
    struct.set $frame16 $s4
    local.get $__frame
    local.get $f__6
    struct.set $frame16 $s5
    local.get $__frame
    i32.const 1
    struct.set $frame16 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $str
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $result)
    local.set $r
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $r
    local.set $__case_0_0
      )
    )
    local.get $__case_0_0
    struct.get $result $tag
    i32.eqz
    (if (result (ref null $str))
      (then
    global.get $__s1
      )
      (else
    local.get $__case_0_0
    struct.get $result $tag
    (if (result (ref null $str))
      (then
    local.get $__case_0_0
    struct.get $result $payload
    ref.cast (ref null $rec_Failure)
    local.set $f__6
    local.get $f__6
    struct.get $rec_Failure $f0
      )
      (else
    ref.null $str
      )
    )
      )
    )
    return
  )
  (func $panicOf__step (param $__task (ref null $task))
    (local $__v (ref null $str))
    local.get $__task
    call $panicOf__body
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
  ;; Attempt `n` of a task that fails until its `succeedAt`-th call:
  ;; `Error("failure <n>")` before it, `Ok("ok after <n>")` from it on. The test
  ;; counts the call (`flaky(countUp(calls), …)`), so the counter's cells are
  ;; reached from the tests alone, and a module importing `async` on a target
  ;; with no counter (wasm) links no call of them.
  ;; @Async — a state machine (decision 392)
  (func $flaky (param $n i32) (param $succeedAt i32) (result (ref null $task))
    (local $__fr (ref null $frame17))
    struct.new_default $frame17 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $n
    struct.set $frame17 $s0
    local.get $__fr
    local.get $succeedAt
    struct.set $frame17 $s1
    i32.const 17 ;; flaky__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $flaky__body (param $__task (ref null $task)) (result (ref null $result))
    (local $n i32)
    (local $succeedAt i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $__frame (ref null $frame17))
    (local $__seek i32)
    (local $__state i32)
    (local $__cnd0 i32)
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame17)
    local.set $__frame
    local.get $__frame
    struct.get $frame17 $s0
    local.set $n
    local.get $__frame
    struct.get $frame17 $s1
    local.set $succeedAt
    local.get $__frame
    struct.get $frame17 $s2
    local.set $__mem0
    local.get $__frame
    struct.get $frame17 $s3
    local.set $__mem1
    local.get $__frame
    struct.get $frame17 $s4
    local.set $__cnd0
    local.get $__frame
    struct.get $frame17 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $__seek
    (if (result i32)
      (then
    local.get $__cnd0 ;; the condition, read back
      )
      (else
    local.get $n
    local.get $succeedAt
    i32.lt_s
    local.tee $__cnd0
      )
    )
    (if (result (ref null $result))
      (then
    i32.const 1
    global.get $__s16
    local.get $n
    call $__std_number_i32ToString
    array.new_fixed $arr_any 2
    global.get $__s1
    call $__arr_join_any
    struct.new $result
    return
      )
      (else
        ref.null $result
      )
    )
    drop
      )
    )
    i32.const 0
    global.get $__s17
    local.get $n
    call $__std_number_i32ToString
    array.new_fixed $arr_any 2
    global.get $__s1
    call $__arr_join_any
    struct.new $result
    return
  )
  (func $flaky__step (param $__task (ref null $task))
    (local $__v (ref null $result))
    local.get $__task
    call $flaky__body
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
  ;; What `nextDelay(policy, attempt)` answers, as text: the milliseconds, or
  ;; `none`.
  (func $pauseText (param $policy (ref null $rec_RetryPolicy)) (param $attempt i32) (result (ref null $str))
    (local $pause anyref)
    local.get $policy
    local.get $attempt
    call $nextDelay
    local.set $pause
    local.get $pause
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $pause
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    call $__std_number_i64ToString
      )
      (else
    global.get $__s18
      )
    )
    return
  )
  ;; `pauseText` for attempts 1 to `last`, joined by `,`.
  (func $pauses (param $policy (ref null $rec_RetryPolicy)) (param $last i32) (result (ref null $str))
    (local $__iter0 (ref null $arr_i32))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $__acc0 i32)
    (local $attempt i32)
    (local $__out0 (ref null $arr_any))
    i32.const 1
    local.get $last
    i32.const 1
    global.get $__s19
    call $__i32_add_chk
    call $array_range
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
    local.get $__len0
    array.new_default $arr_any
    local.set $__out0
    i32.const 0
    local.set $__acc0
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_i32
        local.set $attempt
    local.get $__out0
    local.get $__idx0
    local.get $policy
    local.get $attempt
    call $pauseText
    array.set $arr_any
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    local.get $__out0
    global.get $__s20
    call $__arr_join_any
    return
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (result (ref null $task))
    (local $task (ref null $closure))
    local.get $__env
    struct.get $env0 $c0
    local.set $task
    local.get $task
    call $answered
  )
  (func $__lambda0 (type $sig_0) (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    call $__lambda0__b
  )
  (func $__lambda1__b (param $__env (ref null $env1)) (result (ref null $task))
    (local $task (ref null $closure))
    (local $millis i32)
    local.get $__env
    struct.get $env1 $c0
    local.set $task
    local.get $__env
    struct.get $env1 $c1
    local.set $millis
    local.get $task
    local.get $millis
    call $expireAfter
  )
  (func $__lambda1 (type $sig_0) (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env1)
    call $__lambda1__b
  )
  (func $array_range (param $start i32) (param $stop i32) (result (ref null $arr_i32))
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $count i32)
    (local $low (ref null $arr_i32))
    (local $high (ref null $arr_i32))
    local.get $stop
    local.get $start
    global.get $__s21
    call $__i32_sub_chk
    i32.const 0
    i32.le_s
    (if (result (ref null $arr_i32))
      (then
    array.new_fixed $arr_i32 0
      )
      (else
    local.get $stop
    local.get $start
    global.get $__s22
    call $__i32_sub_chk
    i32.const 1
    i32.eq
    (if (result (ref null $arr_i32))
      (then
    local.get $start
    array.new_fixed $arr_i32 1
      )
      (else
    local.get $stop
    local.get $start
    global.get $__s23
    call $__i32_sub_chk
    local.set $count
    local.get $start
    local.get $start
    local.get $count
    i32.const 2
    i32.div_s
    global.get $__s24
    call $__i32_add_chk
    call $array_range
    local.set $low
    local.get $start
    local.get $count
    i32.const 2
    i32.div_s
    global.get $__s25
    call $__i32_add_chk
    local.get $stop
    call $array_range
    local.set $high
    local.get $low
    local.get $high
    call $__arr_concat_i32
      )
    )
      )
    )
    return
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
  (func $__arr_push_any (param $xs (ref null $arr_any)) (param $x anyref) (result (ref null $arr_any))
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
    local.get $n
    local.get $x
    array.set $arr_any
    local.get $r
  )
  (func $__arr_join_any (param $xs (ref null $arr_any)) (param $sep (ref null $str)) (result (ref null $str))
    (local $n i32)
    (local $i i32)
    (local $acc (ref null $str))
    local.get $xs
    array.len
    local.set $n
    i32.const 0
    array.new_default $str
    local.set $acc
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    local.get $acc
    local.get $sep
    call $__str_concat
    local.set $acc
      )
    )
    local.get $acc
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $str)
    call $__str_concat
    local.set $acc
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $acc
  )
  (func $__arr_concat_i32 (param $xs (ref null $arr_i32)) (param $ys (ref null $arr_i32)) (result (ref null $arr_i32))
    (local $la i32)
    (local $lb i32)
    (local $r (ref null $arr_i32))
    local.get $xs
    array.len
    local.set $la
    local.get $ys
    array.len
    local.set $lb
    local.get $la
    local.get $lb
    i32.add
    array.new_default $arr_i32
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $la
    array.copy $arr_i32 $arr_i32
    local.get $r
    local.get $la
    local.get $ys
    i32.const 0
    local.get $lb
    array.copy $arr_i32 $arr_i32
    local.get $r
  )
  (func $__pr1 (param $v (ref null $str))
    local.get $v
    call $__print_quoted_raw
  )
  (func $__pr0 (param $v (ref null $rec_Failure))
    global.get $__s26
    call $__print_str_raw
    global.get $__s27
    call $__print_str_raw
    global.get $__s28
    call $__print_str_raw
    local.get $v
    struct.get $rec_Failure $f0
    call $__pr1
    global.get $__s29
    call $__print_str_raw
    local.get $v
    struct.get $rec_Failure $f1
    call $__pr1
    global.get $__s30
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
  (func $__unk_print_q (param $v anyref)
    local.get $v
    ref.is_null
    (if
      (then
    global.get $__s34
    call $__print_str_raw
    return
      )
    )
    local.get $v
    call $__print_ebox
    (if
      (then
    return
      )
    )
    local.get $v
    call $__print_arrs
    (if
      (then
    return
      )
    )
    local.get $v
    ref.test (ref null $box_bool)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_bool)
    struct.get $box_bool $v
    call $__print_bool_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    call $__print_i32_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_f64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    call $__print_f64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $box_i64)
    (if
      (then
    local.get $v
    ref.cast (ref null $box_i64)
    struct.get $box_i64 $v
    call $__print_i64_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $str)
    (if
      (then
    local.get $v
    ref.cast (ref null $str)
    call $__print_quoted_raw
    return
      )
    )
    local.get $v
    call $__print_tagged_raw
  )
  (func $__pr3 (param $v anyref)
    local.get $v
    call $__unk_print_q
  )
  (func $__pr2 (param $v (ref null $rec_Gate))
    global.get $__s32
    call $__print_str_raw
    global.get $__s27
    call $__print_str_raw
    global.get $__s33
    call $__print_str_raw
    local.get $v
    struct.get $rec_Gate $f0
    call $__pr3
    global.get $__s30
    call $__print_str_raw
  )
  (func $__tip7 (param $v anyref)
    local.get $v
    ref.cast (ref null $rec_Gate)
    call $__pr2
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
  (func $__tie7 (param $a anyref) (param $b anyref) (result i32)
    local.get $b
    ref.test (ref null $rec_Gate)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    local.get $b
    call $__unk_eq_ref
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
  (func $__unk_eq_s4 (param $a (ref null $rec_Failure)) (param $b (ref null $rec_Failure)) (result i32)
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
  (func $__unk_eq_s7 (param $a (ref null $rec_Gate)) (param $b (ref null $rec_Gate)) (result i32)
    local.get $a
    struct.get $rec_Gate $f0
    local.get $b
    struct.get $rec_Gate $f0
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
  (func $__unk_eq_s20 (param $a (ref null $rec_RetryPolicy)) (param $b (ref null $rec_RetryPolicy)) (result i32)
    local.get $a
    struct.get $rec_RetryPolicy $f0
    local.get $b
    struct.get $rec_RetryPolicy $f0
    i32.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_RetryPolicy $f1
    local.get $b
    struct.get $rec_RetryPolicy $f1
    i64.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_RetryPolicy $f2
    local.get $b
    struct.get $rec_RetryPolicy $f2
    call $__f64_eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    struct.get $rec_RetryPolicy $f3
    local.get $b
    struct.get $rec_RetryPolicy $f3
    i64.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    i32.const 1
  )
  (func $__unk_eq_s21 (param $a (ref null $box_i64)) (param $b (ref null $box_i64)) (result i32)
    local.get $a
    struct.get $box_i64 $v
    local.get $b
    struct.get $box_i64 $v
    i64.eq
    i32.eqz
    (if
      (then
    i32.const 0
    return
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
    call $__unk_eq_s4
    return
      )
    )
    local.get $a
    ref.test (ref null $rec_Gate)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_Gate)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_Gate)
    local.get $b
    ref.cast (ref null $rec_Gate)
    call $__unk_eq_s7
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
    ref.test (ref null $rec_RetryPolicy)
    (if
      (then
    local.get $b
    ref.test (ref null $rec_RetryPolicy)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $rec_RetryPolicy)
    local.get $b
    ref.cast (ref null $rec_RetryPolicy)
    call $__unk_eq_s20
    return
      )
    )
    local.get $a
    ref.test (ref null $box_i64)
    (if
      (then
    local.get $b
    ref.test (ref null $box_i64)
    i32.eqz
    (if
      (then
    i32.const 0
    return
      )
    )
    local.get $a
    ref.cast (ref null $box_i64)
    local.get $b
    ref.cast (ref null $box_i64)
    call $__unk_eq_s21
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
  (func $__pr5 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr6 (param $v i64)
    local.get $v
    call $__print_i64_raw
  )
  (func $__pr7 (param $v f64)
    local.get $v
    call $__print_f64_raw
  )
  (func $__pr4 (param $v (ref null $rec_RetryPolicy))
    global.get $__s40
    call $__print_str_raw
    global.get $__s27
    call $__print_str_raw
    global.get $__s41
    call $__print_str_raw
    local.get $v
    struct.get $rec_RetryPolicy $f0
    call $__pr5
    global.get $__s42
    call $__print_str_raw
    local.get $v
    struct.get $rec_RetryPolicy $f1
    call $__pr6
    global.get $__s43
    call $__print_str_raw
    local.get $v
    struct.get $rec_RetryPolicy $f2
    call $__pr7
    global.get $__s44
    call $__print_str_raw
    local.get $v
    struct.get $rec_RetryPolicy $f3
    call $__pr6
    global.get $__s30
    call $__print_str_raw
  )
  (func $__print_tagged_raw (param $v anyref)
    local.get $v
    ref.test (ref null $closure)
    (if
      (then
    global.get $__s36
    call $__print_str_raw
    local.get $v
    ref.cast (ref null $closure)
    struct.get $closure $arity
    call $__print_i32_raw
    return
      )
    )
    local.get $v
    ref.test (ref null $result)
    (if
      (then
    local.get $v
    ref.cast (ref null $result)
    struct.get $result $tag
    (if
      (then
    global.get $__s37
    call $__print_str_raw
    local.get $v
    ref.cast (ref null $result)
    struct.get $result $payload
    call $__unk_print_q
    global.get $__s30
    call $__print_str_raw
      )
      (else
    global.get $__s38
    call $__print_str_raw
    local.get $v
    ref.cast (ref null $result)
    struct.get $result $payload
    call $__unk_print_q
    global.get $__s30
    call $__print_str_raw
      )
    )
    return
      )
    )
    local.get $v
    ref.test (ref null $task)
    (if
      (then
    global.get $__s39
    call $__panic_fail
    unreachable
      )
    )
    local.get $v
    ref.test (ref null $rec_Failure)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Failure)
    call $__pr0
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_Gate)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_Gate)
    call $__pr2
    return
      )
    )
    local.get $v
    ref.test (ref null $rec_RetryPolicy)
    (if
      (then
    local.get $v
    ref.cast (ref null $rec_RetryPolicy)
    call $__pr4
    return
      )
    )
    local.get $v
    ref.test (ref null $__decl)
    (if
      (then
    local.get $v
    call $__print_decl
    return
      )
    )
    unreachable
  )
  (func $__print_ebox (param $v anyref) (result i32)
    i32.const 0
  )
  (func $__pr8 (param $v (ref null $arr_any))
    (local $n i32)
    (local $i i32)
    global.get $__s45
    call $__print_str_raw
    local.get $v
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    global.get $__s46
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_any
    call $__pr3
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s47
    call $__print_str_raw
  )
  (func $__pr9 (param $v (ref null $arr_i32))
    (local $n i32)
    (local $i i32)
    global.get $__s45
    call $__print_str_raw
    local.get $v
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    global.get $__s46
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_i32
    call $__pr5
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s47
    call $__print_str_raw
  )
  (func $__print_arrs (param $v anyref) (result i32)
    local.get $v
    ref.test (ref null $arr_any)
    (if
      (then
    local.get $v
    ref.cast (ref null $arr_any)
    call $__pr8
    i32.const 1
    return
      )
    )
    local.get $v
    ref.test (ref null $arr_i32)
    (if
      (then
    local.get $v
    ref.cast (ref null $arr_i32)
    call $__pr9
    i32.const 1
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
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
    drop
    return
      )
    )
    local.get $k
    i32.const 1
    i32.eq
    (if
      (then
    local.get $t
    call $failed__step
    return
      )
    )
    local.get $k
    i32.const 2
    i32.eq
    (if
      (then
    local.get $t
    call $awaitGate__step
    return
      )
    )
    local.get $k
    i32.const 3
    i32.eq
    (if
      (then
    local.get $t
    call $allOf__step
    return
      )
    )
    local.get $k
    i32.const 4
    i32.eq
    (if
      (then
    local.get $t
    call $all__step
    return
      )
    )
    local.get $k
    i32.const 5
    i32.eq
    (if
      (then
    local.get $t
    call $runAll__step
    return
      )
    )
    local.get $k
    i32.const 6
    i32.eq
    (if
      (then
    local.get $t
    call $answered__step
    return
      )
    )
    local.get $k
    i32.const 7
    i32.eq
    (if
      (then
    local.get $t
    call $expireAfter__step
    return
      )
    )
    local.get $k
    i32.const 8
    i32.eq
    (if
      (then
    local.get $t
    call $timeout__step
    return
      )
    )
    local.get $k
    i32.const 9
    i32.eq
    (if
      (then
    local.get $t
    call $retryFrom__step
    return
      )
    )
    local.get $k
    i32.const 10
    i32.eq
    (if
      (then
    local.get $t
    call $retry__step
    return
      )
    )
    local.get $k
    i32.const 11
    i32.eq
    (if
      (then
    local.get $t
    call $gated__step
    return
      )
    )
    local.get $k
    i32.const 12
    i32.eq
    (if
      (then
    local.get $t
    call $handshake__step
    return
      )
    )
    local.get $k
    i32.const 13
    i32.eq
    (if
      (then
    local.get $t
    call $answerNow__step
    return
      )
    )
    local.get $k
    i32.const 14
    i32.eq
    (if
      (then
    local.get $t
    call $slowOk__step
    return
      )
    )
    local.get $k
    i32.const 15
    i32.eq
    (if
      (then
    local.get $t
    call $ghost__step
    return
      )
    )
    local.get $k
    i32.const 16
    i32.eq
    (if
      (then
    local.get $t
    call $panicOf__step
    return
      )
    )
    local.get $k
    i32.const 17
    i32.eq
    (if
      (then
    local.get $t
    call $flaky__step
    return
      )
    )
    unreachable
  )
  (func $__task_host_poll (result i32)
    (local $n i32) (local $buf i32) (local $out i32) (local $k i32) (local $i i32) (local $h i32) (local $top i32) (local $node (ref null $hostn))
    global.get $__task_hosts
    local.set $node
    (block $brk
      (loop $cont
        local.get $node
        ref.is_null
        br_if $brk
        local.get $n
        i32.const 1
        i32.add
        local.set $n
        local.get $node
        struct.get $hostn $next
        local.set $node
        br $cont
      )
    )
    local.get $n
    i32.eqz
    (if
      (then
        i32.const 0
        return
      )
    )
    global.get $__heap_ptr
    local.set $top
    local.get $n
    i32.const 4
    i32.mul
    call $__alloc
    local.set $buf
    local.get $n
    i32.const 4
    i32.mul
    call $__alloc
    local.set $out
    global.get $__task_hosts
    local.set $node
    (block $brk
      (loop $cont
        local.get $node
        ref.is_null
        br_if $brk
        local.get $buf
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        local.get $node
        struct.get $hostn $h
        i32.store
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        local.get $node
        struct.get $hostn $next
        local.set $node
        br $cont
      )
    )
    local.get $buf
    local.get $n
    local.get $out
    call $bp_host_wait
    local.set $k
    i32.const 0
    local.set $i
    (block $brk
      (loop $cont
        local.get $i
        local.get $k
        i32.ge_u
        br_if $brk
        local.get $buf
        local.get $out
        local.get $i
        i32.const 4
        i32.mul
        i32.add
        i32.load
        i32.const 4
        i32.mul
        i32.add
        i32.load
        local.set $h
        local.get $h
        call $__task_host_settle
        drop
        local.get $h
        call $bp_host_drop
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $top
    global.set $__heap_ptr
    i32.const 1
  )
  (global $__task_hosts (mut (ref null $hostn)) (ref.null $hostn))
  (func $__task_host_add (param $h i32) (param $t (ref null $task))
    global.get $__task_hosts
    local.get $h
    local.get $t
    struct.new $hostn
    global.set $__task_hosts
  )
  (func $__task_host_settle (param $h i32) (result i32)
    (local $p (ref null $hostn)) (local $n (ref null $hostn))
    global.get $__task_hosts
    local.set $n
    (block $brk
      (loop $cont
        local.get $n
        ref.is_null
        br_if $brk
        local.get $n
        struct.get $hostn $h
        local.get $h
        i32.eq
        (if
          (then
            local.get $p
            ref.is_null
            (if
              (then
                local.get $n
                struct.get $hostn $next
                global.set $__task_hosts
              )
              (else
                local.get $p
                local.get $n
                struct.get $hostn $next
                struct.set $hostn $next
              )
            )
            local.get $n
            struct.get $hostn $t
            call $__task_wake
            i32.const 1
            return
          )
        )
        local.get $n
        local.set $p
        local.get $n
        struct.get $hostn $next
        local.set $n
        br $cont
      )
    )
    i32.const 0
  )
  (func $__task_delay (param $ms i32) (param $v anyref) (result (ref null $task))
    (local $t (ref null $task))
    local.get $ms
    i32.const 0
    i32.lt_s
    (if
      (then
        i32.const 0
        local.set $ms
      )
    )
    i32.const -1
    ref.null struct
    call $__task_new
    local.set $t
    local.get $t
    local.get $v
    struct.set $task $value
    local.get $ms
    call $bp_host_delay
    local.get $t
    call $__task_host_add
    local.get $t
  )
  (func $__task_race (param $xs (ref null $arr_any)) (result (ref null $task))
    (local $n i32) (local $i i32) (local $t (ref null $task)) (local $r (ref null $task))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    i32.eqz
    (if
      (then
        unreachable
      )
    )
    i32.const -1
    ref.null struct
    call $__task_new
    local.set $r
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $xs
        local.get $i
        array.get $arr_any
        ref.cast (ref null $task)
        local.set $t
        local.get $t
        struct.get $task $state
        (if
          (then
            local.get $r
            local.get $t
            struct.get $task $value
            struct.set $task $value
            local.get $r
            call $__task_wake
            local.get $r
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
    i32.const 0
    local.set $i
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $xs
        local.get $i
        array.get $arr_any
        ref.cast (ref null $task)
        i32.const 1
        local.get $r
        i32.const 0
        call $__task_listen
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
  )
  (func $__task_race_of (param $fs (ref null $arr_any)) (result (ref null $task))
    (local $n i32) (local $i i32) (local $xs (ref null $arr_any)) (local $f (ref null $closure))
    local.get $fs
    array.len
    local.set $n
    local.get $n
    array.new_default $arr_any
    local.set $xs
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $fs
        local.get $i
        array.get $arr_any
        ref.cast (ref null $closure)
        local.set $f
        local.get $xs
        local.get $i
        local.get $f
        local.get $f
        struct.get $closure $fn
        ref.cast (ref null $sig_0)
        call_ref $sig_0
        ref.cast (ref null $task)
        array.set $arr_any
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $xs
    call $__task_race
  )
  (func $__task_spawn_all (param $fs (ref null $arr_any)) (result (ref null $task))
    (local $n i32) (local $i i32) (local $out (ref null $arr_any)) (local $f (ref null $closure)) (local $t (ref null $task)) (local $r (ref null $task))
    local.get $fs
    array.len
    local.set $n
    local.get $n
    array.new_default $arr_any
    local.set $out
    i32.const -1
    ref.null struct
    call $__task_new
    local.set $r
    local.get $r
    local.get $out
    struct.set $task $aux
    local.get $r
    local.get $n
    struct.set $task $left
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $fs
        local.get $i
        array.get $arr_any
        ref.cast (ref null $closure)
        local.set $f
        local.get $f
        local.get $f
        struct.get $closure $fn
        ref.cast (ref null $sig_0)
        call_ref $sig_0
        ref.cast (ref null $task)
        local.set $t
        local.get $t
        struct.get $task $state
        (if
          (then
            local.get $out
            local.get $i
            local.get $t
            struct.get $task $value
            array.set $arr_any
            local.get $r
            local.get $r
            struct.get $task $left
            i32.const 1
            i32.sub
            struct.set $task $left
          )
          (else
            local.get $t
            i32.const 2
            local.get $r
            local.get $i
            call $__task_listen
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
    struct.get $task $left
    i32.eqz
    (if
      (then
        local.get $r
        local.get $out
        struct.set $task $value
        local.get $r
        ref.null any
        struct.set $task $aux
        local.get $r
        call $__task_wake
      )
    )
    local.get $r
  )
  (func $__task_host_cancel (param $t (ref null $task))
    (local $p (ref null $hostn)) (local $n (ref null $hostn))
    global.get $__task_hosts
    local.set $n
    (block $brk
      (loop $cont
        local.get $n
        ref.is_null
        br_if $brk
        local.get $n
        struct.get $hostn $t
        local.get $t
        ref.eq
        (if
          (then
            local.get $p
            ref.is_null
            (if
              (then
                local.get $n
                struct.get $hostn $next
                global.set $__task_hosts
              )
              (else
                local.get $p
                local.get $n
                struct.get $hostn $next
                struct.set $hostn $next
              )
            )
            local.get $n
            struct.get $hostn $h
            call $bp_host_drop
            return
          )
        )
        local.get $n
        local.set $p
        local.get $n
        struct.get $hostn $next
        local.set $n
        br $cont
      )
    )
  )
  (func $__task_gate_new (result (ref null $task))
    i32.const -1
    ref.null struct
    call $__task_new
  )
  (func $__task_gate_open (param $g anyref)
    (local $t (ref null $task)) (local $n (ref null $waiter)) (local $r (ref null $task))
    local.get $g
    ref.cast (ref null $task)
    local.set $t
    local.get $t
    struct.get $task $state
    (if
      (then
        return
      )
    )
    local.get $t
    struct.get $task $waiters
    local.set $n
    (block $brk
      (loop $cont
        local.get $n
        ref.is_null
        br_if $brk
        local.get $n
        struct.get $waiter $target
        local.set $r
        local.get $n
        struct.get $waiter $kind
        i32.const 1
        i32.eq
        (if
          (then
            local.get $r
            struct.get $task $state
            i32.eqz
            (if
              (then
                local.get $r
                struct.get $task $aux
                ref.is_null
                i32.eqz
                (if
                  (then
                    local.get $r
                    struct.get $task $aux
                    ref.cast (ref null $task)
                    call $__task_host_cancel
                  )
                )
              )
            )
          )
        )
        local.get $n
        struct.get $waiter $next
        local.set $n
        br $cont
      )
    )
    local.get $t
    i32.const 1
    struct.new $box_i32
    call $__task_settle
  )
  (func $__task_gate_await (param $g anyref) (param $ms i32) (result (ref null $task))
    (local $t (ref null $task)) (local $r (ref null $task)) (local $d (ref null $task))
    local.get $g
    ref.cast (ref null $task)
    local.set $t
    i32.const -1
    ref.null struct
    call $__task_new
    local.set $r
    local.get $t
    struct.get $task $state
    (if
      (then
        local.get $r
        i32.const 1
        struct.new $box_i32
        call $__task_settle
        local.get $r
        return
      )
    )
    local.get $ms
    i32.const 0
    struct.new $box_i32
    call $__task_delay
    local.set $d
    local.get $r
    local.get $d
    struct.set $task $aux
    local.get $t
    i32.const 1
    local.get $r
    i32.const 0
    call $__task_listen
    local.get $d
    i32.const 1
    local.get $r
    i32.const 0
    call $__task_listen
    local.get $r
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (func $__std_number_i64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_i64ToString
    ref.cast (ref null $str)
  )
  (func $__std_number_i32ToString (param $p0 i32) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_i32ToString
    ref.cast (ref null $str)
  )
  (func $__std_number_u64ToString (param $p0 i64) (result (ref null $str))
    local.get $p0
    call $__abi___std_number_u64ToString
    ref.cast (ref null $str)
  )
  (data $__d0 "panic")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "timeout")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "maxAttempts must be at least 1 (the first attempt)")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (data $__d4 "initialMillis must not be negative")
  (global $__s4 (mut (ref null $str)) (ref.null $str))
  (data $__d5 "maxMillis must not be negative")
  (global $__s5 (mut (ref null $str)) (ref.null $str))
  (data $__d6 "maxMillis must be at most 2147483647")
  (global $__s6 (mut (ref null $str)) (ref.null $str))
  (data $__d7 "multiplier must be at least 1.0 (a backoff never shrinks)")
  (global $__s7 (mut (ref null $str)) (ref.null $str))
  (data $__d8 "integer overflow: + on i32 at src/async.bp:335:21")
  (global $__s8 (mut (ref null $str)) (ref.null $str))
  (data $__d9 "toI32: ")
  (global $__s9 (mut (ref null $str)) (ref.null $str))
  (data $__d10 " does not fit i32")
  (global $__s10 (mut (ref null $str)) (ref.null $str))
  (data $__d11 "integer overflow: + on i32 at src/async.bp:371:54")
  (global $__s11 (mut (ref null $str)) (ref.null $str))
  (data $__d12 "async.retry: ")
  (global $__s12 (mut (ref null $str)) (ref.null $str))
  (data $__d13 "gate never opened: ")
  (global $__s13 (mut (ref null $str)) (ref.null $str))
  (data $__d14 "async: no element")
  (global $__s14 (mut (ref null $str)) (ref.null $str))
  (data $__d15 "late")
  (global $__s15 (mut (ref null $str)) (ref.null $str))
  (data $__d16 "failure ")
  (global $__s16 (mut (ref null $str)) (ref.null $str))
  (data $__d17 "ok after ")
  (global $__s17 (mut (ref null $str)) (ref.null $str))
  (data $__d18 "none")
  (global $__s18 (mut (ref null $str)) (ref.null $str))
  (data $__d19 "integer overflow: + on i32 at src/async.bp:727:24")
  (global $__s19 (mut (ref null $str)) (ref.null $str))
  (data $__d20 ",")
  (global $__s20 (mut (ref null $str)) (ref.null $str))
  (data $__d21 "integer overflow: - on i32 at src/async.bp:1326:21")
  (global $__s21 (mut (ref null $str)) (ref.null $str))
  (data $__d22 "integer overflow: - on i32 at src/async.bp:1326:52")
  (global $__s22 (mut (ref null $str)) (ref.null $str))
  (data $__d23 "integer overflow: - on i32 at src/async.bp:1327:26")
  (global $__s23 (mut (ref null $str)) (ref.null $str))
  (data $__d24 "integer overflow: + on i32 at src/async.bp:1328:44")
  (global $__s24 (mut (ref null $str)) (ref.null $str))
  (data $__d25 "integer overflow: + on i32 at src/async.bp:1329:38")
  (global $__s25 (mut (ref null $str)) (ref.null $str))
  (data $__d26 "Failure")
  (global $__s26 (mut (ref null $str)) (ref.null $str))
  (data $__d27 "(")
  (global $__s27 (mut (ref null $str)) (ref.null $str))
  (data $__d28 "message: ")
  (global $__s28 (mut (ref null $str)) (ref.null $str))
  (data $__d29 ", kind: ")
  (global $__s29 (mut (ref null $str)) (ref.null $str))
  (data $__d30 ")")
  (global $__s30 (mut (ref null $str)) (ref.null $str))
  (data $__d31 "std@failure.Failure")
  (global $__s31 (mut (ref null $str)) (ref.null $str))
  (data $__d32 "Gate")
  (global $__s32 (mut (ref null $str)) (ref.null $str))
  (data $__d33 "handle: ")
  (global $__s33 (mut (ref null $str)) (ref.null $str))
  (data $__d34 "null")
  (global $__s34 (mut (ref null $str)) (ref.null $str))
  (data $__d35 "std@async.Gate")
  (global $__s35 (mut (ref null $str)) (ref.null $str))
  (data $__d36 "fn/")
  (global $__s36 (mut (ref null $str)) (ref.null $str))
  (data $__d37 "Error(")
  (global $__s37 (mut (ref null $str)) (ref.null $str))
  (data $__d38 "Ok(")
  (global $__s38 (mut (ref null $str)) (ref.null $str))
  (data $__d39 "wasm cannot print a Task value dynamically yet")
  (global $__s39 (mut (ref null $str)) (ref.null $str))
  (data $__d40 "RetryPolicy")
  (global $__s40 (mut (ref null $str)) (ref.null $str))
  (data $__d41 "maxAttempts: ")
  (global $__s41 (mut (ref null $str)) (ref.null $str))
  (data $__d42 ", initialMillis: ")
  (global $__s42 (mut (ref null $str)) (ref.null $str))
  (data $__d43 ", multiplier: ")
  (global $__s43 (mut (ref null $str)) (ref.null $str))
  (data $__d44 ", maxMillis: ")
  (global $__s44 (mut (ref null $str)) (ref.null $str))
  (data $__d45 "[")
  (global $__s45 (mut (ref null $str)) (ref.null $str))
  (data $__d46 ", ")
  (global $__s46 (mut (ref null $str)) (ref.null $str))
  (data $__d47 "]")
  (global $__s47 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 0
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 7
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 50
    array.new_data $str $__d3
    global.set $__s3
    i32.const 0
    i32.const 34
    array.new_data $str $__d4
    global.set $__s4
    i32.const 0
    i32.const 30
    array.new_data $str $__d5
    global.set $__s5
    i32.const 0
    i32.const 36
    array.new_data $str $__d6
    global.set $__s6
    i32.const 0
    i32.const 57
    array.new_data $str $__d7
    global.set $__s7
    i32.const 0
    i32.const 49
    array.new_data $str $__d8
    global.set $__s8
    i32.const 0
    i32.const 7
    array.new_data $str $__d9
    global.set $__s9
    i32.const 0
    i32.const 17
    array.new_data $str $__d10
    global.set $__s10
    i32.const 0
    i32.const 49
    array.new_data $str $__d11
    global.set $__s11
    i32.const 0
    i32.const 13
    array.new_data $str $__d12
    global.set $__s12
    i32.const 0
    i32.const 19
    array.new_data $str $__d13
    global.set $__s13
    i32.const 0
    i32.const 17
    array.new_data $str $__d14
    global.set $__s14
    i32.const 0
    i32.const 4
    array.new_data $str $__d15
    global.set $__s15
    i32.const 0
    i32.const 8
    array.new_data $str $__d16
    global.set $__s16
    i32.const 0
    i32.const 9
    array.new_data $str $__d17
    global.set $__s17
    i32.const 0
    i32.const 4
    array.new_data $str $__d18
    global.set $__s18
    i32.const 0
    i32.const 49
    array.new_data $str $__d19
    global.set $__s19
    i32.const 0
    i32.const 1
    array.new_data $str $__d20
    global.set $__s20
    i32.const 0
    i32.const 50
    array.new_data $str $__d21
    global.set $__s21
    i32.const 0
    i32.const 50
    array.new_data $str $__d22
    global.set $__s22
    i32.const 0
    i32.const 50
    array.new_data $str $__d23
    global.set $__s23
    i32.const 0
    i32.const 50
    array.new_data $str $__d24
    global.set $__s24
    i32.const 0
    i32.const 50
    array.new_data $str $__d25
    global.set $__s25
    i32.const 0
    i32.const 7
    array.new_data $str $__d26
    global.set $__s26
    i32.const 0
    i32.const 1
    array.new_data $str $__d27
    global.set $__s27
    i32.const 0
    i32.const 9
    array.new_data $str $__d28
    global.set $__s28
    i32.const 0
    i32.const 8
    array.new_data $str $__d29
    global.set $__s29
    i32.const 0
    i32.const 1
    array.new_data $str $__d30
    global.set $__s30
    i32.const 0
    i32.const 19
    array.new_data $str $__d31
    global.set $__s31
    i32.const 0
    i32.const 4
    array.new_data $str $__d32
    global.set $__s32
    i32.const 0
    i32.const 8
    array.new_data $str $__d33
    global.set $__s33
    i32.const 0
    i32.const 4
    array.new_data $str $__d34
    global.set $__s34
    i32.const 0
    i32.const 14
    array.new_data $str $__d35
    global.set $__s35
    i32.const 0
    i32.const 3
    array.new_data $str $__d36
    global.set $__s36
    i32.const 0
    i32.const 6
    array.new_data $str $__d37
    global.set $__s37
    i32.const 0
    i32.const 3
    array.new_data $str $__d38
    global.set $__s38
    i32.const 0
    i32.const 46
    array.new_data $str $__d39
    global.set $__s39
    i32.const 0
    i32.const 11
    array.new_data $str $__d40
    global.set $__s40
    i32.const 0
    i32.const 13
    array.new_data $str $__d41
    global.set $__s41
    i32.const 0
    i32.const 17
    array.new_data $str $__d42
    global.set $__s42
    i32.const 0
    i32.const 14
    array.new_data $str $__d43
    global.set $__s43
    i32.const 0
    i32.const 13
    array.new_data $str $__d44
    global.set $__s44
    i32.const 0
    i32.const 1
    array.new_data $str $__d45
    global.set $__s45
    i32.const 0
    i32.const 2
    array.new_data $str $__d46
    global.set $__s46
    i32.const 0
    i32.const 1
    array.new_data $str $__d47
    global.set $__s47
    call $__init_types
  )
  (func $__new_23 (param $f0 anyref) (result (ref null $rec_Gate))
    global.get $__ti_23
    local.get $f0
    struct.new $rec_Gate
  )
  (global $__ti_23 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (global $__ti_27 (mut (ref null $__tinfo)) (ref.null $__tinfo))
  (elem declare func $__tip4 $__tie4 $__tip7 $__tie7)
  (func $__init_types
    global.get $__s31
    ref.func $__tip4
    ref.func $__tie4
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_27
    global.get $__ti_27
    call $__ti_register
    global.get $__s35
    ref.func $__tip7
    ref.func $__tie7
    ref.null func
    i32.const 0
    struct.new $__tinfo
    global.set $__ti_23
    global.get $__ti_23
    call $__ti_register
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
RUNTIME TRAP (wasmtime):
unknown import: `bp_host::delay` has not been defined
```

----- SOURCE CODE -- main.bp
```botopink
async fn doubled(n: i32) -> Async<i32> {
    return n * 2;
}
async fn doubledF(n: f64) -> Async<f64> {
    return n * 2.0;
}
async fn run() -> Async<void> {
    val ints = await async.runAll([
        { -> doubled(1) },
        { -> doubled(2) },
        { -> doubled(3) },
    ]);
    print(ints);
    val floats = await async.runAll([
        { -> doubledF(1.5) },
        { -> doubledF(2.5) },
    ]);
    print(floats);
}
pub fn main() -> void {
    run();
}

import {io.terminal.print, async} from "std";
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
  (rec
    (type $sig_0 (func (param (ref null $closure)) (result anyref)))
  )
  (rec
    (type $frame0 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $arr_any))) (field $s1 (mut i32)) (field $s2 (mut (ref null $arr_any))) (field $s3 (mut i32)) (field $s4 (mut i32)) (field $s5 (mut (ref null $arr_any))) (field $s6 (mut i32)) (field $s7 (mut i32)) (field $s8 (mut (ref null $task))) (field $s9 (mut anyref)) (field $s10 (mut (ref null $task)))))
    (type $frame1 (struct (field $resume (mut i32)) (field $s0 (mut (ref null $arr_any))) (field $s1 (mut (ref null $task)))))
    (type $frame2 (struct (field $resume (mut i32)) (field $s0 (mut i32))))
    (type $frame3 (struct (field $resume (mut i32)) (field $s0 (mut f64))))
    (type $env0 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env1 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env2 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $frame4 (struct (field $resume (mut i32)) (field $s0 (mut i32)) (field $s1 (mut i32)) (field $s2 (mut (ref null $arr_i32))) (field $s3 (mut (ref null $arr_f64))) (field $s4 (mut (ref null $task))) (field $s5 (mut (ref null $task)))))
    (type $env3 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
    (type $env4 (sub final $closure (struct (field $fn funcref) (field $arity i32) (field $mark i32))))
  )
  (import "std@__rt" "__write_bytes" (func $__write_bytes (param i32 i32)))
  (import "std@__rt" "__alloc" (func $__alloc (param i32) (result i32)))
  (import "std@number" "std:number.floatToString" (func $__std_number_floatToString (param f64) (result i32)))
  (import "std@__rt" "fd_write" (func $fd_write (param i32 i32 i32 i32) (result i32)))
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (elem declare func $__lambda0 $__lambda1 $__lambda2 $__lambda3 $__lambda4)
  ;; @Async — a state machine (decision 392)
  (func $all (param $tasks (ref null $arr_any)) (result (ref null $task))
    (local $__fr (ref null $frame0))
    struct.new_default $frame0 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $tasks
    struct.set $frame0 $s0
    i32.const 0 ;; all__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $all__body (param $__task (ref null $task)) (result (ref null $arr_any))
    (local $tasks (ref null $arr_any))
    (local $__mem0 i32)
    (local $out (ref null $arr_any))
    (local $t i32)
    (local $v i32)
    (local $__frame (ref null $frame0))
    (local $__seek i32)
    (local $__state i32)
    (local $__iter0 (ref null $arr_any))
    (local $__idx0 i32)
    (local $__len0 i32)
    (local $t__sh0 (ref null $task))
    (local $v__sh1 anyref)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame0)
    local.set $__frame
    local.get $__frame
    struct.get $frame0 $s0
    local.set $tasks
    local.get $__frame
    struct.get $frame0 $s1
    local.set $__mem0
    local.get $__frame
    struct.get $frame0 $s2
    local.set $out
    local.get $__frame
    struct.get $frame0 $s3
    local.set $t
    local.get $__frame
    struct.get $frame0 $s4
    local.set $v
    local.get $__frame
    struct.get $frame0 $s5
    local.set $__iter0
    local.get $__frame
    struct.get $frame0 $s6
    local.set $__idx0
    local.get $__frame
    struct.get $frame0 $s7
    local.set $__len0
    local.get $__frame
    struct.get $frame0 $s8
    local.set $t__sh0
    local.get $__frame
    struct.get $frame0 $s9
    local.set $v__sh1
    local.get $__frame
    struct.get $frame0 $s10
    local.set $__aw1
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
    array.new_fixed $arr_any 0
    local.set $out
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $tasks
    local.set $__iter0
    local.get $__iter0
    array.len
    local.set $__len0
    i32.const 0
    local.set $__idx0
      )
    )
    (block $__break
      (loop $__continue
        local.get $__idx0
        local.get $__len0
        i32.ge_s
        br_if $__break
        local.get $__iter0
        local.get $__idx0
        array.get $arr_any
    ref.cast (ref null $task)
        local.set $t__sh0
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
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
    local.get $t__sh0
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $tasks
    struct.set $frame0 $s0
    local.get $__frame
    local.get $__mem0
    struct.set $frame0 $s1
    local.get $__frame
    local.get $out
    struct.set $frame0 $s2
    local.get $__frame
    local.get $t
    struct.set $frame0 $s3
    local.get $__frame
    local.get $v
    struct.set $frame0 $s4
    local.get $__frame
    local.get $__iter0
    struct.set $frame0 $s5
    local.get $__frame
    local.get $__idx0
    struct.set $frame0 $s6
    local.get $__frame
    local.get $__len0
    struct.set $frame0 $s7
    local.get $__frame
    local.get $t__sh0
    struct.set $frame0 $s8
    local.get $__frame
    local.get $v__sh1
    struct.set $frame0 $s9
    local.get $__frame
    local.get $__aw1
    struct.set $frame0 $s10
    local.get $__frame
    i32.const 1
    struct.set $frame0 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $arr_any
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    local.set $v__sh1
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $out
    local.get $v__sh1
    call $__arr_push_any
    local.set $out
      )
    )
        local.get $__idx0
        i32.const 1
        i32.add
        local.set $__idx0
        br $__continue
      )
    )
    i32.const 0
    drop
      )
    )
    local.get $out
    return
  )
  (func $all__step (param $__task (ref null $task))
    (local $__v (ref null $arr_any))
    local.get $__task
    call $all__body
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
  ;; spawnAll — .Wasm(wasi: .SpawnAll)
  (func $spawnAll (param $tasks (ref null $arr_any)) (result (ref null $task))
    local.get $tasks
    call $__task_spawn_all
  )
  ;; @Async — a state machine (decision 392)
  (func $runAll (param $tasks (ref null $arr_any)) (result (ref null $task))
    (local $__fr (ref null $frame1))
    struct.new_default $frame1 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $tasks
    struct.set $frame1 $s0
    i32.const 1 ;; runAll__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $runAll__body (param $__task (ref null $task)) (result (ref null $arr_any))
    (local $tasks (ref null $arr_any))
    (local $__frame (ref null $frame1))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame1)
    local.set $__frame
    local.get $__frame
    struct.get $frame1 $s0
    local.set $tasks
    local.get $__frame
    struct.get $frame1 $s1
    local.set $__aw1
    local.get $__frame
    struct.get $frame1 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
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
    local.get $tasks
    call $spawnAll
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $tasks
    struct.set $frame1 $s0
    local.get $__frame
    local.get $__aw1
    struct.set $frame1 $s1
    local.get $__frame
    i32.const 1
    struct.set $frame1 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    ref.null $arr_any
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $arr_any)
    return
  )
  (func $runAll__step (param $__task (ref null $task))
    (local $__v (ref null $arr_any))
    local.get $__task
    call $runAll__body
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
  (global $gateBudget i32 (i32.const 10000))
  ;; @Async — a state machine (decision 392)
  (func $doubled (param $n i32) (result (ref null $task))
    (local $__fr (ref null $frame2))
    struct.new_default $frame2 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $n
    struct.set $frame2 $s0
    i32.const 2 ;; doubled__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $doubled__body (param $__task (ref null $task)) (result i32)
    (local $n i32)
    (local $__frame (ref null $frame2))
    (local $__seek i32)
    (local $__state i32)
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame2)
    local.set $__frame
    local.get $__frame
    struct.get $frame2 $s0
    local.set $n
    local.get $__frame
    struct.get $frame2 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $n
    i32.const 2
    global.get $__s0
    call $__i32_mul_chk
    return
  )
  (func $doubled__step (param $__task (ref null $task))
    (local $__v i32)
    local.get $__task
    call $doubled__body
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
    struct.new $box_i32
    call $__task_settle
  )
  ;; @Async — a state machine (decision 392)
  (func $doubledF (param $n f64) (result (ref null $task))
    (local $__fr (ref null $frame3))
    struct.new_default $frame3 ;; the frame: the resume index, then every local
    local.set $__fr
    local.get $__fr
    local.get $n
    struct.set $frame3 $s0
    i32.const 3 ;; doubledF__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $doubledF__body (param $__task (ref null $task)) (result f64)
    (local $n f64)
    (local $__frame (ref null $frame3))
    (local $__seek i32)
    (local $__state i32)
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame3)
    local.set $__frame
    local.get $__frame
    struct.get $frame3 $s0
    local.set $n
    local.get $__frame
    struct.get $frame3 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $n
    f64.const 2.0
    f64.mul
    return
  )
  (func $doubledF__step (param $__task (ref null $task))
    (local $__v f64)
    local.get $__task
    call $doubledF__body
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
    struct.new $box_f64
    call $__task_settle
  )
  ;; @Async — a state machine (decision 392)
  (func $run (result (ref null $task))
    (local $__fr (ref null $frame4))
    struct.new_default $frame4 ;; the frame: the resume index, then every local
    local.set $__fr
    i32.const 4 ;; run__step
    local.get $__fr
    call $__task_start ;; runs to its first await
  )
  (func $run__body (param $__task (ref null $task)) (result i32)
    (local $__mem0 i32)
    (local $__mem1 i32)
    (local $ints (ref null $arr_i32))
    (local $floats (ref null $arr_f64))
    (local $__frame (ref null $frame4))
    (local $__seek i32)
    (local $__state i32)
    (local $__aw1 (ref null $task))
    (local $__aw2 (ref null $task))
    local.get $__task
    struct.get $task $frame
    ref.cast (ref null $frame4)
    local.set $__frame
    local.get $__frame
    struct.get $frame4 $s0
    local.set $__mem0
    local.get $__frame
    struct.get $frame4 $s1
    local.set $__mem1
    local.get $__frame
    struct.get $frame4 $s2
    local.set $ints
    local.get $__frame
    struct.get $frame4 $s3
    local.set $floats
    local.get $__frame
    struct.get $frame4 $s4
    local.set $__aw1
    local.get $__frame
    struct.get $frame4 $s5
    local.set $__aw2
    local.get $__frame
    struct.get $frame4 $resume ;; the resume index
    local.tee $__state
    i32.const 0
    i32.ne
    local.set $__seek
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 1
    i32.ge_u
    local.get $__state
    i32.const 1
    i32.le_u
    i32.and
    i32.or
    (if
      (then
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
    ref.func $__lambda0
    i32.const 0 ;; arity
    i32.const 0
    struct.new $env0
    ref.func $__lambda1
    i32.const 0 ;; arity
    i32.const 0
    struct.new $env1
    ref.func $__lambda2
    i32.const 0 ;; arity
    i32.const 0
    struct.new $env2
    array.new_fixed $arr_any 3
    call $runAll
    local.set $__aw1
    local.get $__aw1
    call $__task_pending
    (if
      (then
    local.get $__aw1
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $__mem0
    struct.set $frame4 $s0
    local.get $__frame
    local.get $__mem1
    struct.set $frame4 $s1
    local.get $__frame
    local.get $ints
    struct.set $frame4 $s2
    local.get $__frame
    local.get $floats
    struct.set $frame4 $s3
    local.get $__frame
    local.get $__aw1
    struct.set $frame4 $s4
    local.get $__frame
    local.get $__aw2
    struct.set $frame4 $s5
    local.get $__frame
    i32.const 1
    struct.set $frame4 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    i32.const 0
    return ;; suspended
      )
    )
    )
    local.get $__aw1
    struct.get $task $value ;; the settled value
    ref.cast (ref null $arr_any)
    call $__unbox_arr_i32
    local.set $ints
      )
    )
    local.get $__seek
    i32.eqz
    (if
      (then
    local.get $ints
    call $__pr0
    call $__print_nl
      )
    )
    local.get $__seek
    i32.eqz
    local.get $__state
    i32.const 2
    i32.ge_u
    local.get $__state
    i32.const 2
    i32.le_u
    i32.and
    i32.or
    (if
      (then
    (block $__aw2
    local.get $__seek
    (if
      (then
    local.get $__state
    i32.const 2
    i32.eq
    (if
      (then
    i32.const 0
    local.set $__seek
    br $__aw2 ;; resumed here
      )
    )
    br $__aw2 ;; resuming past this await
      )
    )
    ref.func $__lambda3
    i32.const 0 ;; arity
    i32.const 0
    struct.new $env3
    ref.func $__lambda4
    i32.const 0 ;; arity
    i32.const 0
    struct.new $env4
    array.new_fixed $arr_any 2
    call $runAll
    local.set $__aw2
    local.get $__aw2
    call $__task_pending
    (if
      (then
    local.get $__aw2
    local.get $__task
    call $__task_wait
    local.get $__frame
    local.get $__mem0
    struct.set $frame4 $s0
    local.get $__frame
    local.get $__mem1
    struct.set $frame4 $s1
    local.get $__frame
    local.get $ints
    struct.set $frame4 $s2
    local.get $__frame
    local.get $floats
    struct.set $frame4 $s3
    local.get $__frame
    local.get $__aw1
    struct.set $frame4 $s4
    local.get $__frame
    local.get $__aw2
    struct.set $frame4 $s5
    local.get $__frame
    i32.const 2
    struct.set $frame4 $resume ;; the resume index
    i32.const 1
    global.set $__task_suspended
    i32.const 0
    return ;; suspended
      )
    )
    )
    local.get $__aw2
    struct.get $task $value ;; the settled value
    ref.cast (ref null $arr_any)
    call $__unbox_arr_f64
    local.set $floats
      )
    )
    local.get $floats
    call $__pr2
    call $__print_nl
    i32.const 0
  )
  (func $run__step (param $__task (ref null $task))
    (local $__v i32)
    local.get $__task
    call $run__body
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
    struct.new $box_i32
    call $__task_settle
  )
  (func $main (export "main") (result i32)
    call $run
    drop
    i32.const 0
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (result (ref null $task))
    i32.const 1
    call $doubled
  )
  (func $__lambda0 (type $sig_0) (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    call $__lambda0__b
  )
  (func $__lambda1__b (param $__env (ref null $env1)) (result (ref null $task))
    i32.const 2
    call $doubled
  )
  (func $__lambda1 (type $sig_0) (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env1)
    call $__lambda1__b
  )
  (func $__lambda2__b (param $__env (ref null $env2)) (result (ref null $task))
    i32.const 3
    call $doubled
  )
  (func $__lambda2 (type $sig_0) (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env2)
    call $__lambda2__b
  )
  (func $__lambda3__b (param $__env (ref null $env3)) (result (ref null $task))
    f64.const 1.5
    call $doubledF
  )
  (func $__lambda3 (type $sig_0) (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env3)
    call $__lambda3__b
  )
  (func $__lambda4__b (param $__env (ref null $env4)) (result (ref null $task))
    f64.const 2.5
    call $doubledF
  )
  (func $__lambda4 (type $sig_0) (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env4)
    call $__lambda4__b
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
    drop
    call $__task_finish ;; the tasks main started
  )
  (func $__arr_push_any (param $xs (ref null $arr_any)) (param $x anyref) (result (ref null $arr_any))
    (local $n i32)
    (local $r (ref null $arr_any))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    i32.const 1
    i32.add
    array.new_default $arr_any
    local.set $r
    local.get $r
    i32.const 0
    local.get $xs
    i32.const 0
    local.get $n
    array.copy $arr_any $arr_any
    local.get $r
    local.get $n
    local.get $x
    array.set $arr_any
    local.get $r
  )
  (func $__unbox_arr_i32 (param $xs (ref null $arr_any)) (result (ref null $arr_i32))
    (local $n i32)
    (local $i i32)
    (local $r (ref null $arr_i32))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    array.new_default $arr_i32
    local.set $r
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $r
    local.get $i
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    array.set $arr_i32
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $r
  )
  (func $__pr1 (param $v i32)
    local.get $v
    call $__print_i32_raw
  )
  (func $__pr0 (param $v (ref null $arr_i32))
    (local $n i32)
    (local $i i32)
    global.get $__s1
    call $__print_str_raw
    local.get $v
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    global.get $__s2
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_i32
    call $__pr1
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s3
    call $__print_str_raw
  )
  (func $__unbox_arr_f64 (param $xs (ref null $arr_any)) (result (ref null $arr_f64))
    (local $n i32)
    (local $i i32)
    (local $r (ref null $arr_f64))
    local.get $xs
    array.len
    local.set $n
    local.get $n
    array.new_default $arr_f64
    local.set $r
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $r
    local.get $i
    local.get $xs
    local.get $i
    array.get $arr_any
    ref.cast (ref null $box_f64)
    struct.get $box_f64 $v
    array.set $arr_f64
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    local.get $r
  )
  (func $__pr3 (param $v f64)
    local.get $v
    call $__print_f64_raw
  )
  (func $__pr2 (param $v (ref null $arr_f64))
    (local $n i32)
    (local $i i32)
    global.get $__s1
    call $__print_str_raw
    local.get $v
    array.len
    local.set $n
    (block $brk
    (loop $cont
    local.get $i
    local.get $n
    i32.ge_u
    br_if $brk
    local.get $i
    (if
      (then
    global.get $__s2
    call $__print_str_raw
      )
    )
    local.get $v
    local.get $i
    array.get $arr_f64
    call $__pr3
    local.get $i
    i32.const 1
    i32.add
    local.set $i
    br $cont
    )
    )
    global.get $__s3
    call $__print_str_raw
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
  (func $__i32_add_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i32_sub_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i32_mul_chk (param $a i32) (param $b i32) (param $site (ref null $str)) (result i32)
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
  (func $__i64_add_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
  (func $__i64_sub_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
  (func $__i64_mul_chk (param $a i64) (param $b i64) (param $site (ref null $str)) (result i64)
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
    call $all__step
    return
      )
    )
    local.get $k
    i32.const 1
    i32.eq
    (if
      (then
    local.get $t
    call $runAll__step
    return
      )
    )
    local.get $k
    i32.const 2
    i32.eq
    (if
      (then
    local.get $t
    call $doubled__step
    return
      )
    )
    local.get $k
    i32.const 3
    i32.eq
    (if
      (then
    local.get $t
    call $doubledF__step
    return
      )
    )
    local.get $k
    i32.const 4
    i32.eq
    (if
      (then
    local.get $t
    call $run__step
    return
      )
    )
    unreachable
  )
  (func $__task_host_poll (result i32)
    i32.const 0
  )
  (func $__task_spawn_all (param $fs (ref null $arr_any)) (result (ref null $task))
    (local $n i32) (local $i i32) (local $out (ref null $arr_any)) (local $f (ref null $closure)) (local $t (ref null $task)) (local $r (ref null $task))
    local.get $fs
    array.len
    local.set $n
    local.get $n
    array.new_default $arr_any
    local.set $out
    i32.const -1
    ref.null struct
    call $__task_new
    local.set $r
    local.get $r
    local.get $out
    struct.set $task $aux
    local.get $r
    local.get $n
    struct.set $task $left
    (block $brk
      (loop $cont
        local.get $i
        local.get $n
        i32.ge_u
        br_if $brk
        local.get $fs
        local.get $i
        array.get $arr_any
        ref.cast (ref null $closure)
        local.set $f
        local.get $f
        local.get $f
        struct.get $closure $fn
        ref.cast (ref null $sig_0)
        call_ref $sig_0
        ref.cast (ref null $task)
        local.set $t
        local.get $t
        struct.get $task $state
        (if
          (then
            local.get $out
            local.get $i
            local.get $t
            struct.get $task $value
            array.set $arr_any
            local.get $r
            local.get $r
            struct.get $task $left
            i32.const 1
            i32.sub
            struct.set $task $left
          )
          (else
            local.get $t
            i32.const 2
            local.get $r
            local.get $i
            call $__task_listen
          )
        )
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $cont
      )
    )
    local.get $r
    struct.get $task $left
    i32.eqz
    (if
      (then
        local.get $r
        local.get $out
        struct.set $task $value
        local.get $r
        ref.null any
        struct.set $task $aux
        local.get $r
        call $__task_wake
      )
    )
    local.get $r
  )
  (func $__chk_fail (param $site (ref null $str))
    local.get $site
    call $__panic_fail
    unreachable
  )
  (data $__d0 "integer overflow: * on i32 at main.bp:2:14")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "[")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 ", ")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "]")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 42
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 1
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 2
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 1
    array.new_data $str $__d3
    global.set $__s3
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
[2, 4, 6]
[3.0, 5.0]
```
