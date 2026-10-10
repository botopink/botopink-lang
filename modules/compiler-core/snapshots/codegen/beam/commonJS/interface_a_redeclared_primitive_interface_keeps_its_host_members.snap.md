----- SOURCE CODE -- main.bp
```botopink
behavior Number {
    default fn clampTo(self: Self, lo: Self, hi: Self) -> Self {
        return self.max(lo).min(hi);
    }
}

fn main() {
    val n: i32 = 50;
    @print(n.clampTo(0, 10));
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "bigint")) {
        a.push(String(v));
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
//   default fn clampTo(...)
BigInt.prototype.min = Number.prototype.min = function(other) { return ((__a, __b) => (__a !== __a || __b !== __b) ? NaN : (__b < __a || (__b === __a && Object.is(__b, -0))) ? __b : __a)(this.valueOf(), other); };
BigInt.prototype.max = Number.prototype.max = function(other) { return ((__a, __b) => (__a !== __a || __b !== __b) ? NaN : (__b > __a || (__b === __a && Object.is(__a, -0))) ? __b : __a)(this.valueOf(), other); };
BigInt.prototype.clamp = Number.prototype.clamp = function(lo, hi) {
    const self = this.valueOf();
    return self.max(lo).min(hi);
};
BigInt.prototype.clampTo = Number.prototype.clampTo = function(lo, hi) {
    const self = this.valueOf();
    return self.max(lo).min(hi);
};

function main() {
    const n = 50;
    __bp_print(n.clampTo(0, 10));
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
