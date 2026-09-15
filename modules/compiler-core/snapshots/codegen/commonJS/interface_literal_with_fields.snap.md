----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val DeclKind = record { Record: "Record", Fn: "Fn" };
    val decl = @Decl(kind: DeclKind.Record, name: "Service", fields: [record { name: "x", typeName: "i32", annotations: [] }], methods: [], returnType: "", annotations: []);
    @print(decl.fields.length);
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const DeclKind = ({ Record: "Record", Fn: "Fn" });
    const decl = ({ kind: DeclKind.Record, name: "Service", fields: [({ name: "x", typeName: "i32", annotations: [] })], methods: [], returnType: "", annotations: [] });
    console.log(decl.fields.length);
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
1
```
