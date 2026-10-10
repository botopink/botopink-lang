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
BigInt.prototype.min = Number.prototype.min = function(other) { return ((__a, __b) => (__a !== __a || __b !== __b) ? NaN : (__b < __a || (__b === __a && Object.is(__b, -0))) ? __b : __a)(this.valueOf(), other); };
BigInt.prototype.max = Number.prototype.max = function(other) { return ((__a, __b) => (__a !== __a || __b !== __b) ? NaN : (__b > __a || (__b === __a && Object.is(__a, -0))) ? __b : __a)(this.valueOf(), other); };
BigInt.prototype.clamp = Number.prototype.clamp = function(lo, hi) {
    const self = this.valueOf();
    return self.max(lo).min(hi);
};

// behavior Signed extends Integer
//   fn abs(...)
BigInt.prototype.abs = Number.prototype.abs = function() { return ((__a) => (__a < 0 || Object.is(__a, -0)) ? -__a : __a)(this.valueOf()); };

// behavior Integer extends Number
//   fn toString(...)
//   default fn isEven(...)
//   default fn isOdd(...)
//   fn toI32(...)
//   fn toI64(...)
//   fn toU32(...)
//   fn toU64(...)
//   fn toF64(...)
BigInt.prototype.isEven = Number.prototype.isEven = function() { return ((__a) => typeof __a === "bigint" ? __a % 2n === 0n : __a % 2 === 0)(this.valueOf()); };
BigInt.prototype.isOdd = Number.prototype.isOdd = function() { return ((__a) => typeof __a === "bigint" ? __a % 2n !== 0n : __a % 2 !== 0)(this.valueOf()); };
BigInt.prototype.toI32 = Number.prototype.toI32 = function() { return ((__v) => { if (__v >= -2147483648 && __v <= 2147483647) { return Number(__v); } throw new Error("integer overflow: toI32: " + __v + " does not fit i32"); })(this.valueOf()); };
BigInt.prototype.toI64 = Number.prototype.toI64 = function() { return ((__v) => { if (__v >= -9223372036854775808n && __v <= 9223372036854775807n) { return (__v >= -9007199254740991n && __v <= 9007199254740991n) ? Number(__v) : __v; } throw new Error("integer overflow: toI64: " + __v + " does not fit i64"); })(this.valueOf()); };
BigInt.prototype.toU32 = Number.prototype.toU32 = function() { return ((__v) => { if (__v >= 0 && __v <= 4294967295) { return Number(__v); } throw new Error("integer overflow: toU32: " + __v + " does not fit u32"); })(this.valueOf()); };
BigInt.prototype.toU64 = Number.prototype.toU64 = function() { return ((__v) => { if (__v >= 0 && __v <= 18446744073709551615n) { return __v; } throw new Error("integer overflow: toU64: " + __v + " does not fit u64"); })(this.valueOf()); };
BigInt.prototype.toF64 = Number.prototype.toF64 = function() { return ((__v) => { const __f = Number(__v); if (typeof __v !== "bigint" || BigInt(__f) === __v) { return __f; } throw new Error("integer overflow: toF64: " + __v + " has no exact f64"); })(this.valueOf()); };

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
