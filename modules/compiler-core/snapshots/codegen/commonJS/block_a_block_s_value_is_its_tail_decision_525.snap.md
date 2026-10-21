----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val input = 42;
    val status = {
        val calculo = input * 2;
        if (calculo > 100) {
            "Alto"
        } else {
            "Baixo"
        }
    };
    return status;
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw Object.defineProperty(new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what), "__bp_panic", { value: true }); }

function main() {
    const input = 42;
    const status = (() => {
        const _s = true;
        {
            const calculo = __bp_int((input * 2), -2147483648, 2147483647, "* on i32 at main.bp:4:29");
            return (() => { if ((calculo > 100)) { return "Alto"; } else { return "Baixo"; } })();
        }
    })();
    return status;
}

function _botopink_main() {
    main();
}
if (require.main === module) {
    const __bp_abort = (e) => { const k = (e != null && e.__bp_panic != null) ? ["panic", (typeof e.__bp_panic === "string") ? e.__bp_panic : e.message] : (e != null && typeof e.__bp_assert_loc === "string") ? ["panic", e.message] : [(e != null && e.__bp_host === true) ? "host" : "crash", (e instanceof Error) ? e.message : String(e)]; globalThis.process.stderr.write(k[0] + ": " + k[1] + "\n", () => globalThis.process.exit(1)); };
    globalThis.process.on("uncaughtException", __bp_abort);
    globalThis.process.on("unhandledRejection", __bp_abort);
    _botopink_main();
}

Object.defineProperty(exports, "__bp_priv__", { value: { main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
