----- SOURCE CODE -- main.bp
```botopink
interface Number {
    fn min(self: Self, other: Self) -> Self,
    fn max(self: Self, other: Self) -> Self,

    default fn clamp(self: Self, lo: Self, hi: Self) -> Self {
        return self.max(lo).min(hi);
    }
}

fn main() {
    val n: i32 = 50;
    @print(n.clamp(0, 10));
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

function main() {
    const n = 50;
    console.log(n.clamp(0, 10));
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
10
```
