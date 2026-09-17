```json
{
  "decls": [
    {
      "comment": {
        "text": "module header",
        "is_module": true,
        "is_doc": false
      }
    },
    {
      "comment": {
        "text": "documents the record",
        "is_module": false,
        "is_doc": true
      }
    },
    {
      "comment": {
        "text": "a plain note",
        "is_module": false,
        "is_doc": false
      }
    },
    {
      "type_": {
        "name": "Point",
        "id": 1,
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "implement": [],
        "shape": {
          "record": [
            {
              "name": "x",
              "typeRef": {
                "named": "i32"
              },
              "default": null,
              "annotations": []
            }
          ]
        },
        "trailingComma": false,
        "methods": []
      }
    },
    {
      "comment": {
        "text": "documents the fn",
        "is_module": false,
        "is_doc": true
      }
    },
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "go",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": null,
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "literal": {
                "loc": {
                  "line": 8,
                  "col": 5
                },
                "kind": {
                  "comment": {
                    "kind": {
                      "normal": ""
                    },
                    "text": "inside the body"
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "call": {
                "loc": {
                  "line": 9,
                  "col": 5
                },
                "kind": {
                  "call": {
                    "receiver": null,
                    "callee": "todo",
                    "is_builtin": true,
                    "is_tagged": false,
                    "optional": false,
                    "args": [],
                    "trailing": []
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          }
        ]
      }
    }
  ]
}
```