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

;; `bytes.at` — the byte at index `i` as a word `0..255`, `-1` for a negative
;; `i` or one past the end (the unsigned comparison covers both).
(func $bytes.at (param $b (ref null $str)) (param $i i32) (result i32)
  local.get $i
  local.get $b
  array.len
  i32.ge_u
  (if
    (then
      i32.const -1
      return
    )
  )
  local.get $b
  local.get $i
  array.get_u $str)

;; `bytes.ofWords` — a new `Bytes` of as many bytes as `words` holds, each the
;; low eight bits of its word (an `i8` slot keeps no more).
(func $bytes.ofWords (param $words (ref null $arr_i32)) (result (ref null $str))
  (local $n i32)
  (local $i i32)
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
      local.get $out
      local.get $i
      local.get $words
      local.get $i
      array.get $arr_i32
      array.set $str
      local.get $i
      i32.const 1
      i32.add
      local.set $i
      br $next
    )
  )
  local.get $out)
