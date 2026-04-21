```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "doubled",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "x",
            "typeRef": {
              "named": "Int"
            },
            "typeName": "",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": {
          "named": "Int"
        },
        "body": [
          {
            "expr": {
              "controlFlow": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "binaryOp": {
                      "loc": {
                        "line": 2,
                        "col": 20
                      },
                      "kind": {
                        "add": {
                          "lhs": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 12
                              },
                              "kind": {
                                "builtinCall": {
                                  "name": "@abs",
                                  "args": [
                                    {
                                      "label": null,
                                      "value": {
                                        "identifier": {
                                          "loc": {
                                            "line": 2,
                                            "col": 17
                                          },
                                          "kind": {
                                            "ident": "x"
                                          }
                                        }
                                      },
                                      "comments": []
                                    }
                                  ]
                                }
                              }
                            }
                          },
                          "rhs": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 22
                              },
                              "kind": {
                                "builtinCall": {
                                  "name": "@abs",
                                  "args": [
                                    {
                                      "label": null,
                                      "value": {
                                        "identifier": {
                                          "loc": {
                                            "line": 2,
                                            "col": 27
                                          },
                                          "kind": {
                                            "ident": "x"
                                          }
                                        }
                                      },
                                      "comments": []
                                    }
                                  ]
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