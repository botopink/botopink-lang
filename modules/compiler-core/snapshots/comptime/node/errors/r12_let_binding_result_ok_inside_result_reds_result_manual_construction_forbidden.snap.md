----- SOURCE CODE
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    val r = Result.Ok(result: n);
    return n;
}

----- ERROR
error: result-manual-construction-forbidden: the @Result type variants are only constructed by `return` / `throw` inside #[@result]; outside that the type is treated as opaque.
  ┌─ :3:20
  │
3 │     val r = Result.Ok(result: n);
  │                    ^

  hint: Replace the manual `Result.Ok(...)` / `Result.Error(...)` with the implicit form (`return <r>;` / `throw <e>;`), or move the construction outside the #[@result] body.
