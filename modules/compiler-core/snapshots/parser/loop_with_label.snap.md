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
            "default": null
          }
        ],
        "returnType": null,
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "loop": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "keyword": "for_",
                "generator": null,
                "iter": {
                  "identifier": {
                    "loc": {
                      "line": 2,
                      "col": 15
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
                "paramsLoc": {
                  "line": 2,
                  "col": 24
                },
                "condition": false,
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