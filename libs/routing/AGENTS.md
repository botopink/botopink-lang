# routing

> Path: `libs/routing/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)

The bundled `routing` library (decisions 115, 116, 117): the route matcher and the
routing wires that the server and the browser must both run, **one** implementation
compiled for erlang and commonJS (`contracts.md § 1`). Neutral like std — no framework
imports another to get the matcher; both import it by name,
`import {match.matchPath, table.parseTable} from "routing";`.

**Bundled.** `build.zig`'s `bundled_packages` names it, so the compiler embeds these
`src/` files and loads them (as `routing/<module>`, atoms `routing@<module>`) for any
program that imports `from "routing"` — with no `dependencies` entry, and never from this
directory; listing `routing` in `dependencies` is refused. An edit here reaches a
consumer only through a rebuilt compiler (`zig build`).

Pure `.bp` only (decision 117 rule 8): no `#[@External]` cell, no `declare fn`, no
`.erl` / `.mjs` sidecar, and no framework name anywhere under `src/`. It imports `std`
and nothing else (`url_rules` uses `encoding.percentDecode` / `percentEncode`, `match`
uses `collections.Dict`).

## Tree

```text
routing/
├── AGENTS.md
├── botopink.json      ← "name": "routing", "target": "erlang", "targets": ["erlang", "commonJS"], `files` = every src module
├── src/
│   ├── root.bp        ← `pub mod` per module, a module before the siblings that import it
│   ├── segment.bp     ← SegmentKind, Segment, parseSegment, kindName, pathProblem, trimSlashes, parsePath, patternOf, slotOf
│   ├── table.bp       ← RouteEntry, writeTable, parseTable, kindLabel            (the route table wire, `kind|pattern|slot|verb`)
│   ├── match.bp       ← RouteMatch, matchPath, layoutChain, paramOf, paramsOf, splitPath, attempt, Attempt, segmentWeight, scoreBeats, ancestorPatterns
│   ├── route_kinds.bp ← RouteKind { Static, Dynamic }, writeKinds, parseKinds, routeKindOf   (the `k` blob, `pattern|S|D`)
│   ├── slot_states.bp ← SlotState { Matched, Defaulted, Unchanged, Empty }, writeSlotStates, parseSlotStates   (the `z` blob, `slot|pattern|M|D|U|E`)
│   ├── url_rules.bp   ← PathRules, canonicalize, clientHref, RedirectRule, writeRedirectTable, parseRedirectTable   (`source|destination|1|0`)
│   ├── navigation.bp  ← NavKind { None, NotFound, Redirect }, NavOutcome, signalReason, signalFromReason, isSignalReason, signalPrefixes, signalToWire, signalFromWire
│   └── pattern.bp     ← PatternSegment { Literal, Param, Rest }, parsePattern, matchPattern, patternProblem   (the `:param` grammar)
└── test/              ← one `<module>_test.bp` per module, suite `routing:`
```

## Wires and rules

| Module | Wire / rule | Reading | Writing |
|---|---|---|---|
| `table` | `kind\|pattern\|slot\|verb`, trailing empty fields dropped; kinds `L T P D R S E N` | a short line reads as empty fields | — |
| `route_kinds` | `pattern\|K`, `K` = `S` or `D` | tolerant: a malformed line is skipped; an unnamed pattern is `Dynamic` | strict: `\|`/newline in a pattern halts |
| `slot_states` | `slot\|pattern\|state`, state `M D U E` | tolerant: a line without 3 fields is skipped; an unknown letter is `Empty` | strict: `\|`/newline in a slot or pattern halts |
| `url_rules` | `source\|destination\|1\|0` | tolerant | strict, naming the rule |
| `navigation` | reasons `nav:not-found`, `nav:redirect:<loc>` (307), `nav:permanent-redirect:<loc>` (308), `nav:see-other:<loc>` (303); wire `""` / `N` / `R\|<status>\|<loc>` | the wire is tolerant (anything else is `None`; the location keeps its `\|`); a `nav:` reason with an unknown verb halts, naming the verb | `signalReason(None)` and a redirect status outside 303/307/308 halt |
| `pattern` | literal, `:param`, trailing `:param*` | anything else (`*`, `[`, `(`, `?`, `{`, a bare `:`) is an `Error` whose text is `patternProblem`'s; `:param*` not last is an `Error` | — |

`url_rules.canonicalize` strips `basePath`, applies `trailingSlash`, then percent-decodes
**once**; the query / fragment (from the first `?` or `#`) pass through untouched; a path
outside `basePath` is answered unchanged; an undecodable escape keeps its raw text.
`clientHref` percent-encodes each segment, applies `trailingSlash`, prefixes `basePath`.
The empty `:param` pattern matches only `/` — a caller whose "no pattern" means "every
path" says so itself.

## Testing

```sh
cd libs/routing
../../zig-out/bin/botopink test --target erlang
../../zig-out/bin/botopink test --target commonJS
../../zig-out/bin/botopink format --check src test
```

`zig build test-libs` discovers the package as the cells `routing · erlang` and
`routing · commonJS`. Every expected wire string in the tests is a literal, never a second
call's output. Enum values are compared through a local `case` helper, arrays element by
element (`==` on arrays is reference equality).

## Language notes (measured on the compiler this library landed on)

- The erlang backend refuses a `try` statement inside a `while` body that also reassigns
  a `var` (`variable 'I@2' unsafe in 'case'`) — loops in tests use `assert`, not `try`.
- A `throw` inside a `while` that mutates `var`s, and a `case` over
  `xs.at(i).unwrapOr(Enum.Variant(…))` inside a loop, do not compile on erlang — the
  parser and the matcher compute a problem string first and `throw` after the loop, and
  read enum payloads through a private `case`-returning helper.
- On commonJS a `case (r) { .Ok(_) -> return a; .Error(e) -> return e; }` statement as a
  function's last statement fails with `JumpInValuePosition`; bind a `case r { Ok(_) ->
  a; Error(e) -> e; }` expression instead.
- `asserts.throwsWith` cannot match a needle through a non-ASCII refusal text on erlang
  (the harness reads the `~p` rendering), so every refusal text is ASCII.
- `String.slice` counts bytes on erlang and UTF-16 units on commonJS; every substring goes
  through a private `charOf` / `sub` pair.
