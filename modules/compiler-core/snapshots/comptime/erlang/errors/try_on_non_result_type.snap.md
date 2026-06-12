----- SOURCE CODE
fn fetch() -> i32 {
    return 42;
}
fn process() -> i32 {
    val r = try fetch();
    return r;
}

----- ERROR
error: try on non-Result
  ┌─ :5:13
  │
5 │     val r = try fetch();
  │             ^

  `try` requires a @Result<D, E> value, found 'i32'
