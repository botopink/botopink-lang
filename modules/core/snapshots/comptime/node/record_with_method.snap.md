----- SOURCE CODE -- main.bp
```botopink
val GPSCoordinates = record {
    lat: f64,
    lon: f64,
    fn toString(self: Self) -> string {
        return "Lat: " + self.lat + " Lon: " + self.lon;
    }
};
val g = GPSCoordinates(lat: 5.0, lon: 3.0);
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
    },
    {
      "ast": "val",
      "expr": {
        "ast": "call",
        "params": [
          {
            "name": "lat",
            "value": "f64"
          },
          {
            "name": "lon",
            "value": "f64"
          }
        ],
        "return_type": "GPSCoordinates"
      },
      "return_type": "GPSCoordinates"
    }
  ]
}
```

