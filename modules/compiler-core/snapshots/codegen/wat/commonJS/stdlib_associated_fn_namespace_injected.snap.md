----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val p = Pair.of(1, "one");
    @print(Pair.first(p));
    @print(Function.identity(42));
    val inc = Function.compose({ x -> x + 1 }, { y -> y * 2 });
    @print(inc(10));
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

// behavior Function
//   default fn identity(...)
//   default fn compose(...)
//   default fn flip(...)
//   default fn constant(...)
const Function = {};
Function.identity = function(x) {
    return x;
};
Function.compose = function(f, g) {
    return (a) => {
    return g(f(a));
};
};
Function.flip = function(f) {
    return (b, a) => {
    return f(a, b);
};
};
Function.constant = function(x) {
    return (ignored) => {
    return x;
};
};

// behavior Pair
//   default fn of(...)
//   default fn first(...)
//   default fn second(...)
//   default fn swap(...)
//   default fn mapFirst(...)
//   default fn mapSecond(...)
const Pair = {};
Pair.of = function(first, second) {
    return [first, second];
};
Pair.first = function(p) {
    return p[0];
};
Pair.second = function(p) {
    return p[1];
};
Pair.swap = function(p) {
    return [p[1], p[0]];
};
Pair.mapFirst = function(p, transform) {
    return [transform(p[0]), p[1]];
};
Pair.mapSecond = function(p, transform) {
    return [p[0], transform(p[1])];
};

function main() {
    const p = Pair.of(1, "one");
    __bp_print(Pair.first(p));
    __bp_print(Function.identity(42));
    const inc = Function.compose((x) => {
    return (x + 1);
}, (y) => {
    return (y * 2);
});
    __bp_print(inc(10));
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
1
42
22
```
