# compiler-core/src/lexer — tokenizer reference

> Path: `modules/compiler-core/src/lexer/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Examples: [`./examples.md`](examples.md)

Detailed notes for the lexer entry point (`../lexer.zig`) and the support
files in this directory (`token.zig`, `tests.zig`).

## Tree

```text
lexer/
├── token.zig      ← TokenKind enum + Token struct (lexeme + line/col)
└── tests.zig      ← lexer snapshot tests
```

## Token shape

```zig
Token {
    kind:   TokenKind,
    lexeme: []const u8,  // exact slice of source for this token
    line:   usize,       // 1-based
    col:    usize,       // 1-based
}
```

Tokens never allocate — the `lexeme` is a slice into the original source
string. This means the lifetime of `Token` is bounded by the lifetime of the
source buffer.

## Invariants

| Invariant | Why |
|---|---|
| `Lexer.init(source)` does **not** store an allocator | The token list is the caller's responsibility (`scanAll(alloc)` materializes it) |
| `lexeme` is always a slice of `source` | Snapshot stability + zero-alloc tokens |
| Lexical errors are reported as `LexicalError`, not parser errors | Keeps phase boundaries clean |
| Trivia (whitespace, comments) is dropped before the parser sees tokens | Parser stays declarative; trivia rules live here |

## Numeric literal extensions

The lexer handles three modern niceties around numbers:

| Form | Example | Notes |
|---|---|---|
| Digit separators | `1_000_000`, `0xFF_FF` | Underscores are stripped during lexeme → value conversion |
| Scientific notation | `1.5e-10`, `2E+3` | `e` or `E`; explicit sign optional |
| Unary minus | `-42`, `-1.5e-10` | The lexer emits two tokens; the parser folds them in the primary expression rule |

Unary minus is handled by the parser (`parser.zig` → `parsePrimary`) rather
than the lexer to keep the lexer free of expression-grammar concerns.

## Lexer error policy

Prefer reporting `LexicalError` over a parser error when the token itself is
malformed (e.g. unterminated string, invalid escape, malformed number). The
parser should never have to re-validate token text.

## See also

- Token examples and edge cases → [`./examples.md`](examples.md).
- Lexer façade entry → [`../lexer.zig`](../lexer.zig).
- Parser consumes these tokens → [`../parser/docs.md`](../parser/docs.md).
