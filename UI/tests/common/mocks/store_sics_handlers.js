/* eslint-disable no-unused-vars, no-console */
import { rest } from 'msw'

export const sicsHandlers = [

  rest.get('/erp/api/v0/contacts/sic', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.json({
        items: [
          { code: "541330", description: "Engineering service" },
          { code: "611430", description: "Professional and management development training" }
        ],
        _links: [{
          title : "HTML",
          rel : "download",
          href : "?format=HTML"
        }]
      }),
    )
  }),

  rest.get('/erp/api/v0/contacts/sic/541330', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567890']
      }),
      ctx.json(
        { code: "541330", description: "Engineering service" }
        ),
    )
  }),

  rest.get('/erp/api/v0/contacts/sic/541510', (req, res, ctx) => {

    return res(
      ctx.status(404),
      ctx.json(
          { code: "", description: "" }
        ),
    )
  }),

  rest.post('/erp/api/v0/contacts/sic', (req, res, ctx) => {

    return res(
      ctx.status(201),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json({
        code: "541510",
        description: "Design of computer systems",
      }),
    )
  }),

  rest.put('/erp/api/v0/contacts/sic/541330', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json(
        {
          code: "541330",
          description: "Engineering services"
        }
      )
    )
  })
]