----- SOURCE CODE -- main.bp
```botopink
fn greet(lang: string) -> string {
    val msg = case lang {
        "en" -> "hello";
        "pt" -> "ola";
        _ -> "hi";
    };
    @print(msg);
    return msg;
}
fn main() {
    greet("en");
    greet("pt");
    greet("fr");
}
```

----- JAVASCRIPT -- main.js
```javascript
function greet(lang) {
    const msg = (() => {
        const _s = lang;
        if (_s === "en") return "hello";
        if (_s === "pt") return "ola";
        return "hi";
    })();
    console.log(msg);
    return msg;
}

function main() {
    greet("en");
    greet("pt");
    greet("fr");
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
hello
ola
hi
```
