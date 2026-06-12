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
        "name": "App",
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
              "useHook": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "inner": {
                    "call": {
                      "loc": {
                        "line": 2,
                        "col": 9
                      },
                      "kind": {
                        "call": {
                          "receiver": null,
                          "callee": "effect",
                          "is_builtin": false,
                          "is_tagged": false,
                          "optional": false,
                          "args": [
                            {
                              "label": null,
                              "value": {
                                "function": {
                                  "loc": {
                                    "line": 2,
                                    "col": 16
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "call": {
                                            "loc": {
                                              "line": 2,
                                              "col": 21
                                            },
                                            "kind": {
                                              "call": {
                                                "receiver": null,
                                                "callee": "cleanup",
                                                "is_builtin": false,
                                                "is_tagged": false,
                                                "optional": false,
                                                "args": [],
                                                "trailing": []
                                              }
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ],
                                    "isStarFn": false
                                  }
                                }
                              },
                              "comments": []
                            }
                          ],
                          "trailing": []
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