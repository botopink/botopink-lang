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
                    "name": "item",
                    "value": {
                      "branch": {
                        "loc": {
                          "line": 2,
                          "col": 28
                        },
                        "kind": {
                          "tryCatch": {
                            "expr": {
                              "call": {
                                "loc": {
                                  "line": 2,
                                  "col": 16
                                },
                                "kind": {
                                  "call": {
                                    "receiver": null,
                                    "callee": "getPerson",
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
                                  "col": 34
                                },
                                "kind": {
                                  "throw_": {
                                    "call": {
                                      "loc": {
                                        "line": 2,
                                        "col": 40
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
                                              "label": null,
                                              "value": {
                                                "literal": {
                                                  "loc": {
                                                    "line": 2,
                                                    "col": 46
                                                  },
                                                  "kind": {
                                                    "stringLit": "not found"
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