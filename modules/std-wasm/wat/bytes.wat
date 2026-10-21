;; std-wasm's `Bytes` leaves (front 164 s3 P2-d, decision 585 (k)): the three
;; atoms `encoding`'s byte codecs are written over in botopink. Each function
;; is a `std:` cell's (`#[@External.Wasm(std: "bytes.<function>")]`) and the
;; program calls it as `$__std_bytes_<function>`. A `Bytes` value is the
;; codegen's `$str`, `(array (mut i8))` — a string's layout (decision 549:
;; named, never declared); an array of words is its `$arr_i32`.

;; `bytes.length` — the number of bytes.
(func $bytes.length (param $b (ref null $str)) (result i32)
  local.get $b
  array.len)

;; `bytes.at` — the byte at index `i` as a word `0..255`. Nothing outside
;; `0..length-1` is answered (decision 880): the bare `array.get_u` traps there,
;; a negative `i` read unsigned included. A codec bounds its own reads.
(func $bytes.at (param $b (ref null $str)) (param $i i32) (result i32)
  local.get $b
  local.get $i
  array.get_u $str)

;; `bytes.ofWords` — a new `Bytes` of as many bytes as `words` holds, each its
;; word. A word outside `0..255` is `unreachable` at the first one met (decision
;; 880): the leaf keeps no low eight bits.
(func $bytes.ofWords (param $words (ref null $arr_i32)) (result (ref null $str))
  (local $n i32)
  (local $i i32)
  (local $w i32)
  (local $out (ref null $str))
  local.get $words
  array.len
  local.tee $n
  array.new_default $str
  local.set $out
  (block $done
    (loop $next
      local.get $i
      local.get $n
      i32.ge_u
      br_if $done
      local.get $words
      local.get $i
      array.get $arr_i32
      local.tee $w
      i32.const 255
      i32.gt_u
      (if
        (then
          unreachable
        )
      )
      local.get $out
      local.get $i
      local.get $w
      array.set $str
      local.get $i
      i32.const 1
      i32.add
      local.set $i
      br $next
    )
  )
  local.get $out)
