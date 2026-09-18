----- SOURCE CODE
type Shape { Circle(r: bogusType), Square(side: f64) }

----- ERROR
error: unknown type
  ┌─ :1:24
  │
1 │ type Shape { Circle(r: bogusType), Square(side: f64) }
  │                        ^

  the type 'bogusType' is not defined in this scope
