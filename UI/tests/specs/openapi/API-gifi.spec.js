/**
 * @format
 * @jest-environment node
 */
/* global process, require */

// Import test packages
import jestOpenAPI from "jest-openapi";
import { StatusCodes } from "http-status-codes";
import { create_database, drop_database } from "./database";
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

// GIFI tests
describe("Retrieving all gifis", () => {
    it("GET /gifi should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your serverUrl
        let res = await fetch(serverUrl + "/" + api + "/gl/gifi", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();
    });
});

describe("Retrieving all gifis with old syntax should fail", () => {
    it("GET /gifi/ should fail", async () => {
        let res = await fetch(serverUrl + "/" + api + "/gl/gifi/", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.NOT_FOUND);
    });
});

describe("Retrieve non-existant GIFI 99999", () => {
    it("GET /gifi/99999 should not retrieve invalid GIFI", async () => {
        let res = await fetch(serverUrl + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.NOT_FOUND);
    });
});

describe("Adding the new Test GIFI", () => {
    it("POST /gifi/99999 should allow adding a new GIFI", async () => {
        let res = await fetch(serverUrl + "/" + api + "/gl/gifi", {
            method: "POST",
            body: JSON.stringify({
                accno: "99999",
                description: "Test GIFI"
            }),
            headers: { ...headers, "Content-Type": "application/json" }
        });
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toSatisfySchemaInApiSpec("GIFI");
    });
});

describe("Validate against the example GIFI 99999", () => {
    it("GET /gifi/99999 should validate our new GIFI", async () => {
        let res = await fetch(serverUrl + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const gifiExample = API_yaml.components.examples.validGIFI.value;

        // Assert that the response matches the example in the spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toEqual(gifiExample);
    });
});

describe("Modifying the new GIFI 99999", () => {
    it("PUT /gifi/99999 should allow updating Test GIFI", async () => {
        let res = await fetch(serverUrl + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(serverUrl + "/" + api + "/gl/gifi/99999", {
            method: "PUT",
            body: JSON.stringify({
                accno: "99999",
                description: "Test GIFI"
            }),
            headers: {
                ...headers,
                "Content-Type": "application/json",
                "If-Match": etag
            }
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();

        // Assert that the HTTP response satisfies the OpenAPI spec
        expect(res.data).toSatisfySchemaInApiSpec("GIFI");
    });
});

/*
 * Not implemented yet
describe("Updating the new GIFI 99999", () => {
    it("PATCH /gifi/99999 should allow updating Test GIFI", async () => {
        let res = await fetch(serverUrl + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(
            serverUrl + "/" + api + "/gl/gifi/99999",
            {
                method: "PATCH",
                body: JSON.stringify({
                    accno: "99999",
                    description: "Test GIFI"
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
        expect(res.data).toSatisfySchemaInApiSpec("GIFI");
    });
});
*/

describe("Not Removing the new GIFI 99999", () => {
    it("DELETE /gifi/99999 should allow deleting Test GIFI", async () => {
        let res = await fetch(serverUrl + "/" + api + "/gl/gifi/99999", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();

        res = await fetch(serverUrl + "/" + api + "/gl/gifi/99999", {
            method: "DELETE",
            headers: { ...headers, "If-Match": etag }
        });
        expect(res.status).toEqual(StatusCodes.FORBIDDEN);
    });
});
