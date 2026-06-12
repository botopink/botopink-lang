```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": "future",
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "fetch",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "url",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "defaultVal": null
          }
        ],
        "returnType": {
          "generic": {
            "name": "Future",
            "args": [
              {
                "named": "Response"
              }
            ],
            "is_builtin": true
          }
        },
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "call": {
                      "loc": {
                        "line": 2,
                        "col": 12
                      },
                      "kind": {
                        "call": {
                          "receiver": null,
                          "callee": "download",
                          "is_builtin": false,
                          "is_tagged": false,
                          "optional": false,
                          "args": [
                            {
                              "label": null,
                              "value": {
                                "identifier": {
                                  "loc": {
                                    "line": 2,
                                    "col": 21
                                  },
                                  "kind": {
                                    "ident": "url"
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
            "emptyLinesBefore": 0
          }
        ]
      }
    }
  ]
}
```