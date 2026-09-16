----- SOURCE CODE -- main.bp
```botopink
enum Opt { None, Some(value: i32) }
fn describe(opt: Opt) -> string {
    return case opt {
        None -> "empty";
        Some(v) -> "value: " + v;
    };
}
fn main() {
    @print(describe(Opt.Some(value: 42)));
    @print(describe(Opt.None));
}
```

----- JAVASCRIPT -- main.js
```javascript
const Opt = Object.freeze({
    None: "None",
    Some: (value) => ({ tag: "Some", value }),
});

function describe(opt) {
    return (() => {
        const _s = opt;
        if (_s === "None") return "empty";
        if (_s.tag === "Some") {
            const { v } = _s;
            return ("value: " + v);
        }
    })();
}

function main() {
    console.log(describe(Opt.Some(42)));
    console.log(describe(Opt.None));
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
value: undefined
empty
```
