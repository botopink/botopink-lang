----- SOURCE CODE
val Swimmer = behavior {
    fn swim(self: Self) -> i32;
}
val Diver = behavior {
    fn swim(self: Self) -> i32;
}
type Pato(id: i32)
val PatoNada = implement Swimmer for Pato {
    fn swim(self: Self) -> i32 {
        return self.id;
    }
}
val PatoFundo = implement Diver for Pato {
    fn swim(self: Self) -> i32 {
        return self.id;
    }
}
val donald = Pato(1);
val r = donald.swim();

----- ERROR
error: ambiguous extension method
  ┌─ main.bp:19:16
  │
19 │ val r = donald.swim();
  │                ^

  'Pato.swim' is provided by both 'PatoNada' and 'PatoFundo'
  hint: qualify the call, e.g. `PatoNada.swim(obj)`
