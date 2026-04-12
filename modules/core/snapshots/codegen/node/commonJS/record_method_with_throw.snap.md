----- SOURCE CODE -- main.bp
```botopink
val Invoice = record {
    subtotal: f64,
    taxRate: f64,
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) {
        throw new Error("invalid invoice");
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
        throw Error("invalid invoice");
    }
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
