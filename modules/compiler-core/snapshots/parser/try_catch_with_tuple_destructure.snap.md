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
                  "localBindDestruct": {
                    "pattern": {
                      "tuple_": [
                        "a",
                        "b"
                      ]
                    },
                    "value": {
                      "branch": {
                        "loc": {
                          "line": 2,
                          "col": 19
                        },
                        "kind": {
                          "tryCatch": {
                            "expr": {
                              "call": {
                                "loc": {
                                  "line": 2,
                                  "col": 23
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
                            },
                            "handler": {
                              "jump": {
                                "loc": {
                                  "line": 2,
                                  "col": 37
                                },
                                "kind": {
                                  "throw_": {
                                    "call": {
                                      "loc": {
                                        "line": 2,
                                        "col": 43
                                      },
                                      "kind": {
                                        "call": {
                                          "receiver": null,
                                          "callee": "Error",
                                          "is_builtin": false,
                                          "is_tagged": false,
                                          "optional": false,
                                          "args": [
                                            {
                                              "label": "msg",
                                              "value": {
                                                "literal": {
                                                  "loc": {
                                                    "line": 2,
                                                    "col": 54
                                                  },
                                                  "kind": {
                                                    "stringLit": "failed"
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
                          }
                        }
                      }
                    },
                    "mutable": false
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