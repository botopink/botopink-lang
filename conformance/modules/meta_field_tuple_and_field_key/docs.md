# meta_field_tuple_and_field_key

A tuple is rebuilt as written (`#(1, 9)`) and a `Type.Field<T>` as its key
(`.pages`): a generic meta record whose one parameter types the key
(`Sort<T>(by: Type.Field<T>)`) is read with that parameter the annotated
declaration (`Sort<Book>(by: .pages)`, decision 308).

`Span(range: #(1, 9), label: "Book")` and `Sort(by: .pages, keys: [.pages])` on `Book` — `Book`, `10`, `pages`, `1`.
