```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "name": "f",
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
                  "localBind": {
                    "name": "x",
                    "value": {
                      "controlFlow": {
                        "loc": {
                          "line": 2,
                          "col": 13
                        },
                        "kind": {
                          "try_": {
                            "call": {
                              "loc": {
                                "line": 2,
                                "col": 17
                              },
                              "kind": {
                                "call": {
                                  "receiver": null,
                                  "callee": "fetch",
                                  "args": [],
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