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
                      "callee": "executar",
                      "args": [],
                      "trailing": [
                        {
                          "label": null,
                          "params": [],
                          "body": [
                            {
                              "expr": {
                                "loc": {
                                  "line": 3,
                                  "col": 20
                                },
                                "kind": {
                                  "ident": "ok"
                                }
                              }
                            }
                          ]
                        },
                        {
                          "label": "erro",
                          "params": [],
                          "body": [
                            {
                              "expr": {
                                "loc": {
                                  "line": 3,
                                  "col": 34
                                },
                                "kind": {
                                  "ident": "fail"
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