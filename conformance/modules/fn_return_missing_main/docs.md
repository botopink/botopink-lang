# fn_return_missing_main

Decision 622: `main` writes its return type like every function, `pub fn main() -> void { … }`. Without `->` it is
refused at its name, `fn-return-missing`, before the program runs.
