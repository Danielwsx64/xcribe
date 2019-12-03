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
        "paths": {
          "/users/{users_id}/posts/{id}": {
            "get": {
              "description": "get all user posts",
              "parameters": [
                {
                  "name": "users_id",
                  "in": "path",
                  "required": true,
                  "schema": {
                    "type": "string"
                  }
                },
                {
                  "name": "id",
                  "in": "path",
                  "required": true,
                  "schema": {
                    "type": "string"
                  }
                }
              ],
              "responses": {
                "200": {
                  "description": "Success",
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
                            "type": "integer"
                          },
                          "title": {
                            "type": "string"
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
              "description": "get all users",
              "responses": {
                "200": {
                  "description": "Success",
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
                              "type": "integer"
                            },
                            "name": {
                              "type": "string"
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
              "description": "create an user",
              "requestBody": {
                "required": true,
                "content": {
                  "application/json": {
                    "schema": {
                      "type": "object",
                      "properties": {
                        "age": {
                          "type": "integer"
                        },
                        "name": {
                          "type": "string"
                        }
                      }
                    }
                  }
                }
              },
              "responses": {
                "201": {
                  "description": "Success",
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
                            "type": "integer"
                          },
                          "name": {
                            "type": "string"
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
              "description": "get monitoring info",
              "responses": {
                "200": {
                  "description": "Success",
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
          }
        }
      }
      """
    end
  end
end
