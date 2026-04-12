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
                    "col": 11
                  },
                  "kind": {
                    "lt": {
                      "lhs": {
                        "loc": {
                          "line": 3,
                          "col": 9
                        },
                        "kind": {
                          "ident": "a"
                        }
                      },
                      "rhs": {
                        "loc": {
                          "line": 3,
                          "col": 13
                        },
                        "kind": {
                          "ident": "b"
                        }
                      }
                    }
                  }
                }
              },
              {
                "expr": {
                  "loc": {
                    "line": 4,
                    "col": 11
                  },
                  "kind": {
                    "gt": {
                      "lhs": {
                        "loc": {
                          "line": 4,
                          "col": 9
                        },
                        "kind": {
                          "ident": "a"
                        }
                      },
                      "rhs": {
                        "loc": {
                          "line": 4,
                          "col": 13
                        },
                        "kind": {
                          "ident": "b"
                        }
                      }
                    }
                  }
                }
              },
              {
                "expr": {
                  "loc": {
                    "line": 5,
                    "col": 11
                  },
                  "kind": {
                    "lte": {
                      "lhs": {
                        "loc": {
                          "line": 5,
                          "col": 9
                        },
                        "kind": {
                          "ident": "a"
                        }
                      },
                      "rhs": {
                        "loc": {
                          "line": 5,
                          "col": 14
                        },
                        "kind": {
                          "ident": "b"
                        }
                      }
                    }
                  }
                }
              },
              {
                "expr": {
                  "loc": {
                    "line": 6,
                    "col": 11
                  },
                  "kind": {
                    "gte": {
                      "lhs": {
                        "loc": {
                          "line": 6,
                          "col": 9
                        },
                        "kind": {
                          "ident": "a"
                        }
                      },
                      "rhs": {
                        "loc": {
                          "line": 6,
                          "col": 14
                        },
                        "kind": {
                          "ident": "b"
                        }
                      }
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