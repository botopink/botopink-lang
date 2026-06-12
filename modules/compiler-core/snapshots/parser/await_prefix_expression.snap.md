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
        "annotations": [
          {
            "name": "future",
            "args": [],
            "is_builtin": true
          }
        ],
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
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "x",
                    "value": {
                      "jump": {
                        "loc": {
                          "line": 3,
                          "col": 13
                        },
                        "kind": {
                          "await_": {
                            "call": {
                              "loc": {
                                "line": 3,
                                "col": 19
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
                                            "line": 3,
                                            "col": 25
                                          },
                                          "kind": {
                                            "ident": "url"
                                          }
                                        }
                                      },
                                      "comments": [],
                                      "is_default_inj": false
                                    }
                                  ],
                                  "trailing": []
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
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "identifier": {
                      "loc": {
                        "line": 4,
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