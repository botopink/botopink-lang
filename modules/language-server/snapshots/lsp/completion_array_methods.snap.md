----- SOURCE
```botopink
val xs = [1, 2, 3];
val y = xs.
           ↑
```

----- COMPLETION at (line 1, char 11)
length  [Field]  detail: val length: i32
at  [Method]  detail: fn at(self: Self<T>, index: i32) -> ?T
push  [Method]  detail: fn push(self: Self<T>, item: T)
pop  [Method]  detail: fn pop(self: Self<T>) -> ?T
slice  [Method]  detail: fn slice(self: Self<T>, start: i32, end: ?i32 = null) -> Self<T>
join  [Method]  detail: fn join(self: Self<T>, sep: string) -> string
reverse  [Method]  detail: fn reverse(self: Self<T>) -> Self<T>
indexOf  [Method]  detail: fn indexOf(self: Self<T>, item: T) -> i32
forEach  [Method]  detail: fn forEach(self: Self<T>, action: fn(item: T))
map  [Method]  detail: fn map<U>(self: Self<T>, transform: fn(item: T) -> U) -> Array<U>
filter  [Method]  detail: fn filter(self: Self<T>, pred: fn(item: T) -> bool) -> Self<T>
zip  [Method]  detail: fn zip<U>(self: Self<T>, other: Array<U>) -> Array<#(T, U)>
isEmpty  [Method]  detail: fn isEmpty(self: Self<T>) -> bool
contains  [Method]  detail: fn contains(self: Self<T>, x: T) -> bool
first  [Method]  detail: fn first(self: Self<T>) -> ?T
rest  [Method]  detail: fn rest(self: Self<T>) -> Self<T>
take  [Method]  detail: fn take(self: Self<T>, n: i32) -> Self<T>
drop  [Method]  detail: fn drop(self: Self<T>, n: i32) -> Self<T>
fold  [Method]  detail: fn fold<A>(
        self: Self<T>,
        initial: A,
        f: fn(acc: A, item: T) -> A,
    ) -> A
find  [Method]  detail: fn find(self: Self<T>, pred: fn(item: T) -> bool) -> ?T
count  [Method]  detail: fn count(self: Self<T>, pred: fn(item: T) -> bool) -> i32
all  [Method]  detail: fn all(self: Self<T>, pred: fn(item: T) -> bool) -> bool
any  [Method]  detail: fn any(self: Self<T>, pred: fn(item: T) -> bool) -> bool
append  [Method]  detail: fn append(self: Self<T>, other: Self<T>) -> Self<T>
prepend  [Method]  detail: fn prepend(self: Self<T>, item: T) -> Self<T>
flatten  [Method]  detail: fn flatten<E>(self: Self<T>) -> Array<E>
flatMap  [Method]  detail: fn flatMap<U>(self: Self<T>, transform: fn(item: T) -> U) -> Array<U>
toList  [Method]  detail: fn toList(self: Self<T>) -> Self<T>
some  [Method]  detail: fn some(self: Self<T>, pred: fn(item: T) -> bool) -> bool
every  [Method]  detail: fn every(self: Self<T>, pred: fn(item: T) -> bool) -> bool
flat  [Method]  detail: fn flat<E>(self: Self<T>) -> Array<E>
findIndex  [Method]  detail: fn findIndex(self: Self<T>, pred: fn(item: T) -> bool) -> i32
fill  [Method]  detail: fn fill<E>(self: Self<T>, value: E) -> Array<E>
chunked  [Method]  detail: fn chunked(self: Self<T>, n: i32) -> Array<Self<T>>
sliding  [Method]  detail: fn sliding(self: Self<T>, n: i32) -> Array<Self<T>>
unique  [Method]  detail: fn unique(self: Self<T>) -> Self<T>
