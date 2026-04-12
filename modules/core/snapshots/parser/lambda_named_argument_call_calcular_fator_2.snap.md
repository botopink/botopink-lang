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
                      "receiver": null,
                      "callee": "calcular",
                      "args": [
                        {
                          "label": "fator",
                          "value": {
                            "loc": {
                              "line": 3,
                              "col": 25
                            },
                            "kind": {
                              "numberLit": "2"
                            }
                          }
                        }
                      ],
                      "trailing": []
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