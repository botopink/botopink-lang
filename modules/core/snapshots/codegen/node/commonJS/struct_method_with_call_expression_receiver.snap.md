----- SOURCE CODE -- main.bp
```botopink
val Logger = struct {
    _prefix: string = "",
    fn setPrefix(self: Self, p: string) {
        self._prefix = p;
    }
    fn log(self: Self, msg: string) {
        console.log(self._prefix, msg);
    }
    get prefix(self: Self) -> string {
        return self._prefix;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class Logger {
    _prefix = "";

    setPrefix(p) {
        this._prefix = p;
    }

    log(msg) {
        console.log(this._prefix, msg);
    }

    get prefix() {
        return this._prefix;
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
