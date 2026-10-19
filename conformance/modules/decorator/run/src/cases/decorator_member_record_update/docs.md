# decorator_member_record_update

A member a decorator adds with `compiler.addMember` is written as if by hand, so a record update in its body copies every field it does not name, on every target: `Point(..self, y: 0)` in a method and `Point(..v, z: z)` in an associated fn — `Point(x: 1, y: 0, z: 3)`, then `Point(x: 1, y: 2, z: 9)`.
