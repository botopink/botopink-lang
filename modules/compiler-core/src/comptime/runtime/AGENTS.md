# core/src/comptime/runtime

Comptime evaluation runtime backends. Each backend builds a script from typed
comptime expressions, runs it via the external runtime, and parses the JSON
output back into a map of `id → literal string`.

## Files

| File | Runtime | Command | Output format |
|---|---|---|---|
| `node.zig` | Node.js | `node <script.js>` | JSON array via `process.stdout.write` |
| `erlang.zig` | Erlang/OTP | `escript` or `erlc` + `erl` | JSON array via `json:encode/1` |

## Shared interface

Both backends expose the same public function:

```zig
pub fn run(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
) !eval.RunResult
```

Returns `eval.RunResult`:
- `.script` — the generated source code (JS or Erlang)
- `.values` — `std.StringHashMap([]const u8)` mapping comptime IDs to literal strings

## Build directory layout

Scripts are written to `.botopinkbuild/<build_root>/<runtime>/`:

```
.botopinkbuild/
  node/
    main.js          # generated JavaScript
  erlang/
    main.erl         # generated Erlang module
    main.beam        # compiled beam (erlc output)
```

The previous build is cleaned on each run via `deleteTree`.

## Node.js backend (`node.zig`)

### Script structure
```javascript
const fs = require('fs');
const results = [
    { id: "ct_0", value: <expr> },
    ...
];
process.stdout.write(JSON.stringify(results));
```

### Expression mapping
| botopink | JavaScript |
|---|---|
| `.numberLit` | `42` |
| `.stringLit` | `"hello"` |
| `.add` | `(a + b)` |
| `.sub` | `(a - b)` |
| `.mul` | `(a * b)` |
| `.div` | `(a / b)` |
| `.mod` | `(a % b)` |
| `.arrayLit` | `[elem, ...]` |
| `.comptimeBlock` | value from `break` |

### Result parsing
JSON values are converted to JS literals:
- `integer` / `float` → number string (`"42"`, `"3.14"`)
- `bool` → `"true"` / `"false"`
- `null` → `"null"`
- `string` → quoted string (`'"hello"'`)
- `array` → JS array literal (`'[1, 2, 3]'`)

## Erlang backend (`erlang.zig`)

### Script structure
```erlang
-module(main).
-export([main/1]).

main(_) ->
    Values = [
        #{<<"id">> => <<"ct_0">>, <<"value">> => <expr>},
        ...
    ],
    Json = json:encode(Values),
    io:format("~s~n", [Json]).
```

### Compilation & execution
1. Write `main.erl` to `.botopinkbuild/erlang/`
2. Compile: `erlc -o .botopinkbuild/erlang/ main.erl`
3. Run: `erl -noshell -pa .botopinkbuild/erlang/ -eval "main:main(ok)." -s init stop`

### Expression mapping
| botopink | Erlang |
|---|---|
| `.numberLit` | `42` |
| `.stringLit` | `<<"hello">>` |
| `.add` | `(A + B)` |
| `.sub` | `(A - B)` |
| `.mul` | `(A * B)` |
| `.div` | `(A div B)` |
| `.mod` | `(A rem B)` |
| `.arrayLit` | `[Elem, ...]` |
| `.comptimeBlock` | value from `break` |

### Result parsing
JSON values are converted to Erlang literals:
- `integer` / `float` → number string (`"42"`, `"3.14"`)
- `bool` → `"true"` / `"false"`
- `null` → `"undefined"`
- `string` → Erlang binary (`'<<"hello">>'`)
- `array` → Erlang list (`'[1, 2, 3]'`)

## Dependencies

- **Node.js** — must be available on PATH for `node.zig`
- **Erlang/OTP** — `erlc` and `erl` must be available on PATH for `erlang.zig`
- **`json` module** — Erlang's `json:encode/1` must be available (OTP 25+ or `jsx`/`jiffy`)

## Conventions

See `../AGENTS.md` for comptime module architecture. Both backends:
- Use `std.process.run` to execute the runtime
- Parse JSON from stdout via `std.json.parseFromSlice`
- Return evaluated literals as target-language strings for codegen injection
- Clean previous builds before writing new scripts
