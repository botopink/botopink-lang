----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs = [1, 2, 3];
    val ys = ["a", "b", "c"];
    @print(xs.zip(ys));
}
```

----- JAVASCRIPT -- main.js
```javascript
// interface Array
//   length: i32
//   fn at(...)
//   fn push(...)
//   fn pop(...)
//   default fn slice(...)
//   fn join(...)
//   fn reverse(...)
//   fn indexOf(...)
//   fn forEach(...)
//   fn map(...)
//   fn filter(...)
//   fn zip(...)
//   default fn range(...)
//   default fn repeat(...)
//   default fn isEmpty(...)
//   default fn contains(...)
//   default fn first(...)
//   default fn rest(...)
//   default fn take(...)
//   default fn drop(...)
//   default fn fold(...)
//   default fn find(...)
//   default fn count(...)
//   default fn all(...)
//   default fn any(...)
//   default fn append(...)
//   default fn prepend(...)
//   default fn flatten(...)
//   default fn flatMap(...)
//   default fn toList(...)
//   default fn some(...)
//   default fn every(...)
//   default fn flat(...)
//   default fn findIndex(...)
//   default fn fill(...)
//   default fn chunked(...)
//   default fn sliding(...)
//   default fn unique(...)
Array.range = function(start, stop) {
    return (() => { if ((start >= stop)) { return []; } else { const head = start; return [head, ...(Array.range((start + 1), stop))]; } })();
};
Array.repeat = function(value, times) {
    return (() => { if ((times <= 0)) { return []; } else { const head = value; return [head, ...(Array.repeat(value, (times - 1)))]; } })();
};
Array.prototype.slice = function(start, end) {
     if (end) { return require("./gleam_stdlib.mjs").slice(this, start, end); } else { return require("./gleam_stdlib.mjs").slice(this, start); };
};
Array.prototype.zip = function(other) { return this.map((__x, __i) => [__x, (other)[__i]]).slice(0, Math.min(this.length, (other).length)); };
Array.prototype.isEmpty = function() {
    return (this.length === 0);
};
Array.prototype.contains = function(x) {
    return (this.indexOf(x) !== (-1));
};
Array.prototype.first = function() {
    return this.at(0);
};
Array.prototype.rest = function() {
    return this.slice(1, this.length);
};
Array.prototype.take = function(n) {
    return this.slice(0, n);
};
Array.prototype.drop = function(n) {
    return this.slice(n, this.length);
};
Array.prototype.fold = function(initial, f) {
    let acc = initial;
    this.forEach((x) => {
    acc = f(acc, x);
});
    return acc;
};
Array.prototype.count = function(pred) {
    return this.filter(pred).length;
};
Array.prototype.all = function(pred) {
    return (this.filter(pred).length === this.length);
};
Array.prototype.any = function(pred) {
    return (this.filter(pred).length !== 0);
};
Array.prototype.prepend = function(item) {
    let out = [item];
    this.forEach((x) => {
    return out.push(x);
});
    return out;
};
Array.prototype.flatten = function() {
    let out = [];
    this.forEach((inner) => {
    out = out.concat(inner);
});
    return out;
};
Array.prototype.toList = function() {
    return this;
};
Array.prototype.some = function(pred) {
    return this.any(pred);
};
Array.prototype.every = function(pred) {
    return this.all(pred);
};
Array.prototype.flat = function() {
    return this.flatten();
};
Array.prototype.findIndex = function(pred) {
    let out = (-1);
    let i = 0;
    this.forEach((x) => {
    (() => { if ((out === (-1))) { return (() => { if (pred(x)) { return out = i; } })(); } })();
    i = (i + 1);
});
    return out;
};
Array.prototype.fill = function(value) {
    return Array.repeat(value, this.length);
};
Array.prototype.chunked = function(n) {
    let out = [];
     if ((n <= 0)) { return out; };
    let i = 0;
    let len = this.length;
    while_((i < len), () => {
    const piece = this.slice(i, (i + n));
    out = out.concat([piece]);
    i = (i + n);
});
    return out;
};
Array.prototype.sliding = function(n) {
    let out = [];
     if ((n <= 0)) { return out; };
    let i = 0;
    let len = this.length;
    let last = (len - n);
    while_((i <= last), () => {
    const piece = this.slice(i, (i + n));
    out = out.concat([piece]);
    i = (i + 1);
});
    return out;
};
Array.prototype.unique = function() {
    let out = [];
    let seenLast = false;
    let prev = this.at(0);
    this.forEach((x) => {
    (() => { if (seenLast) { return (() => { if ((prev.unwrapOr(x) !== x)) { out = out.concat([x]); return prev = this.at(out.length); } })(); } else { out = out.concat([x]); seenLast = true; return prev = this.at(0); } })();
});
    return out;
};

function main() {
    const xs = [1, 2, 3];
    const ys = ["a", "b", "c"];
    console.log(xs.zip(ys));
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
```
