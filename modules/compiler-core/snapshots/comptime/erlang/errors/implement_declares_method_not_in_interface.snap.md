----- SOURCE CODE
val Swimmer = interface {
    fn swim(self: Self);
}
record Pato { id: i32 }
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

  'fly' is not declared in any interface implemented for 'Pato'
