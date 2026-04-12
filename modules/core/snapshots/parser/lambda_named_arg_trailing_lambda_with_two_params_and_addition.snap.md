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
                      "trailing": [
                        {
                          "label": null,
                          "params": [
                            "a",
                            "b"
                          ],
                          "body": [
                            {
                              "expr": {
                                "loc": {
                                  "line": 4,
                                  "col": 15
                                },
                                "kind": {
                                  "add": {
                                    "lhs": {
                                      "loc": {
                                        "line": 4,
                                        "col": 13
                                      },
                                      "kind": {
                                        "ident": "a"
                                      }
                                    },
                                    "rhs": {
                                      "loc": {
                                        "line": 4,
                                        "col": 17
                                      },
                                      "kind": {
                                        "ident": "b"
                                      }
                                    }
                                  }
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