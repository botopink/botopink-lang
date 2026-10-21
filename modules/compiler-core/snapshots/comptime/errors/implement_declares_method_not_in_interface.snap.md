----- SOURCE CODE
val Swimmer = behavior {
    fn swim(self: Self) -> i32;
}
type Pato(id: i32)
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) -> i32 {
        return self.id;
    }
    fn fly(self: Self) -> i32 {
        return self.id;
    }
}

----- ERROR
error: unknown method
  ┌─ main.bp:9:8
  │
9 │     fn fly(self: Self) -> i32 {
  │        ^

  'fly' is not declared in any behavior implemented for 'Pato'
