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
                      "branch": {
                        "loc": {
                          "line": 2,
                          "col": 13
                        },
                        "kind": {
                          "tryCatch": {
                            "expr": {
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
                            },
                            "handler": {
                              "jump": {
                                "loc": {
                                  "line": 2,
                                  "col": 31
                                },
                                "kind": {
                                  "throw_": {
                                    "call": {
                                      "loc": {
                                        "line": 2,
                                        "col": 37
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
                                                    "col": 48
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