----- SOURCE
```botopink
val xs = [1, 2, 3];
val y = xs.
           ↑
```

----- COMPLETION at (line 1, char 11)
length  [Field]  detail: val length: i32

    // ── host-backed primitives ──
    #[@external(erlang, "array", "get"),
      @external(node, "./gleam_stdlib.mjs", "index")]
at  [Method]  detail: fn at(self: Self, index: i32) -> ?T
push  [Method]  detail: fn push(self: Self, item: T)
pop  [Method]  detail: fn pop(self: Self) -> ?T
slice  [Method]  detail: fn slice(self: Self, start: i32, end: i32) -> Self
join  [Method]  detail: fn join(self: Self, sep: string) -> string
reverse  [Method]  detail: fn reverse(self: Self) -> Self
indexOf  [Method]  detail: fn indexOf(self: Self, item: T) -> i32
forEach  [Method]  detail: fn forEach(self: Self, action: fn(item: T))
map  [Method]  detail: fn map<U>(self: Self, transform: fn(item: T) -> U) -> Array<U>
filter  [Method]  detail: fn filter(self: Self, pred: fn(item: T) -> bool) -> Self

    // ── producers (associated — no receiver) ──
    // Pure botopink (no host backing): the host `lists:seq`/`duplicate` have the
    // wrong semantics (`seq` is end-inclusive; `duplicate` swaps the args), so
    // these recurse with an array-literal spread `[head, ..tail]`, giving
    // identical end-exclusive `[start, stop)` / `times`-copy results on every
    // backend. `head` is bound to a `val` first so the BEAM backend spills it to a
    // stack slot — an x-register would be clobbered by the recursive call. (No
    // comments inside the bodies: the commonJS if-expr emits as a one-line IIFE,
    // where a `//` would swallow the rest of the block.)
    default
range  [Method]  detail: fn range(start: i32, stop: i32) -> Array<i32>
head  [Field]  detail: val head = start;
            [head, ..(Array.range(start + 1, stop))];
        };
    }

    default
repeat  [Method]  detail: fn repeat<E>(value: E, times: i32) -> Array<E>
isEmpty  [Method]  detail: fn isEmpty(self: Self) -> bool
contains  [Method]  detail: fn contains(self: Self, x: T) -> bool
first  [Method]  detail: fn first(self: Self) -> ?T
rest  [Method]  detail: fn rest(self: Self) -> Self
take  [Method]  detail: fn take(self: Self, n: i32) -> Self
drop  [Method]  detail: fn drop(self: Self, n: i32) -> Self
fold  [Method]  detail: fn fold<A>(self: Self, initial: A, f: fn(acc: A, item: T) -> A) -> A
find  [Method]  detail: fn find(self: Self, pred: fn(item: T) -> bool) -> ?T
count  [Method]  detail: fn count(self: Self, pred: fn(item: T) -> bool) -> i32
all  [Method]  detail: fn all(self: Self, pred: fn(item: T) -> bool) -> bool
any  [Method]  detail: fn any(self: Self, pred: fn(item: T) -> bool) -> bool
append  [Method]  detail: fn append(self: Self, other: Self) -> Self
prepend  [Method]  detail: fn prepend(self: Self, item: T) -> Self
flatten  [Method]  detail: fn flatten<E>(self: Self) -> Array<E>
flatMap  [Method]  detail: fn flatMap<U>(self: Self, transform: fn(item: T) -> U) -> Array<U>
toList  [Method]  detail: fn toList(self: Self) -> Self
