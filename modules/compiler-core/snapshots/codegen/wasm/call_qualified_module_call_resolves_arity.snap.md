----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn map(items: i32[], f: fn(item: i32) -> i32) -> i32[] {
        return items.map(f);
    }
}
type Pipeline(
    items: i32[]) {
    fn run(self: Self, f: fn(item: i32) -> i32) -> i32[] {
        return List.map(self.items, f);
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
  (rec
    (type $rec_Pipeline (struct (field $f0 (mut (ref null $arr_i32)))))
    (type $brand_rec_Pipeline (struct (field f32) (field i32) (field i64) (field f64) (field f64) (field i32) (field f64) (field i64) (field i64) (field f64) (field f32) (field f64) (field i32) (field f32) (field i64) (field f64) (field i64) (field f64) (field f32) (field f32) (field i64) (field i64) (field i32) (field f32) (field f64) (field i64) (field f64) (field i64) (field f64) (field i64) (field i64) (field f32)))
  )
  (memory (export "memory") 1)
  (table funcref (elem))
  (global $__heap_ptr (mut i32) (i32.const 256))
  (func $List_map (param $items (ref null $arr_i32)) (param $f (ref null $closure)) (result (ref null $arr_i32))
    (local $__iter1 (ref null $arr_i32))
    (local $__idx1 i32)
    (local $__len1 i32)
    (local $__acc1 i32)
    (local $__hof0_0 i32)
    (local $__out1 (ref null $arr_i32))
    (local $__fnv2 (ref null $closure))
    local.get $items
    local.set $__iter1
    local.get $__iter1
    array.len
    local.set $__len1
    i32.const 0
    local.set $__idx1
    local.get $__len1
    array.new_default $arr_i32
    local.set $__out1
    i32.const 0
    local.set $__acc1
    (block $__break
      (loop $__continue
        local.get $__idx1
        local.get $__len1
        i32.ge_s
        br_if $__break
        local.get $__iter1
        local.get $__idx1
        array.get $arr_i32
        local.set $__hof0_0
    local.get $__out1
    local.get $__idx1
    local.get $f
    local.set $__fnv2
    local.get $__fnv2
    local.get $__hof0_0
    struct.new $box_i32
    local.get $__fnv2
    struct.get $closure $idx ;; table index
    call_indirect (param (ref null $closure) anyref) (result anyref)
    ref.cast (ref null $box_i32)
    struct.get $box_i32 $v
    array.set $arr_i32
        local.get $__idx1
        i32.const 1
        i32.add
        local.set $__idx1
        br $__continue
      )
    )
    local.get $__out1
    return
  )
  (func $Pipeline_run (param $self (ref null $rec_Pipeline)) (param $f (ref null $closure)) (result (ref null $arr_i32))
    local.get $self
    struct.get $rec_Pipeline $f0
    local.get $f
    call $List_map
    return
  )
  (@custom "botopink.needs" "gc\0a")
)
```

----- RUN LOG -----
```logs
```
