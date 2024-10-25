/**
 * @format
 * @jest-environment node
 */

/**
 * OpenAPI tests
 *
 * @group openapi
 */

// Import test packages
import jestOpenAPI from "jest-openapi";
import { StatusCodes } from "http-status-codes";
import { create_database, drop_database } from "./database";
import { server } from '../../common/mocks/server.js'

// Load an OpenAPI file (YAML or JSON) into this plugin
const openapi = process.env.PWD.replace("/UI","");
jestOpenAPI( openapi + "/openapi/API.yaml");

// Load the API definition
const fs = require("node:fs");
const yaml = require('js-yaml');
const API_yaml = yaml.load(fs.readFileSync(openapi + "/openapi/API.yaml"));

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

// Product/Warehouses tests
describe("Retrieving all products/warehouses", () => {
    it("GET /products/warehouses should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your serverUrl
        let res = await fetch(serverUrl + "/" + api + "/products/warehouses", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all products/warehouses with old syntax should fail", () => {
    it("GET /products/warehouses/ should fail", async () => {
        const res = await fetch(serverUrl + "/" + api + "/products/warehouses/", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.BAD_REQUEST);
    });
});

describe("Retrieve non-existant Warehouse1", () => {
    it("GET /products/warehouses/nv should not retrieve Warehouse1", async () => {
        const res = await fetch(serverUrl + "/" + api + "/products/warehouses/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.NOT_FOUND);
    });
});

describe("Adding the new Warehouse", () => {
    it("POST /products/warehouses/Warehouse1 should allow adding Warehouse1", async () => {
        let res = await fetch(
            serverUrl + "/" + api + "/products/warehouses",
            {
                method: "POST",
                body: JSON.stringify({
                    description: "Warehouse1"
                }),
                headers: {
                    "X-Requested-With": "XMLHttpRequest",
                    "Content-Type": "application/json",
                    ...headers
                },
            }
        );
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toSatisfySchemaInApiSpec("Warehouse");
    });
});

describe("Validate against the example Warehouse", () => {
    it("GET /products/warehouses/1", async () => {
        let res = await fetch(serverUrl + "/" + api + "/products/warehouses/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const warehouseExample = API_yaml.components.examples.validWarehouse.value;

        // Assert that the response matches the example in the spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toEqual(warehouseExample);
    });
});

describe("Modifying the new Warehouse", () => {
    it("PUT /products/warehouses/Warehouse1 should allow updating Warehouse1", async () => {
        let res = await fetch(
            serverUrl + "/" + api + "/products/warehouses/1",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(
            serverUrl + "/" + api + "/products/warehouses/1",
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
        expect(res.data).toSatisfySchemaInApiSpec("Warehouse");
    });
});

/*
 * Not implemented yet
describe("Updating the new Warehouse1", () => {
    it("PATCH /products/warehouses/nv should allow updating Warehouse1", async () => {
        let res = await fetch(serverUrl + "/" + api + "/products/warehouses/PriceGroup1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(
            serverUrl + "/" + api + "/products/warehouses/nv",
            {
                method: "PATCH",
                body: JSON.stringify({
                    description: "Warehouse1"
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
        expect(res.data).toSatisfySchemaInApiSpec("Warehouse");
    });
});
*/

describe("Not removing the new Warehouse", () => {
    it("DELETE /products/warehouses/PriceGroup1 should allow deleting Warehouse1", async () => {
        let res = await fetch(
            serverUrl + "/" + api + "/products/warehouses/1", {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();

        res = await fetch(serverUrl + "/" + api + "/products/warehouses/1", {
            method: "DELETE",
            headers: { ...headers, "If-Match": etag }
        });
        expect(res.status).toEqual(StatusCodes.FORBIDDEN);
    });
});
