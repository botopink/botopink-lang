----- SOURCE CODE -- main.bp
```botopink
type Token {
    Color {
        Red { 100, 500 }
    }
}
fn red500() -> Token {
    return .Color.Red.500;
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $var_Bp__Token__Color_Red (struct (field $f0 (mut i32))))
    (type $var_Token_Color (struct (field $f0 (mut anyref))))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $red500 (result anyref)
    (local $__mem0 i32)
    (local $__mem1 i32)
    i32.const 1 ;; Bp__Token__Color__Red.__500
    struct.new $var_Bp__Token__Color_Red
    struct.new $var_Token_Color
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
