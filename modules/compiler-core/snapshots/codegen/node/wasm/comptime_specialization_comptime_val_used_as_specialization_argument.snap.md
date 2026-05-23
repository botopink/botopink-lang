----- SOURCE CODE -- main.bp
```botopink
val base = comptime 10 + 5;

fn scale(comptime factor: i32, value: i32) -> i32 {
    return value * factor;
}

fn main() {
    val doubled = scale(2, base);
    val tripled = scale(3, base);
    val doubledAgain = scale(2, 100);
}
```

----- COMPTIME JAVASCRIPT -- main.js
```javascript
const fs = require('fs');
const results = [
    { id: "ct_0", value: (10 + 5) }
];
process.stdout.write(JSON.stringify(results));
```

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main
    (local $doubled i32)
    (local $tripled i32)
    (local $doubledAgain i32)
    global.get $base
    call $scale_$0
    local.set $doubled
    global.get $base
    call $scale_$1
    local.set $tripled
    i32.const 100
    call $scale_$0
    local.set $doubledAgain
  )
  (func $scale_$0 (param $value i32)
    (local $factor i32)
    i32.const 2
    local.set $factor
    local.get $value
    local.get $factor
    i32.mul
    return
  )
  (func $scale_$1 (param $value i32)
    (local $factor i32)
    i32.const 3
    local.set $factor
    local.get $value
    local.get $factor
    i32.mul
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
  )
)
```

----- RUN LOG -----
```logs
```
