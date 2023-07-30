/** @format */

/**
 * OpenAPI tests
 *
 * @group openapi
 */

// Import test packages
import axios from "axios";
import jestOpenAPI from "jest-openapi";
import { StatusCodes } from "http-status-codes";
import { create_database, drop_database, load_coa, initialize } from "./database";
import { server } from '../../common/mocks/server.js'

// Load an OpenAPI file (YAML or JSON) into this plugin
const openapi = process.env.PWD.replace("/UI","");
jestOpenAPI( openapi + "/openapi/API.yaml");

// Load the API definition
const API_yaml = require (openapi + "/openapi/API.yaml");

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
    axios.defaults.adapter = 'http';
    create_database(username, password, company);
    load_coa(username, password, company, "locale/coa/us/General.xml");
    initialize(company,"UI/tests/specs/data/Invoices.sql");

    // Establish API mocking before all tests.
    server.listen({
        onUnhandledRequest: 'bypass'
    });
});

afterAll(() => {
    drop_database(company);
});

// Log in before each test
beforeEach(async () => {
    let r = await axios.post(
        serverUrl + "/login.pl?action=authenticate&company=" + encodeURI(company),
        {
            company: company,
            password: password,
            login: username
        },
        {
            headers: {
                "X-Requested-With": "XMLHttpRequest",
                "Content-Type": "application/json"
            }
        }
    );
    if (r.status === StatusCodes.OK) {
        headers = {
            cookie: r.headers["set-cookie"],
            referer: serverUrl + "/" + r.data.target,
            authorization: "Basic " + btoa(username + ":" + password)
        };
    }
});
// Log out after each test
afterEach(async () => {
    let r = await axios.get(serverUrl + "/login.pl?action=logout&target=_top");
    if (r.status === StatusCodes.OK) {
        headers = {};
    }
});

// Invoice tests
describe("Retrieving all invoices", () => {
    it("GET /invoices fail", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/invoices", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.NOT_IMPLEMENTED
        );
    });
});

describe("Adding the new Invoice", () => {
    it("POST /invoices should allow adding a new invoice", async () => {
        let res;
        try {
            res = await axios.post(
                serverUrl + "/" + api + "/invoices",
                {
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
                    "internal-notes": "Internal notes",
                    "invoice-number": "2389434",
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
                            delivery_date: "2022-10-27",
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
                            source: "visa"
                        }
                    ]
                },
                {
                    headers: headers
                }
        );
        } catch(e) {
            console.log(e.response.data);
        }
        expect(res.status).toEqual(StatusCodes.CREATED);
        expect(res.headers.location).toMatch('./1');
    });
});

/*
describe("Adding the new Invoice", () => {
    it("POST /invoices should allow adding a new invoice", async () => {
        let res;
        try {
            res = await axios.post(
                serverUrl + "/" + api + "/invoices",
                {
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
                    description: "Annual gizmos",
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
                            delivery_date: "2022-10-27",
                            description: "A description"
                        }
                    ],
                    notes: "Notes",
                    "internal-notes": "Internal notes",
                    "invoice-number": "2389434",
                    "order-number": "order 345",
                    "po-number": "po 456",
                    "ship-via": "ship via",
                    "shipping-point": "shipping from here",
                    "ship-to": "ship to there",
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
                            source: "visa"
                        }
                    ]
                },
                {
                    headers: headers
                }
        );
        } catch(e) {
            console.log(e.response.data);
        }
        expect(res.status).toEqual(StatusCodes.CREATED);
        expect(res.headers.location).toMatch('./1');
    });
});
*/

describe("Retrieving all invoices with old syntax should fail", () => {
    it("GET /invoices/ should fail", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/invoices/", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.BAD_REQUEST
        );
    });
});

describe("Retrieve first invoice", () => {
    it("GET /invoices/1 should work and satisfy the OpenAPI spec", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/invoices/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Invoice");
    });
});

describe("Validate first invoice against example", () => {
    it("GET /invoices/1 should validate against example", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/invoices/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const invoiceExample = API_yaml.components.examples.validInvoice.value;

        // Assert that the response matches the example in the spec
        expect(res.data).toEqual(invoiceExample);
    });
});

describe("Retrieve non-existant Invoice", () => {
    it("GET /invoices/2 should not retrieve Invoice 2", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/invoices/2", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.NOT_FOUND
        );
    });
});

/*
describe("Modifying the Invoice 1", () => {
    it("PUT /invoices/1 should allow updating Invoice 1", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/invoices/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.put(
            serverUrl + "/" + api + "/invoices/1",
            {
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
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Invoice");
    });
});


 * Not implemented yet
describe("Updating the Invoice 1", () => {
    it("PATCH /invoices/1 should allow updating Invoice 1", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/invoices/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.patch(
            serverUrl + "/" + api + "/invoices/1",
            {
                ...
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Language");
    });
});

describe("Not removing Invoice 1", () => {
    it("DELETE /invoices/1 should allow deleting Invoice 1", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/invoices/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();

        await expect(
            axios.delete(serverUrl + "/" + api + "/invoices/1", {
                headers: { ...headers, "If-Match": res.headers.etag }
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.NOT_IMPLEMENTED
        );
    });
});
*/
