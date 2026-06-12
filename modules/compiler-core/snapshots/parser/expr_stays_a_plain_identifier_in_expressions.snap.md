```json
{
  "decls": [
    {
      "val": {
        "name": "expr",
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "typeAnnotation": null,
        "value": {
          "literal": {
            "loc": {
              "line": 1,
              "col": 12
            },
            "kind": {
              "numberLit": "1"
            }
          }
        }
      }
    },
    {
      "val": {
        "name": "y",
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "typeAnnotation": null,
        "value": {
          "binaryOp": {
            "loc": {
              "line": 2,
              "col": 14
            },
            "op": "add",
            "lhs": {
              "identifier": {
                "loc": {
                  "line": 2,
                  "col": 9
                },
                "kind": {
                  "ident": "expr"
                }
              }
            },
            "rhs": {
              "literal": {
                "loc": {
                  "line": 2,
                  "col": 16
                },
                "kind": {
                  "numberLit": "2"
                }
              }
            }
          }
        }
      }
    }
  ]
}
```