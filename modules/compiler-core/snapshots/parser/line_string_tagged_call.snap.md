```json
{
  "decls": [
    {
      "val": {
        "name": "page",
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "typeAnnotation": null,
        "value": {
          "call": {
            "loc": {
              "line": 1,
              "col": 12
            },
            "kind": {
              "call": {
                "receiver": null,
                "callee": "html",
                "is_builtin": false,
                "is_tagged": true,
                "optional": false,
                "args": [
                  {
                    "label": null,
                    "value": {
                      "literal": {
                        "loc": {
                          "line": 4,
                          "col": 5
                        },
                        "kind": {
                          "stringTemplate": {
                            "multiline": true,
                            "parts": [
                              {
                                "text": "<div>\n  <p>"
                              },
                              {
                                "expr": {
                                  "identifier": {
                                    "loc": {
                                      "line": 1,
                                      "col": 1
                                    },
                                    "kind": {
                                      "ident": "name"
                                    }
                                  }
                                }
                              },
                              {
                                "text": "</p>\n</div>"
                              }
                            ]
                          }
                        }
                      }
                    },
                    "comments": []
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
```