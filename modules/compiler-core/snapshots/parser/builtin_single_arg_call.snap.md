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
            "annotations": [],
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
                      "call": {
                        "receiver": null,
                        "callee": "sizeOf",
                        "is_builtin": true,
                        "is_tagged": false,
                        "optional": false,
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
                        ],
                        "trailing": []
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
                      "call": {
                        "receiver": null,
                        "callee": "typeName",
                        "is_builtin": true,
                        "is_tagged": false,
                        "optional": false,
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
                        ],
                        "trailing": []
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
                      "call": {
                        "receiver": null,
                        "callee": "panic",
                        "is_builtin": true,
                        "is_tagged": false,
                        "optional": false,
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
                        ],
                        "trailing": []
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