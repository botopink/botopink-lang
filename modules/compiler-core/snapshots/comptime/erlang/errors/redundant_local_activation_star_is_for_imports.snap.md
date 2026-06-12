----- SOURCE CODE
val Swimmer = interface {
    fn swim(self: Self);
}
record Pato { id: i32 }
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
PatoNada*;

----- ERROR
error: redundant activation

  `PatoNada*` is redundant: a local extension is auto-applied
  hint: drop it — `*` is only for imports
