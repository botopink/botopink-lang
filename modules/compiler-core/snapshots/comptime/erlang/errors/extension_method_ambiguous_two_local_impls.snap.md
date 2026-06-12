----- SOURCE CODE
val Swimmer = interface {
    fn swim(self: Self);
}
val Diver = interface {
    fn swim(self: Self);
}
record Pato { id: i32 }
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
val PatoFundo = implement Diver for Pato {
    fn swim(self: Self) {
        return self.id;
    }
}
val donald = Pato(1);
val r = donald.swim();

----- ERROR
error: ambiguous extension method
  ┌─ :19:16
  │
19 │ val r = donald.swim();
  │                ^

  'Pato.swim' is provided by both 'PatoNada' and 'PatoFundo'
  hint: qualify the call, e.g. `PatoNada.swim(obj)`
