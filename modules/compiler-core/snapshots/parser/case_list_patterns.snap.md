```json
{
  "decls": [
    {
      "implement": {
        "name": "X",
        "isPub": false,
        "shorthand": false,
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
          {
            "named": "Foo"
          }
        ],
        "target": "Bar",
        "methods": [
          {
            "qualifier": null,
            "name": "run",
            "params": [
              {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "",
                "modifier": "none",
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              }
            ],
            "body": [
              {
                "expr": {
                  "collection": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "case": {
                        "subjects": [
                          {
                            "identifier": {
                              "loc": {
                                "line": 3,
                                "col": 14
                              },
                              "kind": {
                                "ident": "xs"
                              }
                            }
                          }
                        ],
                        "arms": [
                          {
                            "pattern": {
                              "list": {
                                "elems": [],
                                "spread": null
                              }
                            },
                            "body": {
                              "literal": {
                                "loc": {
                                  "line": 4,
                                  "col": 19
                                },
                                "kind": {
                                  "stringLit": "empty"
                                }
                              }
                            },
                            "guard": null,
                            "emptyLinesBefore": 0
                          },
                          {
                            "pattern": {
                              "list": {
                                "elems": [
                                  {
                                    "numberLit": "1"
                                  }
                                ],
                                "spread": null
                              }
                            },
                            "body": {
                              "literal": {
                                "loc": {
                                  "line": 5,
                                  "col": 20
                                },
                                "kind": {
                                  "stringLit": "one"
                                }
                              }
                            },
                            "guard": null,
                            "emptyLinesBefore": 0
                          },
                          {
                            "pattern": {
                              "list": {
                                "elems": [
                                  {
                                    "wildcard": {}
                                  },
                                  {
                                    "wildcard": {}
                                  }
                                ],
                                "spread": null
                              }
                            },
                            "body": {
                              "literal": {
                                "loc": {
                                  "line": 6,
                                  "col": 23
                                },
                                "kind": {
                                  "stringLit": "two"
                                }
                              }
                            },
                            "guard": null,
                            "emptyLinesBefore": 0
                          },
                          {
                            "pattern": {
                              "list": {
                                "elems": [
                                  {
                                    "bind": "first"
                                  }
                                ],
                                "spread": "rest"
                              }
                            },
                            "body": {
                              "identifier": {
                                "loc": {
                                  "line": 7,
                                  "col": 32
                                },
                                "kind": {
                                  "ident": "first"
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
                },
                "emptyLinesBefore": 0
              }
            ]
          }
        ]
      }
    }
  ]
}
```