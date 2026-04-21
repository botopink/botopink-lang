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
                    "name": "item",
                    "value": {
                      "controlFlow": {
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
                                  "col": 34
                                },
                                "kind": {
                                  "return": {
                                    "literal": {
                                      "loc": {
                                        "line": 2,
                                        "col": 41
                                      },
                                      "kind": {
                                        "null_": {}
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