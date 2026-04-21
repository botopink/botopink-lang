```json
{
  "decls": [
    {
      "implement": {
        "name": "X",
        "genericParams": [],
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "interfaces": [
          "Foo"
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
                "typeinfoConstraints": null,
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
                                "col": 15
                              },
                              "kind": {
                                "identAccess": {
                                  "receiver": {
                                    "identifier": {
                                      "loc": {
                                        "line": 3,
                                        "col": 15
                                      },
                                      "kind": {
                                        "ident": "self"
                                      }
                                    }
                                  },
                                  "member": "color"
                                }
                              }
                            }
                          }
                        ],
                        "arms": [
                          {
                            "pattern": {
                              "ident": "Red"
                            },
                            "body": {
                              "literal": {
                                "loc": {
                                  "line": 4,
                                  "col": 20
                                },
                                "kind": {
                                  "stringLit": "red"
                                }
                              }
                            },
                            "emptyLinesBefore": 0
                          },
                          {
                            "pattern": {
                              "variantFields": {
                                "name": "Rgb",
                                "bindings": [
                                  "r",
                                  "g",
                                  "b"
                                ]
                              }
                            },
                            "body": {
                              "literal": {
                                "loc": {
                                  "line": 5,
                                  "col": 29
                                },
                                "kind": {
                                  "stringLit": "rgb"
                                }
                              }
                            },
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