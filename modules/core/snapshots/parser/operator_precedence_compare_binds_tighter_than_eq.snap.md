{
  "decls": [
    {
      "interface": {
        "name": "Test",
        "id": 1,
        "isPub": false,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [],
        "methods": [
          {
            "name": "run",
            "genericParams": [],
            "params": [],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "loc": {
                    "line": 3,
                    "col": 15
                  },
                  "kind": {
                    "eq": {
                      "lhs": {
                        "loc": {
                          "line": 3,
                          "col": 11
                        },
                        "kind": {
                          "lt": {
                            "lhs": {
                              "loc": {
                                "line": 3,
                                "col": 9
                              },
                              "kind": {
                                "ident": "a"
                              }
                            },
                            "rhs": {
                              "loc": {
                                "line": 3,
                                "col": 13
                              },
                              "kind": {
                                "ident": "b"
                              }
                            }
                          }
                        }
                      },
                      "rhs": {
                        "loc": {
                          "line": 3,
                          "col": 20
                        },
                        "kind": {
                          "gt": {
                            "lhs": {
                              "loc": {
                                "line": 3,
                                "col": 18
                              },
                              "kind": {
                                "ident": "c"
                              }
                            },
                            "rhs": {
                              "loc": {
                                "line": 3,
                                "col": 22
                              },
                              "kind": {
                                "ident": "d"
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
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