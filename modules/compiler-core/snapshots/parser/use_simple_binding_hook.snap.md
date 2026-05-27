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
                    "name": "doubled",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 2,
                          "col": 19
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "memo",
                            "is_builtin": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "function": {
                                    "loc": {
                                      "line": 2,
                                      "col": 24
                                    },
                                    "kind": {
                                      "lambda": {
                                        "params": [],
                                        "body": [
                                          {
                                            "expr": {
                                              "binaryOp": {
                                                "loc": {
                                                  "line": 2,
                                                  "col": 35
                                                },
                                                "kind": {
                                                  "op": "mul",
                                                  "lhs": {
                                                    "identifier": {
                                                      "loc": {
                                                        "line": 2,
                                                        "col": 29
                                                      },
                                                      "kind": {
                                                        "ident": "count"
                                                      }
                                                    }
                                                  },
                                                  "rhs": {
                                                    "literal": {
                                                      "loc": {
                                                        "line": 2,
                                                        "col": 37
                                                      },
                                                      "kind": {
                                                        "numberLit": "2"
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