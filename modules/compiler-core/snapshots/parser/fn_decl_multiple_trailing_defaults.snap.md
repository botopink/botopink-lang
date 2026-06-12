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
        "name": "connect",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "host",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "port",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": {
              "literal": {
                "loc": {
                  "line": 1,
                  "col": 38
                },
                "kind": {
                  "numberLit": "80"
                }
              }
            }
          },
          {
            "name": "timeout",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": {
              "literal": {
                "loc": {
                  "line": 1,
                  "col": 57
                },
                "kind": {
                  "numberLit": "30"
                }
              }
            }
          }
        ],
        "returnType": {
          "named": "bool"
        },
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
                        "col": 12
                      },
                      "kind": {
                        "ident": "true"
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