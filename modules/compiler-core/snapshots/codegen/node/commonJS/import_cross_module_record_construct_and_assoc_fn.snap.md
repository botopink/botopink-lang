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
    ok(body: ): Response;
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
const { Response, App } = require("./http.js");

function main() {
    const r = Response.ok("hi");
    console.log(r.body);
    const a = new App(8080, "/");
    console.log(a.port);
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
