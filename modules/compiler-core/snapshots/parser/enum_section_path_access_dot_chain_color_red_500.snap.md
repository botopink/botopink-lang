```json
{
  "decls": [
    {
      "fn": {
        "isPub": false,
        "effect": null,
        "isDeclare": false,
        "isDefault": false,
        "label": null,
        "name": "f",
        "docComment": null,
        "comment": null,
        "moduleComment": null,
        "annotations": [],
        "genericParams": [],
        "params": [],
        "returnType": {
          "named": "i32"
        },
        "body": [
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 2,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "x",
                    "value": {
                      "identifier": {
                        "loc": {
                          "line": 2,
                          "col": 24
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "identifier": {
                                "loc": {
                                  "line": 2,
                                  "col": 20
                                },
                                "kind": {
                                  "identAccess": {
                                    "receiver": {
                                      "identifier": {
                                        "loc": {
                                          "line": 2,
                                          "col": 13
                                        },
                                        "kind": {
                                          "dotIdent": "Color"
                                        }
                                      }
                                    },
                                    "member": "Red",
                                    "optional": false
                                  }
                                }
                              }
                            },
                            "member": "500",
                            "optional": false
                          }
                        }
                      }
                    },
                    "mutable": false,
                    "typeAnnotation": null
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 3,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "y",
                    "value": {
                      "identifier": {
                        "loc": {
                          "line": 3,
                          "col": 20
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "identifier": {
                                "loc": {
                                  "line": 3,
                                  "col": 18
                                },
                                "kind": {
                                  "identAccess": {
                                    "receiver": {
                                      "identifier": {
                                        "loc": {
                                          "line": 3,
                                          "col": 13
                                        },
                                        "kind": {
                                          "dotIdent": "Pad"
                                        }
                                      }
                                    },
                                    "member": "X",
                                    "optional": false
                                  }
                                }
                              }
                            },
                            "member": "4",
                            "optional": false
                          }
                        }
                      }
                    },
                    "mutable": false,
                    "typeAnnotation": null
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "binding": {
                "loc": {
                  "line": 4,
                  "col": 5
                },
                "kind": {
                  "localBind": {
                    "name": "z",
                    "value": {
                      "identifier": {
                        "loc": {
                          "line": 4,
                          "col": 24
                        },
                        "kind": {
                          "identAccess": {
                            "receiver": {
                              "identifier": {
                                "loc": {
                                  "line": 4,
                                  "col": 19
                                },
                                "kind": {
                                  "identAccess": {
                                    "receiver": {
                                      "identifier": {
                                        "loc": {
                                          "line": 4,
                                          "col": 13
                                        },
                                        "kind": {
                                          "dotIdent": "Text"
                                        }
                                      }
                                    },
                                    "member": "Size",
                                    "optional": false
                                  }
                                }
                              }
                            },
                            "member": "X3xl",
                            "optional": false
                          }
                        }
                      }
                    },
                    "mutable": false,
                    "typeAnnotation": null
                  }
                }
              }
            },
            "emptyLinesBefore": 0
          },
          {
            "expr": {
              "jump": {
                "loc": {
                  "line": 5,
                  "col": 5
                },
                "kind": {
                  "return": {
                    "literal": {
                      "loc": {
                        "line": 5,
                        "col": 12
                      },
                      "kind": {
                        "numberLit": "0"
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