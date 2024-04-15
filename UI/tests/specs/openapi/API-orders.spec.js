/** @format */

// Import test packages
import jestOpenAPI from "jest-openapi";
import { StatusCodes } from "http-status-codes";
import {
    create_database,
    drop_database,
    load_coa,
    initialize
} from "./database";
import { server } from "../../common/mocks/server.js";

// Load an OpenAPI file (YAML or JSON) into this plugin
const openapi = process.env.PWD.replace("/UI", "");
jestOpenAPI(openapi + "/openapi/API.yaml");

// Load the API definition
const API_yaml = require(openapi + "/openapi/API.yaml");

// Set API version to use
const api = "erp/api/v0";

// Access to the database test user
const id = Math.random().toString(36).substr(2, 6);

const username = `Jest${id}`;
const password = "Tester";
const company = `lsmb_test_api_${id}`;
const serverUrl = process.env.LSMB_BASE_URL;

let headers = {};

// For all tests
beforeAll(() => {
    create_database(username, password, company);
    load_coa(username, password, company, "locale/coa/us/General.xml");
    initialize(company, "UI/tests/specs/data/Orders.sql");

    // Establish API mocking before all tests.
    server.listen({
        onUnhandledRequest: "bypass"
    });
});

afterAll(() => {
    drop_database(company);
});

const emulateAxiosResponse = async (res) => {
    return {
        data: await res.json(),
        status: res.status,
        statusText: res.statusText,
        headers: res.headers,
        request: {
            path: res.url,
            method: "GET"
        }
    };
};

// Log in before each test
beforeEach(async () => {
    let r = await fetch(
        serverUrl +
            "/login.pl?action=authenticate&company=" +
            encodeURI(company),
        {
            method: "POST",
            body: JSON.stringify({
                company: company,
                password: password,
                login: username
            }),
            headers: {
                "X-Requested-With": "XMLHttpRequest",
                "Content-Type": "application/json"
            }
        }
    );
    if (r.status === StatusCodes.OK) {
        await r.json();
        headers = {
            cookie: r.headers.get("set-cookie")
        };
    }
});
// Log out after each test
afterEach(async () => {
    let r = await fetch(serverUrl + "/login.pl?action=logout&target=_top");
    if (r.status === StatusCodes.OK) {
        headers = {};
    }
});

// Orders tests
describe("Retrieving all orders", () => {
    it("GET /orders fail", async () => {
        let res = await fetch(serverUrl + "/" + api + "/orders", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.NOT_IMPLEMENTED);
    });
});

describe("Adding the new Order", () => {
    it("POST /orders should allow adding a new order", async () => {
        let res;
        try {
            res = await fetch(serverUrl + "/" + api + "/orders", {
                method: "POST",
                body: JSON.stringify({
                    eca: {
                        number: "Customer 1",
                        type: "customer" // Watch for exact case or watch serverUrl stack dump
                    },
                    currency: "USD",
                    dates: {
                        order: "2022-09-01",
                        "required-by": "2022-10-01"
                    },
                    "internal-notes": "Internal notes",
                    lines: [
                        {
                            part: {
                                number: "p1"
                            },
                            price: 56.78,
                            price_fixated: false,
                            unit: "lbs",
                            qty: 1,
                            taxform: true,
                            serialnumber: "1234567890",
                            discount: 12,
                            discount_type: "%",
                            "required-by": "2022-10-27",
                            description: "A description"
                        }
                    ],
                    notes: "Notes",
                    "order-number": "order 345",
                    "po-number": "po 456",
                    "shipping-point": "shipping from here",
                    // TODO: Debug ship-to
                    // "ship-to": "ship to there",
                    "ship-via": "ship via",
                    taxes: {
                        2150: {
                            tax: {
                                category: "2150"
                            },
                            "base-amount": 50,
                            amount: 6.78,
                            source: "Part 1",
                            memo: "tax memo" // Could that be optional?
                        }
                    }
                }),
                headers: { ...headers, "Content-Type": "application/json" }
            });
        } catch (e) {
            console.log(e.response.data);
        }
        expect(res.status).toEqual(StatusCodes.CREATED);
        expect(res.headers.get("location")).toMatch("./1");
    });
});

describe("Retrieving all orders with old syntax should fail", () => {
    it("GET /orders/ should fail", async () => {
        const res = await fetch(serverUrl + "/" + api + "/orders/", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.NOT_FOUND);
    });
});

describe("Retrieve first order", () => {
    it("GET /orders/1 should work and satisfy the OpenAPI spec", async () => {
        let res = await fetch(serverUrl + "/" + api + "/orders/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Order");
    });
});

describe("Validate first order against example", () => {
    it("GET /orders/1 should validate against example", async () => {
        let res = await fetch(serverUrl + "/" + api + "/orders/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const orderExample = API_yaml.components.examples.validOrder.value;

        // Assert that the response matches the example in the spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toEqual(orderExample);
    });
});

describe("Retrieve non-existant Order", () => {
    it("GET /orders/2 should not retrieve Order 2", async () => {
        let res = await fetch(serverUrl + "/" + api + "/orders/2", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.NOT_FOUND);
    });
});

/*
describe("Modifying the new Invoice", () => {
    it("PUT /invoices/1 should allow updating Invoice 1", async () => {
        let res = await fetch(serverUrl + "/" + api + "/invoices/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(
            serverUrl + "/" + api + "/invoices/1",
            {
                method: "PUT",
                body: JSON.stringify({
                    eca: {
                        number: "Customer 1",
                        type: "customer" // Watch for exact case or watch serverUrl stack dump
                    },
                    account: {
                        accno: "1200"
                    },
                    currency: "USD",
                    dates: {
                        created: "2022-09-01",
                        due: "2022-10-01",
                        book: "2022-10-05"
                    },
                    lines: [
                        {
                            part: {
                                number:"p1"
                            },
                            price: 56.78,
                            price_fixated: false,
                            unit: "lbs",
                            qty: 1,
                            taxform: true,
                            serialnumber: "1234567890",
                            discount: 12,
                            discount_type: "%",
                            delivery_date: "2022-10-27",
                            description: "A description",
                            notes: "Notes",
                            "internal-notes": "Internal notes",
                            "invoice-number": "2389434",
                            "order-number": "order 345",
                            "po-number": "po 456",
                            "ship-via": "ship via",
                            "shipping-point": "shipping from here",
                            "ship-to": "ship to there"
                        }
                    ],
                    taxes: {
                        "2150": {
                            tax: {
                                category: "2150"
                            },
                            "base-amount": 50,
                            amount: 6.78,
                            source: "Part 1",
                            memo: "tax memo" // Could that be optional?
                        },
                    },
                    payments: [
                        {
                            account: {
                                accno: "5010"
                            },
                            date: "2022-11-05",
                            amount: 20,
                            memo: "depot",
                            source: "Amex"
                        }
                    ]
                }),
                headers: {
                    ...headers,
                    "Content-Type": "application/json",
                    "If-Match": etag
                }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Invoice");
    });
});


 * Not implemented yet
describe("Updating the Invoice 1", () => {
    it("PATCH /invoices/1 should allow updating Invoice 1", async () => {
        let res = await fetch(serverUrl + "/" + api + "/invoices/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(
            serverUrl + "/" + api + "/invoices/1",
            {
                method: "PATCH",
                body: JSON.stringify({
                    // ...
                }),
                headers: {
                    ...headers,
                    "Content-Type": "application/json",
                    "If-Match": etag
                }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Language");
    });
});

describe("Not removing Invoice 1", () => {
    it("DELETE /invoices/1 should allow deleting Invoice 1", async () => {
        let res = await fetch(serverUrl + "/" + api + "/invoices/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();

        res = await fetch(serverUrl + "/" + api + "/invoices/1", {
            method: "DELETE",
            headers: { ...headers, "If-Match": etag }
        });
        expect(res.status).toEqual(StatusCodes.NOT_IMPLEMENTED);
    });
});
*/
