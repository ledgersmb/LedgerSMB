/* eslint-disable no-unused-vars, no-console */
import { http, HttpResponse } from 'msw';

export const businessTypesHandlers = [

  http.get('/erp/api/v0/contacts/business-types', () => {

    return HttpResponse.json(
      {
        items: [
            { id: "1", description: "Big customer", discount: 0.05, _meta: { ETag: "1234567890" }},
            { id: "2", description: "Bigger customer", discount: 0.15, _meta: { ETag: "1234567890" }}
        ],
        _links: [{
          title : "HTML",
          rel : "download",
          href : "?format=HTML"
        }]
      }, {
      status: 200,
    })
  }),

  http.get('/erp/api/v0/contacts/business-types/2', () => {

    return HttpResponse.json(
      {
        id: "2",
        description: "Bigger customer",
        discount: 0.15
      }, {
      status: 200,
      headers: {
          ETag: '1234567890'
      }
    })
  }),

  http.get('/erp/api/v0/contacts/business-types/3', () => {

    return HttpResponse.json(
      { id: "", code: "", description: "" }, {
      status: 404
      })
  }),

  http.post('/erp/api/v0/contacts/business-types', () => {

    return HttpResponse.json(
      {
        id: "3",
        description: "Great customer",
        discount: 0.22
      }, {
      status: 201,
      headers: {
          ETag: '1234567891'
      }
    })
  }),

  http.put('/erp/api/v0/contacts/business-types/2', () => {

    return HttpResponse.json(
      {
        id: "2",
        description: "Bigger customer",
        discount: 0.25
      }, {
      status: 200,
      headers: {
          ETag: '1234567891'
      }
    })
  })
]
