```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
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
                      "controlFlow": {
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
                                    "args": [],
                                    "trailing": []
                                  }
                                }
                              }
                            },
                            "handler": {
                              "controlFlow": {
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