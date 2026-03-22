# botopink

> Compiler for the botopink language, written in [Zig](https://ziglang.org/).

## Overview

**botopink** is a programming language with its own syntax, currently in early development. This repository contains the compiler frontend: lexer, parser, and AST (Abstract Syntax Tree) representation.

## Project Structure

```
src/
├── main.zig            # Entry point
├── root.zig            # Library root (aggregates tests)
├── lexer.zig           # Main lexer
├── lexer/
│   ├── token.zig       # Token and TokenKind definitions
│   └── tests.zig       # Lexer tests
├── parser.zig          # Main parser
├── parser/
│   └── tests.zig       # Parser tests
├── ast.zig             # AST nodes (Expr, Stmt, Decl, ...)
└── print.zig           # Debug/print utilities
```

## Features

### Lexer
- Full tokenization of the botopink language
- Numeric literals in multiple bases (binary `0b`, octal `0o`, hexadecimal `0x`)
- String literals with escape sequences, including `\u{...}` for Unicode
- Integer, float (`.` suffix), and string (`++`) operators
- Structured lexical error reporting with exact position (byte offset, line, column)

### Parser
- Produces an AST from the token stream
- Declarations: `use`, `interface`, `struct`, `record`, `implement`
- Expressions: literals, field access, method calls, binary operators, `return`, `throw`
- Structured parse error reporting with position and context

### AST
- Typed representation of all language nodes via Zig's `union(enum)`
- Parameter modifiers and generic parameters
- Support for getters, setters, and methods in structs

## Requirements

- [Zig](https://ziglang.org/download/) `0.14.0` or later

## Usage

```bash
# Build the project
zig build

# Run the tests
zig build test
```

## Examples

### `use` — Module imports

```botopink
// Import from a string path
use {foo, bar, baz} from "my-lib"

// Import via function call (dynamic source)
use {x, y} from loader()

// Empty import (module executed for side effects)
use {} from init()
```

### `interface` — Behaviour contract

```botopink
val Drawable = interface {
    val color: String

    // Abstract method — must be implemented
    fn draw(self: Self)

    // Method with a default implementation
    fn log(self: Self) {
        Console.WriteLine("Rendering object with color: " ++ self.color)
    }
}

val Canvas = interface {
    fn clear(self: Self)
    fn drawLine(self: Self, x1: Int, y1: Int)
    fn drawRect(self: Self, x: Int, y: Int, color: String)
}
```

### `struct` — Type with encapsulated state

```botopink
val Account = struct {
    // Private field
    private val _balance: number = 0

    // Getter
    get balance(self: Self) -> number {
        return self._balance
    }

    // Setter with validation
    set balance(self: Self, value: number) {
        throw new Error("Balance cannot be negative")
    }

    // Setter with assignment
    set balance(self: Self, value: number) {
        self._balance = value
    }

    // Method
    fn deposit(self: Self, amount: number) {
        self._balance += amount
    }
}
```

### `record` — Immutable data type (product type)

```botopink
// Simple record
val Point = record(val x: number, val y: number) {}

// Record with a method
val GPSCoordinates = record(val lat: number, val lon: number) {
    fn toString(self: Self) -> String {
        return "Lat: " ++ self.lat ++ " Lon: " ++ self.lon
    }
}
```

### `implement` — Interface implementation for a type

```botopink
// Single interface
val CircleDrawing = implement Drawable for Circle {
    fn draw(self: Self) {}
}

// Multiple interfaces — qualifier resolves name ambiguity
val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
    fn UsbCharger.Connect(self: Self) {
        Console.WriteLine("Connected via USB. Battery level: " ++ self.batteryLevel)
    }
    fn SolarCharger.Connect(self: Self) {
        Console.WriteLine("Connected via Solar Panel. Battery level: " ++ self.batteryLevel)
    }
}
```