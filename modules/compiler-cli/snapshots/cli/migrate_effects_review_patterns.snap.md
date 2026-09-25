# migrate effects — the review patterns

`botopink migrate effects` over 2 file(s).

## `src/main.bp` — input

```botopink
pub type ElementBase(id: i32)
pub type Element(tag: string) implement @Context<ElementBase>

#[@future]
pub fn fetchCount(n: i32) -> @Future<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}

// await in a component whose T is not a @Result: the error has nowhere to go.
#[@use]
fn Page() -> @Component<ElementBase, Element> {
    val n = await fetchCount(1);
    return Element(tag: "p");
}

#[@result]
fn check(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}

// try (the throw of a hook) in a hook whose T is not a @Result.
#[@use]
fn guard(n: i32) -> @Component<ElementBase, i32> {
    val v = try check(n);
    return v;
}

// open point 5: @Future<T> could throw (E = any); @Task<T> cannot.
#[@future]
fn risky(n: i32) -> @Future<i32> {
    if (n < 0) { throw "negative"; };
    return n;
}

#[@resultGenerator]
fn nums(n: i32) -> @ResultGenerator<i32, string> {
    if (n < 0) { throw "negative"; };
    yield n;
}

#[@futureGenerator]
fn stream(n: i32) -> @FutureGenerator<i32, string> {
    val c = await fetchCount(n);
    yield c;
}

// for over a fallible generator, the item used twice: no automatic try.
#[@result]
fn twice(n: i32) -> @Result<i32, string> {
    var t = 0;
    for (nums(n)) { r -> t = t + r + r; };
    return t;
}

// for await over a fallible stream, in a function with no @Result.
#[@future]
fn drain() -> @Future<i32> {
    var t = 0;
    for await (stream(1)) { v -> t = t + v; };
    return t;
}

// case over YieldStep with an Error arm.
fn stepOf(s: YieldStep<i32, string>) -> i32 {
    case (s) {
        .Yield(v) -> return v;
        .Done -> return 0;
        .Error(e) -> return -1;
    }
}

// A host binding declared @Future<T>: a rejection was its error.
#[@future]
#[@External.Node("""Promise.reject(new Error($0))""")]
pub declare fn failing(message: string) -> @Future<i32>;

// .next() by hand on a fallible generator.
fn first(n: i32) -> i32 {
    val g = nums(n);
    val s = g.next();
    return stepOf(s);
}

pub fn main() { @print(1); }
```

## `src/main.bp` — output (type-checked: yes)

```botopink
pub type ElementBase(id: i32)
pub type Element(tag: string) implement @Context<ElementBase>

// TODO(migrate-effects): JavaScript callers: a failure of this function now resolves the Promise with `Error(…)` instead of rejecting it
pub fn fetchCount(n: i32) -> @Task<@Result<i32, string>> {
    if (n < 0) { throw "negative"; };
    return n;
}

// await in a component whose T is not a @Result: the error has nowhere to go.
fn Page() -> @Component<ElementBase, Element> {
    // TODO(migrate-effects): `await` now hands over the `@Result` (the awaited `@Future` could fail) and this function's return has no `@Result` to propagate it into: handle it here (`try await … catch …`, `case`, `notFound()`) or put `@Result` in the return
    val n = await fetchCount(1);
    return Element(tag: "p");
}

fn check(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}

// try (the throw of a hook) in a hook whose T is not a @Result.
fn guard(n: i32) -> @Component<ElementBase, i32> {
    // TODO(migrate-effects): `throw` / `try` needs a `@Result` in the return now (a hook or component no longer propagates): return a `@Result`, or handle the error here with `catch` / `case`
    val v = try check(n);
    return v;
}

// open point 5: @Future<T> could throw (E = any); @Task<T> cannot.
fn risky(n: i32) -> @Task<i32> {
    // TODO(migrate-effects): `@Future<T>` could fail (`E = any`) and this body throws or tries, but `@Task<T>` cannot fail: return `@Task<@Result<T, E>>`, or handle the error here
    if (n < 0) { throw "negative"; };
    return n;
}

fn nums(n: i32) -> @Iterator<@Result<i32, string>> {
    if (n < 0) { throw "negative"; };
    yield n;
}

fn stream(n: i32) -> @Stream<@Result<i32, string>> {
    val c = try await fetchCount(n);
    yield c;
}

// for over a fallible generator, the item used twice: no automatic try.
fn twice(n: i32) -> @Result<i32, string> {
    var t = 0;
    // TODO(migrate-effects): `for` no longer does an implicit `try`: each item of this iterator is a `@Result` now — write `try <item>` where it is used (the return needs a `@Result`), or `case` over it
    for (nums(n)) { r -> t = t + r + r; };
    return t;
}

// for await over a fallible stream, in a function with no @Result.
fn drain() -> @Task<i32> {
    var t = 0;
    // TODO(migrate-effects): `for await` no longer does an implicit `try`: each item of this stream is a `@Result` now — write `try <item>` where it is used (the return needs a `@Result`), or `case` over it
    for await (stream(1)) { v -> t = t + v; };
    return t;
}

// case over YieldStep with an Error arm.
fn stepOf(s: YieldStep<i32>) -> i32 {
    // TODO(migrate-effects): `YieldStep<T>` has no `Error` arm any more: the error travels in the item (`@Iterator<@Result<T, E>>`) — rewrite this `case`
    case (s) {
        .Yield(v) -> return v;
        .Done -> return 0;
        .Error(e) -> return -1;
    }
}

// A host binding declared @Future<T>: a rejection was its error.
// TODO(migrate-effects): a host binding declared `@Future<T>` failed by rejecting (`E = any`); declared `@Task<T>`, a rejection is a fatal host failure — declare `@Task<@Result<T, E>>` if the host can fail
#[@External.Node("""Promise.reject(new Error($0))""")]
pub declare fn failing(message: string) -> @Task<i32>;

// .next() by hand on a fallible generator.
fn first(n: i32) -> i32 {
    val g = nums(n);
    // TODO(migrate-effects): `.next()` on a fallible generator: the step has no `Error` any more, the item is a `@Result` — review how this code handles the error
    val s = g.next();
    return stepOf(s);
}

pub fn main() { @print(1); }
```

## `src/main.bp` — marked for review

- line 4: JavaScript callers: a failure of this function now resolves the Promise with `Error(…)` instead of rejecting it
- line 12: `await` now hands over the `@Result` (the awaited `@Future` could fail) and this function's return has no `@Result` to propagate it into: handle it here (`try await … catch …`, `case`, `notFound()`) or put `@Result` in the return
- line 24: `throw` / `try` needs a `@Result` in the return now (a hook or component no longer propagates): return a `@Result`, or handle the error here with `catch` / `case`
- line 31: `@Future<T>` could fail (`E = any`) and this body throws or tries, but `@Task<T>` cannot fail: return `@Task<@Result<T, E>>`, or handle the error here
- line 49: `for` no longer does an implicit `try`: each item of this iterator is a `@Result` now — write `try <item>` where it is used (the return needs a `@Result`), or `case` over it
- line 57: `for await` no longer does an implicit `try`: each item of this stream is a `@Result` now — write `try <item>` where it is used (the return needs a `@Result`), or `case` over it
- line 64: `YieldStep<T>` has no `Error` arm any more: the error travels in the item (`@Iterator<@Result<T, E>>`) — rewrite this `case`
- line 73: a host binding declared `@Future<T>` failed by rejecting (`E = any`); declared `@Task<T>`, a rejection is a fatal host failure — declare `@Task<@Result<T, E>>` if the host can fail
- line 80: `.next()` on a fallible generator: the step has no `Error` any more, the item is a `@Result` — review how this code handles the error

## `src/legacy.bp` — input

```botopink
// A wrapper alias as the return of an effect function.
#[@future]
fn job() -> Job<i32> {
    val n = await fetchCount(1);
    return n;
}

// for await in a module that was not type-checked.
#[@future]
fn drainAll() -> @Future<i32, string> {
    var t = 0;
    for await (stream(1)) { v -> t = t + v; };
    return t;
}

fn legacy(xs: Iterable) -> Yield<i32, string> {
    return 0;
}
```

## `src/legacy.bp` — output (type-checked: no)

```botopink
// A wrapper alias as the return of an effect function.
// TODO(migrate-effects): the effect is read from the written return: an alias does not activate it — write the wrapper (`@Result`, `@Task`, `@Component<C, T>`, `@Iterator`, `@Stream`) in the return
fn job() -> Job<i32> {
    // TODO(migrate-effects): this module was not type-checked (it does not type-check after normalisation, or the project does not compile it), so this `await` was not classified: write `try await` if the awaited value can fail and its error should propagate
    val n = await fetchCount(1);
    return n;
}

// for await in a module that was not type-checked.
fn drainAll() -> @Task<@Result<i32, string>> {
    var t = 0;
    // TODO(migrate-effects): this module was not type-checked, so this `for await` was not classified: if the stream can fail, its items are `@Result`s now and the implicit `try` is gone — write `try <item>` where it is used, or `case` over it
    for await (stream(1)) { v -> t = t + v; };
    return t;
}

// TODO(migrate-effects): `Iterable` is gone: expose a method that returns an `@Iterator<T>` (`fn iter(self: Self) -> @Iterator<T>`)
// TODO(migrate-effects): `Yield<T, R>` → `YieldStep<T>`: the completion value `R` has no place in the step — end with `break v` (it emits `v` as the last item) or return it separately
fn legacy(xs: Iterable) -> YieldStep<i32> {
    return 0;
}
```

## `src/legacy.bp` — marked for review

- line 2: the effect is read from the written return: an alias does not activate it — write the wrapper (`@Result`, `@Task`, `@Component<C, T>`, `@Iterator`, `@Stream`) in the return
- line 4: this module was not type-checked (it does not type-check after normalisation, or the project does not compile it), so this `await` was not classified: write `try await` if the awaited value can fail and its error should propagate
- line 12: this module was not type-checked, so this `for await` was not classified: if the stream can fail, its items are `@Result`s now and the implicit `try` is gone — write `try <item>` where it is used, or `case` over it
- line 17: `Iterable` is gone: expose a method that returns an `@Iterator<T>` (`fn iter(self: Self) -> @Iterator<T>`)
- line 18: `Yield<T, R>` → `YieldStep<T>`: the completion value `R` has no place in the step — end with `break v` (it emits `v` as the last item) or return it separately
