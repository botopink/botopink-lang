----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val n = -5;
    @print(n.abs());
    @print(n.min(3));
    @print(n.max(10));
    @print(n.clamp(0, 5));
    val x = 7;
    @print(x.isEven());
}
```

----- JAVASCRIPT -- main.js
```javascript
// interface Number
//   fn min(...)
//   fn max(...)
//   default fn clamp(...)
Number.prototype.min = function(other) { return Math.min(this.valueOf(), other); };
Number.prototype.max = function(other) { return Math.max(this.valueOf(), other); };
Number.prototype.clamp = function(lo, hi) {
    const self = this.valueOf();
    return self.max(lo).min(hi);
};

// interface Signed extends Integer
//   fn abs(...)
Number.prototype.abs = function() { return Math.abs(this.valueOf()); };

// interface Integer extends Number
//   fn toString(...)
//   default fn isEven(...)
//   default fn isOdd(...)
Number.prototype.isEven = function() {
    const self = this.valueOf();
    return ((self % 2) === 0);
};
Number.prototype.isOdd = function() {
    const self = this.valueOf();
    return ((self % 2) !== 0);
};

function main() {
    const n = (-5);
    console.log(n.abs());
    console.log(n.min(3));
    console.log(n.max(10));
    console.log(n.clamp(0, 5));
    const x = 7;
    console.log(x.isEven());
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
5
-5
10
0
false
```
