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
      "fields": {
        "lat": "f64",
        "lon": "f64"
      },
      "methods": [
        {
          "name": "toString",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "string"
        }
      ]
    }
  ]
}
```

