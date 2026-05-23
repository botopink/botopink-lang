# Examples — `.bp` token syntax

> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Docs: [`./docs.md`](docs.md)

Concrete snippets of valid `.bp` source showing the syntax the lexer
recognises. Use these as a reference for what each token type looks like
in code.

## Identifiers & keywords

```text
fn        // keyword
val       // keyword
record    // keyword
my_name   // identifier (snake_case)
Counter   // identifier (PascalCase, used for types)
n2        // identifier (digits after first letter)
```

Reserved words may not be used as identifiers — `val val = 1` is an error.

## Integer literals

```text
0
42
1_000_000        // digit separator
0xFF             // hexadecimal
0xFF_FF
0b1010           // binary
0o755            // octal
```

The underscore is purely visual; it disappears during numeric parsing.

## Float literals

```text
3.14
0.5
1.5e10           // scientific
1.5E-10          // upper-case `E`, negative exponent
2e+3             // explicit positive exponent
3.141_592_65     // digit separator inside the mantissa
```

A trailing `.` is **not** a float — `42.` is a parse error. Write `42.0`.

## Unary minus on literals

```text
-42              // two tokens: `-` then `42`
-1.5e-10
val x = -7;      // parsed as UnaryOp(neg, IntLit(7))
```

The lexer always emits `-` and the literal separately; the parser folds
them in the primary expression rule.

## String literals

```text
"hello"
"line one\nline two"
"with \"quotes\""
"unicode: \u{1F600}"
```

Unterminated strings (`"abc` to EOL) raise `LexicalError.UnterminatedString`.

## Operators & punctuation

```text
+ - * / %        // arithmetic
== != < <= > >=  // comparison
&& ||            // logical
|>               // pipeline
= := ->          // binding / assign / fn return
( ) { } [ ]      // grouping
, : ;            // separators
. ..             // member / range
```

## Comments

```text
// single-line comment
// nothing else on the line is tokenised
```

Comments are stripped before the parser sees the token stream. Multi-line
comments are not currently supported.

## A complete tokenizable example

```text
fn area(radius: f32) f32 = {
    val pi = comptime 3.14159265;
    pi * radius * radius
}

val a = area(2.5);
val b = area(-1.0);
```

Every construct above tokenises with no `LexicalError`. Run
`botopink check` to see the parser's view of the same source.

## See also

- Lexer design notes → [`./docs.md`](docs.md).
- Parser consumes these tokens → [`../parser/examples.md`](../parser/examples.md).
- Full language reference → [`../../../../docs.md`](../../../../docs.md).
