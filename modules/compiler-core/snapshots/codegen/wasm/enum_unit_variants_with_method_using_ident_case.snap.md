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
    (type $arr_i32 (array (mut i32)))
    (type $arr_f64 (array (mut f64)))
    (type $arr_any (sub (array (mut anyref))))
    (type $tuple (sub final $arr_any (array (mut anyref))))
    (type $box_i32 (sub (struct (field $v i32))))
    (type $box_i64 (struct (field $v i64)))
    (type $box_f64 (struct (field $v f64)))
    (type $box_bool (sub final $box_i32 (struct (field $v i32))))
    (type $closure (sub (struct (field $idx i32) (field $mark i32))))
    (type $result (struct (field $tag (mut i32)) (field $payload (mut anyref))))
    (type $exn (struct (field $msg (ref null $str)) (field $print i32)))
    (type $task (struct (field $state (mut i32)) (field $waiters (mut (ref null $waiter))) (field $value (mut anyref)) (field $frame (mut structref)) (field $kind i32) (field $next (mut (ref null $task))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $waiter (struct (field $next (mut (ref null $waiter))) (field $kind i32) (field $target (ref null $task)) (field $slot i32)))
    (type $hostn (struct (field $next (mut (ref null $hostn))) (field $h i32) (field $t (ref null $task))))
    (type $gen (struct (field $state (mut i32)) (field $kind i32) (field $frame (mut structref)) (field $value (mut anyref)) (field $src (mut (ref null $gen))) (field $aux (mut anyref)) (field $left (mut i32))))
    (type $cell (struct (field $filled (mut i32)) (field $value (mut anyref))))
  )
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
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
