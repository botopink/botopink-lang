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
        "name": "f",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "rows",
            "typeRef": {
              "array": {
                "labeledTuple": {
                  "elems": [
                    {
                      "named": "i32"
                    },
                    {
                      "named": "string"
                    }
                  ],
                  "labels": [
                    "a",
                    "b"
                  ]
                }
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "pairs",
            "typeRef": {
              "array": {
                "tuple_": [
                  {
                    "named": "i32"
                  },
                  {
                    "named": "string"
                  }
                ]
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 2,
                        "col": 17
                      },
                      "kind": {
                        "identAccess": {
                          "receiver": {
                            "identifier": {
                              "loc": {
                                "line": 2,
                                "col": 12
                              },
                              "kind": {
                                "ident": "rows"
                              }
                            }
                          },
                          "member": "length",
                          "optional": false
                        }
                      }
                    }
                  }
                }
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