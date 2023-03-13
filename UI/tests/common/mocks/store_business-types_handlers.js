/* eslint-disable no-unused-vars, no-console */
import { rest } from 'msw'

export const businessTypesHandlers = [

  rest.get('/erp/api/v0/contacts/business-types', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.json({
        items: [
            { id: "1", description: "Big customer", discount: 0.05 },
            { id: "2", description: "Bigger customer", discount: 0.15 }
        ],
        _links: [{
          title : "HTML",
          rel : "download",
          href : "?format=HTML"
        }]
      })
    )
  }),

  rest.get('/erp/api/v0/contacts/business-types/2', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567890']
      }),
      ctx.json({
        id: "2",
        description: "Bigger customer",
        discount: 0.15
      })
    )
  }),

  rest.get('/erp/api/v0/contacts/business-types/3', (req, res, ctx) => {

    return res(
      ctx.status(404),
      ctx.json(
        { id: "", code: "", description: "" }
      )
    )
  }),

  rest.post('/erp/api/v0/contacts/business-types', (req, res, ctx) => {

    return res(
      ctx.status(201),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json({
        id: "3",
        description: "Great customer",
        discount: 0.22
      })
    )
  }),

  rest.put('/erp/api/v0/contacts/business-types/2', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json({
        id: "2",
        description: "Bigger customer",
        discount: 0.25
      })
    )
  })
]
