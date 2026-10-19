# decorator_argument_decorator_alias

A decorator's name handed to a `Decorator` parameter is resolved where it is written (decision 268): through its module's namespace (`markers.email`) and under an import's alias (`lower`) it is the same declaration's identity, compared with `same` (decision 371), in a `Decorator[]` array too — on every target: `email`, `lowercased`, `2`.
