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
        "name": "echo",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "msg",
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
          "named": "string"
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
                    "identifier": {
                      "loc": {
                        "line": 2,
                        "col": 12
                      },
                      "kind": {
                        "ident": "msg"
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
    },
    {
      "val": {
        "name": "r",
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "typeAnnotation": null,
        "value": {
          "call": {
            "loc": {
              "line": 4,
              "col": 9
            },
            "kind": {
              "call": {
                "receiver": null,
                "callee": "echo",
                "is_builtin": false,
                "is_tagged": false,
                "optional": false,
                "args": [
                  {
                    "label": null,
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 4,
                          "col": 14
                        },
                        "kind": {
                          "stringLit": "hi"
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
  ]
}
```