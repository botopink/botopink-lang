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
              "comptime_": {
                "loc": {
                  "line": 2,
                  "col": 9
                },
                "kind": {
                  "assertPattern": {
                    "pattern": {
                      "variantFields": {
                        "name": "Person",
                        "bindings": [
                          "name",
                          "age"
                        ]
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
                      "call": {
                        "loc": {
                          "line": 2,
                          "col": 44
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "Person",
                            "args": [
                              {
                                "label": "name",
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 2,
                                      "col": 57
                                    },
                                    "kind": {
                                      "stringLit": "bob"
                                    }
                                  }
                                },
                                "comments": []
                              },
                              {
                                "label": "age",
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 2,
                                      "col": 69
                                    },
                                    "kind": {
                                      "numberLit": "12"
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
            },
            "emptyLinesBefore": 0
          }
        ]
      }
    }
  ]
}
```