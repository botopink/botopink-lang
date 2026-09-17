----- SOURCE CODE -- main.bp
```botopink
record Doc {
    title: string,

    fn print(self: Self) -> string {
        return "doc:" + self.title;
    }
}

fn main() {
    val d = Doc(title: "hi");
    @print(d.print());
}
```

----- JAVASCRIPT -- main.js
```javascript
class Doc {
    constructor(title) {
        this.title = title;
    }

    print() {
        return ("doc:" + this.title);
    }
}

function main() {
    const d = new Doc("hi");
    console.log(d.print());
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
doc:hi
```
