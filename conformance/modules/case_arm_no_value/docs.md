# case_arm_no_value

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> The same rule reads every block used as a value: a `case` arm `p { … }`, `comptime { … }` and
> `async { … }` answer their last expression written without `;`. An arm of a `case` used as a value
> whose last expression ends with `;` answers nothing, refused at the arm beside arms that answer a
> value; `break <value>` gives a block no value, refused at the `break`:
