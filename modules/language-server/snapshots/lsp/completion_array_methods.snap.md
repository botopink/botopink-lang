----- SOURCE
```botopink
val xs = [1, 2, 3];
val y = xs.
           ↑
```

----- COMPLETION at (line 1, char 11)
length  [Field]  detail: val length: i32
at  [Method]  detail: fn at(self: Self, index: i32) -> ?T
push  [Method]  detail: fn push(self: Self, item: T)
pop  [Method]  detail: fn pop(self: Self) -> ?T
slice  [Method]  detail: fn slice(self: Self, start: i32, end: i32 = null) -> Self
join  [Method]  detail: fn join(self: Self, sep: string) -> string
reverse  [Method]  detail: fn reverse(self: Self) -> Self
indexOf  [Method]  detail: fn indexOf(self: Self, item: T) -> i32
forEach  [Method]  detail: fn forEach(self: Self, action: fn(item: T))
map  [Method]  detail: fn map<U>(self: Self, transform: fn(item: T) -> U) -> Array<U>
filter  [Method]  detail: fn filter(self: Self, pred: fn(item: T) -> bool) -> Self
zip  [Method]  detail: fn zip<U>(self: Self, other: Array<U>) -> Array<#(T, U)>
isEmpty  [Method]  detail: fn isEmpty(self: Self) -> bool
contains  [Method]  detail: fn contains(self: Self, x: T) -> bool
first  [Method]  detail: fn first(self: Self) -> ?T
rest  [Method]  detail: fn rest(self: Self) -> Self
take  [Method]  detail: fn take(self: Self, n: i32) -> Self
drop  [Method]  detail: fn drop(self: Self, n: i32) -> Self
fold  [Method]  detail: fn fold<A>(
        self: Self,
        initial: A,
        f: fn(acc: A, item: T) -> A,
    ) -> A
find  [Method]  detail: fn find(self: Self, pred: fn(item: T) -> bool) -> ?T
count  [Method]  detail: fn count(self: Self, pred: fn(item: T) -> bool) -> i32
all  [Method]  detail: fn all(self: Self, pred: fn(item: T) -> bool) -> bool
any  [Method]  detail: fn any(self: Self, pred: fn(item: T) -> bool) -> bool
append  [Method]  detail: fn append(self: Self, other: Self) -> Self
prepend  [Method]  detail: fn prepend(self: Self, item: T) -> Self
flatten  [Method]  detail: fn flatten<E>(self: Self) -> Array<E>
flatMap  [Method]  detail: fn flatMap<U>(self: Self, transform: fn(item: T) -> U) -> Array<U>
toList  [Method]  detail: fn toList(self: Self) -> Self
some  [Method]  detail: fn some(self: Self, pred: fn(item: T) -> bool) -> bool
every  [Method]  detail: fn every(self: Self, pred: fn(item: T) -> bool) -> bool
flat  [Method]  detail: fn flat<E>(self: Self) -> Array<E>
findIndex  [Method]  detail: fn findIndex(self: Self, pred: fn(item: T) -> bool) -> i32
fill  [Method]  detail: fn fill<E>(self: Self, value: E) -> Array<E>
chunked  [Method]  detail: fn chunked(self: Self, n: i32) -> Array<Self>
sliding  [Method]  detail: fn sliding(self: Self, n: i32) -> Array<Self>
unique  [Method]  detail: fn unique(self: Self) -> Self
