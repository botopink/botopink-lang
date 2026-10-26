function __bp_adopt(v, C, p) { return (v == null) ? v : (p === "") ? ((typeof v === "object" && !(v instanceof C)) ? Object.assign(Object.create(C.prototype), v) : v) : (p[0] === "a") ? (Array.isArray(v) ? v.map((e) => __bp_adopt(e, C, p.slice(1))) : v) : (p[0] === "r" && typeof v === "object" && "ok" in v) ? { ok: __bp_adopt(v.ok, C, p.slice(1)) } : v; }

//// std/io/os — host OS introspection, cross-backend.

//// 

//// Reference:

////   Node.js  — https://nodejs.org/api/os.html

////              (`os.hostname()`, `os.arch()`, `os.cpus()`, `os.tmpdir()`,

////               `os.userInfo()`, `os.EOL`)

////   Erlang   — https://www.erlang.org/doc/apps/stdlib/erlang.html

////              + https://www.erlang.org/doc/apps/stdlib/filename.html

////              (`inet:gethostname/0`, `erlang:system_info(schedulers_online)`,

////               `filename:basedir/2`, `os:getenv("USER")`)

//// 

//// Each Node template inlines `require('os')` at the call site —

//// `os` is NOT a JS global so the §A2 alias path can't reach it; the

//// arity-branched template form rolls the require + the call into a

//// single expression that renders per call (cheap — Node caches the

//// require).

//// 

//// `cpuCount()` returns the count of logical cores; `tmpdir()` is the

//// host's temp directory; `userInfo()` returns the calling user's uid

//// + username; `eol()` is the platform line-terminator; `target()` is the

//// build's target, read when the program runs.

// Host hostname.

// Node: `require('os').hostname()` (re-require'd inline per call).

// Erlang: `inet:gethostname()` returns `{ok, Name}` (charlist).

// hostname: per-call template (see annotation)
function hostname() { return require('os').hostname(); }
exports.hostname = hostname;

// Host CPU architecture string — `'x64'`, `'arm64'`, etc. std's one

// `arch`: `io.process` declared the same function (`process.arch`) and was

// folded here.

// Node: `require('os').arch()`.

// Erlang: `erlang:system_info(system_architecture)`.

// arch: per-call template (see annotation)
function arch() { return require('os').arch(); }
exports.arch = arch;

// Count of logical CPU cores available to the runtime.

// Node: `require('os').cpus().length`.

// Erlang: `erlang:system_info(schedulers_online)` returns the count

// of online schedulers — the BEAM analogue of "available cores".

// cpuCount: per-call template (see annotation)
function cpuCount() { return require('os').cpus().length; }
exports.cpuCount = cpuCount;

// Host temp directory (an absolute path).

// Node: `require('os').tmpdir()`.

// Erlang: best-effort via the `TMPDIR` env var with a fallback to

// `/tmp` — matches the POSIX convention; on Windows the BEAM-side

// fallback would need `os:getenv("TEMP")` (deferred).

// tmpdir: per-call template (see annotation)
function tmpdir() { return require('os').tmpdir(); }
exports.tmpdir = tmpdir;

// Calling user's basic identity. Node returns a structured object; on

// Erlang there is no direct `os:userInfo` BIF so the template lifts the

// `USER` env var (falling back to `<<"unknown">>`) and reads the uid

// from `process_info` — best-effort, the Erlang side stays informative

// without claiming POSIX-grade accuracy. The Erlang term is the record's

// own run-time shape (13-module-identity decision 21): the tagged tuple

// `{'<module atom>@@<Type>', <fields in declared order>}`, which is

// what `u.username` reads a position out of.

class UserInfo {
    constructor(uid, username) {
        this.uid = uid;
        this.username = username;
    }
}
UserInfo.prototype.__bp = "UserInfo";
exports.UserInfo = UserInfo;

// userInfo: per-call template (see annotation)
function userInfo() { return __bp_adopt((() => { const __u = require('os').userInfo(); return { uid: __u.uid, username: __u.username } })(), UserInfo, ""); }
exports.userInfo = userInfo;

// Platform line terminator — `"\n"` on POSIX, `"\r\n"` on Windows.

// Node reads `require('os').EOL`; Erlang branches on `os:type/0`.

// eol: per-call template (see annotation)
function eol() { return require('os').EOL; }
exports.eol = eol;

// The target the program runs on (decision 989 (7)): `commonJS`, `erlang`,

// `beam` or `wasm` — each target's own constant. The beam target reads the

// erlang cell and answers its own text instead: the assembler writes `beam`

// (`codegen/beam_asm.zig`, `os_target_template`). A run-time answer only: no

// comptime cell serves it, so a build body that reaches it is refused

// (decision 798 (4)) — comptime runs on wasm whatever the target.

// target: per-call template (see annotation)
function target() { return 'commonJS'; }
exports.target = target;

// ── tests ────────────────────────────────────────────────────────────────────

Object.defineProperty(exports, "__bp_priv__", { value: { hostname, arch, cpuCount, tmpdir, UserInfo, userInfo, eol, target } });
