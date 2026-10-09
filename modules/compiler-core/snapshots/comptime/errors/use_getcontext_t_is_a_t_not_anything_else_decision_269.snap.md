----- SOURCE CODE
type BasePagamento(total: i32)
fn total() -> @Component<BasePagamento, i32> {
    val ctx: string = use @getContext(BasePagamento);
    return 0;
}

----- ERROR
error: type mismatch
  ┌─ main.bp:3:23
  │
3 │     val ctx: string = use @getContext(BasePagamento);
  │                       ^

  expected: string
  found:    BasePagamento
