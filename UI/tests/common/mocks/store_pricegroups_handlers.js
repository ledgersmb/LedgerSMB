/* eslint-disable no-unused-vars, no-console */
import { rest } from 'msw'

export const pricegroupHandlers = [

  rest.get('/erp/api/v0/products/pricegroups', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.json({
        items: [
          { id: "1", description: "Price group 1" },
          { id: "2", description: "Price group 2" }
        ],
        _links: [{
          title : "HTML",
          rel : "download",
          href : "?format=HTML"
        }]
      }),
    )
  }),

  rest.get('/erp/api/v0/products/pricegroups/1', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567890']
      }),
      ctx.json(
        { id: "1", description: "Price group 1" },
        ),
    )
  }),

  rest.get('/erp/api/v0/products/pricegroups/3', (req, res, ctx) => {

    return res(
      ctx.status(404),
      ctx.json(
          { id: "", description: "" }
        ),
    )
  }),

  rest.post('/erp/api/v0/products/pricegroups', (req, res, ctx) => {

    return res(
      ctx.status(201),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json({
        id: "3",
        description: "Price Group #3",
      }),
    )
  }),

  rest.put('/erp/api/v0/products/pricegroups/1', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json(
        { id: "1", description: "Price Group #1" }
      )
    )
  })
]