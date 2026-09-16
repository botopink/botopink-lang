----- SOURCE CODE -- main.bp
```botopink
enum Status { Ok, Fail }
#[@result]
fn check(s: Status) -> @Result<i32, string> {
    return case s {
        Ok -> 1;
        Fail -> throw "failed";
    };
}
fn main() {
    @print(check(Status.Ok).isOk());
    @print(check(Status.Fail).isOk());
}
```

----- JAVASCRIPT -- main.js
```javascript
const Status = Object.freeze({
    Ok: "Ok",
    Fail: "Fail",
});

function check(s) {
    return ({ ok: (() => {
        const _s = s;
        if (_s === "Ok") return 1;
        if (_s === "Fail") return return ({ error: "failed" });
    })() });
}

function main() {
    console.log(((_r) => !("error" in _r))(check(Status.Ok)));
    console.log(((_r) => !("error" in _r))(check(Status.Fail)));
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
```
