----- SOURCE CODE -- main.bp
```botopink
fn pairOf(a: i32, b: string) -> #(i32, string) {
    return #(a, b);
}
fn show(p: #(i32, string)) {
    @print(p);
}
fn main() {
    @print(#(true, 1));
    @print(#(#(1, 2), "x"));
    @print([#(1, 2), #(17, 1)]);
    @print(pairOf(7, "s"));
    show(#(3, "z"));
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

function __bp_print_as(shapes) {
    const a = [];
    const f = Array.from(Array.from(arguments).slice(1), (v, i) => __bp_show(v, shapes[i], true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function pairOf(a, b) {
    return [a, b];
}

function show(p) {
    __bp_print_as([["#", null, null]], p);
}

function main() {
    __bp_print_as([["#", null, null]], [true, 1]);
    __bp_print_as([["#", ["#", null, null], null]], [[1, 2], "x"]);
    __bp_print_as([["[", ["#", null, null]]], [[1, 2], [17, 1]]);
    __bp_print_as([["#", null, null]], pairOf(7, "s"));
    show([3, "z"]);
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
#(true,1)
#(#(1,2),"x")
[#(1,2),#(17,1)]
#(7,"s")
#(3,"z")
```
