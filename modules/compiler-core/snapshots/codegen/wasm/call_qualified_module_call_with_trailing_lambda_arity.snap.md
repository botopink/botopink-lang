----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn each(items: i32[], f: fn() -> i32) -> i32[] {
        return items;
    }
}
type Pipeline(
    items: i32[]) {
    fn doubled(self: Self) -> i32[] {
        return List.each(self.items) { ->
            return 2;
        };
    }
}
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
    (type $arr_i32 (array (mut i32)))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
    (type $rec_Pipeline (struct (field $f0 (mut (ref null $arr_i32)))))
    (type $env0 (sub final $closure (struct (field $idx i32) (field $mark i32))))
    (type $box_i32 (struct (field $v i32)))
  )
  (memory (export "memory") 1)
  (table funcref (elem $__lambda0))
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $List_each (param $items (ref null $arr_i32)) (param $f (ref null $closure)) (result (ref null $arr_i32))
    local.get $items
    return
  )
  (func $Pipeline_doubled (param $self (ref null $rec_Pipeline)) (result (ref null $arr_i32))
    local.get $self
    struct.get $rec_Pipeline $f0
    i32.const 0
    i32.const 0
    struct.new $env0
    call $List_each
    return
  )
  (func $__lambda0__b (param $__env (ref null $env0)) (result i32)
    i32.const 2
    return
  )
  (func $__lambda0 (param $__env (ref null $closure)) (result anyref)
    local.get $__env
    ref.cast (ref null $env0)
    call $__lambda0__b
    struct.new $box_i32
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
