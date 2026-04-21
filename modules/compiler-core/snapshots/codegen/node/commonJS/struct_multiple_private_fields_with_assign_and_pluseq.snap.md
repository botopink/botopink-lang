----- SOURCE CODE -- main.bp
```botopink
val BankAccount = struct {
    _balance: f64 = 0.0,
    _owner: string = "",
    fn deposit(self: Self, amount: f64) {
        self._balance += amount;
    }
    fn setOwner(self: Self, name: string) {
        self._owner = name;
    }
    get balance(self: Self) -> f64 {
        return self._balance;
    }
    get owner(self: Self) -> string {
        return self._owner;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class BankAccount {
    _balance = 0.0;
    _owner = "";

    deposit(amount) {
        this._balance += amount;
    }

    setOwner(name) {
        this._owner = name;
    }

    get balance() {
        return this._balance;
    }

    get owner() {
        return this._owner;
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
