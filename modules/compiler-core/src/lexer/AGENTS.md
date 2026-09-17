# compiler-core/src/lexer

> Path: `modules/compiler-core/src/lexer/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Lexer support files. The lexer entry point itself lives at `../lexer.zig`.

## Tree

```text
lexer/
├── AGENTS.md      ← you are here
├── token.zig      ← TokenKind enum + Token struct (lexeme + line/col); `record`/`enum`/`interface` are no longer lexed (declaration-kind tags for the language server only)
├── tests.zig      ← barrel importing every tests/<feature>.zig
└── tests/         ← lexer tests, split by feature
    ├── helpers.zig    ← placeholder harness module (no helpers defined)
    ├── basics.zig     ← empty/whitespace/identifier/number basics
    ├── recognizes.zig ← single-token recognition
    ├── tokenizes.zig  ← multi-token sequences
    ├── strings.zig    ← string literals, escapes, unicode
    ├── keywords.zig   ← reserved words, self/Self, semicolons
    └── errors.zig     ← error tokens & cross-stage error-message units
```

## `Token`

```zig
Token {
    kind:   TokenKind,
    lexeme: []const u8,  // exact slice of source for this token
    line:   usize,       // 1-based, the line the token STARTS on
    col:    usize,       // 1-based, measured from the start of `line`
    offset: usize,       // byte offset of the token's first byte in the source
}
```

`source[offset..offset + lexeme.len]` is the token's text. Diagnostics and LSP
ranges are built from `offset` (`ParseErrorInfo.fromToken`), never from `col`.

### A token's location is where it STARTS

Multi-line tokens (`"""…"""`, `\\ …` line strings) advance the scanner's
`line`/`lineStart` as they consume embedded newlines. `scanAll` snapshots both
into `tokenLine`/`tokenLineStart` before each token, and `addToken` stamps
those — so a `"""` literal is located at its opening quotes, not at its
closing ones. `newlineAt()` is the single place that advances `line` +
`lineStart` together for a newline the scanner walks over inside a literal;
before it existed, `line` moved but `lineStart` did not, and every token on the
closing line of a multi-line literal got a column counted from the opening
line.

Usage: `var l = Lexer.init(source); const tokens = try l.scanAll(alloc);
defer l.deinit(alloc);` — `scanAll` returns `[]const Token` owned by the lexer.
`Lexer.init` does **not** store an allocator.

## Notes

- Prefer reporting a lexical error over a parser error when the token itself is
  malformed: `scanAll` returns `LexerError.LexicalError` and fills
  `Lexer.lexError: ?LexicalError` (`LexicalErrorType`: `DigitOutOfRadix`,
  `RadixIntNovalue`, `BadStringEscape`, `InvalidUnicodeEscape`,
  `InvalidTripleEqual`).
- Numeric literals support `1_000_000` digit separators and scientific notation
  (`1.5e-10`, `2E+3`); unary `-` is handled in the parser primary.
- A new `tests/*.zig` file only runs once it is imported from `tests.zig`.

## A digit after a member `.` is a positional index

`scanNumber` checks the previous token: a number that starts right after a `.`
(adjacent, `prev.offset + 1 == start`) scans integer digits only. `t.0.1` is
`t . 0 . 1` (two tuple indexes), not `t . 0.1`, and `p.0.toString()` is not the
float `0.`. Every other number keeps the decimal / radix / exponent rules.
