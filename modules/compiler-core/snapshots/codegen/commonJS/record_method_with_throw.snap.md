----- SOURCE CODE -- main.bp
```botopink
val Invoice = type(
    subtotal: f64,
    taxRate: f64) {
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) -> Result<void, string> {
        throw "invalid invoice";
        return;
    }
}
```

----- JAVASCRIPT -- main.js
```javascript
class Invoice {
    constructor(subtotal, taxRate) {
        this.subtotal = subtotal;
        this.taxRate = taxRate;
    }

    total() {
        return (this.subtotal + (this.subtotal * this.taxRate));
    }

    validate() {
        return ({ error: "invalid invoice" });
        return ({ ok: null });
    }
}
Invoice.prototype.__bp = "Invoice";
Invoice.prototype.__bp_s = { subtotal: "f", taxRate: "f" };

Object.defineProperty(exports, "__bp_priv__", { value: { Invoice } });
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
