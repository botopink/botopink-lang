----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
    Red,
    Green,
    Blue,
    fn name() -> string {
        case (self) {
            Red -> "red";
            Green -> "green";
            Blue -> "blue";
        };
    }
};
```

----- JAVASCRIPT -- main.js
```javascript
const Color = Object.freeze({
    Red: "Red",
    Green: "Green",
    Blue: "Blue",
    name: function() {
        (() => {
            const _s = self;
            if (_s === "Red") return "red";
            if (_s === "Green") return "green";
            if (_s === "Blue") return "blue";
        })();
    },
});
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
