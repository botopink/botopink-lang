----- SOURCE CODE -- main.bp
```botopink
val UsbCharger = interface {
    fn Connect(self: Self),
};
val SolarCharger = interface {
    fn Connect(self: Self),
};
val SmartCamera = record { batteryLevel: i32 };
val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
    fn UsbCharger.Connect(self: Self) {
        @print("Connected via USB");
    }
    fn SolarCharger.Connect(self: Self) {
        @print("Connected via Solar");
    }
};
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "UsbCharger"
    },
    {
      "ast": "interface_def",
      "name": "SolarCharger"
    },
    {
      "ast": "record_def",
      "name": "SmartCamera",
      "id": 0,
      "fields": {
        "batteryLevel": "i32"
      }
    }
  ]
}
```

