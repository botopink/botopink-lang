----- SOURCE CODE
val Swimmer = behavior {
    fn swim(self: Self);
}
type Pato(id: i32)
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
PatoNada*;

----- ERROR
error: redundant activation
  ┌─ main.bp:10:1
  │
10 │ PatoNada*;
  │ ^

  `PatoNada*` is redundant: a local extension is auto-applied
  hint: drop it — `*` is only for imports
