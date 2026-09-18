----- SOURCE CODE -- main.bp
```botopink
val Color = type {
    Red,
    Rgb(r: i32, g: i32, b: i32),
}
```

----- JAVASCRIPT -- main.js
```javascript
class Color {
    static Rgb(r, g, b) {
        return new Color$Rgb(r, g, b);
    }
}
Color.prototype.__bp = "Color";
class Color$Red extends Color {
}
Color$Red.prototype.tag = "Red";
class Color$Rgb extends Color {
    constructor(r, g, b) {
        super();
        this.r = r;
        this.g = g;
        this.b = b;
    }
}
Color$Rgb.prototype.tag = "Rgb";
Color.Red = new Color$Red();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
