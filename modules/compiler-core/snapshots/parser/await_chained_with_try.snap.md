```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": "future",
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "run",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": {
          "generic": {
            "name": "Future",
            "args": [
              {
                "named": "Int"
              }
            ],
            "is_builtin": true
          }
        },
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
                      "jump": {
                        "loc": {
                          "line": 2,
                          "col": 13
                        },
                        "kind": {
                          "try_": {
                            "jump": {
                              "loc": {
                                "line": 2,
                                "col": 17
                              },
                              "kind": {
                                "await_": {
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
                                        "args": [
                                          {
                                            "label": null,
                                            "value": {
                                              "identifier": {
                                                "loc": {
                                                  "line": 2,
                                                  "col": 29
                                                },
                                                "kind": {
                                                  "ident": "url"
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
                    },
                    "mutable": false,
                    "typeAnnotation": null
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 3,
                        "col": 12
                      },
                      "kind": {
                        "ident": "x"
                      }
                    }
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