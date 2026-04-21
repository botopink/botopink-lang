----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val input = 42;
    val status = @block{
        val calculo = input * 2;
        if (calculo > 100) return "Alto";
        return "Baixo";
    };
    return status;
}
```

----- JAVASCRIPT -- main.js
```javascript
function main() {
    const input = 42;
    const status = (() => { const calculo = (input * 2); if ((calculo > 100)) { return "Alto"; };return "Baixo"; })();
    return status;
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript

```
