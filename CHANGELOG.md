# Changelog

All notable changes to this project will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/).

---

## [0.0.1-beta] - 2026-03-23

### Added

#### Lexer (`src/lexer.zig`, `src/lexer/token.zig`)
- Full tokenization of the botopink language
- Numeric literals in binary (`0b`), octal (`0o`), and hexadecimal (`0x`) bases
- String literals with standard escape sequences and Unicode (`\u{...}`)
- Integer operators: `+`, `-`, `*`, `/`, `<`, `>`, `<=`, `>=`, `%`
- Float operators with `.` suffix: `+.`, `-.`, `*.`, `/.`, `<.`, `>.`, `<=.`, `>=.`
- String concatenation operator `++`
- Punctuation operators: `:`, `,`, `#`, `!`, `=`, `==`, `!=`, `|`, `||`, `&&`, `<<`, `>>`, `|>`, `.`, `->`, `..`, `@`, `+=`
- Grouping delimiters: `(`, `)`, `[`, `]`, `{`, `}`
- Language keywords and identifiers
- Position tracking by byte offset, line, and column
- Comments: normal (`//`) and module doc (`///`)

#### Lexical Errors (`LexicalError`, `LexerError`)
- `DigitOutOfRadix` — digit invalid for the given numeric base
- `RadixIntNoValue` — base prefix with no following digits
- `BadStringEscape` — invalid escape sequence inside a string
- `InvalidUnicodeEscape` — malformed `\u{...}` or codepoint outside the valid Unicode range
- `InvalidTripleEqual` — explicit rejection of the `===` operator
- `UnexpectedSemicolon` — rejection of semicolons as statement separators

#### Parser (`src/parser.zig`)
- Recursive-descent parser consuming a token stream
- Supported declarations: `use`, `interface`, `struct`, `record`, `implement`
- Parameter modifiers (`ParamModifier`) and generic parameters (`GenericParam`)
- Getters and setters in structs
- Qualified method names in `implement` blocks (e.g. `Interface.Method`)

#### Parse Errors (`ParseErrorInfo`, `ParseError`)
- `UnexpectedToken` — unexpected token with position and lexeme reported
- `ReservedWord` — reserved word used as an identifier
- `NoValBinding` — assignment without `val`/`var`
- `OpNakedRight` — binary operator with no right-hand side
- `ListSpreadWithoutTail` — list spread with no tail (`[1, 2, ..]`)
- `ListSpreadNotLast` — elements after a spread in a list (`[..xs, 1, 2]`)
- `UselessSpread` — spread with no elements to its left (`[..xs]`)

#### AST (`src/ast.zig`)
- Expression nodes: `StringLit`, `NumberLit`, `SelfField`, `SelfFieldAssign`, `SelfFieldPlusEq`, `Concat`, `Ident`, `StaticCall`, `ThrowNew`, `Return`, `Lt`
- Top-level declarations: `UseDecl`, `InterfaceDecl`, `StructDecl`, `RecordDecl`, `ImplementDecl`
- `Program` type grouping all file-level declarations

#### Infrastructure
- Entry point `main.zig`
- `root.zig` as library root aggregating all test modules
- Test suites for lexer (`src/lexer/tests.zig`) and parser (`src/parser/tests.zig`)
- `print.zig` with AST debug/print utilities

---

[0.0.1-beta]: https://github.com/your-username/botopink/releases/tag/v0.0.1-beta
