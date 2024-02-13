/* eslint-disable no-unused-vars, no-console */
import { http, HttpResponse } from 'msw'

export const languageHandlers = [

  http.get('/erp/api/v0/languages', () => {

    return HttpResponse.json(
      {
        items: [
            { code: "en", default: false, description: "English" },
            { code: "fr", default: false, description: "Français" }
        ],
        _links: [{
          title : "HTML",
          rel : "download",
          href : "?format=HTML"
        }]
      },
      { status: 200 }
    )
  }),

  http.get('/erp/api/v0/languages/en', () => {

    return HttpResponse.json(
      { code: "en", description: "English" },
      {
        status: 200,
        headers: {
          'ETag': ['1234567890']
        }
      }
    )
  }),

  http.get('/erp/api/v0/languages/zz', () => {

    return HttpResponse.json(
      { code: "", description: "" },
      { status: 404 }
    )
  }),

  http.post('/erp/api/v0/languages', () => {

    return HttpResponse.json(
      {
        code: "my",
        description: "Mayan",
      }, {
        status: 201,
        headers: {
          'ETag': ['1234567891']
        }
      }
    )
  }),

  http.put('/erp/api/v0/languages/en', () => {

    return HttpResponse.json(
        { code: "en", default: false, description: "English (american)" },
      {
        status: 200,
        headers: {
          'ETag': ['1234567891']
        }
      }
    )
  })
]
