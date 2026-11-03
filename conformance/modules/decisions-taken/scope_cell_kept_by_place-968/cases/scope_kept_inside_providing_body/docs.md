> Decisions 809 (8), 968 (2)/(3): a kept `(child, scope)` keeps that child's cell. `Parent` provides `dark`, then
> `use`s a `{ scope, key -> … }` lambda that keeps the scope it is handed inside `Parent`'s body. `Reader`, resolved
> over that kept scope after the render has returned, reads `dark`.
