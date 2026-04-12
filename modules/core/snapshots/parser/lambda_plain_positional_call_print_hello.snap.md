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
                      "callee": "print",
                      "args": [
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 3,
                              "col": 15
                            },
                            "kind": {
                              "stringLit": "hello"
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