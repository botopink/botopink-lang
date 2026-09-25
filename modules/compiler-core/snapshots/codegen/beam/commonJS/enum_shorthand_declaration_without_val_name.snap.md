----- SOURCE CODE -- main.bp
```botopink
type Direction {
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
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
