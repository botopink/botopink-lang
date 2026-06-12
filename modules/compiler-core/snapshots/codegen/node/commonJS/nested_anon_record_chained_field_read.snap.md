----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val outer = record { span: record { start: 5, end: 9 }, kind: 3 };
    @print(outer.span.start);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const outer = ({ span: ({ start: 5, end: 9 }), kind: 3 });
    console.log(outer.span.start);
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
5
```
