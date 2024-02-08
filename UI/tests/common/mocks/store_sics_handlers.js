/* eslint-disable no-unused-vars, no-console */
import { http, HttpResponse } from 'msw'

export const sicsHandlers = [

  http.get('/erp/api/v0/contacts/sic', () => {

    return HttpResponse.json(
      {
        items: [
          { code: "541330", description: "Engineering service", _meta: { ETag: "1234567890" } },
          { code: "611430", description: "Professional and management development training", _meta: { ETag: "1234567889" } }
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

  http.get('/erp/api/v0/contacts/sic/541330', () => {

    return HttpResponse.json(
      { code: "541330", description: "Engineering service" },
      {
        status: 200,
        headers: {
          ETag: '1234567890'
        }
      }
    )
  }),

  http.get('/erp/api/v0/contacts/sic/541510', () => {

    return HttpResponse.json(
      { code: "", description: "" },
      { status: 404 }
    )
  }),

  http.post('/erp/api/v0/contacts/sic', () => {

    return HttpResponse.json(
      {
        code: "541510",
        description: "Design of computer systems",
      },
      {
      status: 201,
      headers: {
          ETag: '1234567891'
      }}
    )
  }),

  http.put('/erp/api/v0/contacts/sic/541330', () => {

    return HttpResponse.json(
      {
        code: "541330",
        description: "Engineering services"
      },
      {
        status: 200,
        headers: {
          ETag: '1234567891'
        }
      }
    )
  })
]
