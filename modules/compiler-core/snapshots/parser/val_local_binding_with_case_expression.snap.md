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
                  "binding": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "localBind": {
                        "name": "result",
                        "value": {
                          "collection": {
                            "loc": {
                              "line": 3,
                              "col": 22
                            },
                            "kind": {
                              "case": {
                                "subjects": [
                                  {
                                    "identifier": {
                                      "loc": {
                                        "line": 3,
                                        "col": 27
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
                                      "literal": {
                                        "loc": {
                                          "line": 4,
                                          "col": 18
                                        },
                                        "kind": {
                                          "stringLit": "ok"
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
                        "mutable": false,
                        "typeAnnotation": null
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