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
                      "call": {
                        "receiver": null,
                        "callee": "calcular",
                        "args": [
                          {
                            "label": "fator",
                            "value": {
                              "literal": {
                                "loc": {
                                  "line": 3,
                                  "col": 25
                                },
                                "kind": {
                                  "numberLit": "2"
                                }
                              }
                            },
                            "comments": []
                          }
                        ],
                        "trailing": [
                          {
                            "label": null,
                            "params": [
                              "a",
                              "b"
                            ],
                            "body": [
                              {
                                "expr": {
                                  "binaryOp": {
                                    "loc": {
                                      "line": 4,
                                      "col": 15
                                    },
                                    "kind": {
                                      "add": {
                                        "lhs": {
                                          "identifier": {
                                            "loc": {
                                              "line": 4,
                                              "col": 13
                                            },
                                            "kind": {
                                              "ident": "a"
                                            }
                                          }
                                        },
                                        "rhs": {
                                          "identifier": {
                                            "loc": {
                                              "line": 4,
                                              "col": 17
                                            },
                                            "kind": {
                                              "ident": "b"
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