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
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

// behavior Number
//   fn min(...)
//   fn max(...)
//   default fn clamp(...)
Number.prototype.min = function(other) { return Math.min(this.valueOf(), other); };
Number.prototype.max = function(other) { return Math.max(this.valueOf(), other); };
Number.prototype.clamp = function(lo, hi) {
    const self = this.valueOf();
    return self.max(lo).min(hi);
};

// behavior Signed extends Integer
//   fn abs(...)
Number.prototype.abs = function() { return Math.abs(this.valueOf()); };

// behavior Integer extends Number
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
    __bp_print(n.abs());
    __bp_print(n.min(3));
    __bp_print(n.max(10));
    __bp_print(n.clamp(0, 5));
    const x = 7;
    __bp_print(x.isEven());
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
