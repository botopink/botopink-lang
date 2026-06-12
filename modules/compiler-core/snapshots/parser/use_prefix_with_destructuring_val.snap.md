```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
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
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBindDestruct": {
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
                      "useHook": {
                        "loc": {
                          "line": 2,
                          "col": 29
                        },
                        "kind": {
                          "inner": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 33
                              },
                              "kind": {
                                "call": {
                                  "receiver": null,
                                  "callee": "state",
                                  "is_builtin": false,
                                  "is_tagged": false,
                                  "optional": false,
                                  "args": [
                                    {
                                      "label": null,
                                      "value": {
                                        "literal": {
                                          "loc": {
                                            "line": 2,
                                            "col": 39
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
                    },
                    "mutable": false
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