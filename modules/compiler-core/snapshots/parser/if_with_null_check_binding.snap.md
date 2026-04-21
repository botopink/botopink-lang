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
                  "localBind": {
                    "name": "email",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 2,
                          "col": 26
                        },
                        "kind": {
                          "null_": {}
                        }
                      }
                    },
                    "mutable": true
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "controlFlow": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "if_": {
                    "cond": {
                      "identifier": {
                        "loc": {
                          "line": 3,
                          "col": 9
                        },
                        "kind": {
                          "ident": "email"
                        }
                      }
                    },
                    "binding": "e",
                    "then_": [
                      {
                        "expr": {
                          "call": {
                            "loc": {
                              "line": 4,
                              "col": 9
                            },
                            "kind": {
                              "call": {
                                "receiver": "console",
                                "callee": "log",
                                "args": [
                                  {
                                    "label": null,
                                    "value": {
                                      "identifier": {
                                        "loc": {
                                          "line": 4,
                                          "col": 21
                                        },
                                        "kind": {
                                          "ident": "e"
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
                        "emptyLinesBefore": 0
                      }
                    ],
                    "else_": null
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