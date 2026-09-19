```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": true,
        "isDefault": false,
        "label": null,
        "name": "emit",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "source",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "void"
        },
        "typeGuardParam": null,
        "body": []
      }
    },
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": true,
        "isDefault": false,
        "label": null,
        "name": "field",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [
          {
            "name": "T",
            "default": null
          },
          {
            "name": "F",
            "default": null
          }
        ],
        "params": [
          {
            "name": "obj",
            "typeRef": {
              "named": "T"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          },
          {
            "name": "name",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "F"
        },
        "typeGuardParam": null,
        "body": []
      }
    },
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": true,
        "isDefault": false,
        "label": null,
        "name": "quit",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [
          {
            "name": "code",
            "typeRef": {
              "named": "i32"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": {
          "named": "noreturn"
        },
        "typeGuardParam": null,
        "body": []
      }
    },
    {
      "delegate": {
        "name": "print",
        "isPub": false,
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "params": [
          {
            "name": "message",
            "typeRef": {
              "named": "string"
            },
            "typeName": "",
            "modifier": "none",
            "fnType": null,
            "destruct": null,
            "default": null
          }
        ],
        "returnType": null
      }
    },
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "main",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": {
          "named": "i32"
        },
        "typeGuardParam": null,
        "body": [
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 5,
                  "col": 20
                },
                "kind": {
                  "return": {
                    "literal": {
                      "loc": {
                        "line": 5,
                        "col": 27
                      },
                      "kind": {
                        "numberLit": "1"
                      }
                    }
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