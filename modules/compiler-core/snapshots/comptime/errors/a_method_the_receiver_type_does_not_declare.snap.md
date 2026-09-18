----- SOURCE CODE
type D(id: i32)
fn main() {
    val d = D(id: 1);
    @print(d.swim());
}

----- ERROR
error: unknown method
  ┌─ :4:14
  │
4 │     @print(d.swim());
  │              ^

  'swim' is not declared in any behavior implemented for 'D'
