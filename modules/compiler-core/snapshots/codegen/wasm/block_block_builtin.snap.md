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

----- WASM TEXT -- main.wat
```wasm
(module
  (memory (export "memory") 1)
  (data (i32.const 256) "\04\00\00\00Alto")
  (data (i32.const 264) "\05\00\00\00Baixo")
  (global $__heap_ptr (mut i32) (i32.const 276))
  (func $main (result i32)
    (local $input i32)
    (local $status i32)
    i32.const 42
    local.set $input
    local.get $input
    i32.const 2
    i32.mul
    local.set $calculo
    global.get $calculo
    i32.const 100
    i32.gt_s
    (if (result i32)
      (then
    i32.const 256
    return
      )
      (else
        i32.const 0
      )
    )
    drop
    i32.const 264
    return
    local.set $status
    local.get $status
    return
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
    drop
  )
)
```

----- RUN LOG -----
```logs
```
