//! Barrel for comptime stage tests. Real tests live in tests/<feature>.zig;
//! the shared harness is tests/helpers.zig. This file only aggregates them
//! so `test_root.zig` (which imports this) discovers every test.

test {
    _ = @import("tests/infer_exprs.zig");
    _ = @import("tests/infer_decls.zig");
    _ = @import("tests/infer_generics.zig");
    _ = @import("tests/infer_errors.zig");
    _ = @import("tests/types.zig");
    _ = @import("tests/variants.zig");
    _ = @import("tests/exhaustiveness.zig");
    _ = @import("tests/effects.zig");
    _ = @import("tests/templates.zig");
    _ = @import("tests/decorators.zig");
    _ = @import("tests/decorator_invocation.zig");
    _ = @import("tests/generic_defaults.zig");
    _ = @import("tests/std_target_gating.zig");
    _ = @import("tests/effect_result.zig");
    _ = @import("tests/effect_future.zig");
    _ = @import("tests/effect_generator.zig");
    _ = @import("tests/builtins_typeinfo.zig");
    _ = @import("primOpTemplate.zig");
    _ = @import("./diagnostics.zig");
    _ = @import("./template_eval.zig");
    _ = @import("./decorator_eval.zig");
}
