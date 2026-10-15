----- SOURCE CODE -- main.bp
```botopink
val Color = type {
    Red,
    Green,
    Blue,
    fn name(self: Self) -> string {
        case (self) {
            Red -> "red";
            Green -> "green";
            Blue -> "blue";
        };
    }
};
```

----- WASM TEXT -- main.wat
```wasm
(module
  (rec
    (type $str (array (mut i8)))
  )
  (memory (export "memory") 1)
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $Color_name (param $self i32) (result (ref null $str))
    (local $__case_0 i32)
    local.get $self
    local.set $__case_0
    local.get $__case_0
    i32.const 0 ;; Red
    i32.eq
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__case_0
    i32.const 1 ;; Green
    i32.eq
    (if (result (ref null $str))
      (then
    global.get $__s1
      )
      (else
    local.get $__case_0
    i32.const 2 ;; Blue
    i32.eq
    (if (result (ref null $str))
      (then
    global.get $__s2
      )
      (else
    ref.null $str
      )
    )
      )
    )
      )
    )
  )
  (data $__d0 "red")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "green")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "blue")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 3
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 5
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 4
    array.new_data $str $__d2
    global.set $__s2
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
