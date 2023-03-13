import { rest } from 'msw';

export const loginHandlers = [

    rest.post('login.pl', async (req, res, ctx) => {

        const action = req.url.searchParams.get('action');
        const params = await req.json();
        const username = params.login;
        const password = params.password;
        const company = params.company;

        if ( action === 'authenticate' ) {
            if ( username === 'MyUser' && password === 'MyPassword' && company === 'MyCompany' ) {
                window.location.assign('http://lsmb/erp.pl?action=root');
                return res(
                  ctx.status(200)
                );
            }
            if ( username && password && company === 'MyOldCompany' ) {
                return res(
                    ctx.status(521)
                );
            }
            if ( username === 'BadUser' && password && company ) {
                return res(
                    ctx.status(401)
                );
            }
        }
        if (username === 'My' && password === 'My' && company === 'My') {
            return res(
                ctx.status(500)
            );
        }
        return res.networkError('Failed to connect');
    })
]
  
