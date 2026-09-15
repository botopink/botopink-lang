----- SOURCE CODE -- pond.bp
```botopink
pub record Pato { id: i32 }
```

----- JAVASCRIPT -- pond.js
```javascript
class Pato {
    constructor(id) {
        this.id = id;
    }
}
exports.Pato = Pato;
```

----- TYPESCRIPT TYPEDEF -- pond.d.ts
```typescript
export declare class Pato {
    readonly id: i32;
    constructor(id: i32);
}

```

----- RUN LOG -----
```logs
```

----- SOURCE CODE -- main.bp
```botopink
import {Pato} from "pond";
val Swimmer = interface {
    fn swim(self: Self);
}
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
fn main() {
    val donald = Pato(2);
    @print(donald.swim());
}
```

----- JAVASCRIPT -- main.js
```javascript
const { Pato } = require("./pond.js");

// interface Swimmer
//   fn swim(...)

// implement Swimmer for Pato
const PatoNada = {
    swim(self) {
        return self.id;
    },
};

function main() {
    const donald = new Pato(2);
    console.log(PatoNada.swim(donald));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
import { Pato } from "pond";





```

----- RUN LOG -----
```logs
2
```
