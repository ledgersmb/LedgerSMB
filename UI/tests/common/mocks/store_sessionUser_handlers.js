/* eslint-disable no-unused-vars, no-console */
import { http, HttpResponse } from 'msw'

export const sessionUserHandlers = [

  http.get('/erp/api/v0/session', ({ request }) => {

    return HttpResponse.json(
      {
        "password_expiration" : "P1Y",
        "roles" : [
            "account_all",
            "base_user",
            "cash_all",
            "gl_all"
        ],
        "preferences" : {
            "numberformat" : "1000.00",
            "printer" : null,
            "stylesheet" : "ledgersmb.css",
            "dateformat" : "yyyy-mm-dd",
            "language" : null
        }
      },
      { status: 200 }
    )
  })

]