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

const failure = require("../../std/failure.js");
const { Failure } = require("../../std/failure.js");

// ── boolean ──────────────────────────────────────────────────────────────────

// Fails when `condition` is false.

function isTrue(condition) {
    if ((condition === false)) { return ({ error: "asserts.isTrue: condition was false" }); }
    return ({ ok: null });
}
exports.isTrue = isTrue;

// Fails when `condition` is true — the dual of `isTrue`, for "this must not

// happen" branches you would otherwise spell as `isTrue(!cond)`.

function isFalse(condition) {
    if (condition) { return ({ error: "asserts.isFalse: condition was true" }); }
    return ({ ok: null });
}
exports.isFalse = isFalse;

// ── equality ─────────────────────────────────────────────────────────────────

// Fails when `actual != expected` (the language's `==`; see the docblock).

function equals(actual, expected) {
    if ((!__bp_eq(actual, expected, 0))) { return ({ error: "asserts.equals: values differ" }); }
    return ({ ok: null });
}
exports.equals = equals;

// Fails when `actual == expected`.

function notEquals(actual, expected) {
    if (__bp_eq(actual, expected, 0)) { return ({ error: "asserts.notEquals: values match" }); }
    return ({ ok: null });
}
exports.notEquals = notEquals;

// Fails when `|actual - expected| > tolerance`. Pick a tolerance that fits the

// operation's numerical budget, not `0.0`. The absolute value is an inline

// `if` rather than `math.abs` — a std module does not import another.

function approxEquals(actual, expected, tolerance) {
    const diff = (actual - expected);
    const absDiff = (() => { if ((diff >= 0.0)) { return diff; } else { return (0.0 - diff); } })();
    if ((absDiff > tolerance)) { return ({ error: "asserts.approxEquals: values differ by more than tolerance" }); }
    return ({ ok: null });
}
exports.approxEquals = approxEquals;

// Private: a value rendered canonically by the host — `JSON.stringify` on

// Node, `io_lib:format("~0tp")` on Erlang. Lifted from the old onze's

// `onzeKey`, where it keyed the call log for the same reason: two values that

// render the same are structurally equal on that host.

// canonical: per-call template (see annotation)

// Fails when the two values differ structurally — arrays and records by

// content, on every target. Needs Node or Erlang at run time (`canonical`).

function deepEquals(actual, expected) {
    if ((JSON.stringify(actual) !== JSON.stringify(expected))) { return ({ error: "asserts.deepEquals: values differ structurally" }); }
    return ({ ok: null });
}
exports.deepEquals = deepEquals;

// ── nil ──────────────────────────────────────────────────────────────────────

// Fails when the optional holds a value. `!= null`, never truthiness — on

// commonJS `if (x)` is false for `0`.

function isNil(value) {
    if ((value != null)) { return ({ error: "asserts.isNil: value was present" }); }
    return ({ ok: null });
}
exports.isNil = isNil;

// Fails when the optional is absent.

function isNotNil(value) {
    if ((value == null)) { return ({ error: "asserts.isNotNil: value was null" }); }
    return ({ ok: null });
}
exports.isNotNil = isNotNil;

// ── result ───────────────────────────────────────────────────────────────────

// Fails when `result` is `Error`. Read the payload at the call site with the

// builtin methods (`try equals(r.unwrapOr(0), 42);`).

function isOk(result) {
    if (((_r) => "error" in _r)(result)) { return ({ error: "asserts.isOk: result was Error" }); }
    return ({ ok: null });
}
exports.isOk = isOk;

// Fails when `result` is `Ok`. To assert that a `Result`-returning body

// fails, this is the tool — `throws` is for a `panic` or a host throw.

function isError(result) {
    if (((_r) => !("error" in _r))(result)) { return ({ error: "asserts.isError: result was Ok" }); }
    return ({ ok: null });
}
exports.isError = isError;

// ── string ───────────────────────────────────────────────────────────────────

// Fails when `needle` is not a substring of `actual`.

function contains(actual, needle) {
    if ((actual.includes(needle) === false)) { return ({ error: "asserts.contains: needle not in actual" }); }
    return ({ ok: null });
}
exports.contains = contains;

// Fails when `needle` is a substring of `actual`.

function notContains(actual, needle) {
    if (actual.includes(needle)) { return ({ error: "asserts.notContains: needle found in actual" }); }
    return ({ ok: null });
}
exports.notContains = notContains;

// Fails when `actual` does not start with `prefix`.

function startsWith(actual, prefix) {
    if ((actual.startsWith(prefix) === false)) { return ({ error: "asserts.startsWith: prefix does not match" }); }
    return ({ ok: null });
}
exports.startsWith = startsWith;

// Fails when `actual` does not end with `suffix`.

function endsWith(actual, suffix) {
    if ((actual.endsWith(suffix) === false)) { return ({ error: "asserts.endsWith: suffix does not match" }); }
    return ({ ok: null });
}
exports.endsWith = endsWith;

// Private `regex.matches` twin, actual-first: inlined here rather than via a

// cross-module call so this file stays self-contained (std-internal modules

// do not import each other). PCRE-ish on both hosts.

// regexMatches: per-call template (see annotation)

// Fails when the regular expression `pattern` (the host's native flavour)

// does not match `actual`. Use `contains` for a literal needle. Needs Node or

// Erlang at run time (`regexMatches`).

function matches(actual, pattern) {
    if (((new RegExp(pattern).test(actual)) === false)) { return ({ error: "asserts.matches: pattern did not match" }); }
    return ({ ok: null });
}
exports.matches = matches;

// ── collection ───────────────────────────────────────────────────────────────

// Fails when the array has elements.

function isEmpty(actual) {
    if ((actual.length !== 0)) { return ({ error: "asserts.isEmpty: array was not empty" }); }
    return ({ ok: null });
}
exports.isEmpty = isEmpty;

// Fails when the array is empty.

function isNotEmpty(actual) {
    if ((actual.length === 0)) { return ({ error: "asserts.isNotEmpty: array was empty" }); }
    return ({ ok: null });
}
exports.isNotEmpty = isNotEmpty;

// Fails when the array's length is not `expected`.

function lengthIs(actual, expected) {
    if ((actual.length !== expected)) { return ({ error: "asserts.lengthIs: length differs" }); }
    return ({ ok: null });
}
exports.lengthIs = lengthIs;

// Fails when no element `==` `element` (`Array.indexOf` — reference equality

// for records on commonJS; extract with `.at(i)` and `deepEquals` instead).

function includes(actual, element) {
    if ((actual.indexOf(element) < 0)) { return ({ error: "asserts.includes: element not found" }); }
    return ({ ok: null });
}
exports.includes = includes;

// Fails when some element `==` `element`.

function notIncludes(actual, element) {
    if ((actual.indexOf(element) >= 0)) { return ({ error: "asserts.notIncludes: element found" }); }
    return ({ ok: null });
}
exports.notIncludes = notIncludes;

// ── numeric ──────────────────────────────────────────────────────────────────

// Fails when `actual` is outside `[low, high]` (both ends included). `i32`

// only: a generic `T` cannot be compared with `<`, and `f64` callers have

// `approxEquals`. `positive`/`negative` are `greaterThan(x, 0)`/`lessThan(x, 0)`.

function between(actual, low, high) {
    // Bound first: an `if (a < b || c > d)` condition does not parse today;
    // (the condition grammar stops at `||`; a `val` initialiser takes the;
    // whole expression) — a parser gap, recorded by the front that owns it.;
    const outside = ((actual < low) || (actual > high));
    if (outside) { return ({ error: "asserts.between: value out of range" }); }
    return ({ ok: null });
}
exports.between = between;

// Fails when `actual <= bound`.

function greaterThan(actual, bound) {
    if ((actual <= bound)) { return ({ error: "asserts.greaterThan: value not greater" }); }
    return ({ ok: null });
}
exports.greaterThan = greaterThan;

// Fails when `actual >= bound`.

function lessThan(actual, bound) {
    if ((actual >= bound)) { return ({ error: "asserts.lessThan: value not less" }); }
    return ({ ok: null });
}
exports.lessThan = lessThan;

// ── exceptions ───────────────────────────────────────────────────────────────

// Private: the message `failure.attempt` caught, or `""` for a body that

// completed.

function caughtMessage(r) {
    const text = (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
            return "";
        }
        if ("error" in _s) {
            const f = _s.error;
            return f.message;
        }
        throw new Error("case_clause");
    })();
    return text;
}

// Fails when `body` completes normally — for a `panic` or a host raise from

// code whose return carries no `Result` (a failing `Result` is `isError`).

// Generic over the body's own type and run under `failure.attempt` (decisions

// 431, 493), so it needs Node or Erlang at run time.

function throws(body) {
    const r = failure.attempt(body);
    if (((_r) => !("error" in _r))(r)) { return ({ error: "asserts.throws: body did not raise" }); }
    return ({ ok: null });
}
exports.throws = throws;

// Fails when `body` completes normally, or when the caught message does not

// contain `needle`. The message is `failure.attempt`'s `Failure.message`: a

// `panic(text)` / `@todo(text)` is its own `text` on every target, byte for

// byte — a needle with a `"`, a `\` or a non-ASCII character matches alike;

// any other host raise is its JS `message` (else `String(e)`) on Node and

// the reason by `~tp` on Erlang (`badarg`).

function throwsWith(body, needle) {
    const r = failure.attempt(body);
    if (((_r) => !("error" in _r))(r)) { return ({ error: "asserts.throwsWith: body did not raise" }); }
    if ((caughtMessage(r).includes(needle) === false)) { return ({ error: "asserts.throwsWith: message does not contain needle" }); }
    return ({ ok: null });
}
exports.throwsWith = throwsWith;

// ── utility ──────────────────────────────────────────────────────────────────

// Always `Error("asserts.fail: <message>")` — the one function whose message

// carries caller text; the escape for a branch the test asserts is unreachable.

function fail(message) {
    return ({ error: ("asserts.fail: " + message) });
}
exports.fail = fail;

// The `Error` payload of an assertion's result, or `""` for `Ok`. Not

// a `-> Result` fn: it is how a test reads a failure message to compare or

// snapshot it (`test-snap.md`), matching over the builtin `Result` enum in a

// function the manual-construction rule does not apply to.

function errorText(r) {
    const text = (() => {
        const _s = r;
        if ("ok" in _s) {
            const v = _s.ok;
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

// ── tests ────────────────────────────────────────────────────────────────────

// One test per function per path, written with `try`; a fail path asserts

// `isError` over the assertion's own result and pins the literal message

// through `errorText` (no host cell, no panic).

function parsePort(s) {
    if ((s === "")) { return ({ error: "empty input" }); }
    return ({ ok: 8080 });
}

function explode() {
    (() => { throw Object.defineProperty(new Error("boom: the widget is on fire"), '__bp_panic', { value: true }) })();
    return 0;
}

// boolean

// equality

// nil

// result

// string

// collection

// numeric

// exceptions

function quoteRaiser() {
    (() => { throw Object.defineProperty(new Error("withHeader(\"Set-Cookie\", v) \\ twice"), '__bp_panic', { value: true }) })();
    return 0;
}

// utility

Object.defineProperty(exports, "__bp_priv__", { value: { failure, Failure, isTrue, isFalse, equals, notEquals, approxEquals, deepEquals, isNil, isNotNil, isOk, isError, contains, notContains, startsWith, endsWith, matches, isEmpty, isNotEmpty, lengthIs, includes, notIncludes, between, greaterThan, lessThan, caughtMessage, throws, throwsWith, fail, errorText, parsePort, explode, quoteRaiser } });
