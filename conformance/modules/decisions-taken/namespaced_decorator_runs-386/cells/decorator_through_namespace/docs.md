# decorator_through_namespace

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A decorator is reached by its name, an alias or a namespace (decision 386):
> `import {markers} from "web";` registers the module's decorators under
> `markers.<name>`, as std's are, so `#[markers.tag]` runs `tag` as `#[tag]`
> imported by name does, and `markers.serverOnly` names a declaration handle
> (`compiler.same(a.decorator, markers.serverOnly)`).
