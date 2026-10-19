# Decision 593 — (c), and a type may be a component — every form behaves and is called as a `fn` component.

The example renders three forms of component under one provided theme. `Badge` is a `component fn`. `Menu` is a type implementing `Component<Element>`: its fields are the props, `title` with its default, and its `render` reads them on `self` and calls the plain helper `item`. `shout` is a lambda marked `component`. `Page` provides a `dark` theme and calls all three alike, and each reads it with `use context`. `Menu(items: ["x"], title: "Principal")` called from `main` answers the component, run under the root scope. The program prints `dark(new) dark:Menu[<a>,<b>] dark!HEY` and `plain:Principal[<x>]`.

Cells in this repository that also bear on it: `modules/decisions-taken/component_wrapper_and_contexts-354/cells/context_provide_read`, `modules/decisions-taken/component_is_lambda_over_render_scope-388/cells/component_is_lambda`, `modules/decisions-taken/async_marked_by_hooks_list-375/cells/component_method_sync`, `modules/decisions-taken/async_marked_by_hooks_list-375/cells/component_default_fn_sync`.

[draft/main.bp](draft/main.bp)
