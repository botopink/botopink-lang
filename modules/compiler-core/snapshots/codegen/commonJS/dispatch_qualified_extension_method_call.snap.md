----- SOURCE CODE -- main.bp
```botopink
val Swimmer = interface {
    fn swim(self: Self);
}
record Pato { id: i32 }
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
fn main() {
    val donald = Pato(3);
    @print(PatoNada.swim(donald));
}
```

----- JAVASCRIPT -- main.js
```javascript
// interface Swimmer
//   fn swim(...)

class Pato {
    constructor(id) {
        this.id = id;
    }
}

// implement Swimmer for Pato
const PatoNada = {
    swim(self) {
        return self.id;
    },
};

function main() {
    const donald = new Pato(3);
    console.log(PatoNada.swim(donald));
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
3
```
