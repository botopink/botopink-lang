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
            "name": "a",
            "typeRef": {
              "array": {
                "named": "unknown"
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "b",
            "typeRef": {
              "array": {
                "generic": {
                  "name": "Box",
                  "args": [
                    {
                      "named": "i32"
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
            "name": "c",
            "typeRef": {
              "array": {
                "array": {
                  "named": "i32"
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
            "name": "d",
            "typeRef": {
              "optional": {
                "array": {
                  "named": "i32"
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
            "name": "e",
            "typeRef": {
              "function": {
                "params": [
                  {
                    "named": "i32"
                  }
                ],
                "returnType": {
                  "array": {
                    "named": "i32"
                  }
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
            "name": "g",
            "typeRef": {
              "generic": {
                "name": "|",
                "args": [
                  {
                    "named": "i32"
                  },
                  {
                    "array": {
                      "named": "string"
                    }
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
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 9,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "literal": {
                      "loc": {
                        "line": 9,
                        "col": 12
                      },
                      "kind": {
                        "numberLit": "1"
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