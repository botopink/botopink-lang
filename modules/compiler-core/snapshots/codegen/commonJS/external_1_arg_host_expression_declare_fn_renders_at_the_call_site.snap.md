----- SOURCE CODE -- main.bp
```botopink
#[@External.Node("process.pid"),
  @External.Erlang("list_to_integer(os:getpid())")]
declare fn pid() -> i32;

fn main() {
    @print(pid() > 0);
}
```

----- JAVASCRIPT -- main.js
```javascript
// pid: per-call template (see annotation)

function main() {
    console.log((process.pid > 0));
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
true
```
