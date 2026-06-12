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
              "comptime_": {
                "loc": {
                  "line": 2,
                  "col": 9
                },
                "kind": {
                  "assertPattern": {
                    "pattern": {
                      "variant": {
                        "name": "Person",
                        "payload": {
                          "fields": [
                            "name",
                            "age"
                          ]
                        }
                      }
                    },
                    "expr": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 36
                        },
                        "kind": {
                          "ident": "r"
                        }
                      }
                    },
                    "handler": {
                      "jump": {
                        "loc": {
                          "line": 2,
                          "col": 44
                        },
                        "kind": {
                          "throw_": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 50
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
                                            "col": 56
                                          },
                                          "kind": {
                                            "stringLit": "is not person"
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
            "emptyLinesBefore": 0
          }
        ]
      }
    }
  ]
}
```