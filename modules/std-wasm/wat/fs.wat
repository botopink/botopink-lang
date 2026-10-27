;; std-wasm's `io/fs` leaves (decision 992): the file system of the process, over the
;; `bp_fs` host functions (`wat_prelude.fs_imports`, which the `wasi` component answers
;; through `wasi:filesystem`, `wat_emitter.zig`). Each function is a `std:` cell's
;; (`#[@External.Wasm(std: "fs.<function>", needs: [.Filesystem])]` in
;; `libs/std/src/io/fs.bp`) and the program calls it as `$__std_fs_<function>`.
;;
;; Paths arrive resolved: relative to the root the host preopens, no leading `/`
;; (`fs.bp` joins a relative path to the working directory, `fs.cwd`). A host
;; failure is `-(1 + code)`, `code` the ordinal of `wasi:filesystem`'s `error-code`
;; (0 `access` … 36 `cross-device`): a leaf answering a count, a handle or a size
;; answers it as a negative number, one answering a value as a `Result<_, i32>`
;; whose `Error` is the code itself.
;;
;; An open file is a handle block in linear memory, which `fs.open` allocates and
;; keeps (it is never freed: the allocator is a bump):
;;   +0  kind    0 a file of the host, 1 bytes held in memory (an `Asset`'s), 2 closed
;;   +4  fd      the host's descriptor; for kind 1 the address of the bytes
;;   +8  pos     the file's position (i64): a read or a write begins there and moves it
;;   +16 length  kind 1: the number of bytes held
;; Everything a leaf allocates besides the block (a path copied in, a buffer read
;; into) is put back when it returns: the heap pointer is saved first.

;; ── helpers ──────────────────────────────────────────────────────────────────

;; `Ok(v)` of an `i32`.
(func $fs.okI32 (param $v i32) (result (ref null $result))
  i32.const 0
  local.get $v
  struct.new $box_i32
  struct.new $result)

;; `Ok(v)` of an `i64`.
(func $fs.okI64 (param $v i64) (result (ref null $result))
  i32.const 0
  local.get $v
  struct.new $box_i64
  struct.new $result)

;; `Error(code)`.
(func $fs.errCode (param $code i32) (result (ref null $result))
  i32.const 1
  local.get $code
  struct.new $box_i32
  struct.new $result)

;; `Ok(s)` of a string or bytes.
(func $fs.okStr (param $s (ref null $str)) (result (ref null $result))
  i32.const 0
  local.get $s
  struct.new $result)

;; `Ok(a)` of an array of strings.
(func $fs.okArr (param $a (ref null $arr_any)) (result (ref null $result))
  i32.const 0
  local.get $a
  struct.new $result)

;; The `n` bytes at `p` of linear memory as a new string.
(func $fs.toStr (param $p i32) (param $n i32) (result (ref null $str))
  (local $r (ref null $str))
  (local $i i32)
  local.get $n
  array.new_default $str
  local.set $r
  (block $done
    (loop $each
      local.get $i
      local.get $n
      i32.ge_u
      br_if $done
      local.get $r
      local.get $i
      local.get $p
      local.get $i
      i32.add
      i32.load8_u
      array.set $str
      local.get $i
      i32.const 1
      i32.add
      local.set $i
      br $each))
  local.get $r)

;; The handle block of a file (`kind`, `a`, `length`), position 0.
(func $fs.block (param $kind i32) (param $a i32) (param $len i32) (result i32)
  (local $p i32)
  i32.const 24
  call $__alloc
  local.set $p
  local.get $p
  local.get $kind
  i32.store
  local.get $p
  local.get $a
  i32.store offset=4
  local.get $p
  i64.const 0
  i64.store offset=8
  local.get $p
  local.get $len
  i32.store offset=16
  local.get $p)

;; A path or text copied into linear memory as `[length][bytes]`; the bytes are at +4.
(func $fs.stage (param $s (ref null $str)) (result i32)
  local.get $s
  call $__gc_to_lin_str)

;; ── the process ──────────────────────────────────────────────────────────────

;; `fs.getenv` — the value of the environment variable `name`, `""` when it is not set.
(func $fs.getenv (param $name (ref null $str)) (result (ref null $str))
  (local $mark i32)
  (local $lin i32)
  (local $cap i32)
  (local $buf i32)
  (local $n i32)
  (local $out (ref null $str))
  global.get $__heap_ptr
  local.set $mark
  local.get $name
  call $fs.stage
  local.set $lin
  i32.const 512
  local.set $cap
  local.get $cap
  call $__alloc
  local.set $buf
  local.get $lin
  i32.const 4
  i32.add
  local.get $lin
  i32.load
  local.get $buf
  local.get $cap
  call $__fs_getenv
  local.set $n
  ;; not set
  local.get $n
  i32.const 0
  i32.lt_s
  (if
    (then
      local.get $mark
      global.set $__heap_ptr
      i32.const 0
      array.new_default $str
      return))
  ;; longer than the buffer: asked again with room for all of it
  local.get $n
  local.get $cap
  i32.gt_u
  (if
    (then
      local.get $n
      local.set $cap
      local.get $cap
      call $__alloc
      local.set $buf
      local.get $lin
      i32.const 4
      i32.add
      local.get $lin
      i32.load
      local.get $buf
      local.get $cap
      call $__fs_getenv
      drop))
  local.get $buf
  local.get $n
  call $fs.toStr
  local.set $out
  local.get $mark
  global.set $__heap_ptr
  local.get $out)

;; `fs.cwd` — the working directory's absolute path, `""` when the host names none.
(func $fs.cwd (result (ref null $str))
  (local $mark i32)
  (local $cap i32)
  (local $buf i32)
  (local $n i32)
  (local $out (ref null $str))
  global.get $__heap_ptr
  local.set $mark
  i32.const 512
  local.set $cap
  local.get $cap
  call $__alloc
  local.set $buf
  local.get $buf
  local.get $cap
  call $__fs_cwd
  local.set $n
  local.get $n
  i32.const 0
  i32.lt_s
  (if
    (then
      local.get $mark
      global.set $__heap_ptr
      i32.const 0
      array.new_default $str
      return))
  local.get $n
  local.get $cap
  i32.gt_u
  (if
    (then
      local.get $n
      local.set $cap
      local.get $cap
      call $__alloc
      local.set $buf
      local.get $buf
      local.get $cap
      call $__fs_cwd
      drop))
  local.get $buf
  local.get $n
  call $fs.toStr
  local.set $out
  local.get $mark
  global.set $__heap_ptr
  local.get $out)

;; ── opening and closing ─────────────────────────────────────────────────────

;; `fs.open` — the handle of the file at `path`: mode 0 to read, 1 to write (created
;; or truncated), 2 to write (created, not truncated), 3 a directory. A directory
;; opened to read is `is-directory`. A handle block (positive), or `-(1 + code)`.
(func $fs.open (param $path (ref null $str)) (param $mode i32) (result i32)
  (local $mark i32)
  (local $lin i32)
  (local $h i32)
  (local $out i32)
  (local $r i32)
  global.get $__heap_ptr
  local.set $mark
  local.get $path
  call $fs.stage
  local.set $lin
  local.get $lin
  i32.const 4
  i32.add
  local.get $lin
  i32.load
  local.get $mode
  call $__fs_open
  local.set $h
  local.get $h
  i32.const 0
  i32.lt_s
  (if
    (then
      local.get $mark
      global.set $__heap_ptr
      local.get $h
      return))
  local.get $mode
  i32.eqz
  (if
    (then
      i32.const 24
      call $__alloc
      local.set $out
      local.get $h
      local.get $out
      call $__fs_stat
      local.set $r
      local.get $r
      i32.const 0
      i32.lt_s
      (if
        (then
          local.get $h
          call $__fs_close
          local.get $mark
          global.set $__heap_ptr
          local.get $r
          return))
      ;; a directory (`descriptor-type` 3) is no file to read
      local.get $out
      i32.load
      i32.const 3
      i32.eq
      (if
        (then
          local.get $h
          call $__fs_close
          local.get $mark
          global.set $__heap_ptr
          i32.const -15
          return))))
  local.get $mark
  global.set $__heap_ptr
  i32.const 0
  local.get $h
  i32.const 0
  call $fs.block)

;; `fs.openMem` — a handle over `data`, held in memory: read like a file, never closed on a disk.
(func $fs.openMem (param $data (ref null $str)) (result i32)
  (local $n i32)
  (local $p i32)
  (local $i i32)
  local.get $data
  array.len
  local.set $n
  local.get $n
  call $__alloc
  local.set $p
  (block $done
    (loop $each
      local.get $i
      local.get $n
      i32.ge_u
      br_if $done
      local.get $p
      local.get $i
      i32.add
      local.get $data
      local.get $i
      array.get_u $str
      i32.store8
      local.get $i
      i32.const 1
      i32.add
      local.set $i
      br $each))
  i32.const 1
  local.get $p
  local.get $n
  call $fs.block)

;; `fs.close` — a file of the host is closed once; closing it again, or bytes held in memory, does nothing.
(func $fs.close (param $h i32)
  local.get $h
  i32.load
  i32.eqz
  (if
    (then
      local.get $h
      i32.load offset=4
      call $__fs_close
      local.get $h
      i32.const 2
      i32.store)))

;; `fs.isMem` — whether the handle holds bytes in memory (an `Asset`'s): they cannot be written.
(func $fs.isMem (param $h i32) (result i32)
  local.get $h
  i32.load
  i32.const 1
  i32.eq)

;; `fs.tell` / `fs.seek` — the position, and the position set.
(func $fs.tell (param $h i32) (result i64)
  local.get $h
  i64.load offset=8)

(func $fs.seek (param $h i32) (param $pos i64)
  local.get $h
  local.get $pos
  i64.store offset=8)

;; ── size, reading, writing ──────────────────────────────────────────────────

;; The file's size in bytes, or `-(1 + code)`.
(func $fs.sizeRaw (param $h i32) (result i64)
  (local $mark i32)
  (local $out i32)
  (local $r i32)
  (local $size i64)
  local.get $h
  i32.load
  i32.const 1
  i32.eq
  (if
    (then
      local.get $h
      i32.load offset=16
      i64.extend_i32_u
      return))
  local.get $h
  i32.load
  i32.const 2
  i32.eq
  (if
    (then
      i64.const -4
      return))
  global.get $__heap_ptr
  local.set $mark
  i32.const 24
  call $__alloc
  local.set $out
  local.get $h
  i32.load offset=4
  local.get $out
  call $__fs_stat
  local.set $r
  local.get $r
  i32.const 0
  i32.lt_s
  (if
    (then
      local.get $mark
      global.set $__heap_ptr
      local.get $r
      i64.extend_i32_s
      return))
  local.get $out
  i64.load offset=8
  local.set $size
  local.get $mark
  global.set $__heap_ptr
  local.get $size)

;; `fs.size` — the file's size in bytes.
(func $fs.size (param $h i32) (result (ref null $result))
  (local $n i64)
  local.get $h
  call $fs.sizeRaw
  local.set $n
  local.get $n
  i64.const 0
  i64.lt_s
  (if
    (then
      i32.const -1
      local.get $n
      i32.wrap_i64
      i32.sub
      call $fs.errCode
      return))
  local.get $n
  call $fs.okI64)

;; Up to `n` bytes from the position into linear memory at `buf`; the count, `-(1 + code)` when the host failed. The position moves.
;; A file of the host answers short only at its end.
(func $fs.pull (param $h i32) (param $buf i32) (param $n i32) (result i32)
  (local $total i32)
  (local $got i32)
  (local $pos i64)
  (local $avail i32)
  local.get $h
  i32.load
  i32.const 2
  i32.eq
  (if
    (then
      i32.const -4
      return))
  local.get $h
  i32.load
  i32.const 1
  i32.eq
  (if
    (then
      ;; bytes held in memory: what is left of them
      local.get $h
      i32.load offset=16
      local.get $h
      i64.load offset=8
      i32.wrap_i64
      i32.sub
      local.set $avail
      local.get $avail
      i32.const 0
      i32.lt_s
      (if
        (then
          i32.const 0
          local.set $avail))
      local.get $n
      local.get $avail
      local.get $n
      local.get $avail
      i32.lt_u
      select
      local.set $got
      local.get $buf
      local.get $h
      i32.load offset=4
      local.get $h
      i64.load offset=8
      i32.wrap_i64
      i32.add
      local.get $got
      memory.copy
      local.get $h
      local.get $h
      i64.load offset=8
      local.get $got
      i64.extend_i32_u
      i64.add
      i64.store offset=8
      local.get $got
      return))
  local.get $h
  i64.load offset=8
  local.set $pos
  (block $done
    (loop $each
      local.get $total
      local.get $n
      i32.ge_u
      br_if $done
      local.get $h
      i32.load offset=4
      local.get $pos
      local.get $buf
      local.get $total
      i32.add
      local.get $n
      local.get $total
      i32.sub
      call $__fs_read
      local.set $got
      local.get $got
      i32.const 0
      i32.lt_s
      (if
        (then
          local.get $got
          return))
      local.get $got
      i32.eqz
      br_if $done
      local.get $pos
      local.get $got
      i64.extend_i32_u
      i64.add
      local.set $pos
      local.get $total
      local.get $got
      i32.add
      local.set $total
      br $each))
  local.get $h
  local.get $pos
  i64.store offset=8
  local.get $total)

;; `fs.read` — up to `n` bytes from the position, empty at the end.
(func $fs.read (param $h i32) (param $n i32) (result (ref null $result))
  (local $mark i32)
  (local $buf i32)
  (local $got i32)
  (local $out (ref null $str))
  global.get $__heap_ptr
  local.set $mark
  local.get $n
  call $__alloc
  local.set $buf
  local.get $h
  local.get $buf
  local.get $n
  call $fs.pull
  local.set $got
  local.get $got
  i32.const 0
  i32.lt_s
  (if
    (then
      local.get $mark
      global.set $__heap_ptr
      i32.const -1
      local.get $got
      i32.sub
      call $fs.errCode
      return))
  local.get $buf
  local.get $got
  call $fs.toStr
  local.set $out
  local.get $mark
  global.set $__heap_ptr
  local.get $out
  call $fs.okStr)

;; `fs.readAll` — every byte from the position to the end.
(func $fs.readAll (param $h i32) (result (ref null $result))
  (local $left i64)
  (local $mark i32)
  (local $cap i32)
  (local $buf i32)
  (local $bigger i32)
  (local $total i32)
  (local $got i32)
  (local $out (ref null $str))
  global.get $__heap_ptr
  local.set $mark
  ;; room for what the size says is left, and one byte more for the look past the end; a block at least
  i32.const 4096
  local.set $cap
  local.get $h
  call $fs.sizeRaw
  local.get $h
  call $fs.tell
  i64.sub
  local.set $left
  local.get $left
  i64.const 4096
  i64.gt_s
  local.get $left
  i64.const 1073741824
  i64.lt_s
  i32.and
  (if
    (then
      local.get $left
      i32.wrap_i64
      i32.const 1
      i32.add
      local.set $cap))
  local.get $cap
  call $__alloc
  local.set $buf
  (block $done
    (loop $each
      ;; full: twice the room, the bytes carried over
      local.get $total
      local.get $cap
      i32.eq
      (if
        (then
          local.get $cap
          i32.const 2
          i32.mul
          call $__alloc
          local.set $bigger
          local.get $bigger
          local.get $buf
          local.get $total
          memory.copy
          local.get $bigger
          local.set $buf
          local.get $cap
          i32.const 2
          i32.mul
          local.set $cap))
      local.get $h
      local.get $buf
      local.get $total
      i32.add
      local.get $cap
      local.get $total
      i32.sub
      call $fs.pull
      local.set $got
      local.get $got
      i32.const 0
      i32.lt_s
      (if
        (then
          local.get $mark
          global.set $__heap_ptr
          i32.const -1
          local.get $got
          i32.sub
          call $fs.errCode
          return))
      local.get $got
      i32.eqz
      br_if $done
      local.get $total
      local.get $got
      i32.add
      local.set $total
      br $each))
  local.get $buf
  local.get $total
  call $fs.toStr
  local.set $out
  local.get $mark
  global.set $__heap_ptr
  local.get $out
  call $fs.okStr)

;; `fs.readLine` — the bytes from the position up to and with the next `\n`, or to the end; empty at the end.
(func $fs.readLine (param $h i32) (result (ref null $result))
  (local $mark i32)
  (local $cap i32)
  (local $buf i32)
  (local $bigger i32)
  (local $total i32)
  (local $got i32)
  (local $i i32)
  (local $line64 i64)
  (local $out (ref null $str))
  global.get $__heap_ptr
  local.set $mark
  i32.const 256
  local.set $cap
  local.get $cap
  call $__alloc
  local.set $buf
  (block $done
    (loop $each
      local.get $total
      local.get $cap
      i32.eq
      (if
        (then
          local.get $cap
          i32.const 2
          i32.mul
          call $__alloc
          local.set $bigger
          local.get $bigger
          local.get $buf
          local.get $total
          memory.copy
          local.get $bigger
          local.set $buf
          local.get $cap
          i32.const 2
          i32.mul
          local.set $cap))
      ;; the position is put back after each look: the line alone is consumed
      local.get $h
      call $fs.tell
      local.set $line64
      local.get $h
      local.get $buf
      local.get $total
      i32.add
      local.get $cap
      local.get $total
      i32.sub
      call $fs.pull
      local.set $got
      local.get $got
      i32.const 0
      i32.lt_s
      (if
        (then
          local.get $mark
          global.set $__heap_ptr
          i32.const -1
          local.get $got
          i32.sub
          call $fs.errCode
          return))
      ;; the first `\n` among the bytes just read
      local.get $total
      local.set $i
      (block $scanned
        (loop $scan
          local.get $i
          local.get $total
          local.get $got
          i32.add
          i32.ge_u
          br_if $scanned
          local.get $buf
          local.get $i
          i32.add
          i32.load8_u
          i32.const 10
          i32.eq
          (if
            (then
              ;; the line ends at `i`: the position is left just past it
              local.get $h
              local.get $line64
              local.get $total
              i64.extend_i32_u
              i64.sub
              local.get $i
              i32.const 1
              i32.add
              i64.extend_i32_u
              i64.add
              i64.store offset=8
              local.get $i
              i32.const 1
              i32.add
              local.set $total
              br $done))
          local.get $i
          i32.const 1
          i32.add
          local.set $i
          br $scan))
      local.get $got
      i32.eqz
      br_if $done
      local.get $total
      local.get $got
      i32.add
      local.set $total
      br $each))
  local.get $buf
  local.get $total
  call $fs.toStr
  local.set $out
  local.get $mark
  global.set $__heap_ptr
  local.get $out
  call $fs.okStr)

;; `fs.write` — `data` at the position, which moves past it; the number of bytes written, or `-(1 + code)`.
(func $fs.write (param $h i32) (param $data (ref null $str)) (result i32)
  (local $mark i32)
  (local $lin i32)
  (local $wrote i32)
  local.get $h
  i32.load
  i32.eqz
  i32.eqz
  (if
    (then
      ;; closed (bad-descriptor), or bytes held in memory (read-only)
      local.get $h
      i32.load
      i32.const 2
      i32.eq
      (if
        (then
          i32.const -4
          return))
      i32.const -34
      return))
  global.get $__heap_ptr
  local.set $mark
  local.get $data
  call $fs.stage
  local.set $lin
  local.get $h
  i32.load offset=4
  local.get $h
  i64.load offset=8
  local.get $lin
  i32.const 4
  i32.add
  local.get $lin
  i32.load
  call $__fs_write
  local.set $wrote
  local.get $mark
  global.set $__heap_ptr
  local.get $wrote
  i32.const 0
  i32.lt_s
  (if
    (then
      local.get $wrote
      return))
  local.get $h
  local.get $h
  i64.load offset=8
  local.get $wrote
  i64.extend_i32_u
  i64.add
  i64.store offset=8
  local.get $wrote)

;; ── what a path is ──────────────────────────────────────────────────────────

;; `fs.statKind` — `descriptor-type` of the entry at `path` (3 directory, 5 link, 6 file …), a link followed when `follow` is 1;
;; `-(1 + code)` when the host failed.
(func $fs.statKind (param $path (ref null $str)) (param $follow i32) (result i32)
  (local $mark i32)
  (local $lin i32)
  (local $out i32)
  (local $r i32)
  global.get $__heap_ptr
  local.set $mark
  local.get $path
  call $fs.stage
  local.set $lin
  i32.const 24
  call $__alloc
  local.set $out
  local.get $lin
  i32.const 4
  i32.add
  local.get $lin
  i32.load
  local.get $follow
  local.get $out
  call $__fs_stat_at
  local.set $r
  local.get $r
  i32.const 0
  i32.lt_s
  (if
    (then
      local.get $mark
      global.set $__heap_ptr
      local.get $r
      return))
  local.get $out
  i32.load
  local.set $r
  local.get $mark
  global.set $__heap_ptr
  local.get $r)

;; `fs.statSize` — the size in bytes of the entry at `path` (a link followed).
(func $fs.statSize (param $path (ref null $str)) (result (ref null $result))
  (local $mark i32)
  (local $lin i32)
  (local $out i32)
  (local $r i32)
  (local $size i64)
  global.get $__heap_ptr
  local.set $mark
  local.get $path
  call $fs.stage
  local.set $lin
  i32.const 24
  call $__alloc
  local.set $out
  local.get $lin
  i32.const 4
  i32.add
  local.get $lin
  i32.load
  i32.const 1
  local.get $out
  call $__fs_stat_at
  local.set $r
  local.get $r
  i32.const 0
  i32.lt_s
  (if
    (then
      local.get $mark
      global.set $__heap_ptr
      i32.const -1
      local.get $r
      i32.sub
      call $fs.errCode
      return))
  local.get $out
  i64.load offset=8
  local.set $size
  local.get $mark
  global.set $__heap_ptr
  local.get $size
  call $fs.okI64)

;; `fs.statMtime` — the modification time of the entry at `path` (a link followed) in whole seconds since the epoch.
(func $fs.statMtime (param $path (ref null $str)) (result (ref null $result))
  (local $mark i32)
  (local $lin i32)
  (local $out i32)
  (local $r i32)
  (local $mtime i64)
  global.get $__heap_ptr
  local.set $mark
  local.get $path
  call $fs.stage
  local.set $lin
  i32.const 24
  call $__alloc
  local.set $out
  local.get $lin
  i32.const 4
  i32.add
  local.get $lin
  i32.load
  i32.const 1
  local.get $out
  call $__fs_stat_at
  local.set $r
  local.get $r
  i32.const 0
  i32.lt_s
  (if
    (then
      local.get $mark
      global.set $__heap_ptr
      i32.const -1
      local.get $r
      i32.sub
      call $fs.errCode
      return))
  local.get $out
  i64.load offset=16
  local.set $mtime
  local.get $mark
  global.set $__heap_ptr
  local.get $mtime
  call $fs.okI64)

;; `fs.list` — the names in the directory at `path`, in the host's order.
(func $fs.list (param $path (ref null $str)) (result (ref null $result))
  (local $mark i32)
  (local $lin i32)
  (local $s i32)
  (local $tmp i32)
  (local $first i32)
  (local $rec i32)
  (local $n i32)
  (local $len i32)
  (local $count i32)
  (local $i i32)
  (local $names (ref null $arr_any))
  global.get $__heap_ptr
  local.set $mark
  local.get $path
  call $fs.stage
  local.set $lin
  local.get $lin
  i32.const 4
  i32.add
  local.get $lin
  i32.load
  call $__fs_readdir_open
  local.set $s
  local.get $s
  i32.const 0
  i32.lt_s
  (if
    (then
      local.get $mark
      global.set $__heap_ptr
      i32.const -1
      local.get $s
      i32.sub
      call $fs.errCode
      return))
  ;; one entry at a time into `tmp` (a type, then the name), kept as `[length][name]` records laid one after the other
  i32.const 1024
  call $__alloc
  local.set $tmp
  global.get $__heap_ptr
  local.set $first
  (block $end
    (loop $each
      local.get $s
      local.get $tmp
      i32.const 1024
      call $__fs_readdir_next
      local.set $len
      local.get $len
      i32.const -100
      i32.eq
      br_if $end
      local.get $len
      i32.const 0
      i32.lt_s
      (if
        (then
          local.get $s
          call $__fs_readdir_close
          local.get $mark
          global.set $__heap_ptr
          i32.const -1
          local.get $len
          i32.sub
          call $fs.errCode
          return))
      local.get $len
      i32.const 4
      i32.add
      call $__alloc
      local.set $rec
      local.get $rec
      local.get $len
      i32.store
      local.get $rec
      i32.const 4
      i32.add
      local.get $tmp
      i32.const 4
      i32.add
      local.get $len
      memory.copy
      local.get $count
      i32.const 1
      i32.add
      local.set $count
      br $each))
  local.get $s
  call $__fs_readdir_close
  local.get $count
  array.new_default $arr_any
  local.set $names
  local.get $first
  local.set $rec
  (block $filled
    (loop $fill
      local.get $i
      local.get $count
      i32.ge_u
      br_if $filled
      local.get $rec
      i32.load
      local.set $len
      local.get $names
      local.get $i
      local.get $rec
      i32.const 4
      i32.add
      local.get $len
      call $fs.toStr
      array.set $arr_any
      ;; the next record: past the name, to a multiple of four
      local.get $rec
      i32.const 4
      i32.add
      local.get $len
      i32.add
      i32.const 3
      i32.add
      i32.const -4
      i32.and
      local.set $rec
      local.get $i
      i32.const 1
      i32.add
      local.set $i
      br $fill))
  local.get $mark
  global.set $__heap_ptr
  local.get $names
  call $fs.okArr)

;; ── changing it ──────────────────────────────────────────────────────────────

;; `fs.mkdir` / `fs.rmdir` / `fs.unlink` — 0, or `-(1 + code)`.
(func $fs.mkdir (param $path (ref null $str)) (result i32)
  (local $mark i32)
  (local $lin i32)
  (local $r i32)
  global.get $__heap_ptr
  local.set $mark
  local.get $path
  call $fs.stage
  local.set $lin
  local.get $lin
  i32.const 4
  i32.add
  local.get $lin
  i32.load
  call $__fs_mkdir
  local.set $r
  local.get $mark
  global.set $__heap_ptr
  local.get $r)

(func $fs.rmdir (param $path (ref null $str)) (result i32)
  (local $mark i32)
  (local $lin i32)
  (local $r i32)
  global.get $__heap_ptr
  local.set $mark
  local.get $path
  call $fs.stage
  local.set $lin
  local.get $lin
  i32.const 4
  i32.add
  local.get $lin
  i32.load
  call $__fs_rmdir
  local.set $r
  local.get $mark
  global.set $__heap_ptr
  local.get $r)

(func $fs.unlink (param $path (ref null $str)) (result i32)
  (local $mark i32)
  (local $lin i32)
  (local $r i32)
  global.get $__heap_ptr
  local.set $mark
  local.get $path
  call $fs.stage
  local.set $lin
  local.get $lin
  i32.const 4
  i32.add
  local.get $lin
  i32.load
  call $__fs_unlink
  local.set $r
  local.get $mark
  global.set $__heap_ptr
  local.get $r)

;; `fs.symlink` — the link at `link` holding `target` as written (not resolved); 0, or `-(1 + code)`.
(func $fs.symlink (param $target (ref null $str)) (param $link (ref null $str)) (result i32)
  (local $mark i32)
  (local $t i32)
  (local $l i32)
  (local $r i32)
  global.get $__heap_ptr
  local.set $mark
  local.get $target
  call $fs.stage
  local.set $t
  local.get $link
  call $fs.stage
  local.set $l
  local.get $t
  i32.const 4
  i32.add
  local.get $t
  i32.load
  local.get $l
  i32.const 4
  i32.add
  local.get $l
  i32.load
  call $__fs_symlink
  local.set $r
  local.get $mark
  global.set $__heap_ptr
  local.get $r)
