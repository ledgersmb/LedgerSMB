import { rest } from 'msw'

export const gifiHandlers = [

  rest.get('/erp/api/v0/gl/gifi', (req, res, ctx) => {
  
    return res(
      ctx.status(200),
      ctx.json({
        items : [
          {
            "accno" : "0000",
            "description" : "Dummy account"
          },
          {
            "accno" : "0001",
            "description" : "Dummy account 1"
          }
        ],
        _links : [
          {
            "href" : "?format=HTML",
            "rel" : "download",
            "title" : "HTML"
          }
        ]
      }),
    )
  }),

  rest.get('/erp/api/v0/gl/gifi/0000', (req, res, ctx) => {
  
    return res(
      ctx.status(200),
      ctx.set({
        'ETag': ['1234567890']
      }),
      ctx.json({
        "accno" : "0000",
        "description" : "Dummy account"
      }),
    )
  }),

  rest.get('/erp/api/v0/gl/gifi/0002', (req, res, ctx) => {

    return res(
      ctx.status(404),
      ctx.json({
        code: "",
        description: ""
      }),
    )
  }),

  rest.post('/erp/api/v0/gl/gifi', (req, res, ctx) => {

    return res(
      ctx.status(201),
      ctx.set({
        'ETag': ['1234567891']
      }),
      ctx.json({
        accno: "0002",
        description: "Dummy account 2",
      }),
    )
  }),

  rest.put('/erp/api/v0/gl/gifi/0000', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
        'ETag': ['1234567891']
      }),
      ctx.json({
        accno: "0000",
        description: "Funny account"
      })
    )
  })

]
