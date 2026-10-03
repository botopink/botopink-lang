----- SOURCE CODE -- main.bp
```botopink
fn get_coordinates() -> #(f64, f64) {
    return #(0.0, 0.0);
}
fn extract_coordinates() {
    val #(longitude, latitude) = get_coordinates();
}
```

----- JAVASCRIPT -- main.js
```javascript
function get_coordinates() {
    return [0.0, 0.0];
}

function extract_coordinates() {
    const [ longitude, latitude ] = get_coordinates();
}
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript



```

----- RUN LOG -----
```logs
```
