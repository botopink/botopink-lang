----- SOURCE CODE
type Shape { Circle(r: bogusType), Square(side: f64) }

----- ERROR
error: unknown type
  ┌─ main.bp:1:24
  │
1 │ type Shape { Circle(r: bogusType), Square(side: f64) }
  │                        ^

  the type 'bogusType' is not defined in this scope
