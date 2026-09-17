----- SOURCE CODE -- main.bp
```botopink
fn render(words: Array<string>) -> string {
    var out = "";
    var count = 0;
    val emit = { w ->
        out = out + "<" + w + ">";
        count = count + 1;
    };
    emit("start");
    loop (words) { w -> emit(w); };
    return out + " " + count.toString();
}
fn main() {
    @print(render(["a", "b"]));
}
```

----- JAVASCRIPT -- main.js
```javascript
function render(words) {
    let out = "";
    let count = 0;
    const emit = (w) => {
    out = (((out + "<") + w) + ">");
    count = (count + 1);
};
    emit("start");
    for (const w of words) {
    emit(w);
}
    return ((out + " ") + count.toString());
}

function main() {
    console.log(render(["a", "b"]));
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
<start><a><b> 3
```
