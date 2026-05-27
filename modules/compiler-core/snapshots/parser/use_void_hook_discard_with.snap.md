```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
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
                  "useBind": {
                    "name": "_",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 2,
                          "col": 13
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "effect",
                            "is_builtin": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "function": {
                                    "loc": {
                                      "line": 2,
                                      "col": 20
                                    },
                                    "kind": {
                                      "lambda": {
                                        "params": [],
                                        "body": [
                                          {
                                            "expr": {
                                              "call": {
                                                "loc": {
                                                  "line": 2,
                                                  "col": 25
                                                },
                                                "kind": {
                                                  "call": {
                                                    "receiver": null,
                                                    "callee": "cleanup",
                                                    "is_builtin": false,
                                                    "args": [],
                                                    "trailing": []
                                                  }
                                                }
                                              }
                                            },
                                            "emptyLinesBefore": 0
                                          }
                                        ]
                                      }
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