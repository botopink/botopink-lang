# compiler-core/src/format/tests

> Path: `modules/compiler-core/src/format/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) (owns the per-file breakdown)

Formatter tests, split by feature (`idempotent.zig` checks `fmt(fmt(x)) == fmt(x)`).
Aggregated by the sibling barrel `../tests.zig` for `test_root.zig`; shared
harness lives in `helpers.zig`.

When adding a test file here, register it in `../tests.zig` or it will not run.
`declarations.zig` ends with front 17's rows: a module-level `var` keeps its
keyword and its `#[@BeamMemory.…]` annotation, and a labelled annotation
argument keeps its label (`assertFormat` + `assertIdempotent`).

## The property `assertIdempotent` does not imply

`helpers.zig` carries three assertions, and the third exists because the first
two were both green on a formatter that **deleted the `default` keyword** and
every comment on an enum variant:

| | Asserts | Blind to |
|---|---|---|
| `assertFormat(src)` | the output equals a text a human wrote | anything nobody thought to write down |
| `assertIdempotent(src)` | pass 2 equals pass 1 | **every deletion** — a file that has lost a comment stays lost, so pass 2 agrees |
| `assertLossless(src)` | no token of the source is missing from the output | a token that **moved** (`assertFormat`'s expected text pins that) |

**Idempotence is not fidelity.** `assertIdempotent` passes on a formatter that
deletes every comment in the file: the deletion happens once, and the second pass
has nothing left to delete. That is exactly how `botopink format` came to rewrite
`pub default mod X;` as `pub mod X;` with 239 tests green — and why
`format --check` then reported the broken file as **clean**. The two are asserted
together now: `assertIdempotent` calls `assertLossless` first, so the pairing
cannot come apart again.

`assertLossless` is defined over the **whole token stream**, not over comments
alone — the deletion that motivated it was a keyword. It is *containment*: every
source token occurs in the output at least as many times. Two exemptions, both
written out in `helpers.zig` so they are reviewable rather than implied:

- `droppable_separators` — `;` `,` `{` `}`, the separators the canonical form may
  add or drop (a single-statement `if` branch loses its braces, an open list
  gains a trailing comma). None of them carries a name.
- the pre-1.0.3 **binding** form — `val Name = behavior { … };` prints as
  `behavior Name { … }`, so that `val` and that `=` are syntax of the form being
  translated. Exempt only in that exact shape: a `val` anywhere else is a binding
  whose loss would be a real one.

Order is not asserted, and the reason was measured rather than assumed: the
surface translations *move* tokens — the name past the keyword above, and
`fn f(s comptime: string)` → `fn f(comptime s: string)`. An ordered subsequence
check fails on all five such cases in `idempotent.zig` with nothing lost at all.

`assertFormatLossless` is the pair `assertFormat` + `assertLossless`; every case
in `comments.zig` uses it, and every case in `idempotent.zig` gets the property
through `assertIdempotent`.

**Measured.** Run at `4841983`, the front's parent, `assertLossless` fails on
**4 of 5** probes: the `default` keyword of `pub default mod` / `pub default fn`
(D1), a trailing comment on an enum variant, a leading one (G3), and the **last**
record field's trailing comment (G2). After D1 alone, 3 of 5. After the parser
and printer commits of step 4, 0.
