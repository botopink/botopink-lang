```json
{
  "decls": [
    {
      "val": {
        "name": "component",
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "typeAnnotation": null,
        "value": {
          "call": {
            "loc": {
              "line": 1,
              "col": 17
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
                          "line": 3,
                          "col": 22
                        },
                        "kind": {
                          "stringTemplate": {
                            "multiline": true,
                            "parts": [
                              {
                                "text": "\n<Button label="
                              },
                              {
                                "expr": {
                                  "identifier": {
                                    "loc": {
                                      "line": 1,
                                      "col": 1
                                    },
                                    "kind": {
                                      "ident": "title"
                                    }
                                  }
                                }
                              },
                              {
                                "text": "></Button>\n"
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