# botopink Language Reference

Complete examples and language features organized by topic. Each example is backed by a snapshot test in the codegen suite.

## Table of Contents

- [Imports](#imports)
- [Variables](#variables)
- [Functions](#functions)
- [Operators](#operators)
- [Conditionals](#conditionals)
- [Error Handling](#error-handling)
- [Null Safety](#null-safety)
- [Structs](#structs)
- [Records](#records)
- [Enums](#enums)
- [Interfaces](#interfaces)
- [Pattern Matching](#pattern-matching)
- [Loops](#loops)
- [Lambdas](#lambdas)
- [Comptime Evaluation](#comptime-evaluation)
- [Function Specialization](#function-specialization)
- [Loop Unrolling](#loop-unrolling)
- [Delegates](#delegates)
- [Implement](#implement)
- [Destructuring](#destructuring)
- [Arrays and Tuples](#arrays-and-tuples)

---

## Imports

### Named imports

```botopink
use { foo, bar } from "mylib";
```

**Generates:**
```javascript
const { foo, bar } = require("./mylib.js");
```

### Multi-module public function import

```botopink
// math.bp
pub fn double(x: i32) -> i32 {
    return x * 2;
}

// main.bp
use { double } from "math";
val result = double(21);
```

### Multi-module public value import

```botopink
// config.bp
pub val PORT = 8080;
pub val HOST = "localhost";

// main.bp
use { PORT, HOST } from "config";
val addr = HOST;
val port = PORT;
```

---

## Variables

### Number literal

```botopink
val x = 42;
```

### String literal

```botopink
val greeting = "hello";
```

### Binary expression

```botopink
val sum = 1 + 2;
```

### Null literal

```botopink
val nothing = null;
```

### Optional annotation with null

```botopink
val msg: ?string = null;
```

### Public value declaration

```botopink
pub val VERSION = 1;
pub val HOST = "localhost";
```

**Generates:**
```javascript
const VERSION = 1;
const HOST = "localhost";
```

---

## Functions

### Private function with return

```botopink
fn double(x: i32) -> i32 {
    return x * 2;
}
```

### Public exported function

```botopink
pub fn add(a: i32, b: i32) -> i32 {
    return a + b;
}
```

### Function with local binding

```botopink
fn double(x: i32) -> i32 {
    val result = x * 2;
    return result;
}
```

---

## Operators

### Comparison

```botopink
fn isPositive(n: i32) -> bool {
    return n > 0;
}
```

**Generates:** `return (n > 0);`

### Equality

```botopink
fn isZero(n: i32) -> bool {
    return n == 0;
}
```

**Generates:** `return (n === 0);`

---

## Conditionals

### Simple conditional in function body

```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    return r;
}
```

**Generates:**
```javascript
function sign(n) {
    const r = (() => { if ((n > 0)) { return "positive"; } })();
    return r;
}
```

### Conditional with else branch

```botopink
fn describe(n: i32) -> string {
    return if (n > 0) { "positive"; } else { "non-positive"; };
}
```

---

## Error Handling

### Propagate without catch

```botopink
fn fetch() -> i32 {
    todo;
}
fn process() -> i32 {
    val r = try fetch();
    return r;
}
```

**Generates:**
```javascript
function process() {
    const r = fetch();
    return r;
}
```

### With inline catch handler

```botopink
fn fetch() -> i32 {
    todo;
}
fn safe() -> i32 {
    val r = try fetch() catch 0;
    return r;
}
```

**Generates:**
```javascript
function safe() {
    const r = (() => { try { return fetch(); } catch(_e) { return (0)(_e); } })();
    return r;
}
```

---

## Null Safety

### Null-check binding

```botopink
var email: ?string = null;
if (email) { e ->
    print("Email: " + e);
};
```

---

## Structs

### Private field, method, getter

```botopink
val Counter = struct {
    _count: i32 = 0,
    fn increment(self: Self) {
        self._count += 1;
    }
    get count(self: Self) -> i32 {
        return self._count;
    }
}
```

**Generates:**
```javascript
class Counter {
    _count = 0;

    increment() {
        this._count += 1;
    }

    get count() {
        return this._count;
    }
}
```

### Setter and two getters

```botopink
val Temperature = struct {
    _celsius: f64 = 0.0,
    set celsius(self: Self, value: f64) {
        self._celsius = value;
    }
    get celsius(self: Self) -> f64 {
        return self._celsius;
    }
    get fahrenheit(self: Self) -> f64 {
        return self._celsius * 1.8 + 32.0;
    }
}
```

### Multiple private fields with assign and pluseq

```botopink
val BankAccount = struct {
    _balance: f64 = 0.0,
    _owner: string = "",
    fn deposit(self: Self, amount: f64) {
        self._balance += amount;
    }
    fn setOwner(self: Self, name: string) {
        self._owner = name;
    }
    get balance(self: Self) -> f64 {
        return self._balance;
    }
    get owner(self: Self) -> string {
        return self._owner;
    }
}
```

### Method with call expression receiver

```botopink
val Logger = struct {
    _prefix: string = "",
    fn setPrefix(self: Self, p: string) {
        self._prefix = p;
    }
    fn log(self: Self, msg: string) {
        console.log(self._prefix, msg);
    }
    get prefix(self: Self) -> string {
        return self._prefix;
    }
}
```

**Generates:**
```javascript
class Logger {
    _prefix = "";

    setPrefix(p) {
        this._prefix = p;
    }

    log(msg) {
        console.log(this._prefix, msg);
    }

    get prefix() {
        return this._prefix;
    }
}
```

### Shorthand declaration without val name

```botopink
struct Counter {
    _count: i32 = 0,
    fn increment(self: Self) {
        self._count += 1;
    }
    get count(self: Self) -> i32 {
        return self._count;
    }
}
```

---

## Records

### Two fields

```botopink
val Point = record { x: i32, y: i32 };
```

**Generates:**
```javascript
class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}
```

### Methods using self fields in arithmetic

```botopink
val Vec2 = record {
    x: f64,
    y: f64,
    fn lengthSq(self: Self) -> f64 {
        return self.x * self.x + self.y * self.y;
    }
    fn scale(self: Self, factor: f64) -> f64 {
        return self.x * factor;
    }
}
```

**Generates:**
```javascript
class Vec2 {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }

    lengthSq() {
        return ((this.x * this.x) + (this.y * this.y));
    }

    scale(factor) {
        return (this.x * factor);
    }
}
```

### Method with throw

```botopink
val Invoice = record {
    subtotal: f64,
    taxRate: f64,
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) {
        throw new Error("invalid invoice");
    }
}
```

### Method with todo placeholder

```botopink
record Unimplemented {
    id: i32,
    fn process(self: Self) -> string {
        return todo;
    }
}
```

### Shorthand declaration without val name

```botopink
record Vec2 {
    x: f64,
    y: f64,
    fn dot(self: Self, other: Vec2) -> f64 {
        return self.x * other.x + self.y * other.y;
    }
}
```

---

## Enums

### Unit variants

```botopink
val Direction = enum {
    North,
    South,
    East,
    West,
}
```

### Payload variant

```botopink
val Color = enum {
    Red,
    Rgb(r: i32, g: i32, b: i32),
}
```

### Payload variants with method using variantFields case

```botopink
val Shape = enum {
    Circle(radius: f64),
    Square(side: f64),
    Triangle(base: f64, height: f64),
    fn area(shape: Self) -> f64 {
        return case shape {
            Circle(radius) -> radius * radius * 3.14;
            Square(side) -> side * side;
            Triangle(base, height) -> base * height * 0.5;
            _ -> 0.0;
        };
    }
}
```

### Unit variants with method using ident case

```botopink
val HttpMethod = enum {
    Get,
    Post,
    Put,
    Delete,
    fn name(m: Self) -> string {
        val label = case m {
            Get -> "GET";
            Post -> "POST";
            Put -> "PUT";
            _ -> "DELETE";
        };
        return label;
    }
}
```

### Mixed unit and payload with method using mixed case

```botopink
val Maybe = enum {
    Nothing,
    Just(value: string),
    fn check(m: Self) -> string {
        return case m {
            Nothing -> "nothing";
            Just(value) -> "just";
        };
    }
}
```

### Method using qualified enum member

```botopink
val Status = enum {
    Active,
    Inactive,
    fn isDefault(s: Self) -> string {
        val current = Status.Active;
        return current;
    }
}
```

### Shorthand declaration without val name

```botopink
enum Direction {
    North,
    South,
    East,
    West,
}
```

---

## Interfaces

### Emits comment

```botopink
val Drawable = interface {
    val color: string,
    fn draw(self: Self);
}
```

**Generates:**
```javascript
// interface Drawable
//   color: string
//   fn draw(...)
```

---

## Pattern Matching

### Number literal patterns

```botopink
fn classify(n: i32) -> string {
    val result = case n {
        0 -> "zero";
        1 -> "one";
        _ -> "many";
    };
    return result;
}
```

**Generates:**
```javascript
function classify(n) {
    const result = (() => {
        const _s = n;
        if (_s === 0) return "zero";
        if (_s === 1) return "one";
        return "many";
    })();
    return result;
}
```

### String literal patterns

```botopink
fn greet(lang: string) -> string {
    val msg = case lang {
        "en" -> "hello";
        "pt" -> "ola";
        _ -> "hi";
    };
    return msg;
}
```

### OR patterns with numbers

```botopink
fn classify(day: i32) -> string {
    val kind = case day {
        6 | 7 -> "weekend";
        _ -> "weekday";
    };
    return kind;
}
```

**Generates:**
```javascript
function classify(day) {
    const kind = (() => {
        const _s = day;
        if (_s === 6 || _s === 7) return "weekend";
        return "weekday";
    })();
    return kind;
}
```

### List patterns empty, single, spread

```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

**Generates:**
```javascript
function describe() {
    const items = ["a", "b", "c"];
    return (() => {
        const _s = items;
        if (_s.length === 0) return "empty";
        if (_s.length === 1) {
            const x = _s[0];
            return "one";
        }
        if (_s.length >= 1) {
            const rest = _s.slice(1);
            const first = _s[0];
            return "many";
        }
    })();
}
```

---

## Loops

### Side-effect print in iterator

```botopink
val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
loop (messages, 0..) { msg, i ->
    print("mensagem");
};
```

**Generates:**
```javascript
const messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
const _loop = for (const [msg, i] of Object.entries(messages)) {
    print("mensagem");
};
```

### Side-effect over range

```botopink
loop (0..10) { i ->
    print("item");
};
```

### Map with break simple

```botopink
val ids = [10, 20, 30];
val dobrados = loop (ids) { id ->
    break id * 2;
};
```

**Generates:**
```javascript
const ids = [10, 20, 30];
const dobrados = for (const [id] of Object.entries(ids)) {
    (id * 2);
};
```

### Map with break (add tax)

```botopink
val precosBrutos = [100, 250, 400];
val precosComTaxa = loop (precosBrutos) { valor ->
    val taxa = valor * 0.15;
    break valor + taxa;
};
```

### Filter with conditional break

```botopink
val precosBrutos = [100, 250, 400];
val apenasGrandes = loop (precosBrutos) { valor ->
    if (valor > 200) {
        break valor;
    };
};
```

### Even numbers with break

```botopink
val processamento = loop (0..10) { i ->
    if (i % 2 == 0) {
        break i;
    };
};
```

---

## Lambdas

### Trailing lambda block

```botopink
fn run() {
    todo;
}
fn main() {
    run { x ->
        return "done";
    };
}
```

**Generates:**
```javascript
function main() {
    run((x) => {
        return "done";
    });
}
```

### Trailing lambda with multiple params

```botopink
fn calc(factor: i32) -> i32 {
    todo;
}
fn main() {
    val r = calc(2) { a, b ->
        return 0;
    };
}
```

**Generates:**
```javascript
function main() {
    const r = calc(2, (a, b) => {
        return 0;
    });
}
```

---

## Comptime Evaluation

### Integer addition folds to literal

```botopink
val v1 = comptime 1 + 1;
```

**Generates:**
```javascript
const v1 = 2;
```

### Block with break value inlines result

```botopink
val t = comptime {
    break 2 + 22;
};
```

**Generates:**
```javascript
const t = 24;
```

### Float multiplication folds to literal

```botopink
val pi2 = comptime {
    break 3.14 * 2.0;
};
```

**Generates:**
```javascript
const pi2 = 6.28;
```

### Multiplication binds tighter than addition

```botopink
val n = comptime {
    break 2 + 3 * 4;
};
```

**Generates:**
```javascript
const n = 14;
```

### Runtime identifier inside comptime raises error

```botopink
// ERROR: comptime code cannot reference runtime identifiers
val msg = comptime {
    break greeting;  // 'greeting' not defined at comptime
};
```

**Error:**
```
error: runtime identifier 'greeting' inside comptime expression
```

### Comptime val folds arithmetic to literal

```botopink
val result = comptime 10 + 20;
```

**Generates:**
```javascript
const result = 30;
```

### Comptime basic: val and plain function coexist

```botopink
val x = comptime 1 + 2;

fn double(n: i32) -> i32 {
    return n * 2;
}

fn main() {
    val r = double(21);
}
```

**Generates:**
```javascript
const x = 3;

function double(n) {
    return (n * 2);
}

function main() {
    const r = double(21);
}
```

---

## Function Specialization

### Simple function body without loop

```botopink
fn execute(comptime slug: string, input: i32) -> i32 {
    return input + 0;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
    val r3 = execute("calc", 5);
}
```

**Generates:**
```javascript
function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
    const r3 = execute_$0(5);  // reuses $0 (slug="calc")
}

/**
 * Specialization execute_$0
 * slug: calc
 */
function execute_$0(input) {
    return (input + 0);
}

/**
 * Specialization execute_$1
 * slug: noop
 */
function execute_$1(input) {
    return (input + 0);
}
```

### Distinct string args generate specialized functions

```botopink
fn build(prefix comptime: string, name: string) -> string {
    return prefix + ": " + name;
}

fn main() {
    val r1 = build("INFO", "Sistema iniciado");
    val r2 = build("WARN", "Memória alta");
    val r3 = build("INFO", "Log replicado");
}
```

**Generates:**
```javascript
function main() {
    const r1 = build_$0("Sistema iniciado");
    const r2 = build_$1("Memória alta");
    const r3 = build_$0("Log replicado");  // reuses $0 (prefix="INFO")
}

/**
 * Specialization build_$0
 * prefix: INFO
 */
function build_$0(name) {
    return ("INFO" + ": " + name);
}

/**
 * Specialization build_$1
 * prefix: WARN
 */
function build_$1(name) {
    return ("WARN" + ": " + name);
}
```

### Distinct integer args generate specialized functions

```botopink
fn multiply(comptime factor: i32, x: i32) -> i32 {
    return x * factor;
}

fn calculate() {
    val double = multiply(2, 21);
    val triple = multiply(3, 21);
    val doubleAgain = multiply(2, 10);
}
```

**Generates:**
```javascript
function calculate() {
    const double = multiply_$0(21);
    const triple = multiply_$1(21);
    const doubleAgain = multiply_$0(10);  // reuses $0 (factor=2)
}

/**
 * Specialization multiply_$0
 * factor: 2
 */
function multiply_$0(x) {
    return (x * 2);
}

/**
 * Specialization multiply_$1
 * factor: 3
 */
function multiply_$1(x) {
    return (x * 3);
}
```

### Same string arg reuses specialized function

```botopink
fn build(comptime prefix: string, name: string) -> string {
    return prefix + ": " + name;
}

fn main() {
    val r1 = build("INFO", "Sistema iniciado");
    val r2 = build("WARN", "Memória alta");
    val r3 = build("INFO", "Log replicado");
}
```

**Generates:**
```javascript
function main() {
    const r1 = build_$0("Sistema iniciado");
    const r2 = build_$1("Memória alta");
    const r3 = build_$0("Log replicado");  // ← same $0 as r1
}
```

### Comptime val used as specialization argument

```botopink
val base = comptime 10 + 5;

fn scale(comptime factor: i32, value: i32) -> i32 {
    return value * factor;
}

fn main() {
    val doubled = scale(2, base);
    val tripled = scale(3, base);
    val doubledAgain = scale(2, 100);
}
```

**Generates:**
```javascript
const base = 15;

function main() {
    const doubled = scale_$0(15);
    const tripled = scale_$1(15);
    const doubledAgain = scale_$0(100);  // reuses $0
}

function scale_$0(value) {
    return (value * 2);
}

function scale_$1(value) {
    return (value * 3);
}
```

---

## Loop Unrolling

### Single if condition resolved per element

```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = input * 2;
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

**Generates:**
```javascript
function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

/**
 * Specialization execute_$0
 * slug: calc
 */
function execute_$0(input) {
    let output = 0;
    output = (input * 2);  // ← loop unrolled, if folded for "calc"
    return output;
}

/**
 * Specialization execute_$1
 * slug: noop
 */
function execute_$1(input) {
    let output = 0;
    output = input;  // ← loop unrolled, if folded for "noop"
    return output;
}
```

### Nested if-else chain fully folded

```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            if (cmd == "calc") {
                output = input * 2;
            } else if (cmd == "noop") {
                output = input;
            };
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

**Generates:**
```javascript
function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

function execute_$0(input) {
    let output = 0;
    output = (input * 2);  // ← nested if-else fully folded
    return output;
}

function execute_$1(input) {
    let output = 0;
    output = input;
    return output;
}
```

### Case expression folded inside unrolled loop

```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = case cmd {
                "calc" -> input * 2;
                "noop" -> input;
                _ -> 0;
            };
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

**Generates:**
```javascript
function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

function execute_$0(input) {
    let output = 0;
    output = (input * 2);  // ← case folded: cmd="calc" matched
    return output;
}

function execute_$1(input) {
    let output = 0;
    output = input;  // ← case folded: cmd="noop" matched
    return output;
}
```

### Runtime array loop preserved, comptime param specialized

```botopink
val COMMANDS = ["calc", "noop", "help"];  // NOT comptime

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = input * 2;
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

**Generates:**
```javascript
function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

/**
 * Specialization execute_$0
 * slug: calc
 */
function execute_$0(input) {
    let output = 0;
    for (const [cmd] of Object.entries(COMMANDS)) {
        if (cmd === "calc") {  // ← slug baked in, loop preserved
            output = (input * 2);
        }
    }
    return output;
}

/**
 * Specialization execute_$1
 * slug: noop
 */
function execute_$1(input) {
    let output = 0;
    for (const [cmd] of Object.entries(COMMANDS)) {
        if (cmd === "noop") {  // ← slug baked in, loop preserved
            output = (input * 2);
        }
    }
    return output;
}
```

---

## Delegates

### Emits comment

```botopink
declare fn Callback(msg: string) -> void;
```

**Generates:**
```javascript
// delegate Callback
function Callback(msg) { /* implemented elsewhere */ }
```

---

## Implement

### Attaches methods to prototype

```botopink
interface Printable {
    fn print(self: Self),
}
record Person { name: string }
val PersonPrintable = implement Printable for Person {
    fn print(self: Self) {
        return self.name;
    }
}
```

**Generates:**
```javascript
// interface Printable
//   fn print(...)

class Person {
    constructor(name) {
        this.name = name;
    }
}
```

---

## Destructuring

### Record val binding

```botopink
record Point { x: i32, y: i32 }
fn describe(p: Point) -> i32 {
    val { x, y } = p;
    return x;
}
```

### Record parameter in fn

```botopink
record Person { name: string, age: i32 }
fn greet({ name, age }: Person) -> string {
    return name;
}
```

---

## Arrays and Tuples

### Array literal

```botopink
val items = ["a", "b", "c"];
```

### Empty array

```botopink
val empty: i32[] = [];
```

---

## Compiler Improvements (v0.0.11-beta)

### Allocator Consistency

All compiler components now follow a consistent pattern: **allocator is never stored, always passed as parameter**.

**Before:**
```zig
pub const Parser = struct {
    allocator: std.mem.Allocator,  // stored
    // ...
};
pub fn init(tokens: []const Token, allocator: std.mem.Allocator) Parser { ... }
```

**After:**
```zig
pub const Parser = struct {
    // no allocator field
    // ...
};
pub fn init(tokens: []const Token) Parser { ... }
pub fn parse(this: *This, alloc: std.mem.Allocator) ParseError!Program { ... }
```

This pattern applies to:
- `Parser` — `init(tokens)`, all methods receive `alloc` as first parameter
- `Lexer` — `init(source)`, `scanAll(alloc)`, `deinit(alloc)`
- All codegen functions — `alloc: std.mem.Allocator` as first parameter name
- All Emitter structs — `alloc` passed in `init()`, used consistently

### Code Reduction via Helper Functions

**Binary operator emission** (commonJS.zig, erlang.zig):
```zig
// Before: 14 operators × 6 lines = 84 lines
.add => |b| {
    try self.w("(");
    try self.emitExpr(b.lhs.*);
    try self.w(" + ");
    try self.emitExpr(b.rhs.*);
    try self.w(")");
},
// ... 13 more

// After: 1 helper + 14 single-line calls = 28 lines
fn emitBinaryOp(self: *Emitter, op: []const u8, lhs: *ast.Expr, rhs: *ast.Expr) !void {
    try self.w("(");
    try self.emitExpr(lhs.*);
    try self.w(" ");
    try self.w(op);
    try self.w(" ");
    try self.emitExpr(rhs.*);
    try self.w(")");
}

.add => |b| try self.emitBinaryOp("+", b.lhs, b.rhs),
.sub => |b| try self.emitBinaryOp("-", b.lhs, b.rhs),
// ... 12 more
```

**Parser helpers:**
- `boxExpr(alloc, expr)` — replaces repetitive `allocator.create(Expr)` pattern
- `parseStmtListInBraces(alloc)` — replaces duplicate `parseBraceBlock` function
- `parseCommaSeparatedIdentifiers(alloc, stopAt)` — reusable for extends, imports, etc.
- `reportReservedWordError()` — centralized reserved word error creation

**Total savings:** ~122 lines of repetitive code eliminated.
