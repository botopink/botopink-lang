{
  "decls": [
    {
      "implement": {
        "name": "X",
        "genericParams": [],
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
                "typeName": "Self",
                "modifier": "none",
                "typeinfoConstraints": null,
                "fnType": null,
                "destruct": null
              }
            ],
            "body": [
              {
                "expr": {
                  "loc": {
                    "line": 3,
                    "col": 9
                  },
                  "kind": {
                    "case": {
                      "subject": {
                        "loc": {
                          "line": 3,
                          "col": 14
                        },
                        "kind": {
                          "ident": "n"
                        }
                      },
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
                            "loc": {
                              "line": 4,
                              "col": 26
                            },
                            "kind": {
                              "stringLit": "even"
                            }
                          }
                        },
                        {
                          "pattern": {
                            "wildcard": {}
                          },
                          "body": {
                            "loc": {
                              "line": 5,
                              "col": 21
                            },
                            "kind": {
                              "stringLit": "other"
                            }
                          }
                        }
                      ]
                    }
                  }
                }
              }
            ]
          }
        ]
      }
    }
  ]
}