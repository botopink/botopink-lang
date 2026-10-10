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
            "name": "xs",
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
          },
          {
            "name": "b",
            "typeRef": {
              "generic": {
                "name": "Box",
                "args": [
                  {
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
                ],
                "is_builtin": false
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "o",
            "typeRef": {
              "generic": {
                "name": "|",
                "args": [
                  {
                    "optional": {
                      "named": "i32"
                    }
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
                    "literal": {
                      "loc": {
                        "line": 2,
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