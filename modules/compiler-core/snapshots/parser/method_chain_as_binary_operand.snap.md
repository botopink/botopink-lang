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
                    "name": "ok",
                    "value": {
                      "binaryOp": {
                        "loc": {
                          "line": 2,
                          "col": 35
                        },
                        "op": "gt",
                        "lhs": {
                          "call": {
                            "loc": {
                              "line": 2,
                              "col": 27
                            },
                            "kind": {
                              "call": {
                                "receiver": {
                                  "call": {
                                    "loc": {
                                      "line": 2,
                                      "col": 18
                                    },
                                    "kind": {
                                      "call": {
                                        "receiver": {
                                          "identifier": {
                                            "loc": {
                                              "line": 2,
                                              "col": 14
                                            },
                                            "kind": {
                                              "ident": "obj"
                                            }
                                          }
                                        },
                                        "callee": "value",
                                        "is_builtin": false,
                                        "is_tagged": false,
                                        "optional": false,
                                        "args": [
                                          {
                                            "label": null,
                                            "value": {
                                              "literal": {
                                                "loc": {
                                                  "line": 2,
                                                  "col": 24
                                                },
                                                "kind": {
                                                  "numberLit": "1"
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
                                },
                                "callee": "count",
                                "is_builtin": false,
                                "is_tagged": false,
                                "optional": false,
                                "args": [],
                                "trailing": []
                              }
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
                              "numberLit": "0"
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