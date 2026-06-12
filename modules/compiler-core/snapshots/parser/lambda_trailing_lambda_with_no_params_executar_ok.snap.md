```json
{
  "decls": [
    {
      "interface": {
        "name": "Test",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [],
        "trailingComma": false,
        "methods": [
          {
            "name": "run",
            "annotations": [],
            "genericParams": [],
            "params": [],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "call": {
                    "loc": {
                      "line": 3,
                      "col": 9
                    },
                    "kind": {
                      "call": {
                        "receiver": null,
                        "callee": "executar",
                        "is_builtin": false,
                        "is_tagged": false,
                        "optional": false,
                        "args": [],
                        "trailing": [
                          {
                            "label": null,
                            "params": [],
                            "body": [
                              {
                                "expr": {
                                  "identifier": {
                                    "loc": {
                                      "line": 3,
                                      "col": 20
                                    },
                                    "kind": {
                                      "ident": "ok"
                                    }
                                  }
                                },
                                "emptyLinesBefore": 0
                              }
                            ]
                          }
                        ]
                      }
                    }
                  }
                },
                "emptyLinesBefore": 0
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
```