----- SOURCE CODE -- main.bp
```botopink
fn getName(name: ?string) -> string {
    if (name) { n ->
        return n;
    };
    return "unknown";
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $getName (param $name (ref null $str)) (result (ref null $str))
    (local $n i32)
    (local $__opt0 (ref null $str))
    (local $n__0 (ref null $str))
    local.get $name
    local.tee $__opt0
    ref.is_null
    i32.eqz
    (if (result (ref null $str))
      (then
    local.get $__opt0
    local.set $n__0
    local.get $n__0
    return
      )
      (else
        ref.null $str
      )
    )
    drop
    global.get $__s0
    return
  )
  (data $__d0 "unknown")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 7
    array.new_data $str $__d0
    global.set $__s0
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
