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
        "annotations": [
          {
            "name": "future",
            "args": [],
            "is_builtin": true
          }
        ],
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
            "default": null
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
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "call": {
                      "loc": {
                        "line": 3,
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
                                    "line": 3,
                                    "col": 21
                                  },
                                  "kind": {
                                    "ident": "url"
                                  }
                                }
                              },
                              "comments": [],
                              "is_default_inj": false
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