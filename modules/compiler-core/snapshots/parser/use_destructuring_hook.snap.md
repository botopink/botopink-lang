```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "App",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": null,
        "body": [
          {
            "expr": {
              "useHook": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "useBindDestruct": {
                    "pattern": {
                      "names": {
                        "fields": [
                          {
                            "field_name": "count",
                            "bind_name": "count"
                          },
                          {
                            "field_name": "setCount",
                            "bind_name": "setCount"
                          }
                        ],
                        "hasSpread": false
                      }
                    },
                    "value": {
                      "call": {
                        "loc": {
                          "line": 2,
                          "col": 29
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "state",
                            "is_builtin": false,
                            "args": [
                              {
                                "label": null,
                                "value": {
                                  "literal": {
                                    "loc": {
                                      "line": 2,
                                      "col": 35
                                    },
                                    "kind": {
                                      "numberLit": "0"
                                    }
                                  }
                                },
                                "comments": []
                              }
                            ],
                            "trailing": []
                          }
                        }
                      }
                    }
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          }
        ]
      }
    }
  ]
}
```