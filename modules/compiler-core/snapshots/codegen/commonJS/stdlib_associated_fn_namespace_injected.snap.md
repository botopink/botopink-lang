----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val p = Pair.of(1, "one");
    @print(Pair.first(p));
    @print(Function.identity(42));
    val inc = Function.compose({ x -> x + 1 }, { y -> y * 2 });
    @print(inc(10));
}
```

----- JAVASCRIPT -- main.js
```javascript
// interface Function
//   default fn identity(...)
//   default fn compose(...)
//   default fn flip(...)
//   default fn constant(...)
const Function = {};
Function.identity = function(x) {
    return x;
};
Function.compose = function(f, g) {
    return (a) => {
    return g(f(a));
};
};
Function.flip = function(f) {
    return (b, a) => {
    return f(a, b);
};
};
Function.constant = function(x) {
    return (ignored) => {
    return x;
};
};

// interface Pair
//   default fn of(...)
//   default fn first(...)
//   default fn second(...)
//   default fn swap(...)
//   default fn mapFirst(...)
//   default fn mapSecond(...)
const Pair = {};
Pair.of = function(first, second) {
    return [first, second];
};
Pair.first = function(p) {
    return p[0];
};
Pair.second = function(p) {
    return p[1];
};
Pair.swap = function(p) {
    return [p[1], p[0]];
};
Pair.mapFirst = function(p, transform) {
    return [transform(p[0]), p[1]];
};
Pair.mapSecond = function(p, transform) {
    return [p[0], transform(p[1])];
};

function main() {
    const p = Pair.of(1, "one");
    console.log(Pair.first(p));
    console.log(Function.identity(42));
    const inc = Function.compose((x) => {
    return (x + 1);
}, (y) => {
    return (y * 2);
});
    console.log(inc(10));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
1
42
22
```
