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
        "name": "describe",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "x",
            "typeRef": {
              "optional": {
                "named": "i32"
              }
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "string"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "collection": {
                      "loc": {
                        "line": 2,
                        "col": 12
                      },
                      "kind": {
                        "case": {
                          "subjects": [
                            {
                              "identifier": {
                                "loc": {
                                  "line": 2,
                                  "col": 17
                                },
                                "kind": {
                                  "ident": "x"
                                }
                              }
                            }
                          ],
                          "arms": [
                            {
                              "pattern": {
                                "ident": "null"
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 2,
                                    "col": 28
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "literal": {
                                            "loc": {
                                              "line": 2,
                                              "col": 28
                                            },
                                            "kind": {
                                              "stringLit": "absent"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
                                  }
                                }
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            },
                            {
                              "pattern": {
                                "ident": "v"
                              },
                              "body": {
                                "function": {
                                  "loc": {
                                    "line": 2,
                                    "col": 43
                                  },
                                  "kind": {
                                    "syntax": "lambda",
                                    "params": [],
                                    "body": [
                                      {
                                        "expr": {
                                          "literal": {
                                            "loc": {
                                              "line": 2,
                                              "col": 43
                                            },
                                            "kind": {
                                              "stringLit": "present"
                                            }
                                          }
                                        },
                                        "emptyLinesBefore": 0
                                      }
                                    ]
                                  }
                                }
                              },
                              "guard": null,
                              "emptyLinesBefore": 0
                            }
                          ],
                          "trailingComments": []
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