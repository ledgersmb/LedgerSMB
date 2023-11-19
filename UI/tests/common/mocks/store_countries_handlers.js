/* eslint-disable no-unused-vars, no-console */
import { http, HttpResponse } from 'msw'

export const countriesHandlers = [

  http.get('/erp/api/v0/countries', () => {

    return HttpResponse.json(
      {
        items: [
            { code: "ca", default: false, name: "Canada" },
            { code: "us", default: false, name: "United States" }
        ],
        _links: [{
          title : "HTML",
          rel : "download",
          href : "?format=HTML"
        }]
      }, {
        status: 200
      })
  }),

  http.get('/erp/api/v0/countries/us', () => {

    return HttpResponse.json(
      { code: "us", name: "United States" },
      {
      status: 200,
      headers: {
          'ETag': ['1234567890']
        }
      }
    )
  }),

  http.get('/erp/api/v0/countries/zz', () => {

    return HttpResponse.json(
      { code: "", name: "" },
      { status: 404 }
    )
  }),

  http.post('/erp/api/v0/countries', () => {

    return HttpResponse.json(
      {
        code: "zz",
        name: "Atlantida",
      },
      {
        status: 201,
        headers: {
          'ETag': ['1234567891']
        }
      }
    )
  }),

  http.put('/erp/api/v0/countries/us', () => {

    return HttpResponse.json(
        { code: "us", default: false, name: "America" },
        {
            status: 200,
            headers: {
                'ETag': ['1234567891']
            }
        }
    )
  })
]
