/* eslint-disable no-unused-vars, no-console */
import { http, HttpResponse } from 'msw'

export const warehousesHandlers = [

  http.get('/erp/api/v0/products/warehouses', () => {

    return HttpResponse.json(
      {
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
      },
      { status: 200 }
    )
  }),

  http.get('/erp/api/v0/products/warehouses/2', () => {

    return HttpResponse.json(
      { id: "2", description: "Huge warehouse" },
      {
        status: 200,
        headers: {
          'ETag': ['1234567890']
        }
      }
    )
  }),

  http.get('/erp/api/v0/products/warehouses/4', () => {

    return HttpResponse.json(
      { id: "", description: "" },
      { status: 404 }
    )
  }),

  http.post('/erp/api/v0/products/warehouses', () => {

    return HttpResponse.json(
      {
        id: "4",
        description: "Mars warehouse",
      },
      {
        status: 201,
        headers: {
          'ETag': ['1234567891']
        }
      }
    )
  }),

  http.put('/erp/api/v0/products/warehouses/2', () => {

    return HttpResponse.json(
      { id: "2", description: "Biggest warehouse" },
      {
        status: 200,
        headers: {
          'ETag': ['1234567891']
        }
      }
    )
  })
]
