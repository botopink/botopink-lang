----- SOURCE CODE -- main.bp
```botopink
val Status = type {
    Active,
    Inactive,
    fn isDefault(s: Self) -> string {
        val current = Status.Active;
        return current;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class Status {
    static isDefault(s) {
        const current = Status.Active;
        return current;
    }
}
Status.prototype.__bp = "Status";
class Status$Active extends Status {
}
Status$Active.prototype.tag = "Active";
class Status$Inactive extends Status {
}
Status$Inactive.prototype.tag = "Inactive";
Status.Active = new Status$Active();
Status.Inactive = new Status$Inactive();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
