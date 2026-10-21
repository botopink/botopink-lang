# tuple_variable_in_generic_text

A tuple bound to a local and handed to a generic function that writes its type parameter as text is written as a tuple
on every target, as the same tuple written in the call is. The wasm backend binds the function's `T` to the tuple's type
from the local's written value, not only from a literal.
