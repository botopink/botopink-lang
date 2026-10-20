----- SOURCE CODE -- main.bp
```botopink
val UsbCharger = behavior {
    fn Connect(self: Self) -> void;
};
val SolarCharger = behavior {
    fn Connect(self: Self) -> void;
};
val SmartCamera = type(batteryLevel: i32);
val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
    fn UsbCharger.Connect(self: Self) -> void {
        print("Connected via USB");
    }
    fn SolarCharger.Connect(self: Self) -> void {
        print("Connected via Solar");
    }
};

import {io.terminal.print} from "std";
```

----- TYPED AST JSON -- main.json
```json
{
  "declarations": [
    {
      "ast": "interface_def",
      "name": "UsbCharger",
      "methods": [
        {
          "name": "Connect",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "void"
        }
      ]
    },
    {
      "ast": "interface_def",
      "name": "SolarCharger",
      "methods": [
        {
          "name": "Connect",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ],
          "return_type": "void"
        }
      ]
    },
    {
      "ast": "record_def",
      "name": "SmartCamera",
      "fields": {
        "batteryLevel": "i32"
      }
    },
    {
      "ast": "implement_def",
      "name": "CameraPowerCharger",
      "interfaces": [
        "UsbCharger",
        "SolarCharger"
      ],
      "target": "SmartCamera",
      "methods": [
        {
          "name": "Connect",
          "qualifier": "UsbCharger",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ]
        },
        {
          "name": "Connect",
          "qualifier": "SolarCharger",
          "params": [
            {
              "name": "self",
              "type": "Self"
            }
          ]
        }
      ]
    }
  ]
}
```

