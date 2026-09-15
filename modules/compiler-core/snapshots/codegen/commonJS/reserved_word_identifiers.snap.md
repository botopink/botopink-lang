----- SOURCE CODE -- main.bp
```botopink
pub fn delete(with: string, class: string) -> string {
    val static = with + class;
    return static;
}

fn main() {
    @print(delete("a", "b"));
}
```

----- JAVASCRIPT -- main.js
```javascript
function delete_(with_, class_) {
    const static_ = (with_ + class_);
    return static_;
}
exports.delete = delete_;

function main() {
    console.log(delete_("a", "b"));
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript
export declare function delete(with: , class: ): string;



```

----- RUN LOG -----
```logs
ab
```
