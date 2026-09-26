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
              "array": {
                "generic": {
                  "name": "Result",
                  "args": [
                    {
                      "named": "i32"
                    },
                    {
                      "named": "string"
                    }
                  ],
                  "is_builtin": true
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