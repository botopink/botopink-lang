----- SOURCE CODE -- main.bp
```botopink
fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn validate(n: i32) -> @Result<i32, string> { @todo(); }
fn main() {
    val r = parseAge("42")
        .map({ n -> n + 1 })
        .flatMap({ n -> validate(n) })
        .unwrapOr(0);
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

function parseAge(s) {
    (() => { throw new Error("not implemented") })();
}

function validate(n) {
    (() => { throw new Error("not implemented") })();
}

function main() {
    const r = ((_r) => "error" in _r ? (0) : _r.ok)(((_r) => "error" in _r ? _r : ((n) => {
    return validate(n);
})(_r.ok))(((_r) => "error" in _r ? _r : { ok: ((n) => {
    return __bp_int((n + 1), -2147483648, 2147483647, "+ on i32 at main.bp:5:23");
})(_r.ok) })(parseAge("42"))));
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
```
