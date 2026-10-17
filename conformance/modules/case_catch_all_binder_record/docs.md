# case_catch_all_binder_record

A name alone is not a pattern: to give the matched value a name, bind it in the body (`_ { n -> … }`). The binder of a catch-all arm over a record is that record: its fields read as declared, a generic record's too, wherever the `case` stands.
