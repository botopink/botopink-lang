```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "collect",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "items",
            "typeRef": {
              "array": {
                "named": "Int"
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": null,
        "body": [
          {
            "expr": {
              "loop": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "iter": {
                  "identifier": {
                    "loc": {
                      "line": 2,
                      "col": 16
                    },
                    "kind": {
                      "ident": "items"
                    }
                  }
                },
                "indexRange": null,
                "params": [
                  "item"
                ],
                "body": [
                  {
                    "expr": {
                      "jump": {
                        "loc": {
                          "line": 3,
                          "col": 9
                        },
                        "kind": {
                          "yield": {
                            "label": "acc",
                            "value": {
                              "identifier": {
                                "loc": {
                                  "line": 3,
                                  "col": 20
                                },
                                "kind": {
                                  "ident": "item"
                                }
                              }
                            }
                          }
                        }
                      }
                    },
                    "emptyLinesBefore": 0
                  }
                ],
                "awaitLoop": false,
                "label": "acc"
              }
            },
            "emptyLinesBefore": 0
          }
        ]
      }
    }
  ]
}
```