----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val precosBrutos = [100, 250, 400];
    var precosComTaxa = [];
    for (precosBrutos) { valor ->
        val taxa = valor * 0.15;
        precosComTaxa.push(valor + taxa);
    };
    @print(precosComTaxa);
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: the wasm backend cannot place a float in this array: nothing types its elements as floats (write the array's type, `Array<f64>`)
  ┌─ :6:34
  │
6 │         precosComTaxa.push(valor + taxa);
  │                                  ^
```

