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
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "doubled",
                    "value": {
                      "useHook": {
                        "loc": {
                          "line": 2,
                          "col": 19
                        },
                        "kind": {
                          "inner": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 23
                              },
                              "kind": {
                                "call": {
                                  "receiver": null,
                                  "callee": "memo",
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
                                            "col": 28
                                          },
                                          "kind": {
                                            "syntax": "lambda",
                                            "params": [],
                                            "body": [
                                              {
                                                "expr": {
                                                  "binaryOp": {
                                                    "loc": {
                                                      "line": 2,
                                                      "col": 39
                                                    },
                                                    "op": "mul",
                                                    "lhs": {
                                                      "identifier": {
                                                        "loc": {
                                                          "line": 2,
                                                          "col": 33
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
                                                          "col": 41
                                                        },
                                                        "kind": {
                                                          "numberLit": "2"
                                                        }
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