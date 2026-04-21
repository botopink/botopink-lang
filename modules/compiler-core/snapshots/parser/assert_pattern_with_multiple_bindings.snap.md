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
                        "name": "Point",
                        "bindings": [
                          "x",
                          "y"
                        ]
                      }
                    },
                    "expr": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 30
                        },
                        "kind": {
                          "ident": "point"
                        }
                      }
                    },
                    "handler": {
                      "call": {
                        "loc": {
                          "line": 2,
                          "col": 42
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "Point",
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 2,
                                      "col": 48
                                    },
                                    "kind": {
                                      "numberLit": "0"
                                    }
                                  }
                                },
                                "comments": []
                              },
                              {
                                "label": null,
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 2,
                                      "col": 51
                                    },
                                    "kind": {
                                      "numberLit": "0"
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