----- SOURCE CODE -- main.bp
```botopink
val HttpMethod = type {
    Get,
    Post,
    Put,
    Delete,
    fn name(m: Self) -> string {
        val label = case m {
            Get -> "GET";
            Post -> "POST";
            Put -> "PUT";
            _ -> "DELETE";
        };
        return label;
    }
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
  (func $HttpMethod_name (param $m i32) (result (ref null $str))
    (local $label (ref null $str))
    (local $__case_0 i32)
    local.get $m
    local.set $__case_0
    local.get $__case_0
    i32.const 0 ;; Get
    i32.eq
    (if (result (ref null $str))
      (then
    global.get $__s0
      )
      (else
    local.get $__case_0
    i32.const 1 ;; Post
    i32.eq
    (if (result (ref null $str))
      (then
    global.get $__s1
      )
      (else
    local.get $__case_0
    i32.const 2 ;; Put
    i32.eq
    (if (result (ref null $str))
      (then
    global.get $__s2
      )
      (else
    global.get $__s3
      )
    )
      )
    )
      )
    )
    local.set $label
    local.get $label
    return
  )
  (data $__d0 "GET")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "POST")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (data $__d2 "PUT")
  (global $__s2 (mut (ref null $str)) (ref.null $str))
  (data $__d3 "DELETE")
  (global $__s3 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 3
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 4
    array.new_data $str $__d1
    global.set $__s1
    i32.const 0
    i32.const 3
    array.new_data $str $__d2
    global.set $__s2
    i32.const 0
    i32.const 6
    array.new_data $str $__d3
    global.set $__s3
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
