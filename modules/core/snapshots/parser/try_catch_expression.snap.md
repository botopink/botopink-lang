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
                "localBind": {
                  "name": "x",
                  "value": {
                    "loc": {
                      "line": 2,
                      "col": 13
                    },
                    "kind": {
                      "tryCatch": {
                        "expr": {
                          "loc": {
                            "line": 2,
                            "col": 17
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
                            "col": 31
                          },
                          "kind": {
                            "throw_": {
                              "loc": {
                                "line": 2,
                                "col": 37
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
                                          "col": 48
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