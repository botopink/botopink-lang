----- SOURCE CODE -- main.bp
```botopink
behavior Shape {
    fn area(self: Self) -> i32;
}

type Square(side: i32) implement Shape {
    fn area(self: Self) -> i32 {
        return self.side * self.side;
    }
}

type Size { Small, Large(n: i32) }

fn weight(s: Size) -> i32 {
    return case s {
        Small -> 1;
        Large(n) -> n;
    };
}

fn main() {
    val sq = Square(side: 3);
    @print(sq.area());
    @print(weight(Size.Large(n: 5)) + weight(Size.Small));
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

// behavior Shape
//   fn area(...)

class Square {
    constructor(side) {
        this.side = side;
    }

    area() {
        return (this.side * this.side);
    }
}
Square.prototype.__bp = "Square";

class Size {
    static Large(n) {
        return new Size$Large(n);
    }
}
Size.prototype.__bp = "Size";
class Size$Small extends Size {
}
Size$Small.prototype.tag = "Small";
class Size$Large extends Size {
    constructor(n) {
        super();
        this.n = n;
    }
}
Size$Large.prototype.tag = "Large";
Size.Small = new Size$Small();

function weight(s) {
    return (() => {
        const _s = s;
        if (_s instanceof Size$Small) return 1;
        if (_s.tag === "Large") {
            const { n } = _s;
            return n;
        }
    })();
}

function main() {
    const sq = new Square(3);
    __bp_print(sq.area());
    __bp_print((weight(Size.Large(5)) + weight(Size.Small)));
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
9
6
```
