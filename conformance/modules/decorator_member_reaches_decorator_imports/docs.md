> Decision 669 — names in code a decorator writes resolve in the module that
> wrote it, that module's imports included. `#[counted]`'s member calls
> `panic` and `print`, which `checks` imports from std; this module imports
> neither, and calls the member.
