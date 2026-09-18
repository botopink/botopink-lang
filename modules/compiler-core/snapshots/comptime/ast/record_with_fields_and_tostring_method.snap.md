----- SOURCE CODE -- main.bp
```botopink
val GPSCoordinates = type(
    lat: f64,
    lon: f64) {
    fn toString(self: Self) -> string {
        return "Lat: " + self.lat + " Lon: " + self.lon;
    }
}
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "record_def",
      "name": "GPSCoordinates",
      "id": 0,
      "fields": {
        "lat": "f64",
        "lon": "f64"
      }
    }
  ]
}
```

