----- SOURCE CODE -- main.bp
```botopink
val Invoice = type(
    subtotal: f64,
    taxRate: f64) {
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) {
        throw "invalid invoice";
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
        throw "invalid invoice";
    }
}
Invoice.prototype.__bp = "Invoice";
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```

----- RUN LOG -----
```logs
```
