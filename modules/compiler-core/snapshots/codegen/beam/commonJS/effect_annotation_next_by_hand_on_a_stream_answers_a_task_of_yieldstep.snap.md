----- SOURCE CODE -- main.bp
```botopink
fn countdown(n: i32) -> @Stream<i32> {
    var i = n;
    while (i > 0) {
        yield i;
        i = i - 1;
    };
}
fn stepText(s: YieldStep<i32>) -> string {
    val t = case s {
        Yield(v) -> "yield " + v.toString();
        Done -> "done";
    };
    return t;
}
fn run() -> @Task<void> {
    val s = countdown(1);
    @print(stepText(await s.next()));
    @print(stepText(await s.next()));
}
pub fn main() {
    run();
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

function __bp_yield_step(r) { return r.done ? YieldStep.Done : YieldStep.Yield(r.value); }

class YieldStep {
    static Yield(value) {
        return new YieldStep$Yield(value);
    }
}
YieldStep.prototype.__bp = "YieldStep";
class YieldStep$Yield extends YieldStep {
    constructor(value) {
        super();
        this.value = value;
    }
}
YieldStep$Yield.prototype.tag = "Yield";
class YieldStep$Done extends YieldStep {
}
YieldStep$Done.prototype.tag = "Done";
YieldStep.Done = new YieldStep$Done();

async function* countdown(n) {
    let i = n;
    while ((i > 0)) {
    yield i;
    i = (i - 1);
}
}

function stepText(s) {
    const t = (() => {
        const _s = s;
        if (_s.tag === "Yield") {
            const { value: v } = _s;
            return ("yield " + v.toString());
        }
        if (_s.tag === "Done") return "done";
    })();
    return t;
}

async function run() {
    const s = countdown(1);
    __bp_print(stepText(await s.next().then(__bp_yield_step)));
    __bp_print(stepText(await s.next().then(__bp_yield_step)));
}

function main() {
    run();
}
exports.main = main;

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript






export declare function main(): void;

```

----- RUN LOG -----
```logs
yield 1
done
```
