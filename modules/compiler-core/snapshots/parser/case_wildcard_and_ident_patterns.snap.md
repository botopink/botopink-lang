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
                                "ident": "x"
                              }
                            }
                          }
                        ],
                        "arms": [
                          {
                            "pattern": {
                              "wildcard": {}
                            },
                            "body": {
                              "identifier": {
                                "loc": {
                                  "line": 4,
                                  "col": 18
                                },
                                "kind": {
                                  "ident": "y"
                                }
                              }
                            },
                            "emptyLinesBefore": 0
                          },
                          {
                            "pattern": {
                              "ident": "Red"
                            },
                            "body": {
                              "identifier": {
                                "loc": {
                                  "line": 5,
                                  "col": 20
                                },
                                "kind": {
                                  "ident": "z"
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