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

// COUNTRY tests
describe("Retrieving all countries", () => {
    it("GET /countries should satisfy OpenAPI spec", async () => {
        // Get an HTTP response from your serverUrl
        let res = await fetch(serverUrl + "/" + api + "/countries", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res).toSatisfyApiSpec();
    }, 20000);
});

describe("Retrieving all countries with old syntax should fail", () => {
    it("GET /countries/ should fail", async () => {
        let res = await fetch(serverUrl + "/" + api + "/countries/", {
                headers: headers
        });
        expect(res.status).toEqual(StatusCodes.BAD_REQUEST);
    });
});

describe("Validate against the example country", () => {
    it("GET /countries/NL", async () => {
        let res = await fetch(serverUrl + "/" + api + "/countries/NL", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);

        // Pick the example
        const countryExample = API_yaml.components.examples.validCountry.value;

        // Assert that the response matches the example in the spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toEqual(countryExample);
    });
});

describe("Retrieve non-existant COUNTRY ZZ should fail", () => {
    it("GET /countries/ZZ should not retrieve invalid COUNTRY", async () => {
        let res = await fetch(serverUrl + "/" + api + "/countries/ZZ", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.NOT_FOUND);
    });
});

describe("Adding the new Test COUNTRY ZZ", () => {
    it("POST /countries/ZZ should allow adding a new COUNTRY", async () => {
        let res = await fetch(serverUrl + "/" + api + "/countries", {
            method: "POST",
            body: JSON.stringify({
                code: "ZZ",
                name: "Atlantika"
            }),
            headers: { ...headers, "Content-Type": "application/json" }
        });
        expect(res.status).toEqual(StatusCodes.CREATED);

        // Assert that the HTTP response satisfies the OpenAPI spec
        res = await emulateAxiosResponse(res);
        expect(res.data).toSatisfySchemaInApiSpec("Country");
    });
});

describe("Modifying the new COUNTRY ZZ", () => {
    it("PUT /countries/ZZ should allow modifying Atlantica", async () => {
        let res = await fetch(serverUrl + "/" + api + "/countries/ZZ", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(serverUrl + "/" + api + "/countries/ZZ", {
            method: "PUT",
            body: JSON.stringify({
                code: "ZZ",
                name: "Atlantica"
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
        expect(res.data).toSatisfySchemaInApiSpec("Country");
    });
});

/*
 * Not implemented yet
describe("Updating the new COUNTRY ZZ", () => {
    it("PATCH /countries/ZZ should allow updating Atlantica", async () => {
        let res = await fetch(serverUrl + "/" + api + "/countries/ZZ", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();
        res = await fetch(serverUrl + "/" + api + "/countries/ZZ", {
            method: "PATCH",
            body: JSON.stringify({
                code: "ZZ",
                name: "Atlantika"
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
        expect(res.data).toSatisfySchemaInApiSpec("COUNTRY");
    });
});
*/

describe("Not Removing COUNTRY ZZ", () => {
    it("DELETE /countries/ZZ should not allow deleting Test COUNTRY", async () => {
        let res = await fetch(serverUrl + "/" + api + "/countries/ZZ", {
            headers: headers
        });
        expect(res.status).toEqual(StatusCodes.OK);
        const etag = res.headers.get("etag");
        expect(etag).toBeDefined();

        res = await fetch(serverUrl + "/" + api + "/countries/ZZ", {
            method: "DELETE",
            headers: { ...headers, "If-Match": etag }
        });
        expect(res.status).toEqual(StatusCodes.FORBIDDEN);
    });
});
