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
        "params": [],
        "returnType": null,
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
                    "name": "x",
                    "value": {
                      "jump": {
                        "loc": {
                          "line": 2,
                          "col": 13
                        },
                        "kind": {
                          "try_": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 17
                              },
                              "kind": {
                                "call": {
                                  "receiver": null,
                                  "callee": "fetch",
                                  "is_builtin": false,
                                  "is_tagged": false,
                                  "optional": false,
                                  "args": [],
                                  "trailing": []
                                }
                              }
                            }
                          }
                        }
                      }
                    },
                    "mutable": false,
                    "typeAnnotation": null
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