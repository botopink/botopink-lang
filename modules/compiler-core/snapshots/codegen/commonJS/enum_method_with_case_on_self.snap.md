----- SOURCE CODE -- main.bp
```botopink
val Color = type {
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
class Color {
    static name() {
        (() => {
            const _s = this;
            if (_s instanceof Color$Red) return "red";
            if (_s instanceof Color$Green) return "green";
            if (_s instanceof Color$Blue) return "blue";
        })();
    }
}
Color.prototype.__bp = "Color";
class Color$Red extends Color {
}
Color$Red.prototype.tag = "Red";
class Color$Green extends Color {
}
Color$Green.prototype.tag = "Green";
class Color$Blue extends Color {
}
Color$Blue.prototype.tag = "Blue";
Color.Red = new Color$Red();
Color.Green = new Color$Green();
Color.Blue = new Color$Blue();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
