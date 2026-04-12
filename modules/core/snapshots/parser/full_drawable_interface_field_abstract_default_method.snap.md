{
  "decls": [
    {
      "interface": {
        "name": "Drawable",
        "id": 1,
        "isPub": false,
        "annotations": [],
        "genericParams": [],
        "extends": [],
        "fields": [
          {
            "name": "color",
            "typeName": "string"
          }
        ],
        "methods": [
          {
            "name": "draw",
            "genericParams": [],
            "params": [
              {
                "name": "self",
                "typeName": "Self",
                "modifier": "none",
                "typeinfoConstraints": null,
                "fnType": null,
                "destruct": null
              }
            ],
            "returnType": null,
            "body": null,
            "is_default": false,
            "is_declare": false,
            "isPub": false
          },
          {
            "name": "log",
            "genericParams": [],
            "params": [
              {
                "name": "self",
                "typeName": "Self",
                "modifier": "none",
                "typeinfoConstraints": null,
                "fnType": null,
                "destruct": null
              }
            ],
            "returnType": null,
            "body": [
              {
                "expr": {
                  "loc": {
                    "line": 5,
                    "col": 9
                  },
                  "kind": {
                    "call": {
                      "receiver": "Console",
                      "callee": "WriteLine",
                      "args": [
                        {
                          "label": null,
                          "value": {
                            "loc": {
                              "line": 5,
                              "col": 59
                            },
                            "kind": {
                              "add": {
                                "lhs": {
                                  "loc": {
                                    "line": 5,
                                    "col": 27
                                  },
                                  "kind": {
                                    "stringLit": "Rendering object with color: "
                                  }
                                },
                                "rhs": {
                                  "loc": {
                                    "line": 5,
                                    "col": 61
                                  },
                                  "kind": {
                                    "identAccess": {
                                      "receiver": {
                                        "loc": {
                                          "line": 5,
                                          "col": 61
                                        },
                                        "kind": {
                                          "ident": "self"
                                        }
                                      },
                                      "member": "color"
                                    }
                                  }
                                }
                              }
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