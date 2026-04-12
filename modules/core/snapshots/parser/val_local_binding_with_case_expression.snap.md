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
                    "localBind": {
                      "name": "result",
                      "value": {
                        "loc": {
                          "line": 3,
                          "col": 22
                        },
                        "kind": {
                          "case": {
                            "subject": {
                              "loc": {
                                "line": 3,
                                "col": 27
                              },
                              "kind": {
                                "ident": "x"
                              }
                            },
                            "arms": [
                              {
                                "pattern": {
                                  "wildcard": {}
                                },
                                "body": {
                                  "loc": {
                                    "line": 4,
                                    "col": 21
                                  },
                                  "kind": {
                                    "stringLit": "ok"
                                  }
                                }
                              }
                            ]
                          }
                        }
                      },
                      "mutable": false
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