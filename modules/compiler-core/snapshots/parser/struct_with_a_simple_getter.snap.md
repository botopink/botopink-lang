```json
{
  "decls": [
    {
      "struct": {
        "name": "Account",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "members": [
          {
            "getter": {
              "name": "balance",
              "selfParam": {
                "name": "self",
                "typeRef": {
                  "named": "Self"
                },
                "typeName": "Self",
                "modifier": "none",
                "fnType": null,
                "destruct": null,
                "defaultVal": null
              },
              "returnType": "number",
              "body": [
                {
                  "expr": {
                    "jump": {
                      "loc": {
                        "line": 3,
                        "col": 9
                      },
                      "kind": {
                        "return": {
                          "identifier": {
                            "loc": {
                              "line": 3,
                              "col": 21
                            },
                            "kind": {
                              "identAccess": {
                                "receiver": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 16
                                    },
                                    "kind": {
                                      "ident": "self"
                                    }
                                  }
                                },
                                "member": "_balance",
                                "optional": false
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
        ],
        "trailingComma": false
      }
    }
  ]
}
```