----- SOURCE CODE -- main.bp
```botopink
val Direction = type {
    North,
    South,
    East,
    West,
}
```

----- JAVASCRIPT -- main.js
```javascript
class Direction {
}
Direction.prototype.__bp = "Direction";
class Direction$North extends Direction {
}
Direction$North.prototype.tag = "North";
class Direction$South extends Direction {
}
Direction$South.prototype.tag = "South";
class Direction$East extends Direction {
}
Direction$East.prototype.tag = "East";
class Direction$West extends Direction {
}
Direction$West.prototype.tag = "West";
Direction.North = new Direction$North();
Direction.South = new Direction$South();
Direction.East = new Direction$East();
Direction.West = new Direction$West();

Object.defineProperty(exports, "__bp_priv__", { value: { Direction, Direction$North, Direction$South, Direction$East, Direction$West } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
