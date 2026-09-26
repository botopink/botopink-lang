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
        "name": "size",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "v",
            "typeRef": {
              "generic": {
                "name": "|",
                "args": [
                  {
                    "named": "i32"
                  },
                  {
                    "named": "string"
                  }
                ],
                "is_builtin": false
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
          "generic": {
            "name": "|",
            "args": [
              {
                "named": "i32"
              },
              {
                "named": "string"
              }
            ],
            "is_builtin": false
          }
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "w",
                    "value": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 34
                        },
                        "kind": {
                          "ident": "v"
                        }
                      }
                    },
                    "mutable": false,
                    "typeAnnotation": {
                      "generic": {
                        "name": "|",
                        "args": [
                          {
                            "named": "i32"
                          },
                          {
                            "named": "string"
                          },
                          {
                            "named": "bool"
                          }
                        ],
                        "is_builtin": false
                      }
                    }
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 3,
                        "col": 12
                      },
                      "kind": {
                        "ident": "w"
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