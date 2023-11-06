/* eslint-disable no-unused-vars, no-console */
import { http, HttpResponse } from 'msw'

export const pricegroupHandlers = [

  http.get('/erp/api/v0/products/pricegroups', () => {

    return HttpResponse.json(
      {
        items: [
          { id: "1", description: "Price group 1" },
          { id: "2", description: "Price group 2" }
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

  http.get('/erp/api/v0/products/pricegroups/1', () => {

    return HttpResponse.json(
      { id: "1", description: "Price group 1" },
      {
        status: 200,
        headers: {
          'ETag': ['1234567890']
        }
      }
    )
  }),

  http.get('/erp/api/v0/products/pricegroups/3', () => {

    return HttpResponse.json(
      { id: "", description: "" },
      { status: 404 }
    )
  }),

  http.post('/erp/api/v0/products/pricegroups', () => {

    return HttpResponse.json(
      {
        id: "3",
        description: "Price Group #3",
      },
      {
        status: 201,
        headers: {
          'ETag': ['1234567891']
        }
      }
    )
  }),

  http.put('/erp/api/v0/products/pricegroups/1', () => {

    return HttpResponse.json(
      { id: "1", description: "Price Group #1" },
      {
        status: 200,
        headers: {
          'ETag': ['1234567891']
        }
      }
    )
  })
]
