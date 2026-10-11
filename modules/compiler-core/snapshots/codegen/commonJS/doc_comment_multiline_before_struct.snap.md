----- SOURCE CODE -- main.bp
```botopink
/// User account structure
/// Holds name and email
val Account = type(name: string, email: string);
```

----- JAVASCRIPT -- main.js
```javascript
/** User account structure */

/** Holds name and email */

class Account {
    constructor(name, email) {
        this.name = name;
        this.email = email;
    }
}
Account.prototype.__bp = "Account";
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
