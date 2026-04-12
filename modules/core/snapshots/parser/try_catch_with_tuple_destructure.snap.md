{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "f",
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": null,
        "body": [
          {
            "expr": {
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
                    "loc": {
                      "line": 2,
                      "col": 19
                    },
                    "kind": {
                      "tryCatch": {
                        "expr": {
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
                        },
                        "handler": {
                          "loc": {
                            "line": 2,
                            "col": 37
                          },
                          "kind": {
                            "throw_": {
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
                                        "loc": {
                                          "line": 2,
                                          "col": 54
                                        },
                                        "kind": {
                                          "stringLit": "failed"
                                        }
                                      }
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
                  "mutable": false
                }
              }
            }
          }
        ]
      }
    }
  ]
}