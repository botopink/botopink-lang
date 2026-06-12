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
        "name": "main",
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
                    "name": "s",
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 2,
                          "col": 22
                        },
                        "kind": {
                          "stringLit": "abc"
                        }
                      }
                    },
                    "mutable": false,
                    "typeAnnotation": {
                      "optional": {
                        "named": "string"
                      }
                    }
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "up",
                    "value": {
                      "call": {
                        "loc": {
                          "line": 3,
                          "col": 17
                        },
                        "kind": {
                          "call": {
                            "receiver": {
                              "identifier": {
                                "loc": {
                                  "line": 3,
                                  "col": 14
                                },
                                "kind": {
                                  "ident": "s"
                                }
                              }
                            },
                            "callee": "to_upper",
                            "is_builtin": false,
                            "is_tagged": false,
                            "optional": true,
                            "args": [],
                            "trailing": []
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