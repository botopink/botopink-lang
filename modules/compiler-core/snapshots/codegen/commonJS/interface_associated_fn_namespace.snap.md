----- SOURCE CODE -- main.bp
```botopink
interface Pairish<A, B> {
    default fn of(first: A, second: B) -> #(A, B) {
        return #(first, second);
    }
    default fn first(p: #(A, B)) -> A {
        return p._0;
    }
}

fn main() {
    val p = Pairish.of(1, "one");
    @print(Pairish.first(p));
}
```

----- JAVASCRIPT -- main.js
```javascript
// interface Pairish
//   default fn of(...)
//   default fn first(...)
const Pairish = {};
Pairish.of = function(first, second) {
    return [first, second];
};
Pairish.first = function(p) {
    return p[0];
};

function main() {
    const p = Pairish.of(1, "one");
    console.log(Pairish.first(p));
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
