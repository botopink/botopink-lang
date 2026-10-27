# Decision 264 — Integer overflow is a program error on every target: `+`, `-`, `*`, unary `-` and the compound assignments of every inte

[cases/int_arith_at_bounds/src/main.bp](cases/int_arith_at_bounds/src/main.bp)
[cells/int_division_min_by_minus_one/src/main.bp](cells/int_division_min_by_minus_one/src/main.bp)
[cells/int_overflow_add_i32/src/main.bp](cells/int_overflow_add_i32/src/main.bp)
[cells/int_overflow_add_i8/src/main.bp](cells/int_overflow_add_i8/src/main.bp)
[cells/int_overflow_negate_i32/src/main.bp](cells/int_overflow_negate_i32/src/main.bp)
[cells/int_overflow_plus_assign/src/main.bp](cells/int_overflow_plus_assign/src/main.bp)
[cells/int_overflow_sub_u32/src/main.bp](cells/int_overflow_sub_u32/src/main.bp)

Proved also by [abort_text_overflow](../runtime_abort_prints_failure-535/cells/abort_text_overflow/src/main.bp)
Proved also by [bigint_division_by_zero](../bigint_decimal_strict_json-332/cells/bigint_division_by_zero/src/main.bp)
Proved also by [bigint_to_i64_aborts](../bigint_decimal_strict_json-332/cells/bigint_to_i64_aborts/src/main.bp)
Proved also by [i64_full_range](../i64_is_64_bit_everywhere-319/cells/i64_full_range/src/main.bp)
Proved also by [int_overflow_mul_i64](../i64_is_64_bit_everywhere-319/cells/int_overflow_mul_i64/src/main.bp)
Proved also by [int_overflow_sub_i64_min](../i64_is_64_bit_everywhere-319/cells/int_overflow_sub_i64_min/src/main.bp)
Proved also by [std_failure_attempt_abort_kinds](../failure_kinds-492/cases/std_failure_attempt_abort_kinds/src/main.bp)
