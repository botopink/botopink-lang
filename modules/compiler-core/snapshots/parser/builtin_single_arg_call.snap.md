```json
{
  "decls": [
    {
      "interface": {
        "name": "Test",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [],
        "trailingComma": false,
        "methods": [
          {
            "name": "run",
            "genericParams": [],
            "params": [],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "builtinCall": {
                        "name": "@sizeOf",
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "identifier": {
                                "loc": {
                                  "line": 3,
                                  "col": 17
                                },
                                "kind": {
                                  "ident": "Int"
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
                "emptyLinesBefore": 0
              },
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 4,
                      "col": 9
                    },
                    "kind": {
                      "builtinCall": {
                        "name": "@typeName",
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "identifier": {
                                "loc": {
                                  "line": 4,
                                  "col": 19
                                },
                                "kind": {
                                  "ident": "Bool"
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
                "emptyLinesBefore": 0
              },
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 5,
                      "col": 9
                    },
                    "kind": {
                      "builtinCall": {
                        "name": "@panic",
                        "args": [
                          {
                            "label": null,
                            "value": {
                              "literal": {
                                "loc": {
                                  "line": 5,
                                  "col": 16
                                },
                                "kind": {
                                  "stringLit": "unreachable"
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
                "emptyLinesBefore": 0
              }
            ],
            "is_default": true,
            "is_declare": false,
            "isPub": false
          }
        ]
      }
    }
  ]
}
```