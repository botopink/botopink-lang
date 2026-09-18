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
            "name": "x",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "xs",
            "typeRef": {
              "array": {
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
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "ys",
            "typeRef": {
              "array": {
                "array": {
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
                }
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
                        "col": 15
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
                                "ident": "xs"
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