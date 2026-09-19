----- SOURCE CODE -- main.bp
```botopink
val Maybe = type {
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
class Maybe {
    static Just(value) {
        return new Maybe$Just(value);
    }

    static check(m) {
        return (() => {
            const _s = m;
            if (_s instanceof Maybe$Nothing) return "nothing";
            if (_s.tag === "Just") {
                const { value } = _s;
                return "just";
            }
        })();
    }
}
Maybe.prototype.__bp = "Maybe";
class Maybe$Nothing extends Maybe {
}
Maybe$Nothing.prototype.tag = "Nothing";
class Maybe$Just extends Maybe {
    constructor(value) {
        super();
        this.value = value;
    }
}
Maybe$Just.prototype.tag = "Just";
Maybe.Nothing = new Maybe$Nothing();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
