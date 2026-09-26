# actions

> Path: `libs/actions/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)

The bundled `actions` library (decision 116 rule 2): the server-action protocol both
halves read and write — the `state` grammar and `ActionState`, the v1 result envelope,
the JSON-RPC body and the `refresh` value — **one** implementation compiled for erlang
and commonJS (`contracts.md § 3`). The server writes the envelope and reads the RPC
body with it; the browser reads the envelope and writes the RPC body with it; neither
framework keeps a copy or pins the literals — they are asserted once, here.

**Bundled.** `build.zig`'s `bundled_packages` names it after `routing` (it imports
routing): any program's `from "actions"` loads the copy embedded in the compiler, as
`actions/<module>` (atoms `actions@<module>`), with no `dependencies` entry and never from
this directory; listing `actions` in `dependencies` is refused. An edit here reaches a
consumer only through a rebuilt compiler.

It names no field and no header: the hidden form field and the action header are the
deployment's values, passed to both sides by whoever wires them (decision 114 item 7).

Pure `.bp` only (decision 117 rule 8): no `#[@External]` cell, no `declare fn`, no
`.erl` / `.mjs` sidecar, no framework name under `src/`. It imports `std` (`json`,
`encoding`) and the bundled `routing` (`navigation`), nothing else. JSON is written with
std's `json.quote` / `json.array` / `json.object` and read with std's `json.decode`
(member order kept, duplicates refused — the same botopink on both targets).

## Tree

```text
actions/
├── botopink.json      "name": "actions", "target": "erlang", "targets": ["erlang", "commonJS"]
├── AGENTS.md
├── src/root.bp        pub mod state; pub mod envelope; pub mod rpc; pub mod refresh;
├── src/state.bp       ActionState (fieldError, hasError), newActionState, writeState, parseState
├── src/envelope.bp    ActionEnvelope, writeEnvelope, readEnvelope, parseActionState
├── src/rpc.bp         RpcCall, writeRpcBody, parseRpcBody
├── src/refresh.bp     refreshValue
└── test/              state_test · envelope_test · rpc_test · refresh_test (suite `actions:`)
```

Consumers: `import {envelope.writeEnvelope, state.writeState} from "actions";` —
bundled, so no `dependencies` entry (listing it is refused).

## Surface and wires

| Module | Surface | Rules |
|---|---|---|
| `state` | `type ActionState(ok, message, redirectTo, fields: Array<#(string, string)>)` with `fieldError(name)` (`""` when absent) and `hasError()` (`!ok` or any field message); `newActionState(message)` (`ok: true`, no fields); `writeState(message, fields)`; `parseState(state) -> #(message, fields)` | form-encoded with std `encoding.formStringify` / `formParse` (percent-encoded, `+` read as space). `message` is always written first (`message=` when empty), then `f.<name>` per field in order. Reading ignores every key that is neither `message` nor `f.`-prefixed; `""` reads `#("", [])` |
| `envelope` | `type ActionEnvelope(ok, state, revalidated: Array<string>, n, payload)`; `writeEnvelope(e)`; `readEnvelope(text) -> @Result<ActionEnvelope, string>`; `parseActionState(envelope) -> ActionState` (decision 78) | `{"v":1,"ok":…,"state":…,"revalidated":[…],"redirect":…,"n":…,"payload":…}`, `v` first, keys in that order. `redirect` is DERIVED from `n` (routing `signalFromWire(n)`: a redirect's location, else `""`) and has no parameter; the reader refuses an envelope whose `redirect` disagrees with its `n`. Reader: not JSON, not an object, `v` ≠ 1 (missing included), a known key of the wrong kind → `Error` naming it (`actions.readEnvelope: …`); a missing key reads empty, an unknown key is ignored. `parseActionState` takes `ok` / `redirectTo` from the envelope's own keys, never from `state`; an envelope that does not read is `ok: false` with the reader's error as `message` |
| `rpc` | `type RpcCall(id, args: Array<string>)`; `writeRpcBody(call)`; `parseRpcBody(body) -> @Result<RpcCall, string>` | `{"v":1,"id":…,"args":[…]}`. Reader: an empty/whitespace body, not JSON, not an object, `v` ≠ 1, `id` missing / not a string / empty, `args` not an array of strings → `Error` naming it (`actions.parseRpcBody: …`); missing `args` is `[]`; unknown keys ignored |
| `refresh` | `refreshValue()` → `refresh` | the header value asking for a re-render of the current route |

## Testing

```sh
cd libs/actions
../../zig-out/bin/botopink test --target erlang
../../zig-out/bin/botopink test --target commonJS
../../zig-out/bin/botopink format --check src test
```

19 tests (state 7, envelope 7, rpc 4, refresh 1), green on both rows; every expected
text is a literal. `zig build test-libs` runs the two cells.

## Language notes (measured)

- An array's `at(…).unwrapOr(…)` inside a METHOD body of a record is not dispatched
  (erlang: `unwrapOr/2 undefined`; commonJS: `Cannot read properties of undefined`), so
  `ActionState.fieldError` delegates to the module fn `fieldErrorOf`.
- A method of a record reached through another module (`parseActionState(…).fieldError`)
  needs the record TYPE imported in the calling file (`import {ActionState} from "state"`)
  or erlang reports `fieldError/2 undefined`.
- `erlc` crashes (`internal error in pass beam_ssa_opt`, `beam_ssa_type:simplify/2`)
  on: bind a `case` over a `@Result` to a `val`, then `r.unwrapOr(record)` in the `else`
  of an `if … return … else { … }`. `parseActionState` matches `Ok(e)` / `Error(msg)`
  directly instead.
- A bundled library is compiled like any consumer of std: a `behavior` default or
  templated method (`String.chars`, `Bool.negate`, …) is a `String.prototype` /
  `Boolean.prototype` patch on commonJS that only a module using it installs. std's
  `json.decode` once relied on two and failed from here (`s.chars is not a
  function`); it now converts through its own cells. Prefer operators (`!x`) and
  native-named methods in this library.
- `asserts.errorText` takes `@Result<void, string>`; the tests read an `Error` payload
  through a local `case` helper instead.
- Non-ASCII literals are truncated on erlang, so every message text is ASCII.
