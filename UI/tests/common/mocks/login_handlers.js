/** @format */

import { http, HttpResponse } from "msw";

export const loginHandlers = [
    http.post("login.pl", async ({ request }) => {
        const url = new URL(request.url);
        const action = url.searchParams.get("action");
        const params = await request.json();
        const username = params.login;
        const password = params.password;
        const company = params.company;

        if (action === "authenticate") {
            if (
                username === "MyUser" &&
                password === "MyPassword" &&
                company === "MyCompany"
            ) {
                window.location.assign("http://lsmb/erp.pl?action=root");
                return new HttpResponse(null, {
                    status: 200
                });
            }
            if (username && password && company === "MyOldCompany") {
                return new HttpResponse(null, {
                    status: 521
                });
            }
            if (username === "BadUser" && password && company) {
                return new HttpResponse(null, {
                    status: 401
                });
            }
        }
        if (username === "My" && password === "My" && company === "My") {
            return new HttpResponse(null, {
                status: 500
            });
        }
        return new HttpResponse.error("Failed to connect");
    })
];
