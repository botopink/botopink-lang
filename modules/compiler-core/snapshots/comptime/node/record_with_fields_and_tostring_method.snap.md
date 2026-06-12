----- SOURCE CODE -- main.bp
```botopink
val GPSCoordinates = record {
    lat: number,
    lon: number,
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
        "lat": "number",
        "lon": "number"
      }
    }
  ]
}
```

