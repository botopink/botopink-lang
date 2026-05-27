```json
{
  "decls": [
    {
      "implement": {
        "name": "CircleDrawing",
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
          "Drawable"
        ],
        "target": "Circle",
        "methods": [
          {
            "qualifier": null,
            "name": "draw",
            "params": [
              {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "",
                "modifier": "none",
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              }
            ],
            "body": [
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "call": {
                        "receiver": null,
                        "callee": "print",
                        "is_builtin": true,
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "literal": {
                                "loc": {
                                  "line": 3,
                                  "col": 16
                                },
                                "kind": {
                                  "stringLit": "Drawing circle"
                                }
                              }
                            },
                            "comments": []
                          }
                        ],
                        "trailing": []
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
              }
            ]
          }
        ]
      }
    }
  ]
}
```