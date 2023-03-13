/* eslint-disable no-unused-vars, no-console */
import { rest } from 'msw'

export const sessionUserHandlers = [

  rest.get('/erp/api/v0/session', (req, res, ctx) => {

    return res(
      ctx.status(200),
      ctx.json({
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
      }),
    )
  }),

]