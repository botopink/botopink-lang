----- SOURCE CODE
val Swimmer = behavior {
    fn swim(self: Self);
}
type Pato(id: i32)
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
    fn fly(self: Self) {
        return self.id;
    }
}

----- ERROR
error: unknown method
  ┌─ main.bp:9:8
  │
9 │     fn fly(self: Self) {
  │        ^

  'fly' is not declared in any behavior implemented for 'Pato'
