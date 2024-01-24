/** @format */

// Import test packages
import jestOpenAPI from "jest-openapi";
import { StatusCodes } from "http-status-codes";
import { create_database, drop_database } from "./database";
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
    create_database(username, password, company);

    // Establish API mocking before all tests.
    server.listen({
        onUnhandledRequest: 'bypass'
    });
});

afterAll(() => {
    drop_database(company);
});

const emulateAxiosResponse = async(res) => {
    return {
        data: await res.json(),
        status: res.status,
        statusText: res.statusText,
        headers: res.headers,
        request: {
            path: res.url,
            method: 'GET'
        }
    };
};

// Log in before each test
beforeEach(async () => {
    let r = await fetch(
        serverUrl + "/login.pl?action=authenticate&company=" + encodeURI(company),
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
        const data = await r.json();
        headers = {
            cookie: r.headers.get("set-cookie"),
            referer: serverUrl + "/" + data.target,
            authorization: "Basic " + btoa(username + ":" + password)
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

// Product/Pricegroups tests
describe("Retrieving all products/pricegroups", () => {
    it("GET /products/pricegroups should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your serverUrl
        let res = await fetch(
            serverUrl + "/" + api + "/products/pricegroups",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all products/pricegroups with old syntax should fail", () => {
    it("GET /products/pricegroups/ should fail", async () => {
        let res = await fetch(serverUrl + "/" + api + "/products/pricegroups/", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.BAD_REQUEST);
    });
});

describe("Retrieve non-existant Pricegroup1", () => {
    it("GET /products/pricegroups/nv should not retrieve Pricegroup1", async () => {
        let res = await fetch(serverUrl + "/" + api + "/products/pricegroups/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.NOT_FOUND);
    });
});

describe("Adding the new Price Group", () => {
    it("POST /products/pricegroups/Pricegroup1 should allow adding Pricegroup1", async () => {
        let res = await fetch(
            serverUrl + "/" + api + "/products/pricegroups",
            {
                method: "POST",
                body: JSON.stringify({
                    name: "Pricegroup1",
                    description: "Pricegroup1"
                }),
                headers: {
                    "X-Requested-With": "XMLHttpRequest",
                    "Content-Type": "application/json",
                    ...headers
                }
            }
        );
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toSatisfySchemaInApiSpec("Pricegroup");
    });
});

describe("Validate against the example Pricegroup", () => {
    it("GET /products/pricegroups/1", async () => {
        let res = await fetch(serverUrl + "/" + api + "/products/pricegroups/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const pricegroupExample = API_yaml.components.examples.validPricegroup.value;

        // Assert that the response matches the example in the spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toEqual(pricegroupExample);
    });
});

describe("Modifying the new Price Group", () => {
    it("PUT /products/pricegroups/Pricegroup1 should allow updating Pricegroup1", async () => {
        let res = await fetch(
            serverUrl + "/" + api + "/products/pricegroups/1",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(
            serverUrl + "/" + api + "/products/pricegroups/1",
            {
                method: "PUT",
                body: JSON.stringify({
                    id: 1,
                    description: "PriceGroup1"
                }),
                headers: {
                    ...headers,
                    "content-type": "application/json",
                    "If-Match": etag
                }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Pricegroup");
    });
});

/*
 * Not implemented yet
describe("Updating the new Pricegroup1", () => {
    it("PATCH /products/pricegroups/nv should allow updating Pricegroup1", async () => {
        let res = await fetch(serverUrl + "/" + api + "/products/pricegroups/PriceGroup1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(
            serverUrl + "/" + api + "/products/pricegroups/nv",
            {
                method: "PATCH",
                body: JSON.stringify({
                    description: "Pricegroup1"
                }),
                headers: {
                    "X-Requested-With": "XMLHttpRequest",
                    "Content-Type": "application/json",
                    ...headers,
                    "If-Match": etag
                }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Pricegroup");
    });
});
*/

describe("Not removing the new Price Group", () => {
    it("DELETE /products/pricegroups/PriceGroup1 should allow deleting Pricegroup1", async () => {
        let res = await fetch(
            serverUrl + "/" + api + "/products/pricegroups/1",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();

        res = await fetch(serverUrl + "/" + api + "/products/pricegroups/1", {
            method: "DELETE",
            headers: { ...headers, "If-Match": etag }
        });
        expect(res.status).toEqual(StatusCodes.FORBIDDEN);
    });
});
