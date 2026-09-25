----- SOURCE CODE
#[@resultGenerator]
fn nums() -> @ResultGenerator<i32, string> {
    yield 1;
    break "not an i32";
}

----- ERROR
error: iterator-break-type-mismatch: `break <v>` emits `v` as the generator's last item, so `v` must be the item type `T` of the wrapper
  ┌─ :4:5
  │
4 │     break "not an i32";
  │     ^

  hint: Either change the `break <expr>;` value to the item type, or widen the wrapper's first generic.
