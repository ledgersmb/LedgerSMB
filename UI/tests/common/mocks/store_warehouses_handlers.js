/* eslint-disable no-unused-vars, no-console */
import { rest } from 'msw'

export const warehousesHandlers = [

  rest.get('/erp/api/v0/products/warehouses', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.json({
        items: [
          { id: "1", description: "Modern warehouse" },
          { id: "2", description: "Huge warehouse" },
          { id: "3", description: "Moon warehouse" },
      ],
        _links: [{
          title : "HTML",
          rel : "download",
          href : "?format=HTML"
        }]
      }),
    )
  }),

  rest.get('/erp/api/v0/products/warehouses/2', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567890']
      }),
      ctx.json(
          { id: "2", description: "Huge warehouse" }
        ),
    )
  }),

  rest.get('/erp/api/v0/products/warehouses/4', (req, res, ctx) => {

    return res(
      ctx.status(404),
      ctx.json(
          { id: "", description: "" }
        ),
    )
  }),

  rest.post('/erp/api/v0/products/warehouses', (req, res, ctx) => {

    return res(
      ctx.status(201),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json({
        id: "4",
        description: "Mars warehouse",
      }),
    )
  }),

  rest.put('/erp/api/v0/products/warehouses/2', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json(
        { id: "2", description: "Biggest warehouse" }
      )
    )
  })
]