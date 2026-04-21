----- SOURCE CODE -- main.bp
```botopink
val Maybe = enum {
    Nothing,
    Just(value: string),
    fn check(m: Self) -> string {
        return case m {
            Nothing -> "nothing";
            Just(value) -> "just";
        };
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
const Maybe = Object.freeze({
    Nothing: "Nothing",
    Just: (value) => ({ tag: "Just", value }),
    check: function(m) {
        return (() => {
            const _s = m;
            if (_s === "Nothing") return "nothing";
            if (_s.tag === "Just") {
                const { value } = _s;
                return "just";
            }
        })();
    },
});
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
