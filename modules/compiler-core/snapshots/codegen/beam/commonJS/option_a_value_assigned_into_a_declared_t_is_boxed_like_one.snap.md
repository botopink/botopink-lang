----- SOURCE CODE -- main.bp
```botopink
type Box(items: Array<i32>) {
    fn total(self: Self) -> i32 {
        var sum = 0;
        self.items.forEach({ n -> sum = sum + n });
        return sum;
    }
    fn isBig(self: Self) -> bool { return self.items.length > 1; }
    fn doubled(self: Self) -> Array<i32> { return self.items.map({ n -> n * 2 }); }
    fn label(self: Self) -> string { return "box"; }
}
fn main() {
    var seen = 0;
    [1, 2].forEach({ n -> seen = n });
    @print(seen);
    val b = Box(items: [3, 4]);
    @print(b.total());
    var h: ?i32 = null;
    @print(h);
    h = 5;
    @print(h);
    var acc: ?i32 = null;
    [7, 8].forEach({ n -> acc = n });
    @print(acc);
    @print(b.isBig());
    @print(b.doubled());
    @print(b.label());
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(Number.isInteger(v) ? v.toFixed(1) : String(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
    }
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

class Box {
    constructor(items) {
        this.items = items;
    }

    total() {
        let sum = 0;
        this.items.forEach((n) => {
    sum = (sum + n);
});
        return sum;
    }

    isBig() {
        return (this.items.length > 1);
    }

    doubled() {
        return this.items.map((n) => {
    return (n * 2);
});
    }

    label() {
        return "box";
    }
}
Box.prototype.__bp = "Box";

function main() {
    let seen = 0;
    [1, 2].forEach((n) => {
    seen = n;
});
    __bp_print(seen);
    const b = new Box([3, 4]);
    __bp_print(b.total());
    let h = null;
    __bp_print(h);
    h = 5;
    __bp_print(h);
    let acc = null;
    [7, 8].forEach((n) => {
    acc = n;
});
    __bp_print(acc);
    __bp_print(b.isBig());
    __bp_print(b.doubled());
    __bp_print(b.label());
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
2
7
null
5
8
true
[6, 8]
box
```
