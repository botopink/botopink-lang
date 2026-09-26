----- SOURCE CODE -- std/io/env.bp
```botopink
//// std/io/env — process environment variables, cross-backend.
////
//// Reference:
////   Node.js  — https://nodejs.org/api/process.html#processenv
////   Erlang   — https://www.erlang.org/doc/man/os.html#getenv-1
////
//// `read(name)` looks up the host env var, returning `?string` (null
//// when the var is unset). `write(name, value)` and `clear(name)`
//// mutate the process env table — call ordering matters across modules
//// that read the same vars. The fn names avoid the reserved keywords
//// `get` / `set` (which introduce struct getters/setters in the
//// grammar — see `parser.zig isMemberName`), so the env reads
//// `env.read("HOME")` rather than `env.get("HOME")`.

// Read the value of env var `name`, or `null` when unset.
// Node: `(process.env[$0] ?? null)` (the property-access form keeps
// arbitrary key names usable; `?? null` coerces `undefined` to the bp
// `?string` representation).
// Erlang: `os:getenv($0)` returns either a charlist or `false`; the
// template lifts `false` to `undefined` (the bp `null`) and the
// charlist to a binary.
#[@External.Node("""(process.env[$0] ?? null)""")]
#[@External.Erlang("""(fun(__N) -> case os:getenv(binary_to_list(__N)) of false -> undefined; __V -> list_to_binary(__V) end end)($0)""")]
pub declare fn read(name: string) -> ?string;

// Write `value` to env var `name`. The host APIs mutate the process
// env table in place.
#[@External.Node("""(process.env[$0] = $1)""")]
#[@External.Erlang("os:putenv(binary_to_list($0), binary_to_list($1))")]
pub declare fn write(name: string, value: string) -> void;

// Clear env var `name`. After this call, `read(name)` returns `null`.
#[@External.Node("""(delete process.env[$0])""")]
#[@External.Erlang("os:unsetenv(binary_to_list($0))")]
pub declare fn clear(name: string) -> void;

// Program arguments, excluding the runtime and the script path.
// Node: `process.argv.slice(2)` (drops `node` + the script entry).
// Erlang: `init:get_plain_arguments/0` returns a list of charlists;
// the template projects each through `list_to_binary/1` so the result
// is `[binary()]`, matching the bp `string[]` representation.
#[@External.Node("""(process.argv.slice(2))""")]
#[@External.Erlang("""[list_to_binary(__A) || __A <- init:get_plain_arguments()]""")]
pub declare fn args() -> string[];

// All env vars as `(name, value)` pairs.
// Node: `Object.entries(process.env)` — each entry arrives as a
// `[name, value]` two-element array; per botopink's tuple
// representation on Node, `#(string, string)` lowers to a two-element
// array, so the shape passes through directly.
// Erlang: walk `os:getenv/0` (returns `[Name=Value]` charlists),
// split each entry on the first `=` and project to a `{binary, binary}`
// 2-tuple matching the bp `#(string, string)` shape. (`os:list_env_vars/0`
// would be cleaner but is not on every OTP release.)
#[@External.Node("""(Object.entries(process.env))""")]
#[@External.Erlang("""(fun() -> [(fun(__E) -> [__K, __V] = string:split(__E, "=", leading), {list_to_binary(__K), list_to_binary(__V)} end)(__E) || __E <- os:getenv()] end)()""")]
pub declare fn vars() -> Array<#(string, string)>;

// ── tests ────────────────────────────────────────────────────────────────────

test "env.write + env.read round-trips a value" {
    write("BOTOPINK_TEST_KEY", "round-trip-value");
    val v = read("BOTOPINK_TEST_KEY");
    assert v.unwrapOr("missing") == "round-trip-value";
}

test "env.read returns null for an unset key" {
    clear("BOTOPINK_TEST_UNSET");
    val v = read("BOTOPINK_TEST_UNSET");
    assert v.unwrapOr("absent") == "absent";
}

test "env.clear cancels a prior write" {
    write("BOTOPINK_TEST_CYCLE", "alive");
    clear("BOTOPINK_TEST_CYCLE");
    val v = read("BOTOPINK_TEST_CYCLE");
    assert v.unwrapOr("dead") == "dead";
}

test "env.args returns an array (possibly empty under the lib-test runner)" {
    val xs = args();
    assert xs.length >= 0;
}

test "env.vars yields a non-empty pair list after env.write" {
    write("BOTOPINK_TEST_ARGSVARS", "alive");
    val pairs = vars();
    val n = pairs.length;
    assert n > 0;
    clear("BOTOPINK_TEST_ARGSVARS");
}

```

----- BEAM ASSEMBLY -- std/io/env.S
```erlang
{module, std@io@env}.
{exports, [{read, 1}, {write, 2}, {clear, 1}, {args, 0}, {vars, 0}]}.
{attributes, []}.
{labels, 52}.
%%% std/io/env — process environment variables, cross-backend.
%%% 
%%% Reference:
%%%   Node.js  — https://nodejs.org/api/process.html#processenv
%%%   Erlang   — https://www.erlang.org/doc/man/os.html#getenv-1
%%% 
%%% `read(name)` looks up the host env var, returning `?string` (null
%%% when the var is unset). `write(name, value)` and `clear(name)`
%%% mutate the process env table — call ordering matters across modules
%%% that read the same vars. The fn names avoid the reserved keywords
%%% `get` / `set` (which introduce struct getters/setters in the
%%% grammar — see `parser.zig isMemberName`), so the env reads
%%% `env.read("HOME")` rather than `env.get("HOME")`.
% Read the value of env var `name`, or `null` when unset.
% Node: `(process.env[$0] ?? null)` (the property-access form keeps
% arbitrary key names usable; `?? null` coerces `undefined` to the bp
% `?string` representation).
% Erlang: `os:getenv($0)` returns either a charlist or `false`; the
% template lifts `false` to `undefined` (the bp `null`) and the
% charlist to a binary.

{function, read, 1, 13}.
  {label, 12}.
    {line, [{location, "std@io@env.erl", 1}]}.
    {func_info, {atom, std@io@env}, {atom, read}, 1}.
  {label, 13}.
    {call_only, 1, {f, 3}}.
% Write `value` to env var `name`. The host APIs mutate the process
% env table in place.

{function, write, 2, 17}.
  {label, 16}.
    {line, [{location, "std@io@env.erl", 2}]}.
    {func_info, {atom, std@io@env}, {atom, write}, 2}.
  {label, 17}.
    {call_only, 2, {f, 15}}.
% Clear env var `name`. After this call, `read(name)` returns `null`.

{function, clear, 1, 21}.
  {label, 20}.
    {line, [{location, "std@io@env.erl", 3}]}.
    {func_info, {atom, std@io@env}, {atom, clear}, 1}.
  {label, 21}.
    {call_only, 1, {f, 19}}.
% Program arguments, excluding the runtime and the script path.
% Node: `process.argv.slice(2)` (drops `node` + the script entry).
% Erlang: `init:get_plain_arguments/0` returns a list of charlists;
% the template projects each through `list_to_binary/1` so the result
% is `[binary()]`, matching the bp `string[]` representation.

{function, args, 0, 31}.
  {label, 30}.
    {line, [{location, "std@io@env.erl", 4}]}.
    {func_info, {atom, std@io@env}, {atom, args}, 0}.
  {label, 31}.
    {call_only, 0, {f, 23}}.
% All env vars as `(name, value)` pairs.
% Node: `Object.entries(process.env)` — each entry arrives as a
% `[name, value]` two-element array; per botopink's tuple
% representation on Node, `#(string, string)` lowers to a two-element
% array, so the shape passes through directly.
% Erlang: walk `os:getenv/0` (returns `[Name=Value]` charlists),
% split each entry on the first `=` and project to a `{binary, binary}`
% 2-tuple matching the bp `#(string, string)` shape. (`os:list_env_vars/0`
% would be cleaner but is not on every OTP release.)

{function, vars, 0, 51}.
  {label, 50}.
    {line, [{location, "std@io@env.erl", 5}]}.
    {func_info, {atom, std@io@env}, {atom, vars}, 0}.
  {label, 51}.
    {call_only, 0, {f, 33}}.
% ── tests ────────────────────────────────────────────────────────────────────

{function, '__bp_tpl_0-t/1-fun-0-', 1, 7}.
  {label, 6}.
    {func_info, {atom, std@io@env}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 1}.
  {label, 7}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, os, getenv, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 11}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 11}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, list_to_binary, 1}, 3}.

{function, '__bp_tpl_0', 1, 3}.
  {label, 2}.
    {func_info, {atom, std@io@env}, {atom, '__bp_tpl_0'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1', 2, 15}.
  {label, 14}.
    {func_info, {atom, std@io@env}, {atom, '__bp_tpl_1'}, 2}.
  {label, 15}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext_last, 2, {extfunc, os, putenv, 2}, 4}.

{function, '__bp_tpl_2', 1, 19}.
  {label, 18}.
    {func_info, {atom, std@io@env}, {atom, '__bp_tpl_2'}, 1}.
  {label, 19}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, os, unsetenv, 1}, 2}.

{function, '__bp_tpl_3', 0, 23}.
  {label, 22}.
    {func_info, {atom, std@io@env}, {atom, '__bp_tpl_3'}, 0}.
  {label, 23}.
    {allocate, 6, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, nil, {y, 1}}.
    {call_ext, 0, {extfunc, init, get_plain_arguments, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 2}}.
  {label, 27}.
    {move, {y, 2}, {x, 0}}.
    {test, is_nonempty_list, {f, 28}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 2}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_binary, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 2, 0}.
    {put_list, {y, 5}, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 27}}.
  {label, 28}.
    {move, {y, 2}, {x, 0}}.
    {test, is_nil, {f, 29}, [{x, 0}]}.
    {jump, {f, 26}}.
  {label, 29}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 26}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_4--t/0-fun-0--fun-1-', 1, 45}.
  {label, 44}.
    {func_info, {atom, std@io@env}, {atom, '__bp_tpl_4--t/0-fun-0--fun-1-'}, 1}.
  {label, 45}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {literal, [61]}, {x, 1}}.
    {move, {atom, leading}, {x, 2}}.
    {call_ext, 3, {extfunc, string, split, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 48}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_nonempty_list, {f, 48}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 7}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_nil, {f, 48}, [{x, 0}]}.
    {jump, {f, 49}}.
  {label, 48}.
    {move, {y, 3}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_binary, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_binary, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_tpl_4-t/0-fun-0-', 0, 37}.
  {label, 36}.
    {func_info, {atom, std@io@env}, {atom, '__bp_tpl_4-t/0-fun-0-'}, 0}.
  {label, 37}.
    {allocate, 6, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, nil, {y, 1}}.
    {call_ext, 0, {extfunc, os, getenv, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 2}}.
  {label, 41}.
    {move, {y, 2}, {x, 0}}.
    {test, is_nonempty_list, {f, 42}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 2}}.
    {move, {y, 4}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 45}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 2, 0}.
    {put_list, {y, 5}, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 41}}.
  {label, 42}.
    {move, {y, 2}, {x, 0}}.
    {test, is_nil, {f, 43}, [{x, 0}]}.
    {jump, {f, 40}}.
  {label, 43}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 40}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_tpl_4', 0, 33}.
  {label, 32}.
    {func_info, {atom, std@io@env}, {atom, '__bp_tpl_4'}, 0}.
  {label, 33}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- std/probe.bp
```botopink
import {io: {env: {read}}} from "std";

pub fn home() -> ?string {
    return read("HOME");
}
```

----- COMPILE DIAGNOSTIC -- std/probe
```text
error: std-root-imports-io: std module `probe` is at the root of std, which is pure; `io.env.read` imports from `io/`
  ┌─ std/probe.bp:1:20
  │
1 │ import {io: {env: {read}}} from "std";
  │                    ^

  hint: Move the module under `io/` (it talks to the world), or take the value it needs as a parameter.
```

