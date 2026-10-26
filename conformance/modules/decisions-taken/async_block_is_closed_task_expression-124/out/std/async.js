function __bp_array_at(xs, i) { return xs.at(i) ?? null; }

function __bp_eq(a, b, d) {
    if (Object.is(a, b)) {
        return true;
    }
    if ((((((d > 32) || (a === null)) || (b === null)) || (typeof a !== "object")) || (a.constructor !== b.constructor))) {
        return false;
    }
    if (Array.isArray(a)) {
        return ((a.length === b.length) && a.every((e, i) => __bp_eq(e, b[i], (d + 1))));
    }
    const k = Object.keys(a);
    return ((k.length === Object.keys(b).length) && k.every((n) => __bp_eq(a[n], b[n], (d + 1))));
}

function __bp_task(p) {
    const t = p.then((r) => { if (r != null && "error" in r) { t.__bp_failure = true; throw r.error; } return (r == null) ? r : r.ok; });
    t.__bp_fails = true;
    t.catch(() => {});
    return t;
}

function __bp_await(t) {
    return (t != null && t.__bp_fails === true) ? t.then((v) => ({ ok: v }), (e) => { if (t.__bp_failure === true) { return { error: e }; } throw e; }) : t;
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

// behavior array
//   length: i32
//   fn at(...)
//   fn push(...)
//   fn pop(...)
//   default fn slice(...)
//   fn join(...)
//   fn reverse(...)
//   fn indexOf(...)
//   default fn lastIndexOf(...)
//   fn forEach(...)
//   fn map(...)
//   fn filter(...)
//   fn zip(...)
//   fn range(...)
//   fn repeat(...)
//   default fn isEmpty(...)
//   default fn contains(...)
//   default fn first(...)
//   default fn rest(...)
//   default fn take(...)
//   default fn drop(...)
//   default fn fold(...)
//   default fn find(...)
//   default fn count(...)
//   default fn all(...)
//   default fn any(...)
//   default fn append(...)
//   default fn prepend(...)
//   default fn flatten(...)
//   default fn flatMap(...)
//   default fn toList(...)
//   default fn some(...)
//   default fn every(...)
//   default fn flat(...)
//   default fn findIndex(...)
//   default fn fill(...)
//   default fn chunked(...)
//   default fn sliding(...)
//   default fn unique(...)
Array.range = function(start, stop) { return ((__a, __b) => Array.from({ length: Math.max(0, __b - __a) }, (_, __i) => __a + __i))(start, stop); };
Array.repeat = function(value, times) { return ((__v, __n) => Array.from({ length: Math.max(0, __n) }, () => __v))(value, times); };
Array.prototype.slice = function(start, end) {
    if ((end != null)) { return ((__xs, __a, __e) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); const __f = __e < 0 ? Math.max(__n + __e, 0) : Math.min(__e, __n); return Array.from({ length: Math.max(__f - __b, 0) }, (_, __i) => __xs[__b + __i]); })(this, start, end); } else { return ((__xs, __a) => { const __n = __xs.length; if (__a == null) __a = 0; const __b = __a < 0 ? Math.max(__n + __a, 0) : Math.min(__a, __n); return Array.from({ length: __n - __b }, (_, __i) => __xs[__b + __i]); })(this, start); }
};
Array.prototype.indexOf = function(item) { return this.findIndex((__e) => __bp_eq(__e, item, 0)); };
Array.prototype.lastIndexOf = function(item) { return this.findLastIndex((__e) => __bp_eq(__e, item, 0)); };
Array.prototype.zip = function(other) { return this.map((__x, __i) => [__x, (other)[__i]]).slice(0, Math.min(this.length, (other).length)); };
Array.prototype.isEmpty = function() {
    return (this.length === 0);
};
Array.prototype.contains = function(x) {
    return (this.indexOf(x) !== (-1));
};
Array.prototype.first = function() {
    return __bp_array_at(this, 0);
};
Array.prototype.rest = function() {
    return this.slice(1, this.length);
};
Array.prototype.take = function(n) {
    return this.slice(0, n);
};
Array.prototype.drop = function(n) {
    return this.slice(n, this.length);
};
Array.prototype.fold = function(initial, f) {
    let acc = initial;
    this.forEach((x) => {
    acc = f(acc, x);
});
    return acc;
};
Array.prototype.count = function(pred) {
    return this.filter(pred).length;
};
Array.prototype.all = function(pred) {
    return (this.filter(pred).length === this.length);
};
Array.prototype.any = function(pred) {
    return (this.filter(pred).length !== 0);
};
Array.prototype.prepend = function(item) {
    let out = [item];
    this.forEach((x) => {
    return out.push(x);
});
    return out;
};
Array.prototype.flatten = function() {
    let out = [];
    this.forEach((inner) => {
    out = out.concat(inner);
});
    return out;
};
Array.prototype.toList = function() {
    return this;
};
Array.prototype.some = function(pred) {
    return this.any(pred);
};
Array.prototype.every = function(pred) {
    return this.all(pred);
};
Array.prototype.flat = function() {
    return this.flatten();
};
Array.prototype.findIndex = function(pred) {
    let out = (-1);
    let i = 0;
    this.forEach((x) => {
    (() => { if ((out === (-1))) { return (() => { if (pred(x)) { return out = i; } })(); } })();
    i = (i + 1);
});
    return out;
};
Array.prototype.fill = function(value) {
    return Array.repeat(value, this.length);
};
Array.prototype.chunked = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const len = this.length;
    for (const k of Array.from({length: Math.max(0, (len) - (0))}, (_, __i) => (0) + __i)) {
    (() => { if ((((k % n) + 0) === 0)) { return out = out.concat([this.slice(k, (k + n))]); } })();
}
    return out;
};
Array.prototype.sliding = function(n) {
    let out = [];
    if ((n <= 0)) { return out; }
    const windows = ((this.length - n) + 1);
    if ((windows <= 0)) { return out; }
    for (const k of Array.from({length: Math.max(0, (windows) - (0))}, (_, __i) => (0) + __i)) {
    out = out.concat([this.slice(k, (k + n))]);
}
    return out;
};
Array.prototype.unique = function() {
    let out = [];
    this.forEach((x) => {
    return (() => { if ((!out.any((y) => {
    return __bp_eq(y, x, 0);
}))) { return out = out.concat([x]); } })();
});
    return out;
};

// behavior Integer extends Number
//   fn toString(...)
//   default fn isEven(...)
//   default fn isOdd(...)
//   fn toI32(...)
//   fn toI64(...)
//   fn toU32(...)
//   fn toU64(...)
//   fn toF64(...)
BigInt.prototype.isEven = Number.prototype.isEven = function() {
    const self = this.valueOf();
    return ((self % 2) === 0);
};
BigInt.prototype.isOdd = Number.prototype.isOdd = function() {
    const self = this.valueOf();
    return ((self % 2) !== 0);
};
BigInt.prototype.toI32 = Number.prototype.toI32 = function() { return ((__v) => { if (__v >= -2147483648 && __v <= 2147483647) { return Number(__v); } throw new Error("integer overflow: toI32: " + __v + " does not fit i32"); })(this.valueOf()); };
BigInt.prototype.toI64 = Number.prototype.toI64 = function() { return ((__v) => { if (__v >= -9223372036854775808n && __v <= 9223372036854775807n) { return (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; } throw new Error("integer overflow: toI64: " + __v + " does not fit i64"); })(this.valueOf()); };
BigInt.prototype.toU32 = Number.prototype.toU32 = function() { return ((__v) => { if (__v >= 0 && __v <= 4294967295) { return Number(__v); } throw new Error("integer overflow: toU32: " + __v + " does not fit u32"); })(this.valueOf()); };
BigInt.prototype.toU64 = Number.prototype.toU64 = function() { return ((__v) => { if (__v >= 0 && __v <= 18446744073709551615n) { return __v; } throw new Error("integer overflow: toU64: " + __v + " does not fit u64"); })(this.valueOf()); };
BigInt.prototype.toF64 = Number.prototype.toF64 = function() { return ((__v) => { const __f = Number(__v); if (typeof __v !== "bigint" || BigInt(__f) === __v) { return __f; } throw new Error("integer overflow: toF64: " + __v + " has no exact f64"); })(this.valueOf()); };

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

const failure = require("../std/failure.js");

// ── instruments ──────────────────────────────────────────────────────────────

// Which backend is running. The future surface's erlang behaviour differs from

// its commonJS behaviour by design, and a test that asserts one of the two has

// to know which it is looking at. Private: the divergence is this module's to

// document, not a consumer's to branch on.

// hostTarget: per-call template (see annotation)

// The host's monotonic clock in milliseconds. `std/io/clock` has the same cell,

// and this root module may not import from `io/` (decision 106), so this file

// carries its own. Private — `clock.monotonicMillis()` is the public spelling.

// monoMillis: per-call template (see annotation)

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

// delay: per-call template (see annotation)
function delay(millis, value) { return ((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))(millis, value); }
exports.delay = delay;

// A Async whose value is `Error(message)` — the failing instrument `allOf` and

// `timeout` are tested with. On commonJS it rejects with `message` (decision

// 432); `await` reads it as `Error(message)`.

function failed(message) {
    return __bp_task((async () => {
        return ({ error: message });
    })());
}
exports.failed = failed;

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

class Gate {
    constructor(handle) {
        this.handle = handle;
    }
}
Gate.prototype.__bp = "Gate";
exports.Gate = Gate;

// gateHandle: per-call template (see annotation)

// gateOpen: per-call template (see annotation)

// gateAwait: per-call template (see annotation)

// A new, closed gate.

function newGate() {
    return new Gate(({ opened: false, waiters: [] }));
}
exports.newGate = newGate;

// Open `gate`: every task awaiting it answers, and so does every later

// `awaitGate`. Opening an open gate changes nothing.

function openGate(gate) {
    ((__g) => { __g.opened = true; for (const __w of __g.waiters.splice(0)) { __w(); } return undefined; })(gate.handle);
}
exports.openGate = openGate;

// `true` once `gate` is open, `false` when `millis` pass first. The budget is

// not the ordering — the gate is; it only turns a gate nobody opens into a red

// assertion instead of a hang, so a test gives it a margin no scheduling delay

// can cross (seconds) and opens every gate it closes. An open gate answers at

// once and leaves no timer behind.

async function awaitGate(gate, millis) {
    return await ((__g, __ms) => __g.opened ? Promise.resolve(true) : new Promise((__r) => { const __on = () => { clearTimeout(__t); __r(true); }; const __t = setTimeout(() => { __g.waiters = __g.waiters.filter((__w) => __w !== __on); __r(false); }, __ms); __g.waiters.push(__on); }))(gate.handle, millis);
}
exports.awaitGate = awaitGate;

// ── reading a settled element ────────────────────────────────────────────────

// The `Error` payload of a `Result<T, string>`, or `""` for `Ok`. `Result`

// carries `isOk`/`isError`/`unwrapOr` as builtins but no way to read the error

// side, so without this a caller can see THAT a widget failed and never WHY —

// the shape decision 67 refuses.

function errorText(settled) {
    const text = (() => {
        const _s = settled;
        if ("ok" in _s) {
            const _v = _s.ok;
            return "";
        }
        if ("error" in _s) {
            const e = _s.error;
            return e;
        }
        throw new Error("case_clause");
    })();
    return text;
}
exports.errorText = errorText;

// ── started tasks ────────────────────────────────────────────────────────────

// The values of every Async, in input order, or the FIRST `Error` in input

// order. The tasks were started by the caller (`allOf([fetchUser(1),

// fetchUser(2)])`), so on commonJS they run concurrently and this only waits;

// on erlang they already ran. `allOf([])` answers `Ok([])`.

function allOf(tasks) {
    return __bp_task((async () => {
        let out = [];
        for (const t of tasks) {
    const _try0 = await __bp_await(t);
        if ("error" in _try0) return _try0;
        const v = _try0.ok;
    out = out.concat([v]);
}
        return ({ ok: out });
    })());
}
exports.allOf = allOf;

// The values of every Async, in input order — the infallible `allOf`.

async function all(tasks) {
    let out = [];
    for (const t of tasks) {
    const v = await __bp_await(t);
    out = out.concat([v]);
}
    return out;
}
exports.all = all;

// commonJS: the FASTEST Async to answer, `Promise.race`.

// ERLANG: ELEMENT ZERO. Every Async resolved before the call, so there is no

// timing left to measure and this answers the first element of the list. That

// is not a bug to be fixed here and no server front may depend on it — use

// `raceOf`, whose tasks are unstarted when it receives them. Both behaviours

// are pinned by `async: race ---- commonJS fastest, erlang element zero`.

// 

// `race([])` is a programming error, fatal on both targets

// (`async.race: empty task list`).

// race: per-call template (see annotation)
function race(tasks) { return ((__fs) => __fs.length === 0 ? Promise.reject(new Error('async.race: empty task list')) : Promise.race(__fs.map(((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t))))(tasks); }
exports.race = race;

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

// spawnAll: per-call template (see annotation)

// The public face of the cell above: a real function, so a module compiled

// separately (the BEAM backend links modules by name) can call it — a

// template-only `declare fn` has no body to export.

async function runAll(tasks) {
    return await Promise.all((tasks).map((__f) => ((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t)((__f)())));
}
exports.runAll = runAll;

// The first task to ANSWER, not the first in the list. The LOSERS keep

// running and their values are discarded: there is no cancellation surface in

// botopink, and a race that reported the loser would not be a race.

// 

// `raceOf([])` is a programming error, fatal on both targets

// (`async.raceOf: empty task list`), rather than blocking forever.

// raceOf: per-call template (see annotation)
function raceOf(tasks) { return ((__ts) => __ts.length === 0 ? Promise.reject(new Error('async.raceOf: empty task list')) : Promise.race(__ts.map((__f) => ((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t)((__f)()))))(tasks); }
exports.raceOf = raceOf;

// `task`'s value as `Ok` — the racer `timeout` puts beside the clock.

function answered(task) {
    return __bp_task((async () => {
        return ({ ok: await __bp_await(task()) });
    })());
}

// `Error("timeout")` after `millis` — the clock `timeout` races against

// `task`, whose type it answers in (decision 668: `task` binds `T`).

function expireAfter(task, millis) {
    return __bp_task((async () => {
        await ((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))(millis, 0);
        return ({ error: "timeout" });
    })());
}

// `Ok(value)` when the task answered inside the budget, `Error("timeout")`

// when it did not. A task over a `Result` keeps its own failure INSIDE the

// `Ok` (`Ok(Error(e))`): the budget and the task's outcome are two answers,

// and neither hides the other. The task KEEPS RUNNING; the caller stops

// waiting. Expressed over `raceOf` + `delay`.

function timeout(task, millis) {
    return __bp_task((async () => {
        return await __bp_await(((__ts) => __ts.length === 0 ? Promise.reject(new Error('async.raceOf: empty task list')) : Promise.race(__ts.map((__f) => ((__t) => (__t != null && __t.__bp_fails === true) ? __t.then((__v) => ({ ok: __v }), (__e) => { if (__t.__bp_failure === true) { return { error: __e }; } throw __e; }) : __t)((__f)()))))([() => {
    return answered(task);
}, () => {
    return expireAfter(task, millis);
}]));
    })());
}
exports.timeout = timeout;

// ── retry (1.0.11-beta front 97) ─────────────────────────────────────────────

// How a fallible task is tried again: at most `maxAttempts` attempts, a pause

// of `initialMillis` after the first failure, each later pause `multiplier`

// times the one before, none above `maxMillis`. There is no jitter and no

// field that means "for ever" (decision 67): a policy is usable only when

// `maxAttempts` is at least 1, the two delays are not negative, `maxMillis`

// is at most 2147483647 (the longest timer both targets arm) and `multiplier`

// is at least 1.0 — a backoff never shrinks, and one that could would retry

// in a near-zero-delay loop.

class RetryPolicy {
    constructor(maxAttempts, initialMillis, multiplier, maxMillis) {
        this.maxAttempts = maxAttempts;
        this.initialMillis = initialMillis;
        this.multiplier = multiplier;
        this.maxMillis = maxMillis;
    }
}
RetryPolicy.prototype.__bp = "RetryPolicy";
RetryPolicy.prototype.__bp_s = { multiplier: "f" };
exports.RetryPolicy = RetryPolicy;

// Internal: why `policy` is not usable, `""` when it is.

function policyProblem(policy) {
    if ((policy.maxAttempts < 1)) { return "maxAttempts must be at least 1 (the first attempt)"; }
    if ((policy.initialMillis < 0)) { return "initialMillis must not be negative"; }
    if ((policy.maxMillis < 0)) { return "maxMillis must not be negative"; }
    if ((policy.maxMillis > 2147483647)) { return "maxMillis must be at most 2147483647"; }
    const grows = (policy.multiplier >= 1.0);
    if ((grows === false)) { return "multiplier must be at least 1.0 (a backoff never shrinks)"; }
    return "";
}

// Internal: an `i64` of milliseconds as an `f64`, and back — the whole

// milliseconds of a delay that is never negative. Not `toF64()`, which aborts

// on an integer past 2^53 that no `f64` holds: the delay is a float

// computation, and an `initialMillis` that large rounds as the float does

// (and is then capped by `maxMillis`). The Node forms take and answer

// decision 319's canonical form — `Number` reads a `BigInt` (`initialMillis`

// past 2^53 − 1), and a whole number past 2^53 − 1 answers as a `BigInt`.

// millisAsFloat: per-call template (see annotation)

// wholeMillis: per-call template (see annotation)

// Internal: `initial × multiplier^(attempt − 1)`, never above `ceiling`. One

// multiplication per attempt — the same IEEE operations in the same order on

// both targets, where a host `pow` would not promise the same last bit — and

// none once the ceiling is reached, so it cannot overflow.

function grown(initial, multiplier, ceiling, attempt) {
    const steady = ((multiplier <= 1.0) || (initial <= 0.0));
    if (steady) { return (() => { if ((initial > ceiling)) { return ceiling; } else { return initial; } })(); }
    let pause = initial;
    let step = 1;
    while (((step < attempt) && (pause < ceiling))) {
    pause = (pause * multiplier);
    step = __bp_int((step + 1), -2147483648, 2147483647, "+ on i32 at src/async.bp:335:21");
}
    return (() => { if ((pause > ceiling)) { return ceiling; } else { return pause; } })();
}

// The pause that follows attempt `attempt` (the first attempt is 1), in whole

// milliseconds: `initialMillis × multiplier^(attempt − 1)`, rounded down and

// never above `maxMillis`. `null` once `attempt` is past `maxAttempts` — there

// is no further attempt to wait for — and for an attempt below 1 or a policy

// that is not usable.

function nextDelay(policy, attempt) {
    const usable = (policyProblem(policy) === "");
    const inside = ((attempt >= 1) && (attempt <= policy.maxAttempts));
    const answers = (usable && inside);
    if ((answers === false)) { return null; }
    return ((__x) => { const __f = Math.floor(__x); return Number.isSafeInteger(__f) ? __f : BigInt(__f); })(grown(Number(policy.initialMillis), policy.multiplier, Number(policy.maxMillis), attempt));
}
exports.nextDelay = nextDelay;

// Internal: attempt number `attempt` of `retry`, and every one after it.

function retryFrom(policy, work, attempt, __bp_ty_T, __bp_ty_E) {
    return __bp_task((async () => {
        const outcome = await __bp_await(work());
        const settled = (((_r) => !("error" in _r))(outcome) || (attempt >= policy.maxAttempts));
        if (settled) { return outcome; }
        const pause = (() => { const __bp_nullish = nextDelay(policy, attempt); if (__bp_nullish != null) { return __bp_nullish; } else { return policy.maxMillis; } })();
        await ((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))(pause.toI32(), 0);
        return await __bp_await(retryFrom(policy, work, __bp_int((attempt + 1), -2147483648, 2147483647, "+ on i32 at src/async.bp:371:54")));
    })());
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

function retry(policy, work, __bp_ty_T, __bp_ty_E) {
    return __bp_task((async () => {
        const problem = policyProblem(policy);
        (() => { if ((problem !== "")) { return (() => { throw Object.defineProperty(new Error(["async.retry: ", problem].join("")), '__bp_panic', { value: true }) })(); } })();
        return await __bp_await(retryFrom(policy, work, 1));
    })());
}
exports.retry = retry;

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

class Probe {
    constructor(id, label) {
        this.id = id;
        this.label = label;
    }
}
Probe.prototype.__bp = "Probe";

// How long a test task waits on a gate before it gives up. Every gate a test

// closes is opened again, so this passes only when the code under test is

// wrong — and then as a red assertion, not a hang.

const gateBudget = 10000;

// `value` once `gate` opens; a value naming the failure when it never does.

async function gated(gate, value) {
    const opened = await awaitGate(gate, gateBudget);
    return (() => { if (opened) { return value; } else { return ("gate never opened: " + value); } })();
}

// Open `mine`, then answer `value` once `theirs` is open. Two of these over the

// same pair of gates, crossed, can only BOTH answer when they run at the same

// time: whichever runs first alone waits on a gate the other has not opened.

async function handshake(mine, theirs, value) {
    openGate(mine);
    return await gated(theirs, value);
}

// `value` with no timer at all: resolved in the microtask queue on commonJS,

// the process's first reply on erlang.

async function answerNow(value) {
    return value;
}

// ── delay and failed ─────────────────────────────────────────────────────────

// ── gates ────────────────────────────────────────────────────────────────────

// ── allOf and all ────────────────────────────────────────────────────────────

function slowOk(millis, value) {
    return __bp_task((async () => {
        return ({ ok: await ((__ms, __v) => new Promise((__r) => { const __end = performance.now() + __ms; const __tick = () => { const __left = __end - performance.now(); if (__left > 0) { setTimeout(__tick, Math.ceil(__left)); } else { __r(__v); } }; setTimeout(__tick, __ms); }))(millis, value) });
    })());
}

// ── runAll ───────────────────────────────────────────────────────────────────

// A settled element to stand in for the `?T` fallback of `.at(i)`. `Array.at`

// answers an optional and `unwrapOr` needs a value of the element type, which

// here is itself a `Result`; this is the cheapest way to spell one.

function errorProbe() {
    return ({ error: "async: no element" });
}

// ── raceOf ───────────────────────────────────────────────────────────────────

// ── timeout ──────────────────────────────────────────────────────────────────

// The expired task of the test above: waits for `release`, opens `done` and

// answers.

async function ghost(release, done) {
    const v = await gated(release, "late");
    openGate(done);
    return v;
}

// ── retry ────────────────────────────────────────────────────────────────────

// Internal, test scaffolding: a counter the attempts of one `retry` share —

// a closure cannot count on erlang, where a `var` it captures is a copy.

// Node: an object. Erlang: a `counters` reference.

// newCounter: per-call template (see annotation)

// Count one more and answer the count.

// countUp: per-call template (see annotation)

// countOf: per-call template (see annotation)

// The text a task panics with, `""` when it answered — a panic inside a

// `-> Async` function is a rejected Promise on commonJS and a raise on erlang.

async function panicOf(body) {
    const r = await __bp_await(failure.attemptTask(body));
    return (() => {
        const _s = r;
        if ("ok" in _s) {
            return "";
        }
        if ("error" in _s) {
            const f = _s.error;
            return f.message;
        }
        throw new Error("case_clause");
    })();
}

// Attempt `n` of a task that fails until its `succeedAt`-th call:

// `Error("failure <n>")` before it, `Ok("ok after <n>")` from it on. The test

// counts the call (`flaky(countUp(calls), …)`), so the counter's cells are

// reached from the tests alone, and a module importing `async` on a target

// with no counter (wasm) links no call of them.

function flaky(n, succeedAt) {
    return __bp_task((async () => {
        if ((n < succeedAt)) { return ({ error: ["failure ", n.toString()].join("") }); }
        return ({ ok: ["ok after ", n.toString()].join("") });
    })());
}

// What `nextDelay(policy, attempt)` answers, as text: the milliseconds, or

// `none`.

function pauseText(policy, attempt) {
    const pause = nextDelay(policy, attempt);
    return (() => { if ((pause != null)) { return pause.toString(); } else { return "none"; } })();
}

// `pauseText` for attempts 1 to `last`, joined by `,`.

function pauses(policy, last) {
    return Array.range(1, __bp_int((last + 1), -2147483648, 2147483647, "+ on i32 at src/async.bp:727:24")).map((attempt) => {
    return pauseText(policy, attempt);
}).join(",");
}

Object.defineProperty(exports, "__bp_priv__", { value: { failure, delay, failed, Gate, newGate, openGate, awaitGate, errorText, allOf, all, race, runAll, raceOf, answered, expireAfter, timeout, RetryPolicy, policyProblem, grown, nextDelay, retryFrom, retry, Probe, gateBudget, gated, handshake, answerNow, slowOk, errorProbe, ghost, panicOf, flaky, pauseText, pauses } });
