# decorator_lambda_many_locals

A decorator body's lambda that holds many locals runs while the program compiles, on every target: 120 `val`s for each field of a three-field record, then the length of their join — `1450,1090,1450`.
