import { http, HttpResponse } from 'msw'

export const gifiHandlers = [

  http.get('/erp/api/v0/gl/gifi', () => {

    return HttpResponse.json(
      {
        items : [
          {
            "accno" : "0000",
            "description" : "Dummy account"
          },
          {
            "accno" : "0001",
            "description" : "Dummy account 1"
          }
        ],
        _links : [
          {
            "href" : "?format=HTML",
            "rel" : "download",
            "title" : "HTML"
          }
        ]
      },
      {
        status: 200
      }
    )
  }),

  http.get('/erp/api/v0/gl/gifi/0000', () => {

    return HttpResponse.json(
      {
        "accno" : "0000",
        "description" : "Dummy account"
      }, {
        status: 200,
        headers: {
          'ETag': ['1234567890']
        }
      }
    )
  }),

  http.get('/erp/api/v0/gl/gifi/0002', () => {

    return HttpResponse.json(
      {
        code: "",
        description: ""
      },
      { status: 404 }
    )
  }),

  http.post('/erp/api/v0/gl/gifi', () => {

    return HttpResponse.json(
      {
        accno: "0002",
        description: "Dummy account 2",
      }, {
      status: 201,
      headers: {
        'ETag': ['1234567891']
      }
    })
  }),

  http.put('/erp/api/v0/gl/gifi/0000', () => {

    return HttpResponse.json(
      {
        accno: "0000",
        description: "Funny account"
      }, {
        status: 200,
        headers: {
          'ETag': ['1234567891']
        }
      })
  })
]
