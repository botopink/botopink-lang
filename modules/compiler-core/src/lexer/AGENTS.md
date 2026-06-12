# compiler-core/src/lexer

> Path: `modules/compiler-core/src/lexer/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Lexer support files. The lexer entry point itself lives at `../lexer.zig`.

## Tree

```text
lexer/
├── AGENTS.md      ← you are here
├── docs.md        ← tokenizer reference (invariants, error policy)
├── examples.md    ← `.bp` token syntax (numbers, strings, identifiers)
├── token.zig      ← TokenKind enum + Token struct (lexeme + line/col)
├── tests.zig      ← barrel: aggregates tests/<feature>.zig for test_root.zig
└── tests/         ← lexer tests, split by feature
    ├── helpers.zig    ← shared harness (`pub fn assertTokens`, imports)
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

Usage: `Lexer.init(source).scanAll(alloc)` returns `[]Token`. `Lexer.init`
does **not** store an allocator.

## Notes

- Prefer reporting `LexicalError` over a parser error when the token itself is
  malformed.
- Numeric literals support `1_000_000` digit separators, scientific notation
  (`1.5e-10`, `2E+3`), and unary `-` is handled in the parser primary.
