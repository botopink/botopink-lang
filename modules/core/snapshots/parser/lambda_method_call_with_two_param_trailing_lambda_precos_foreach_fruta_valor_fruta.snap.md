{
  "decls": [
    {
      "interface": {
        "name": "Test",
        "id": 1,
        "isPub": false,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [],
        "methods": [
          {
            "name": "run",
            "genericParams": [],
            "params": [],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "loc": {
                    "line": 3,
                    "col": 9
                  },
                  "kind": {
                    "call": {
                      "receiver": "precos",
                      "callee": "forEach",
                      "args": [],
                      "trailing": [
                        {
                          "label": null,
                          "params": [
                            "fruta",
                            "valor"
                          ],
                          "body": [
                            {
                              "expr": {
                                "loc": {
                                  "line": 3,
                                  "col": 42
                                },
                                "kind": {
                                  "ident": "fruta"
                                }
                              }
                            }
                          ]
                        }
                      ]
                    }
                  }
                }
              }
            ],
            "is_default": true,
            "is_declare": false,
            "isPub": false
          }
        ]
      }
    }
  ]
}