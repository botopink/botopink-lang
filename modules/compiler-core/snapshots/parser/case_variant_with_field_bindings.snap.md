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
                                "col": 20
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
                                  "member": "color",
                                  "optional": false
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
                            "guard": null,
                            "emptyLinesBefore": 0
                          },
                          {
                            "pattern": {
                              "variant": {
                                "name": "Rgb",
                                "payload": {
                                  "fields": [
                                    "r",
                                    "g",
                                    "b"
                                  ]
                                }
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