/* eslint-disable no-unused-vars, no-console */
import { rest } from 'msw'

export const languageHandlers = [

  rest.get('/erp/api/v0/languages', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.json({
        items: [
          { code: "en", description: "English" },
          { code: "fr", description: "Français" }
        ],
        _links: [{
          title : "HTML",
          rel : "download",
          href : "?format=HTML"
        }]
      }),
    )
  }),

  rest.get('/erp/api/v0/languages/en', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567890']
      }),
      ctx.json(
          { code: "en", description: "English" }
        ),
    )
  }),

  rest.get('/erp/api/v0/languages/zz', (req, res, ctx) => {

    return res(
      ctx.status(404),
      ctx.json(
          { code: "", description: "" }
        ),
    )
  }),

  rest.post('/erp/api/v0/languages', (req, res, ctx) => {

    return res(
      ctx.status(201),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json({
        code: "my",
        description: "Mayan",
      }),
    )
  }),

  rest.put('/erp/api/v0/languages/en', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.set({
          'ETag': ['1234567891']
      }),
      ctx.json(
        { code: "en", description: "English (american)" }
      )
    )
  })
]