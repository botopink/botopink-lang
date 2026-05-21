# compiler-core/src/lexer

> Path: `modules/compiler-core/src/lexer/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Lexer support files. The lexer entry point itself lives at `../lexer.zig`.

## Tree

```text
lexer/
├── AGENTS.md      ← you are here
├── token.zig      ← TokenKind enum + Token struct (lexeme + line/col)
└── tests.zig      ← lexer snapshot tests
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
