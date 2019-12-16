defmodule Xcribe.SwaggerExamples do
  defmacro __using__(_opts \\ []) do
    quote do
      alias Xcribe.Request

      @sample_swagger_output """
      {
        "openapi": "3.0.0",
        "info": {
          "title": "Basic API",
          "version": "0.1.0",
          "description": "The description of the API"
        },
        "security": [
          {
            "api_key": []
          }
        ],
        "paths": {
          "/users/{users_id}/posts/{id}": {
            "get": {
              "summary": "",
              "description": "",
              "parameters": [
                {
                  "name": "users_id",
                  "in": "path",
                  "description": "",
                  "required": true,
                  "schema": {
                    "type": "string"
                  }
                },
                {
                  "name": "id",
                  "in": "path",
                  "description": "",
                  "required": true,
                  "schema": {
                    "type": "string"
                  }
                }
              ],
              "security": [
                {
                  "api_key": []
                }
              ],
              "responses": {
                "200": {
                  "description": "get all user posts",
                  "headers": {
                    "cache-control": {
                      "schema": {
                        "type": "string"
                      }
                    },
                    "content-type": {
                      "schema": {
                        "type": "string"
                      }
                    }
                  },
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "object",
                        "properties": {
                          "id": {
                            "type": "integer",
                            "description": ""
                          },
                          "title": {
                            "type": "string",
                            "description": ""
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          "/users": {
            "get": {
              "summary": "",
              "description": "",
              "security": [
                {
                  "api_key": []
                }
              ],
              "responses": {
                "200": {
                  "description": "get all users",
                  "headers": {
                    "cache-control": {
                      "schema": {
                        "type": "string"
                      }
                    },
                    "content-type": {
                      "schema": {
                        "type": "string"
                      }
                    }
                  },
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "properties": {
                            "id": {
                              "type": "integer",
                              "description": ""
                            },
                            "name": {
                              "type": "string",
                              "description": ""
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            },
            "post": {
              "summary": "",
              "description": "",
              "security": [
                {
                  "api_key": []
                }
              ],
              "requestBody": {
                "required": true,
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "properties": {
                        "age": {
                          "type": "integer",
                          "description": ""
                        },
                        "name": {
                          "type": "string",
                          "description": ""
                        }
                      }
                    }
                  }
                }
              },
              "responses": {
                "201": {
                  "description": "create an user",
                  "headers": {
                    "cache-control": {
                      "schema": {
                        "type": "string"
                      }
                    },
                    "content-type": {
                      "schema": {
                        "type": "string"
                      }
                    }
                  },
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "object",
                        "properties": {
                          "age": {
                            "type": "integer",
                            "description": ""
                          },
                          "name": {
                            "type": "string",
                            "description": ""
                          }
                        }
                      }
                    }
                  }
                },
                "400": {
                  "description": "invalid parameters",
                  "headers": {
                    "cache-control": {
                      "schema": {
                        "type": "string"
                      }
                    },
                    "content-type": {
                      "schema": {
                        "type": "string"
                      }
                    }
                  },
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "object",
                        "properties": {
                          "message": {
                            "type": "string",
                            "description": ""
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          "/monitoring/": {
            "get": {
              "summary": "",
              "description": "",
              "security": [
                {
                  "api_key": []
                }
              ],
              "responses": {
                "200": {
                  "description": "get monitoring info",
                  "headers": {
                    "content-type": {
                      "schema": {
                        "type": "string"
                      }
                    }
                  },
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "properties": {
                            "status": {
                              "type": "string",
                              "description": ""
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          "/server/{server_id}/protocols": {
            "post": {
              "summary": "",
              "description": "Application protocols is a awesome feature of our app",
              "security": [
                {
                  "api_key": []
                }
              ],
              "parameters": [
                {
                  "name": "server_id",
                  "in": "path",
                  "description": "The id number of the server",
                  "required": true,
                  "schema": {
                    "type": "integer"
                  }
                }
              ],
              "requestBody": {
                "required": true,
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "properties": {
                        "priority": {
                          "type": "integer",
                          "description": "the priority of the protocol. It could be 0 or 1"
                        },
                        "name": {
                          "type": "string",
                          "description": "The protocol full name"
                        }
                      }
                    }
                  }
                }
              },
              "responses": {
                "201": {
                  "description": "create the protocol",
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "object",
                        "properties": {
                          "id": {
                            "type": "integer",
                            "description": ""
                          },
                          "name": {
                            "type": "string",
                            "description": ""
                          }
                        }
                      }
                    }
                  },
                  "headers": {
                    "content-type": {
                      "schema": {
                        "type": "string"
                      }
                    }
                  }
                }
              }
            }
          },
          "/server/{server_id}/protocols/{id}": {
            "get": {
              "summary": "You can show a protocol with show action",
              "description": "Application protocols is a awesome feature of our app",
              "security": [
                {
                  "api_key": []
                }
              ],
              "parameters": [
                {
                  "name": "server_id",
                  "in": "path",
                  "description": "The id number of the server",
                  "required": true,
                  "schema": {
                    "type": "integer"
                  }
                },
                {
                  "name": "id",
                  "in": "path",
                  "description": "the number id of the protocol",
                  "required": true,
                  "schema": {
                    "type": "integer"
                  }
                }
              ],
              "responses": {
                "200": {
                  "description": "show the protocol",
                  "content": {
                    "application/json": {
                      "schema": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "properties": {
                            "id": {
                              "type": "integer",
                              "description": ""
                            },
                            "name": {
                              "type": "string",
                              "description": ""
                            }
                          }
                        }
                      }
                    }
                  },
                  "headers": {
                    "content-type": {
                      "schema": {
                        "type": "string"
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      """
    end
  end
end
