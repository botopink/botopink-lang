{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "doubled",
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "x",
            "typeName": "Int",
            "modifier": "none",
            "typeinfoConstraints": null,
            "fnType": null,
            "destruct": null
          }
        ],
        "returnType": {
          "named": "Int"
        },
        "body": [
          {
            "expr": {
              "loc": {
                "line": 2,
                "col": 5
              },
              "kind": {
                "return": {
                  "loc": {
                    "line": 2,
                    "col": 20
                  },
                  "kind": {
                    "add": {
                      "lhs": {
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
                                  "loc": {
                                    "line": 2,
                                    "col": 17
                                  },
                                  "kind": {
                                    "ident": "x"
                                  }
                                }
                              }
                            ]
                          }
                        }
                      },
                      "rhs": {
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
                                  "loc": {
                                    "line": 2,
                                    "col": 27
                                  },
                                  "kind": {
                                    "ident": "x"
                                  }
                                }
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
        ]
      }
    }
  ]
}