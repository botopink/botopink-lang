----- SOURCE CODE -- main.bp
```botopink
fn get_coordinates() -> #(f64, f64) {
    return #(0.0, 0.0);
}
fn extract_coordinates() -> void {
    val #(longitude, latitude) = get_coordinates();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__get_coordinates'/0, '__bp_priv__extract_coordinates'/0]).

get_coordinates() ->
    {0.0, 0.0}.

extract_coordinates() ->
    {Longitude, Latitude} = get_coordinates().

'__bp_priv__get_coordinates'() -> get_coordinates().

'__bp_priv__extract_coordinates'() -> extract_coordinates().
```

----- RUN LOG -----
```logs
```
