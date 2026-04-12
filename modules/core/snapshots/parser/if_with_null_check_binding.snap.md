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
                  "name": "email",
                  "value": {
                    "loc": {
                      "line": 2,
                      "col": 26
                    },
                    "kind": {
                      "null_": {}
                    }
                  },
                  "mutable": true
                }
              }
            }
          },
          {
            "expr": {
              "loc": {
                "line": 3,
                "col": 5
              },
              "kind": {
                "if_": {
                  "cond": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "ident": "email"
                    }
                  },
                  "binding": "e",
                  "then_": [
                    {
                      "expr": {
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
                                  "loc": {
                                    "line": 4,
                                    "col": 21
                                  },
                                  "kind": {
                                    "ident": "e"
                                  }
                                }
                              }
                            ],
                            "trailing": []
                          }
                        }
                      }
                    }
                  ],
                  "else_": null
                }
              }
            }
          }
        ]
      }
    }
  ]
}