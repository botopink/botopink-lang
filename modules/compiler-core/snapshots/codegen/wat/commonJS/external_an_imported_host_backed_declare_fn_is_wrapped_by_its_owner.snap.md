----- SOURCE CODE -- hostlib.bp
```botopink
#[@External.Node("String($0)"),
  @External.Erlang("""iolist_to_binary(io_lib:format("~0tp", [$0]))""")]
pub declare fn hostKey(v: i32) -> string;

#[@External.Node("$0.length"),
  @External.Erlang("erlang", "length")]
pub declare fn hostLen(xs: Array<string>) -> i32;

#[@External.Node("console.log($0)")]
pub declare fn nodeOnly(s: string) -> void;
```

----- JAVASCRIPT -- hostlib.js
```javascript
// hostKey: per-call template (see annotation)
function hostKey(v) { return String(v); }
exports.hostKey = hostKey;

// hostLen: per-call template (see annotation)
function hostLen(xs) { return xs.length; }
exports.hostLen = hostLen;

// nodeOnly: per-call template (see annotation)
function nodeOnly(s) { return console.log(s); }
exports.nodeOnly = nodeOnly;
```

----- TYPESCRIPT TYPEDEF -- hostlib.d.ts
```typescript
export declare function hostKey(v: number): string;


export declare function hostLen(xs: Array<string>): number;


export declare function nodeOnly(s: string): void;

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import { hostKey, hostLen, nodeOnly };

pub fn main() {
    @print(hostKey(42));
    @print(hostLen(["a", "b"]));
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

const { hostKey, hostLen, nodeOnly } = require("./hostlib.js");

function main() {
    __bp_print(hostKey(42));
    __bp_print(hostLen(["a", "b"]));
}
exports.main = main;

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { hostKey, hostLen, nodeOnly } from "./hostlib";






export declare function main(): void;

```

----- RUN LOG -----
```logs
42
2
```
