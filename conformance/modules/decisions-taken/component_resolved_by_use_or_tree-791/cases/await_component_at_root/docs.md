# await_component_at_root

Decision 791 (4): outside every component body an `await` of a component is refused too, `await-component`; the root is run by `c.run(RenderScope.root())`.
