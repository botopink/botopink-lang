# migrate effects — every automatic pattern

`botopink migrate effects` over 1 file(s).

## `src/main.bp` — input

```botopink
pub type ParseError { Empty, Bad(text: string) }
pub type ElementBase(id: i32)
pub type Element(tag: string) implement @Context<ElementBase>
pub type State(value: i32)

// #[@result] — the annotation goes, the return stays.
#[@result]
fn parsePort(s: string) -> @Result<i32, ParseError> {
    if (s == "") { throw ParseError.Empty; };
    return 80;
}

// #[@future] + @Future<T, E> → @Task<@Result<T, E>>, and its awaits of a
// fallible future become `try await`.
#[@future]
fn fetchCount(n: i32) -> @Future<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}

// @Future<T> → @Task<T>.
#[@future]
fn delayed(n: i32) -> @Future<i32> {
    return n;
}

#[@future]
fn total(a: i32) -> @Future<i32, string> {
    val x = await fetchCount(a);
    val y = await delayed(a);
    return x + y;
}

// #[@use] + @Component<C, T> → @Component<C, T>.
#[@use]
fn state(initial: i32) -> @Component<ElementBase, State> {
    return State(value: initial);
}

// #[@context] + @Context<B, R> (pre-121) → @Component<B, R>.
#[@context]
fn counter(start: i32) -> @Context<ElementBase, i32> {
    val s = use state(start);
    return s.value;
}

// @Use<C, T> (front 21's spelling) → @Component<C, T>.
#[@use]
fn theme() -> @Use<ElementBase, string> {
    return "dark";
}

// @Component<T> → @Component<B, T>, B read from `T implement @Context<B>`.
#[@use]
fn Card() -> @Component<Element> {
    val n = use counter(0);
    return Element(tag: "div");
}

// `-> Element` on a component that uses a hook → @Component<ElementBase, Element>.
fn Badge() -> Element {
    val t = use theme();
    return Element(tag: t);
}

// #[@generator] + @Generator<T> → @Iterator<T>.
#[@generator]
fn upto(n: i32) -> @Generator<i32> {
    var i = 0;
    while (i < n) { yield i; i = i + 1; };
}

// #[@resultGenerator] + @ResultGenerator<T, E> → @Iterator<@Result<T, E>>.
#[@resultGenerator]
fn ports(n: i32) -> @ResultGenerator<i32, ParseError> {
    var i = 0;
    while (i < n) { val p = try parsePort("x"); yield p; i = i + 1; };
}

// #[@iterator] + @Iterator<T, E> (pre-121) → @Iterator<@Result<T, E>>.
#[@iterator]
fn ports2(n: i32) -> @Iterator<i32, ParseError> {
    var i = 0;
    while (i < n) { val p = try parsePort("y"); yield p; i = i + 1; };
}

// #[@futureGenerator] + @FutureGenerator<T, E> → @Stream<@Result<T, E>>.
#[@futureGenerator]
fn pages(n: i32) -> @FutureGenerator<i32, string> {
    var i = 0;
    while (i < n) { val c = await fetchCount(i); yield c; i = i + 1; };
}

// #[@asyncGenerator] + @AsyncIterator<T, E> (pre-121) → @Stream<@Result<T, E>>.
#[@asyncGenerator]
fn pages2(n: i32) -> @AsyncIterator<i32, string> {
    var i = 0;
    while (i < n) { val c = await fetchCount(i); yield c; i = i + 1; };
}

// `for` over a fallible generator: the implicit `try` becomes explicit
// at the one use of the item (the return has a @Result).
#[@result]
fn sum(n: i32) -> @Result<i32, ParseError> {
    var t = 0;
    for (ports(n)) { r -> t = t + r; };
    return t;
}

// `for await` over a fallible stream, likewise.
#[@future]
fn countPages() -> @Future<i32, string> {
    var t = 0;
    for await (pages(3)) { p -> t = t + p; };
    return t;
}

// `loop await (g) { x -> }` (pre-105) → `for await`.
#[@future]
fn countPages2() -> @Future<i32, string> {
    var t = 0;
    loop await (pages2(3)) { p -> t = t + p; };
    return t;
}

// Annotated loops → `iter` / `stream` loops; `loop (xs) { x -> }` → `for`,
// `loop (cond)` → `while` (pre-105).
fn loops(xs: i32[]) -> i32 {
    val squares = #[@generator] loop {
        for (xs) { x -> yield x * x; };
        break;
    };
    val evens = #[@resultGenerator] loop {
        yield 2;
        break;
    };
    val ticks = #[@futureGenerator] loop { yield 1; break; };
    val odds = #[@iterator] loop { yield 3; break; };
    val beats = #[@asyncGenerator] loop { yield 4; break; };
    var n = 0;
    loop (xs) { x -> n = n + x; };
    loop (n > 100) { n = n - 1; };
    return n;
}

// YieldStep<T, E> → YieldStep<T>; IteratorStep<T, E> (pre-103) → YieldStep<T>.
fn stepValue(s: YieldStep<i32, string>) -> i32 {
    return 0;
}
fn stepValue2(s: IteratorStep<i32, string>) -> i32 {
    return 0;
}

pub fn main() { @print(1); }
```

## `src/main.bp` — output (type-checked: yes)

```botopink
pub type ParseError { Empty, Bad(text: string) }
pub type ElementBase(id: i32)
pub type Element(tag: string) implement @Context<ElementBase>
pub type State(value: i32)

// #[@result] — the annotation goes, the return stays.
fn parsePort(s: string) -> @Result<i32, ParseError> {
    if (s == "") { throw ParseError.Empty; };
    return 80;
}

// #[@future] + @Future<T, E> → @Task<@Result<T, E>>, and its awaits of a
// fallible future become `try await`.
fn fetchCount(n: i32) -> @Task<@Result<i32, string>> {
    if (n < 0) { throw "negative"; };
    return n;
}

// @Future<T> → @Task<T>.
fn delayed(n: i32) -> @Task<i32> {
    return n;
}

fn total(a: i32) -> @Task<@Result<i32, string>> {
    val x = try await fetchCount(a);
    val y = await delayed(a);
    return x + y;
}

// #[@use] + @Component<C, T> → @Component<C, T>.
fn state(initial: i32) -> @Component<ElementBase, State> {
    return State(value: initial);
}

// #[@context] + @Context<B, R> (pre-121) → @Component<B, R>.
fn counter(start: i32) -> @Component<ElementBase, i32> {
    val s = use state(start);
    return s.value;
}

// @Use<C, T> (front 21's spelling) → @Component<C, T>.
fn theme() -> @Component<ElementBase, string> {
    return "dark";
}

// @Component<T> → @Component<B, T>, B read from `T implement @Context<B>`.
fn Card() -> @Component<ElementBase, Element> {
    val n = use counter(0);
    return Element(tag: "div");
}

// `-> Element` on a component that uses a hook → @Component<ElementBase, Element>.
fn Badge() -> @Component<ElementBase, Element> {
    val t = use theme();
    return Element(tag: t);
}

// #[@generator] + @Generator<T> → @Iterator<T>.
fn upto(n: i32) -> @Iterator<i32> {
    var i = 0;
    while (i < n) { yield i; i = i + 1; };
}

// #[@resultGenerator] + @ResultGenerator<T, E> → @Iterator<@Result<T, E>>.
fn ports(n: i32) -> @Iterator<@Result<i32, ParseError>> {
    var i = 0;
    while (i < n) { val p = try parsePort("x"); yield p; i = i + 1; };
}

// #[@iterator] + @Iterator<T, E> (pre-121) → @Iterator<@Result<T, E>>.
fn ports2(n: i32) -> @Iterator<@Result<i32, ParseError>> {
    var i = 0;
    while (i < n) { val p = try parsePort("y"); yield p; i = i + 1; };
}

// #[@futureGenerator] + @FutureGenerator<T, E> → @Stream<@Result<T, E>>.
fn pages(n: i32) -> @Stream<@Result<i32, string>> {
    var i = 0;
    while (i < n) { val c = try await fetchCount(i); yield c; i = i + 1; };
}

// #[@asyncGenerator] + @AsyncIterator<T, E> (pre-121) → @Stream<@Result<T, E>>.
fn pages2(n: i32) -> @Stream<@Result<i32, string>> {
    var i = 0;
    while (i < n) { val c = try await fetchCount(i); yield c; i = i + 1; };
}

// `for` over a fallible generator: the implicit `try` becomes explicit
// at the one use of the item (the return has a @Result).
fn sum(n: i32) -> @Result<i32, ParseError> {
    var t = 0;
    for (ports(n)) { r -> t = t + (try r); };
    return t;
}

// `for await` over a fallible stream, likewise.
fn countPages() -> @Task<@Result<i32, string>> {
    var t = 0;
    for await (pages(3)) { p -> t = t + (try p); };
    return t;
}

// `loop await (g) { x -> }` (pre-105) → `for await`.
fn countPages2() -> @Task<@Result<i32, string>> {
    var t = 0;
    for await (pages2(3)) { p -> t = t + (try p); };
    return t;
}

// Annotated loops → `iter` / `stream` loops; `loop (xs) { x -> }` → `for`,
// `loop (cond)` → `while` (pre-105).
fn loops(xs: i32[]) -> i32 {
    val squares = iter for (xs) { x -> yield x * x; };
    val evens = iter loop {
        yield 2;
        break;
    };
    val ticks = stream loop { yield 1; break; };
    val odds = iter loop { yield 3; break; };
    val beats = stream loop { yield 4; break; };
    var n = 0;
    for (xs) { x -> n = n + x; };
    while (n > 100) { n = n - 1; };
    return n;
}

// YieldStep<T, E> → YieldStep<T>; IteratorStep<T, E> (pre-103) → YieldStep<T>.
fn stepValue(s: YieldStep<i32>) -> i32 {
    return 0;
}
fn stepValue2(s: YieldStep<i32>) -> i32 {
    return 0;
}

pub fn main() { @print(1); }
```

## `src/main.bp` — marked for review

(none)
