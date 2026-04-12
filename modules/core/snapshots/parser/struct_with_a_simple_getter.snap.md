{
  "decls": [
    {
      "struct": {
        "name": "Account",
        "id": 1,
        "isPub": false,
        "annotations": [],
        "genericParams": [],
        "members": [
          {
            "getter": {
              "name": "balance",
              "selfParam": {
                "name": "self",
                "typeName": "Self",
                "modifier": "none",
                "typeinfoConstraints": null,
                "fnType": null,
                "destruct": null
              },
              "returnType": "number",
              "body": [
                {
                  "expr": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "return": {
                        "loc": {
                          "line": 3,
                          "col": 16
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "loc": {
                                "line": 3,
                                "col": 16
                              },
                              "kind": {
                                "ident": "self"
                              }
                            },
                            "member": "_balance"
                          }
                        }
                      }
                    }
                  }
                }
              ]
            }
          }
        ]
      }
    }
  ]
}