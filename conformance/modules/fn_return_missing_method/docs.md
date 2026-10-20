# fn_return_missing_method

Decision 622: a method writes its return type as a free `fn` does. `Square.area` returns `self.side * self.side` and
writes no `->`; its type is not read off its `return`s (06 C9's inference is removed), and it is refused at its name,
`fn-return-missing`. It used to build and print `9`.
