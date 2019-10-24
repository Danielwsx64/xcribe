
path:
 verbo:
 sumario: do verbo
 descrição: do verbo
 parametros:
  [ nome:, in:[path, query, header, cookie], required:, description:, schema: {type: }  ]
 request_body:
  required: true,
  content:
   application/json
     schema:
      type: object,
      properties:
        username:
          type: string
          example: "daniel"
 responses:
   '200':
      description: A user object.
        content:
          application/json:
            schema:
              type: object
              properties:
                id:
                  type: integer
                  format: int64
                  example: 4
                name:
                  type: string
                  example: Jessica Smith
