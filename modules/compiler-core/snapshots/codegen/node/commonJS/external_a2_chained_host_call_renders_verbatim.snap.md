----- SOURCE CODE -- main.bp
```botopink
#[@External.Erlang("base64:encode($0)"),
  @External.Node("""Buffer.from($0, 'utf8').toString('base64')""")]
pub declare fn b64encode(s: string) -> string;

fn main() {
    @print(b64encode("hi"));
}
```

----- JAVASCRIPT -- main.js
```javascript
// b64encode: per-call template (see annotation)

function main() {
    console.log(Buffer.from("hi", 'utf8').toString('base64'));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function b64encode(s: ): string;



```

----- RUN LOG -----
```logs
aGk=
```
