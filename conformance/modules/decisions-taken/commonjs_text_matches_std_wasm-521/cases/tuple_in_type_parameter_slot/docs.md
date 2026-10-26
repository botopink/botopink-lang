# tuple_in_type_parameter_slot

A tuple held in a type parameter's slot is printed as a tuple on every target: a generic record's field
(`Box(value: #(1, 2))`), the answer of a generic function (`id(#(3, "x"))`), the two together, a tuple inside an array
in the slot, and a record field declared a tuple. JavaScript holds a tuple as an array, so commonJS reads the tuple
from the type the call binds.
