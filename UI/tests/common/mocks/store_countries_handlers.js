/* eslint-disable no-unused-vars, no-console */
import { rest } from 'msw'

export const countriesHandlers = [

  rest.get('/erp/api/v0/countries', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.json({
        items: [
          { short_name: "ca", name: "Canada" },
          { short_name: "us", name: "United States" }
        ],
        _links: [{
          title : "HTML",
          rel : "download",
          href : "?format=HTML"
        }]
      }),
    )
  }),

  rest.get('/erp/api/v0/countries/us', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567890']
      }),
      ctx.json(
          { short_name: "us", name: "United States" }
        ),
    )
  }),

  rest.get('/erp/api/v0/countries/zz', (req, res, ctx) => {

    return res(
      ctx.status(404),
      ctx.json(
          { short_name: "", name: "" }
        ),
    )
  }),

  rest.post('/erp/api/v0/countries', (req, res, ctx) => {

    return res(
      ctx.status(201),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json({
        short_name: "zz",
        name: "Atlantida",
      }),
    )
  }),

  rest.put('/erp/api/v0/countries/us', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json(
        { short_name: "us", name: "America" }
      )
    )
  })
]