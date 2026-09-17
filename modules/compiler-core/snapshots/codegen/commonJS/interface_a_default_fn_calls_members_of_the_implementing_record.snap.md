----- SOURCE CODE -- main.bp
```botopink
interface Bounded {
    fn min(self: Self, other: Self) -> Self,
    fn max(self: Self, other: Self) -> Self,

    default fn clamp(self: Self, lo: Self, hi: Self) -> Self {
        return self.max(lo).min(hi);
    }
}

record Money implement Bounded {
    cents: i32,

    fn min(self: Self, other: Self) -> Self {
        return if (self.cents < other.cents) { self; } else { other; };
    }

    fn max(self: Self, other: Self) -> Self {
        return if (self.cents > other.cents) { self; } else { other; };
    }
}

fn main() {
    val m = Money(cents: 500).clamp(Money(cents: 0), Money(cents: 120));
    @print(m.cents);
}
```

----- JAVASCRIPT -- main.js
```javascript
// interface Bounded
//   fn min(...)
//   fn max(...)
//   default fn clamp(...)

class Money {
    constructor(cents) {
        this.cents = cents;
    }

    min(other) {
        return (() => { if ((this.cents < other.cents)) { return this; } else { return other; } })();
    }

    max(other) {
        return (() => { if ((this.cents > other.cents)) { return this; } else { return other; } })();
    }

    clamp(lo, hi) {
        return this.max(lo).min(hi);
    }
}

function main() {
    const m = new Money(500).clamp(new Money(0), new Money(120));
    console.log(m.cents);
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
120
```
