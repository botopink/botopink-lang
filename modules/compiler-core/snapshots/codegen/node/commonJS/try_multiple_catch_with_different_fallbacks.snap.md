----- SOURCE CODE -- main.bp
```botopink
record UserError { msg: string }
#[@result]
fn fetchName() -> @Result<string, UserError> {
    throw UserError(msg: "name missing");
}
#[@result]
fn fetchAge() -> @Result<i32, UserError> {
    throw UserError(msg: "age missing");
}
fn loadUser() {
    val name = try fetchName() catch "anonymous";
    val age = try fetchAge() catch 0;
    @print(name, age);
}
fn main() {
    loadUser();
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
    return ({ error: new UserError("name missing") });
}

function fetchAge() {
    return ({ error: new UserError("age missing") });
}

function loadUser() {
    const _try0 = fetchName();
    const name = "error" in _try0 ? ("anonymous") : _try0.ok;
    const _try1 = fetchAge();
    const age = "error" in _try1 ? (0) : _try1.ok;
    console.log(name, age);
}

function main() {
    loadUser();
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
anonymous 0
```
