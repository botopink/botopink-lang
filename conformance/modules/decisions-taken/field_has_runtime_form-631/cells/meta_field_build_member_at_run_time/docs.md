# meta_field_build_member_at_run_time

A field read back from a typed meta record holds its owner and its name at
run time (`Field(Book, "pages")`, decision 631); its `annotations`, like its
`typeName`, is a build member, so reading it in `main` is refused at the read.
