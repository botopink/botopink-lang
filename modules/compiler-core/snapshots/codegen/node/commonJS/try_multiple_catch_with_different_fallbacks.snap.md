----- SOURCE CODE -- main.bp
```botopink
record UserError { msg: string }
fn fetchName() -> @Result(string, UserError) {
    throw UserError(msg: "name missing");
}
fn fetchAge() -> @Result(i32, UserError) {
    throw UserError(msg: "age missing");
}
fn loadUser() {
    val name = try fetchName() catch "anonymous";
    val age = try fetchAge() catch 0;
    @print(name, age);
}
```

----- JAVASCRIPT -- main.js
```javascript
class UserError {
    constructor(msg) {
        this.msg = msg;
    }
}

function fetchName() {
    throw UserError("name missing");
}

function fetchAge() {
    throw UserError("age missing");
}

function loadUser() {
    const name = (() => { try { return fetchName(); } catch(_e) { return ("anonymous")(_e); } })();
    const age = (() => { try { return fetchAge(); } catch(_e) { return (0)(_e); } })();
    console.log(name, age);
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript







```

----- RUN LOG -----
```logs
```
