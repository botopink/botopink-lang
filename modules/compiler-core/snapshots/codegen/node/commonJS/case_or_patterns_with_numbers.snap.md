----- SOURCE CODE -- main.bp
```botopink
fn classify(day: i32) -> string {
    val kind = case day {
        6 | 7 -> "weekend";
        _ -> "weekday";
    };
    @print(kind);
    return kind;
}
fn main() {
    classify(3);
    classify(6);
    classify(7);
}
```

----- JAVASCRIPT -- main.js
```javascript
function classify(day) {
    const kind = (() => {
        const _s = day;
        if (_s === 6 || _s === 7) return "weekend";
        return "weekday";
    })();
    console.log(kind);
    return kind;
}

function main() {
    classify(3);
    classify(6);
    classify(7);
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
weekday
weekend
weekend
```
