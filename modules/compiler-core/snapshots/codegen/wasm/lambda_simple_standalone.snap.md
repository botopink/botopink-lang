----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func = {s ->
        return s;
    };
    return func("hello");
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
    (type $env0 (sub final $closure (struct (field $idx i32) (field $mark i32))))
  )
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0))
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $main (result (ref null $str))
    (local $func (ref null $closure))
    (local $__fnv0 (ref null $closure))
    i32.const 0
    i32.const 0
    struct.new $env0
    local.set $func
    local.get $func
    local.set $__fnv0
    local.get $__fnv0
    global.get $__s0
    local.get $__fnv0
    struct.get $closure $idx ;; table index
    call_indirect (param (ref null $closure) anyref) (result anyref)
    ref.cast (ref null $str)
    return
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (param $s (ref null $str)) (result (ref null $str))
    local.get $s
    return
  )
  (func $__lambda0 (param $__env (ref null $closure)) (param $__a0 anyref) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    local.get $__a0
    ref.cast (ref null $str)
    call $__lambda0__b
  )
  (func $_botopink_main (export "_botopink_main") (export "_start")
    (call $main)
    drop
  )
  (data $__d0 "hello")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 5
    array.new_data $str $__d0
    global.set $__s0
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
