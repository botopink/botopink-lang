----- SOURCE CODE -- main.bp
```botopink
fn main() -> string {
    val func: fn(string)-> string = {s ->
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
  (rec
    (type $env0 (sub final $closure (struct (field $idx i32) (field $mark i32))))
  )
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (table funcref (elem $__lambda0))
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
