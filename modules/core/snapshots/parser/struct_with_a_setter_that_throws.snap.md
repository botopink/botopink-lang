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
            "setter": {
              "name": "balance",
              "params": [
                {
                  "name": "self",
                  "typeName": "Self",
                  "modifier": "none",
                  "typeinfoConstraints": null,
                  "fnType": null,
                  "destruct": null
                },
                {
                  "name": "value",
                  "typeName": "number",
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
                      "throw_": {
                        "loc": {
                          "line": 3,
                          "col": 15
                        },
                        "kind": {
                          "call": {
                            "receiver": null,
                            "callee": "Error",
                            "args": [
                              {
                                "label": "msg",
                                "value": {
                                  "loc": {
                                    "line": 3,
                                    "col": 26
                                  },
                                  "kind": {
                                    "stringLit": "Saldo nao pode ser negativo"
                                  }
                                }
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
          }
        ]
      }
    }
  ]
}