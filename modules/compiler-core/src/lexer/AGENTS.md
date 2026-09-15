# compiler-core/src/lexer

> Path: `modules/compiler-core/src/lexer/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Lexer support files. The lexer entry point itself lives at `../lexer.zig`.

## Tree

```text
lexer/
├── AGENTS.md      ← you are here
├── token.zig      ← TokenKind enum + Token struct (lexeme + line/col)
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
    line:   usize,       // 1-based
    col:    usize,       // 1-based
}
```

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
