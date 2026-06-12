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
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
