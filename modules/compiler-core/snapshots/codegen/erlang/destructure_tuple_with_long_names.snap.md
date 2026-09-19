----- SOURCE CODE -- main.bp
```botopink
fn get_coordinates() -> #(f64, f64) {
    return #(0.0, 0.0);
}
fn extract_coordinates() {
    val #(longitude, latitude) = get_coordinates();
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

get_coordinates() ->
    {0.0, 0.0}.

extract_coordinates() ->
    {Longitude, Latitude} = get_coordinates().
```

----- RUN LOG -----
```logs
```
