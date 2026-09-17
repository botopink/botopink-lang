----- SOURCE CODE -- http.bp
```botopink
pub record Response {
    body: string,
    fn ok(body: string) -> Response {
        return Response(body: body);
    }
}

pub record App {
    port: i32,
    path: string,
}
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
exports.Response = Response;

class App {
    constructor(port, path) {
        this.port = port;
        this.path = path;
    }
}
exports.App = App;
```

----- TYPESCRIPT TYPEDEF -- http.d.ts
```typescript
export declare class Response {
    readonly body: string;
    constructor(body: string);
    ok(body: string): Response;
}


export declare class App {
    readonly port: i32;
    readonly path: string;
    constructor(port: i32, path: string);
}

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {Response, App} from "http";

fn main() {
    val r = Response.ok("hi");
    @print(r.body);
    val a = App(8080, "/");
    @print(a.port);
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
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { Response, App } from "http";


import { Response, App } from "http";



```

----- RUN LOG -----
```logs
hi
8080
```
