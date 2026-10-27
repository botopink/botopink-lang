----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() -> Result<void, string> {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch throw "is not person";
    return;
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
    (type $box_big (struct (field $v (ref null $str))))
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
    (type $rec_Person (struct (field $f0 (mut (ref null $str))) (field $f1 (mut i32))))
    (type $brand_rec_Person (struct (field f64) (field i64) (field f64) (field f64) (field i64) (field i32) (field f32) (field f32) (field i64) (field f32) (field f32) (field f32) (field i64) (field i64) (field i32) (field i32) (field f64) (field i32) (field f32) (field f64) (field i64) (field f64) (field i32) (field i32) (field f32) (field f32) (field i64) (field i32) (field i64) (field i64) (field f32) (field i64)))
  )
  (memory (export "memory") (import "std@__rt" "memory") 1)
  (global $__heap_ptr (import "std@__rt" "__heap_ptr") (mut i32))
  (func $f (result (ref null $result))
    (local $__mem0 i32)
    (local $r (ref null $rec_Person))
    (local $__assert_0 (ref null $rec_Person))
    (local $name (ref null $str))
    (local $age i32)
    global.get $__s0
    i32.const 30
    struct.new $rec_Person
    local.set $r
    local.get $r
    local.set $__assert_0
    local.get $__assert_0
    ref.test (ref null $rec_Person)
    local.get $__assert_0
    ref.is_null
    i32.eqz
    i32.and
    i32.eqz
    (if
      (then
    i32.const 1
    global.get $__s1
    struct.new $result
    return
      )
    )
    local.get $__assert_0
    struct.get $rec_Person $f0
    local.set $name
    local.get $__assert_0
    struct.get $rec_Person $f1
    local.set $age
    i32.const 0
    i32.const 0
    struct.new $box_i32
    struct.new $result
    return
  )
  (data $__d0 "ann")
  (global $__s0 (mut (ref null $str)) (ref.null $str))
  (data $__d1 "is not person")
  (global $__s1 (mut (ref null $str)) (ref.null $str))
  (start $__init_strs)
  (func $__init_strs
    i32.const 0
    i32.const 3
    array.new_data $str $__d0
    global.set $__s0
    i32.const 0
    i32.const 13
    array.new_data $str $__d1
    global.set $__s1
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
