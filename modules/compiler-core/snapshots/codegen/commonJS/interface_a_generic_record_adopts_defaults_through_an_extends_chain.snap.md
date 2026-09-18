----- SOURCE CODE -- main.bp
```botopink
behavior Sized {
    fn size(self: Self) -> i32;

    default fn isEmpty(self: Self) -> bool {
        return self.size() == 0;
    }
}

behavior Counted extends Sized {
    default fn twiceSize(self: Self) -> i32 {
        return self.size() * 2;
    }
}

type Bag<T>(
    items: Array<T>,
) implement Counted {
    pub fn size(self: Self) -> i32 {
        return self.items.length;
    }
}

fn main() {
    @print(Bag(items: []).isEmpty());
    @print(Bag(items: [1]).isEmpty());
    @print(Bag(items: [1, 2]).twiceSize());
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(",")) + (t ? ")" : "]"));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

// behavior Sized
//   fn size(...)
//   default fn isEmpty(...)

// behavior Counted extends Sized
//   default fn twiceSize(...)

class Bag {
    constructor(items) {
        this.items = items;
    }

    size() {
        return this.items.length;
    }

    twiceSize() {
        return (this.size() * 2);
    }

    isEmpty() {
        return (this.size() === 0);
    }
}
Bag.prototype.__bp = "Bag";

function main() {
    __bp_print(new Bag([]).isEmpty());
    __bp_print(new Bag([1]).isEmpty());
    __bp_print(new Bag([1, 2]).twiceSize());
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
true
false
4
```
