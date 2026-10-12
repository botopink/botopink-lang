----- SOURCE CODE -- http.bp
```botopink
pub type Response(
    body: string) {
    fn ok(body: string) -> Response {
        return Response(body: body);
    }
}

pub type App(
    port: i32,
    path: string,
)
```

----- JAVASCRIPT -- http.js
```javascript
class Response {
    constructor(body) {
        this.body = body;
    }

    static ok(body) {
        return new Response(body);
    }
}
Response.prototype.__bp = "Response";
exports.Response = Response;

class App {
    constructor(port, path) {
        this.port = port;
        this.path = path;
    }
}
App.prototype.__bp = "App";
exports.App = App;

Object.defineProperty(exports, "__bp_priv__", { value: { Response, App } });
```

----- TYPESCRIPT TYPEDEF -- http.d.ts
```typescript
export declare class Response {
    readonly body: string;
    constructor(body: string);
    ok(body: string): Response;
}


export declare class App {
    readonly port: number;
    readonly path: string;
    constructor(port: number, path: string);
}

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {http.Response, http.App};

fn main() {
    val r = Response.ok("hi");
    @print(r.body);
    val a = App(8080, "/");
    @print(a.port);
}
```

----- JAVASCRIPT -- main.js
```javascript
function __bp_f64(v) {
    if (!Number.isFinite(v)) { return String(v); }
    const s = Object.is(v, -0) ? "-0" : String(v);
    const i = s.indexOf("e");
    if (i < 0) { return s.indexOf(".") < 0 ? s + ".0" : s; }
    const m = s.slice(0, i);
    return (m.indexOf(".") < 0 ? m + ".0" : m) + "e" + s.slice(i + 1).replace("+", "");
}

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
        a.push(__bp_f64(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if ((((typeof v === "object") && (v != null)) && (typeof v.__bp !== "string"))) {
        const k = Object.keys(v);
        if (((k.length === 1) && ((k[0] === "ok") || (k[0] === "error")))) {
            return ((((k[0] === "ok") ? "Ok(" : "Error(") + __bp_show(v[k[0]], null, false, a)) + ")");
        }
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

const { Response, App } = require("./http.js");

function main() {
    const r = Response.ok("hi");
    __bp_print(r.body);
    const a = new App(8080, "/");
    __bp_print(a.port);
}

function _botopink_main() {
    main();
}
if (require.main === module) _botopink_main();

Object.defineProperty(exports, "__bp_priv__", { value: { Response, App, main } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { Response, App } from "./http";





```

----- RUN LOG -----
```logs
hi
8080
```
