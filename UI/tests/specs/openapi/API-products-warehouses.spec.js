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
    axios.defaults.adapter = 'http';
    create_database(username, password, company);

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

// Product/Warehouses tests
describe("Retrieving all products/warehouses", () => {
    it("GET /products/warehouses should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your serverUrl
        let res = await axios.get(serverUrl + "/" + api + "/products/warehouses", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all products/warehouses with old syntax should fail", () => {
    it("GET /products/warehouses/ should fail", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/products/warehouses/", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.BAD_REQUEST
        );
    });
});

describe("Retrieve non-existant Warehouse1", () => {
    it("GET /products/warehouses/nv should not retrieve Warehouse1", async () => {
        await expect(
            axios.get(serverUrl + "/" + api + "/products/warehouses/1", {
                headers: headers
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.NOT_FOUND
        );
    });
});

describe("Adding the new Warehouse", () => {
    it("POST /products/warehouses/Warehouse1 should allow adding Warehouse1", async () => {
        let res = await axios.post(
            serverUrl + "/" + api + "/products/warehouses",
            {
                description: "Warehouse1"
            },
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Warehouse");
    });
});

describe("Validate against the example Warehouse", () => {
    it("GET /products/warehouses/1", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/products/warehouses/1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const warehouseExample = API_yaml.components.examples.validWarehouse.value;

        // Assert that the response matches the example in the spec
        expect(res.data).toEqual(warehouseExample);
    });
});

describe("Modifying the new Warehouse", () => {
    it("PUT /products/warehouses/Warehouse1 should allow updating Warehouse1", async () => {
        let res = await axios.get(
            serverUrl + "/" + api + "/products/warehouses/1",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.put(
            serverUrl + "/" + api + "/products/warehouses/1",
            {
                id: 1,
                description: "PriceGroup1"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Warehouse");
    });
});

/*
 * Not implemented yet
describe("Updating the new Warehouse1", () => {
    it("PATCH /products/warehouses/nv should allow updating Warehouse1", async () => {
        let res = await axios.get(serverUrl + "/" + api + "/products/warehouses/PriceGroup1", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();
        res = await axios.patch(
            serverUrl + "/" + api + "/products/warehouses/nv",
            {
                description: "Warehouse1"
            },
            {
                headers: { ...headers, "If-Match": res.headers.etag }
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("Warehouse");
    });
});
*/

describe("Not removing the new Price Group", () => {
    it("DELETE /products/warehouses/PriceGroup1 should allow deleting Warehouse1", async () => {
        let res = await axios.get(
            serverUrl + "/" + api + "/products/warehouses/1",
            {
                headers: headers
            }
        );
        expect(res.status).toEqual(StatusCodes.OK);
        expect(res.headers.etag).toBeDefined();

        await expect(
            axios.delete(serverUrl + "/" + api + "/products/warehouses/1", {
                headers: { ...headers, "If-Match": res.headers.etag }
            })
        ).rejects.toThrow(
            "Request failed with status code " + StatusCodes.FORBIDDEN
        );
    });
});
