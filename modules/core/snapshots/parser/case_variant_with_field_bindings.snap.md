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
                          "col": 15
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "loc": {
                                "line": 3,
                                "col": 15
                              },
                              "kind": {
                                "ident": "self"
                              }
                            },
                            "member": "color"
                          }
                        }
                      },
                      "arms": [
                        {
                          "pattern": {
                            "ident": "Red"
                          },
                          "body": {
                            "loc": {
                              "line": 4,
                              "col": 20
                            },
                            "kind": {
                              "stringLit": "red"
                            }
                          }
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
                            "loc": {
                              "line": 5,
                              "col": 29
                            },
                            "kind": {
                              "stringLit": "rgb"
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