----- SOURCE CODE -- pond.bp
```botopink
val Swimmer = interface {
    fn swim(self: Self);
}
pub record Pato { id: i32 }
pub val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
```

----- JAVASCRIPT -- pond.js
```javascript
// interface Swimmer
//   fn swim(...)

class Pato {
    constructor(id) {
        this.id = id;
    }
}
exports.Pato = Pato;

// implement Swimmer for Pato
const PatoNada = {
    swim(self) {
        return self.id;
    },
};
exports.PatoNada = PatoNada;
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
import {Pato, PatoNada*} from "pond";
fn main() {
    val donald = Pato(2);
    @print(donald.swim());
}
```

----- JAVASCRIPT -- main.js
```javascript
const { Pato, PatoNada } = require("./pond.js");

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
import { Pato, PatoNada } from "pond";



```

----- RUN LOG -----
```logs
2
```
