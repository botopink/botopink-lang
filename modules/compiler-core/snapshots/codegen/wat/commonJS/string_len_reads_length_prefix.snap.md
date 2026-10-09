----- SOURCE CODE -- main.bp
```botopink
fn n() -> i32 {
    val s = "hello";
    return s.len;
}
```

----- JAVASCRIPT -- main.js
```javascript
const __bp_surrogate = /[\uD800-\uDFFF]/;
const __bp_surrogate_k = new Array(64).fill("");
const __bp_surrogate_v = new Array(64).fill(false);
function __bp_has_surrogate(s) {
    const h = s.length & 63;
    if (__bp_surrogate_k[h] === s) { return __bp_surrogate_v[h]; }
    const p = __bp_surrogate.test(s);
    __bp_surrogate_k[h] = s;
    __bp_surrogate_v[h] = p;
    return p;
}

function __bp_str_length(s) {
    if (!__bp_has_surrogate(s)) { return s.length; }
    let n = 0;
    for (const c of s) { n += 1; }
    return n;
}

function n() {
    const s = "hello";
    return __bp_str_length(s);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
