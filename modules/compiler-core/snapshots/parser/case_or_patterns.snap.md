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
                                "col": 14
                              },
                              "kind": {
                                "ident": "n"
                              }
                            }
                          }
                        ],
                        "arms": [
                          {
                            "pattern": {
                              "or": [
                                {
                                  "numberLit": "2"
                                },
                                {
                                  "numberLit": "4"
                                },
                                {
                                  "numberLit": "6"
                                }
                              ]
                            },
                            "body": {
                              "literal": {
                                "loc": {
                                  "line": 4,
                                  "col": 26
                                },
                                "kind": {
                                  "stringLit": "even"
                                }
                              }
                            },
                            "emptyLinesBefore": 0
                          },
                          {
                            "pattern": {
                              "wildcard": {}
                            },
                            "body": {
                              "literal": {
                                "loc": {
                                  "line": 5,
                                  "col": 18
                                },
                                "kind": {
                                  "stringLit": "other"
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