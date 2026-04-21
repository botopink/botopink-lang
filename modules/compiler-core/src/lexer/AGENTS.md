# core/src/lexer

Lexer support files. The lexer entry point is `../lexer.zig`.

## Files

| File | Role |
|---|---|
| `token.zig` | `TokenKind` enum and `Token` struct (lexeme + line/col positions) |
| `tests.zig` | Lexer snapshot tests |

## Token struct

```zig
Token {
    kind:   TokenKind,
    lexeme: []const u8,  // the actual source text of this token
    line:   usize,       // 1-based line number
    col:    usize,       // 1-based column
}
```

`Lexer.init(src).scanAll(allocator)` returns `[]Token`.

## Conventions

See `../AGENTS.md` for core architecture. Lexing errors are `LexicalError` kinds — prefer lexical errors over parser errors when token is malformed.
